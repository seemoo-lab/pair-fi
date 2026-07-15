import 'package:pairfi/router/app_routes.dart';

class NexmonPairingRoutes {
  static const String _baseRoute = AppRoutes.nexmon;
  static const String roleSelection = _baseRoute;
  static const String coordinatorSetup = '$_baseRoute/CoordinatorSetup';
  static const String coordinatorRunning = '$_baseRoute/CoordinatorRunning';
  static const String participantRunning = '$_baseRoute/ParticipantRunning';
  static const String success = '$_baseRoute/Success';
}
