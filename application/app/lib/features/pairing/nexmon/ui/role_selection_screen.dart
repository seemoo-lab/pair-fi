import 'package:flutter/material.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_pairing_routes.dart';
import 'package:pairfi/generated/l10n.dart';
import 'package:pairfi/features/pairing/ui-shared/role_selection_card_widget.dart';
import 'package:pairfi/helper/location_service_helper.dart';

class NexmonRoleSelectionScreen extends StatelessWidget {
  const NexmonRoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: const Text("Nexmon Pairing"),
        title: const Text("Role Selection"),
      ),
      body: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            10, 10, 10, MediaQuery.of(context).size.height * 0.05),
        child: Column(children: [
          Text(S.of(context).groupPairingSelectRole,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 10),
          RoleSelectionCardWidget(
              assetName: "assets/grouppairing/coordinator-abstract-people-color.svg",
              title: S.of(context).groupPairingCoordinator,
              description: S.of(context).groupPairingCoordinatorHelp,
              action: () => _navigateToNext(true, context)),
          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          RoleSelectionCardWidget(
              assetName: "assets/grouppairing/participant-abstract-people-color.svg",
              title: S.of(context).groupPairingParticipant,
              description: S.of(context).groupPairingDeviceHelp,
              action: () => _navigateToNext(false, context)),
        ]),
      ),
    );
  }

  Future<void> _navigateToNext(bool isCoordinator, BuildContext context) async {
    if (!(await _checkPairingRequirements())) {
      if (!context.mounted) {
        return;
      }
      await LocationServiceHelper.instance.showLocationServiceAlert(context);
      return;
    }

    if (!context.mounted) {
      return;
    }
    if (isCoordinator) {
      Navigator.of(context).pushReplacementNamed(NexmonPairingRoutes.coordinatorSetup);
    } else {
      Navigator.of(context).pushReplacementNamed(NexmonPairingRoutes.participantRunning);
    }
  }

  Future<bool> _checkPairingRequirements() async {
    final locationServiceEnabled = await LocationServiceHelper.instance.isLocationServicesEnabled();
    debugPrint("Location Service enabled: $locationServiceEnabled");
    return locationServiceEnabled;
  }
}
