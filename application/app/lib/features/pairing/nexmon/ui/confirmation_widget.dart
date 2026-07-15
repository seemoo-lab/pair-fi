import 'package:flutter/material.dart';
import 'package:pairfi/generated/l10n.dart';
import 'package:pairfi/helper/ui/button_row.dart';
import 'package:pairfi/helper/ui/hint_text_card.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_constants.dart';

/// Widget displayed when the user must confirm blue lock.
///
/// {@category Widgets}

typedef AnswerCallback = void Function(bool confirm);

class UserConfirmationWidget extends StatelessWidget {
  final int? numParticipants;
  final AnswerCallback confirmCallback;
  final int? magicVerificationNumber;

  const UserConfirmationWidget({super.key,
    required this.numParticipants,
    required this.magicVerificationNumber,
    required this.confirmCallback});

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              //Icon(Icons.lock, size: MediaQuery.of(context).size.height * 0.33, color: Colors.blue),
              Center(
                child: Text(
                  NexmonConstants.magicEmojis[magicVerificationNumber ?? 9],
                  style: Theme.of(context).textTheme.headlineLarge,
                  textScaler: const TextScaler.linear(3.0),
                ),
              ),
              const Spacer(),
              HintTextCard(S.of(context).groupPairingVerificationPromptWithSize(numParticipants.toString())),
              const SizedBox(height: 20),
              ButtonRow(
                primaryText: S.of(context).dialogButtonYes,
                primaryIcon: Icons.check_rounded,
                primaryAction: (context) async {
                  confirmCallback(true);
                },
                secondaryText: S.of(context).dialogButtonNo,
                secondaryIcon: Icons.close_rounded,
                secondaryAction: (context) async {
                  confirmCallback(false);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
