
import 'package:pairfi/features/profile/user_model.dart';

/// Abstract class to define a service to store local application data
/// Bemerkung: Das Interface muss eigentlich weg, da es nur einmal implementiert wird, aber aufgrund der zwei Versionen zwei mal gebraucht wird.
/// {@category Interfaces}
abstract class GuiUtilityInterface {
  Future init();

  void resetDatabase();

  Future<void> insertOrUpdateUser(User user, {allowSelf = false});
  Future<void> addOrVerifyUser(PairingData pairingData);

  Future<List<User>> getAllUser();
  Future<User> getUserDetails(String userId);

  //Future<void> createTestData();
}
