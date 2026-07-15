import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:pairfi/features/pairing/audio/interfaces/second_channel_interface.dart';
import 'package:pairfi/features/settings/settings_interface.dart';
import 'package:pairfi/helper_functions.dart';

class NexmonUDPChannelService extends SecondChannelService<Uint8List> {
  static const PACKET_TYPE_DATA_RESPONSE = 0x04;
  static const PACKET_TYPE_PING_REPLY = 0x06;

  final InternetAddress _nexmonHost;
  final int _nexmonPort;
  final InternetAddress _listenIP;
  final int _listenPort;

  String get nexmonHost => _nexmonHost.address;
  int get nexmonPort => _nexmonPort;
  String get listenIP => _listenIP.address;
  int get listenPort => _listenPort;

  /// A stream that publishes the sequence numbers of successful ping messages
  final StreamController<int> _pingReplies;

  static NexmonUDPChannelService createServiceWithSettings(SettingsService settings) {
    final nexmonHost = settings.getString("nexmonHostIP") ?? "192.168.49.255";
    final nexmonPort = int.tryParse(settings.getString("nexmonPort") ?? "52066") ?? 52066;

    return NexmonUDPChannelService(nexmonHost, nexmonPort, "0.0.0.0", 52067);
  }

  NexmonUDPChannelService(String nexmonHost, this._nexmonPort, String listenIP, this._listenPort)
      : this._nexmonHost = InternetAddress(nexmonHost),
        this._listenIP = InternetAddress(listenIP),
        this._pingReplies = StreamController() {
    cleanInit();
  }

  final List<Uint8List> _receivedData = [];

  RawDatagramSocket? _socket;

  Function(Uint8List)? _onReceiveData;

  Future<void> cleanInit() async {
    await _setupUDPListener();
  }

  @override
  Future<bool> startTransmission(Uint8List data) async {
    if (data.length > 0xff) {
      throw Exception("Data is too large!");
    }

    debugPrint("[NexmonUDPChannelService] Starting transmission of ${data.toHexString()}");

    final packetHeader = Uint8List.fromList([0x01, data.length]);
    final packet = packetHeader + data;

    final bytesSent = _socket?.send(packet, _nexmonHost, _nexmonPort) ?? 0;
    return bytesSent > 0;
  }

  @override
  Future<void> stopTransmission() async {
    debugPrint("[NexmonUDPChannelService] Stopping transmission.");
    final packet = Uint8List.fromList([0x02]);
    _socket?.send(packet, _nexmonHost, _nexmonPort);
  }

  @override
  Future<void> startReceiving({Function(Uint8List)? onData}) async {
    debugPrint("[NexmonUDPChannelService] Starting reception.");
    _onReceiveData = onData;

    final packet = Uint8List.fromList([0x03]);

    _socket?.send(packet, _nexmonHost, _nexmonPort);
  }

  @override
  Future<void> stopReceiving() async {
    _onReceiveData = null;
  }

  @override
  Future<List<Uint8List>> getAllReceivedData() async {
    return _receivedData;
  }

  @override
  Future<Uint8List?> getReceivedData() async {
    if (_receivedData.isEmpty) {
      return null;
    }
    return _receivedData.removeAt(0);
  }

  /// Sends a ping to the Nexmon chip. Replies to this ping are provided in the
  /// stream returned by [getPingReplies]. The caller must keep track of
  /// sequence numbers and handle timeouts itself.
  Future<void> sendPing(int sequenceNumber) async {
    if (sequenceNumber > 0xff) {
      throw Exception("Sequence number must be between 0 and 255.");
    }

    final packet = Uint8List.fromList([0x05, sequenceNumber]);
    _socket?.send(packet, _nexmonHost, _nexmonPort);
  }

  Stream<int> getPingReplies() {
    return _pingReplies.stream;
  }

  Future<void> sendConfig(String config) async {
    if (config.length > 0xffff) {
      throw Exception("Config string is too long. Maximum 65535 bytes allowed");
    }

    final lengthBytes = [config.length >> 8, config.length & 0xff];
    final packet = Uint8List.fromList([0x07] + lengthBytes + ascii.encode(config));
    _socket?.send(packet, _nexmonHost, _nexmonPort);
  }

  Future<void> _setupUDPListener() async {
    if (_socket != null) {
      return;
    }
    debugPrint("[NexmonUDPChannelService] Starting UDP Listener on $_listenIP:$_listenPort");
    _socket = await RawDatagramSocket.bind(_listenIP, _listenPort);
    _socket?.broadcastEnabled = true;
    _socket?.listen(_handleUDPMessage);
  }

  void _closeUDPListener() {
    debugPrint("[NexmonUDPChannelService] Closing UDP Listener");
    _socket?.close();
    _socket = null;
  }

  @override
  Future<void> dispose() async {
    await stopTransmission();
    await stopReceiving();
    _closeUDPListener();
  }

  Future<void> _handleUDPMessage(RawSocketEvent event) async {
    if (event == RawSocketEvent.read) {
      final packet = _socket?.receive();
      if (packet == null) {
        return;
      }

      final packetBytes = packet.data;
      if (packetBytes.isEmpty) {
        return;
      }

      debugPrint("[NexmonUDPChannelService] Received UDP packet: ${packetBytes.toHexString()}");
      switch (packetBytes.first) {
        case PACKET_TYPE_PING_REPLY:
          if (packetBytes.length == 2) {
            _pingReplies.sink.add(packetBytes[1]);
          }
          break;

        case PACKET_TYPE_DATA_RESPONSE:
          final dataLength = packetBytes[1];
          final actualData = packetBytes.sublist(2, 2 + dataLength);
          _receivedData.add(actualData);
          _onReceiveData?.call(actualData);
          break;
      }
    }
  }
}
