import 'package:flutter/material.dart';
import 'package:pairfi/features/contacts/ui/address_book_screen.dart';
import 'package:pairfi/features/home/ui/home_page_screen.dart';
import 'package:pairfi/features/pairing/nexmon/nexmon_pairing_routes.dart';
import 'package:pairfi/features/pairing/nexmon/ui/coordinator_running_screen.dart';
import 'package:pairfi/features/pairing/nexmon/ui/coordinator_setup_screen.dart';
import 'package:pairfi/features/pairing/nexmon/ui/participant_running_screen.dart';
import 'package:pairfi/features/pairing/nexmon/ui/role_selection_screen.dart';
//import 'package:pairfi/features/pairing/pairing_screen.dart';
import 'package:pairfi/features/pairing/ui-shared/error_widget.dart';
import 'package:pairfi/features/profile/ui/profile_screen.dart';
//import 'package:pairfi/features/settings/ui/settings_screen.dart';
import 'package:pairfi/features/setup/ui/permissions_screen.dart';
import 'package:pairfi/features/setup/ui/profile_creation_screen.dart';
import 'package:pairfi/features/setup/ui/welcome_screen.dart';
import 'package:pairfi/router/app_routes.dart';

/// Helper to link named routes to screens
///
/// {@category Router}
class AppRouter {
  AppRouter._();

  static Map<String, WidgetBuilder> routes = {
    AppRoutes.homePage: (BuildContext context) => const HomePageScreen(),
    AppRoutes.contacts: (BuildContext context) => const AddressBookScreen(),
    AppRoutes.profile: (BuildContext context) => const ProfileScreen(),
    AppRoutes.profileCreation: (BuildContext context) => const ProfileCreationScreen(),
    AppRoutes.permissions: (BuildContext context) => const PermissionsScreen(),
    AppRoutes.welcome: (BuildContext context) => WelcomeScreen(),
    //AppRoutes.settings: (BuildContext context) => const SettingsScreen(),
    AppRoutes.error: (BuildContext context) => const PairFiErrorWidget(),
    AppRoutes.nexmon: (BuildContext context) => const NexmonRoleSelectionScreen(),
    NexmonPairingRoutes.coordinatorSetup: (BuildContext context) => const NexmonCoordinatorSetupScreen(),
    NexmonPairingRoutes.participantRunning: (BuildContext context) => const NexmonParticipantRunningScreen(),
    NexmonPairingRoutes.coordinatorRunning: (BuildContext context) => const NexmonCoordinatorRunningScreen(),
  };
}
