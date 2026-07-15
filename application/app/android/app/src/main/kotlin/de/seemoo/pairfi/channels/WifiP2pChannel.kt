@file:Suppress("DEPRECATION")

package de.seemoo.pairfi.channels

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.p2p.WifiP2pConfig
//import android.net.wifi.p2p.WifiP2pDiscoveryConfig
import android.net.wifi.p2p.WifiP2pGroup
import android.net.wifi.p2p.WifiP2pInfo
import android.net.wifi.p2p.WifiP2pManager
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.NetworkInfo
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WifiP2pChannel(
    private val activity: Activity,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler, BroadcastReceiver() {

    private val intentFilter = IntentFilter()

    init {
        channel.setMethodCallHandler(this)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
        intentFilter.addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
    }

    private var isRegistered = false
    private var manager: WifiP2pManager? = null
    //private var wifiChannel: WifiP2pManager.Channel? = null
    private lateinit var wifiChannel: WifiP2pManager.Channel// = null

    private val peers = mutableListOf<WifiP2pDevice>()
    private val peerListListener = WifiP2pManager.PeerListListener { peerList ->
        val refreshedPeers = peerList.deviceList
        if (refreshedPeers != peers) {
            peers.clear()
            peers.addAll(refreshedPeers)
            peers.forEach { peer ->
                Log.d("WifiP2pChannel", peer.toString())
            }
        }
        if (peers.isEmpty()) {
            Log.d("WifiP2pChannel", "No devices found")
            return@PeerListListener
        }
    }

    private val connectionListener = WifiP2pManager.ConnectionInfoListener { info ->
        // String from WifiP2pInfo struct
        val groupOwnerAddress: String = info.groupOwnerAddress.hostAddress
        // After the group negotiation, we can determine the group owner
        // (server).
        Log.d("WifiP2pChannel", info.toString())
        if (info.groupFormed && info.isGroupOwner) {
            manager?.requestPeers(wifiChannel, peerListListener)
            manager?.requestGroupInfo(wifiChannel) { group: WifiP2pGroup? ->
                if (group == null) {
                    Log.d("WifiP2pChannel", "group is null")
                } else {
                    Log.d("WifiP2pChannel", group.toString()) // this finally gives us the client info...
                }
            }
            // Do whatever tasks are specific to the group owner.
            // One common case is creating a group owner thread and accepting
            // incoming connections.
        } else if (info.groupFormed) {
            // The other device acts as the peer (client). In this case,
            // you'll want to create a peer thread that connects
            // to the group owner.
        }
    }

    private var ssid: String? = null
    private var netId: Int = -1

    /// Called when this BroadcastReceiver is receiving an Intent broadcast.
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                Log.d("WifiP2pChannel", "intent WIFI_P2P_STATE_CHANGED_ACTION")
                // Determine if Wifi P2P mode is enabled or not, alert
                // the Activity.
                val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                activity.runOnUiThread {
                    channel.invokeMethod(
                        "wifi_p2p_available",
                        state == WifiP2pManager.WIFI_P2P_STATE_ENABLED
                    )
                }
            }

            WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                Log.d("WifiP2pChannel", "intent WIFI_P2P_PEERS_CHANGED_ACTION")
                manager?.requestPeers(wifiChannel, peerListListener)
                //val deviceList = intent.getParcelableExtra(WifiP2pManager.EXTRA_P2P_DEVICE_LIST) as? WifiP2pDeviceList
                //Log.d("WifiP2pChannel", "Peers: ${deviceList?.toString()}")
            }

            WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                Log.d("WifiP2pChannel", "intent WIFI_P2P_CONNECTION_CHANGED_ACTION")
                if (manager != null) {
                    val group: WifiP2pGroup? = intent.getParcelableExtra(WifiP2pManager.EXTRA_WIFI_P2P_GROUP)
                    activity.runOnUiThread {
                        if (group == null) {
                            channel.invokeMethod("wifi_p2p_group_info", null)
                        } else {
                            channel.invokeMethod(
                                "wifi_p2p_group_info", mapOf(
                                    "ssid" to group.networkName,
                                    "passphrase" to group.passphrase
                                )
                            )
                        }
                    }

                    val connection: WifiP2pInfo? =
                        intent.getParcelableExtra(WifiP2pManager.EXTRA_WIFI_P2P_INFO)
                    activity.runOnUiThread {
                        if (connection?.groupOwnerAddress == null) {
                            channel.invokeMethod("wifi_p2p_connection_info", null)
                        } else {
                            channel.invokeMethod(
                                "wifi_p2p_connection_info", mapOf(
                                    "isOwner" to connection.isGroupOwner,
                                    "ownerAddress" to connection.groupOwnerAddress.hostAddress
                                )
                            )
                        }
                    }
                    manager?.let { manager ->
                        val networkInfo: NetworkInfo? = intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO) as? NetworkInfo
                        if (networkInfo?.isConnected == true) {
                            // We are connected with the other device, request connection
                            // info to find group owner IP
                            manager.requestConnectionInfo(wifiChannel, connectionListener)
                        }
                    }
                } else {
                    Log.d("WifiP2pChannel", "manager is null!")
                }
            }

            WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION -> {
                Log.d("WifiP2pChannel", "intent WIFI_P2P_THIS_DEVICE_CHANGED_ACTION")
                val thisDevice = intent.getParcelableExtra(WifiP2pManager.EXTRA_WIFI_P2P_DEVICE) as? WifiP2pDevice
                Log.d("WifiP2pChannel", thisDevice.toString())
            }
        }
    }

    /// Handle the incoming method call for the gp_wifip2p channel.
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
            || ActivityCompat.checkSelfPermission(activity, Manifest.permission.NEARBY_WIFI_DEVICES) != PackageManager.PERMISSION_GRANTED) {
            return
        }
        if (call.method == "init") {
            if (manager == null) {
                manager = activity.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
                wifiChannel = manager!!.initialize(activity, activity.mainLooper, null)
                result.success(true)
            } else {
                if (wifiChannel != null) {
                    wifiChannel.close()
                    wifiChannel = manager!!.initialize(activity, activity.mainLooper, null)
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
        } else if (call.method == "close") {
            if (wifiChannel != null) {
                wifiChannel.close()
                result.success(true)
            } else {
                result.success(false)
            }
        } else if (call.method == "start_listening") {
                manager!!.startListening(wifiChannel, object : WifiP2pManager.ActionListener {
                    override fun onSuccess() {
                        result.success(true)
                    }

                    override fun onFailure(reason: Int) {
                        Log.d("WifiP2pChannel", "start_listening failed with reason: $reason")
                        result.success(false)
                    }
                })
        } else if (call.method == "stop_listening") {
            manager!!.stopListening(wifiChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onFailure(reason: Int) {
                    Log.d("WifiP2pChannel", "stop_listening failed with reason: $reason")
                    result.success(false)
                }
            })
        } else if (call.method == "start_peer_discovery") {
//            val frequencyMhz: Int? = call.argument<Int?>("frequencyMhz")
//            val builder = WifiP2pDiscoveryConfig.Builder(WifiP2pManager.WIFI_P2P_SCAN_SINGLE_FREQ)
//            if (frequencyMhz != null) builder.setFrequencyMhz(frequencyMhz)
//            val config = builder.build()
//            manager!!.startPeerDiscovery(wifiChannel, config, object : WifiP2pManager.ActionListener {
//                override fun onSuccess() {
//                    result.success(true)
//                }
//
//                override fun onFailure(reason: Int) {
//                    Log.d("WifiP2pChannel", "start_peer_discovery failed with reason: $reason")
//                    result.success(false)
//                }
//            })
            manager!!.discoverPeers(wifiChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onFailure(reason: Int) {
                    Log.d("WifiP2pChannel", "start_peer_discovery failed with reason: $reason")
                    result.success(false)
                }
            })
        } else if (call.method == "stop_peer_discovery") {
            manager!!.stopPeerDiscovery(wifiChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onFailure(reason: Int) {
                    Log.d("WifiP2pChannel", "stop_peer_discovery failed with reason: $reason")
                    result.success(false)
                }
            })
        } else if (call.method == "req_connection_info") {
            if (Build.VERSION.SDK_INT >= 29) {
                manager!!.requestConnectionInfo(wifiChannel) { connection: WifiP2pInfo? ->
                    if (connection?.groupOwnerAddress == null) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "isOwner" to connection.isGroupOwner,
                                "ownerAddress" to connection.groupOwnerAddress.hostAddress
                            )
                        )
                    }
                }
            } else {
                val wifiManager =
                    activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val dhcpInfo = wifiManager.dhcpInfo
                if (dhcpInfo == null || dhcpInfo.gateway == 0) {
                    result.success(null)
                } else {
                    result.success(
                        mapOf(
                            "isOwner" to false,
                            "ownerAddress" to android.text.format.Formatter.formatIpAddress(dhcpInfo.gateway)
                        )
                    )
                }
            }
        } else if (call.method == "req_group_info") {
            if (Build.VERSION.SDK_INT >= 29) {
                manager!!.requestGroupInfo(wifiChannel) { group: WifiP2pGroup? ->
                    if (group == null) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "ssid" to group.networkName,
                                "passphrase" to group.passphrase
                            )
                        )
                    }
                }
            } else {
                val wifiManager = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                val wifiInfo = wifiManager.connectionInfo
                if (wifiInfo.ssid == ssid) {
                    result.success(
                        mapOf(
                            "ssid" to ssid,
                            "passphrase" to ""
                        )
                    )
                } else {
                    result.success(null)
                }
            }
        } else if (call.method == "create_group") {
            manager!!.createGroup(wifiChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onFailure(reason: Int) {
                    Log.d("WifiP2pChannel", "create_group failed with reason: $reason")
                    result.success(false)
                }
            })
        } else if (call.method == "create_group_with_config") {
            val ssid: String? = call.argument<String?>("ssid")
            val passphrase: String? = call.argument<String?>("passphrase")
            val frequency: Int? = call.argument<Int?>("frequency")
            val band: Int? = call.argument<Int?>("band")
            val builder = WifiP2pConfig.Builder()
            if (ssid != null) builder.setNetworkName(ssid)
            if (passphrase != null) builder.setPassphrase(passphrase)
            if (frequency != null) builder.setGroupOperatingFrequency(frequency)
            if (band != null) {
                val p2pConfigBand : Int
                when (band) {
                    2 -> p2pConfigBand = WifiP2pConfig.GROUP_OWNER_BAND_2GHZ
                    5 -> p2pConfigBand = WifiP2pConfig.GROUP_OWNER_BAND_5GHZ
                    //6 -> p2pConfigBand = WifiP2pConfig.GROUP_OWNER_BAND_6GHZ // SDK >= 36
                    else -> p2pConfigBand = WifiP2pConfig.GROUP_OWNER_BAND_AUTO
                }
                builder.setGroupOperatingBand(band)
            }
            val config = builder.build()
            manager!!.createGroup(wifiChannel, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onFailure(reason: Int) {
                    Log.d("WifiP2pChannel", "create_group_with_config failed with reason: $reason")
                    result.success(false)
                }
            })
        } else if (call.method == "remove_group") {
            manager!!.removeGroup(wifiChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    result.success(true)
                }

                override fun onFailure(reason: Int) {
                    result.success(false)
                }
            })
        } else if (call.method == "connect") {
            if (Build.VERSION.SDK_INT >= 29) {

                val config = WifiP2pConfig.Builder()
                    .setNetworkName(call.argument<String>("ssid")!!)
                    .setPassphrase(call.argument<String>("passphrase")!!)
                    .build()
                manager!!.connect(wifiChannel, config, object : WifiP2pManager.ActionListener {
                    override fun onSuccess() {
                        result.success(true)
                    }

                    override fun onFailure(reason: Int) {
                        result.success(false)
                    }
                })
            } else {
                val wifiConfiguration = WifiConfiguration()
                wifiConfiguration.SSID = String.format("\"%s\"", call.argument<String>("ssid")!!)
                wifiConfiguration.preSharedKey =
                    String.format("\"%s\"", call.argument<String>("passphrase")!!)
                ssid = String.format("\"%s\"", call.argument<String>("ssid")!!)


                val wifiManager = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                netId = wifiManager.connectionInfo.networkId
                val newNetId = wifiManager.addNetwork(wifiConfiguration)
                wifiManager.disconnect()
                wifiManager.enableNetwork(newNetId, true)
                wifiManager.reconnect()
                result.success(true)
            }
        } else if (call.method == "disconnect") {
            if (Build.VERSION.SDK_INT < 29 && netId != -1) {
                val wifiManager = activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                wifiManager.disconnect()
                wifiManager.enableNetwork(netId, true)
                wifiManager.reconnect()
                netId = -1
                result.success(true)
            } else {
                result.success(true)
            }
        } else if (call.method == "register") {
            if (isRegistered) {
                result.success(false)
            } else {
                activity.registerReceiver(this, intentFilter)
                isRegistered = true
                result.success(true)
            }
        } else if (call.method == "unregister") {
            if (isRegistered) {
                activity.unregisterReceiver(this)
                isRegistered = false
                result.success(true)
            } else {
                result.success(false)
            }
        } else {
            result.notImplemented()
        }
    }

}
