import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_pairing_routes.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_coordinator_state.dart';
import 'package:pairfi/generated/l10n.dart';
import 'package:pairfi/helper/ui/button_row.dart';
import 'package:pairfi/helper/ui/hint_text_card.dart';
import 'package:pairfi/helper/ui/tappable_number_card.dart';
import 'package:provider/provider.dart';

class NexmonCoordinatorSetupScreen extends StatefulWidget {
  const NexmonCoordinatorSetupScreen({super.key});

  @override
  State<StatefulWidget> createState() => _NexmonCoordinatorSetupScreenState();
}

class _NexmonCoordinatorSetupScreenState extends State<NexmonCoordinatorSetupScreen> {
  static const int minNumParticipants = 2;

  final TextEditingController _customNumberController = TextEditingController(text: "");

  bool _startButtonDisabled = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<NexmonCoordinatorState>(builder: (context, state, child) {
      return PopScope(
        onPopInvoked: (didPop) async {
          if (didPop) {
            await state.reset();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).groupPairingSetupGroupSize),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: buildParticipantCountSelectionColumn(state),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ButtonRow(
                  primaryText: S.of(context).groupPairingSetupGo,
                  primaryIcon: Icons.arrow_forward_rounded,
                  primaryAction: _startButtonDisabled ? null : (context) {
                    final customNumParticipants = int.tryParse(_customNumberController.text);
                    if (customNumParticipants != null && customNumParticipants >= minNumParticipants) {
                      _submitNumParticipants(customNumParticipants, state);
                    }
                  },
                  secondaryText: S.of(context).groupPairingSetupBack,
                  secondaryIcon: Icons.arrow_back_rounded,
                  secondaryAction: (context) {
                    Navigator.of(context).pushReplacementNamed(NexmonPairingRoutes.roleSelection);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  List<Widget> buildParticipantCountSelectionColumn(NexmonCoordinatorState state) {
    return [
      HintTextCard(S.of(context).groupPairingSetupParticipantCountDescription),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(6, (i) {
          final num = i + minNumParticipants;
          return TappableNumberCard(num, onTap: () =>
              _submitNumParticipants(num, state)
          );
        }),
      ),
      const SizedBox(height: 15),
      Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Or enter a custom number:",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: TextField(
                maxLines: 1,
                controller: _customNumberController,
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(hintText: "0"),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                onChanged: (value) {
                  setState(() {
                    final num = int.tryParse(value);
                    if (num != null && num >= minNumParticipants) {
                      _startButtonDisabled = false;
                    } else {
                      _startButtonDisabled = true;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void _submitNumParticipants(int numParticipants, NexmonCoordinatorState state) {
    state.numParticipants = numParticipants;
    state.startPairing();
    Navigator.of(context).pushReplacementNamed(NexmonPairingRoutes.coordinatorRunning);
    print("Submitted number of participants: $numParticipants");
  }
}
