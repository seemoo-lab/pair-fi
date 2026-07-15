import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pairfi/features/pairing/nexmon/ui/confirmation_widget.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_constants.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_pairing_routes.dart';
import 'package:pairfi/features/pairing/nexmon/ui/idle_waiting_screen.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_coordinator_state.dart';
import 'package:pairfi/features/pairing/success_widget.dart';
import 'package:pairfi/features/pairing/ui-shared/error_widget.dart';
import 'package:pairfi/generated/l10n.dart';
import 'package:pairfi/helper/ui/hint_text_card.dart';
import 'package:provider/provider.dart';

class NexmonCoordinatorRunningScreen extends StatefulWidget {
  const NexmonCoordinatorRunningScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NexmonCoordinatorRunningScreenState();
}

class _NexmonCoordinatorRunningScreenState extends State<NexmonCoordinatorRunningScreen> {
  late NexmonCoordinatorState _state;
  final int _magicNumber = Random().nextInt(9); // random digit >= 0 and < 9

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          debugPrint("did pop");
          await _state.reset();
        }
      },
      child: Consumer<NexmonCoordinatorState>(builder: (context, state, child) {
        _state = state;
        switch (state.protocolStage) {
          case NexmonCoordinatorProtocolStage.magicEmoji:
            return buildMagicEmojiScreen(context);
          case NexmonCoordinatorProtocolStage.commitments:
          case NexmonCoordinatorProtocolStage.mainReveals:
          case NexmonCoordinatorProtocolStage.verification:
          case NexmonCoordinatorProtocolStage.matchReveals:
            return IdleWaitingScreen(
                appBarText: S.of(context).nexmonRunningTitle,
                bodyText: S.of(context).nexmonRunningExchangingInformation
            );
          case NexmonCoordinatorProtocolStage.userConfirm:
            return Scaffold(
              appBar: AppBar(
                title: Text(S.of(context).nexmonRunningUserConfirmationTitle)
              ),
              body: UserConfirmationWidget(
                  numParticipants: _state.numParticipants,
                  magicVerificationNumber: _state.magicVerificationNumber,
                  confirmCallback: (confirm) {
                    _state.handleUserConfirmation(confirm);
                  }
              )
            );
          case NexmonCoordinatorProtocolStage.decryption:
            return IdleWaitingScreen(
                appBarText: S.of(context).nexmonRunningTitle,
                bodyText: S.of(context).nexmonRunningDecrypting
            );
          case NexmonCoordinatorProtocolStage.done:
            return Scaffold(
              appBar: AppBar(
                title: Text(S.of(context).nexmonRunningTitle),
              ),
              body: PairingSuccessWidget(_state.successListData!, () => {})
            );
          case NexmonCoordinatorProtocolStage.securityError:
            return PairFiErrorWidget(args: ErrorWidgetArgs.security(
                context,
                cancelAction: (ctx) => Navigator.of(ctx).pop(),
                retryAction: _errorRetryAction
            ));
          case NexmonCoordinatorProtocolStage.error:
            return PairFiErrorWidget(args: ErrorWidgetArgs.unknown(
              context,
              details: _state.errorMessage,
              cancelAction: (ctx) => Navigator.of(ctx).pop(),
              retryAction: _errorRetryAction,
            ));
          case NexmonCoordinatorProtocolStage.timeout:
            return PairFiErrorWidget(args: ErrorWidgetArgs.timeout(
                context,
                cancelAction: (ctx) => Navigator.of(ctx).pop(),
                retryAction: _errorRetryAction,
            ));
        }
      }),
    );
  }

  void _errorRetryAction(BuildContext context) {
    _state.reset();
    Navigator.of(context).popAndPushNamed(NexmonPairingRoutes.coordinatorSetup);
  }

  Widget buildMagicEmojiScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emoji"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const HintTextCard("Make sure that all participants select this emoji."),
            const SizedBox(height: 25),
            Text(
              NexmonConstants.magicEmojis[_magicNumber],
              style: Theme.of(context).textTheme.headlineLarge,
              textScaler: const TextScaler.linear(3.0),
            ),
            const SizedBox(height: 25),
            Text(
              "${_state.numConnectedParticipants}/${(_state.numParticipants ?? 0)-1} participants have connected...",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 25),
            const SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(strokeWidth: 6)
            ),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _state.reset();
  }
}