import 'package:flutter/material.dart';
import 'package:pairfi/features/profile/identity_service.dart';
import 'package:pairfi/features/profile/user_model.dart';
import 'package:pairfi/generated/l10n.dart';
import 'package:pairfi/helper/gui_utility_interface.dart';
import 'package:pairfi/service_locator.dart';
import 'bottom_info_widget.dart';
import 'profile_widget.dart';

/// This screen shows any profile (own or other) and can be configured by state variables [editable], [showVerification], [userId] (User to be shown).
///
/// {@category Screens}
class ProfileScreen extends StatefulWidget {
  const ProfileScreen(
      {super.key,
        this.editable = true,
        this.showVerification = false,
        this.userId = ""});
  final bool editable;
  final bool showVerification;
  final String userId;

  @override
  State<ProfileScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<ProfileScreen> {
  final _identityService = getIt<IdentityService>();
  final _localDatabaseService = getIt<GuiUtilityInterface>();
  late User _user;
  late bool _editable = false;
  late bool _showVerification;
  late ProfileWidget profileWidget;

  late String _id = widget.userId;

  @override
  void initState() {
    super.initState();
    _editable = widget.editable;
    _showVerification = widget.showVerification;
  }

  @override
  Widget build(BuildContext context) {
    FutureBuilder fb;
    if (_id.isNotEmpty) {
      fb = profileWidgetBuilder();
    } else {
      fb = FutureBuilder<String>(
        future: _identityService.deviceId,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            _id = snapshot.data!;
            return profileWidgetBuilder();
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }

    if (_editable) {
      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).profile),
        ),
        body: fb,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).profile),
        ),
        body: fb,
        bottomNavigationBar: const BottomInfoWidget(),
      );
    }
  }

  FutureBuilder<User> profileWidgetBuilder() {
    return FutureBuilder<User>(
      future: _localDatabaseService.getUserDetails(_id),
      builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
        if (snapshot.hasData) {
          _user = snapshot.data!;
          return profileWidget = ProfileWidget(
            _user,
            edit: _editable,
            showVerification: _showVerification,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
