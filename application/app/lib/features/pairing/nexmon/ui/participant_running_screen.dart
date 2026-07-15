import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_constants.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_pairing_routes.dart';
import 'package:pairfi/features/pairing/nexmon/ui/confirmation_widget.dart';
import 'package:pairfi/features/pairing/nexmon/ui/idle_waiting_screen.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_participant_state.dart';
import 'package:pairfi/features/pairing/success_widget.dart';
import 'package:pairfi/features/pairing/ui-shared/error_widget.dart';
import 'package:pairfi/generated/l10n.dart';
import 'package:pairfi/helper/ui/hint_text_card.dart';
import 'package:pairfi/helper/ui/tappable_number_card.dart';
import 'package:provider/provider.dart';

class NexmonParticipantRunningScreen extends StatefulWidget {
  const NexmonParticipantRunningScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NexmonParticipantRunningScreenState();
}

class _NexmonParticipantRunningScreenState extends State<NexmonParticipantRunningScreen> {
  late NexmonParticipantState _state;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          await _state.reset();
        }
      },
      child: Consumer<NexmonParticipantState>(builder: (context, state, child) {
        _state = state;

        switch (state.protocolStage) {
          case NexmonParticipantProtocolStage.magicNumberSelection:
            return buildMagicNumberSelection(context);
          case NexmonParticipantProtocolStage.waitingForWifiP2PConnection:
            return buildWaitingForCoordinatorScreen(context);
          case NexmonParticipantProtocolStage.waitingForOthers:
            return buildWaitingForConnectionScreen(context);
          case NexmonParticipantProtocolStage.commitments:
          case NexmonParticipantProtocolStage.mainReveals:
          case NexmonParticipantProtocolStage.verification:
          case NexmonParticipantProtocolStage.matchReveals:
            return IdleWaitingScreen(
                appBarText: S.of(context).nexmonRunningTitle,
                bodyText: S.of(context).nexmonRunningExchangingInformation
            );
          case NexmonParticipantProtocolStage.userConfirm:
            return Scaffold(
              appBar: AppBar(
                title: Text(S.of(context).nexmonRunningUserConfirmationTitle)
              ),
              body: UserConfirmationWidget(
                numParticipants: _state.numParticipants,
                magicVerificationNumber: _state.magicVerificationNumber,
                confirmCallback: (confirm) {
                  _state.handleUserConfirmation(confirm);
                },
              ),
            );
          case NexmonParticipantProtocolStage.decryption:
            return IdleWaitingScreen(
                appBarText: S.of(context).nexmonRunningTitle,
                bodyText: S.of(context).nexmonRunningDecrypting
            );
          case NexmonParticipantProtocolStage.done:
            return Scaffold(
              appBar: AppBar(
                title: Text(S.of(context).nexmonRunningTitle),
              ),
              body: PairingSuccessWidget(_state.successListData!, () => {})
            );
          case NexmonParticipantProtocolStage.securityError:
            return PairFiErrorWidget(args: ErrorWidgetArgs.security(
              context,
              cancelAction: (ctx) => Navigator.of(ctx).pop(),
              retryAction: _errorRetryAction
            ));
          case NexmonParticipantProtocolStage.error:
            return PairFiErrorWidget(args: ErrorWidgetArgs.unknown(
              context,
              details: _state.errorMessage,
              cancelAction: (ctx) => Navigator.of(ctx).pop(),
              retryAction: _errorRetryAction,
            ));
          case NexmonParticipantProtocolStage.timeout:
          return PairFiErrorWidget(args: ErrorWidgetArgs.timeout(
              context,
              cancelAction: (ctx) => Navigator.of(ctx).pop(),
              retryAction: _errorRetryAction
          ));
        }
      }),
    );
  }

  void _errorRetryAction(BuildContext context) {
    _state.reset();
    Navigator.of(context).popAndPushNamed(NexmonPairingRoutes.participantRunning);
  }

  Widget buildMagicNumberSelection(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Emoji"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HintTextCard("Select the emoji that is shown on the coordinator's screen"),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                children: List.generate(9, (i) {
                  return TappableNumberCard.emoji(
                    NexmonConstants.magicEmojis[i],
                    onTap: () => _state.startPairing(i)
                  );
                }),
              ),
            ],
          ),
        ));
  }

  Widget buildWaitingForCoordinatorScreen(BuildContext context) {
    return const IdleWaitingScreen(
        appBarText: "Connecting...",
        bodyText: "Connecting to coordinator..."
    );
  }

  Widget buildWaitingForConnectionScreen(BuildContext context) {
    return const IdleWaitingScreen(
        appBarText: "Waiting for others",
        hintCardText: "Waiting for other participants to connect to the coordinator as well.",
        bodyText: "Waiting for others...");
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _state.reset();
  }
}
