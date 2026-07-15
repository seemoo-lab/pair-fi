import 'package:flutter/material.dart';
import 'package:pairfi/router/app_routes.dart';
import 'package:pairfi/generated/l10n.dart';

import 'menu_card_widget.dart';

/// The Home Screen of the app with buttons as grid tiles.
/// Each Button is from [MenuCard] Widget.
/// {@category Screens}
class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  initState() {
    FocusManager.instance.primaryFocus
        ?.unfocus(); //Remove Keyboard in this screen
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    GridView menuCardGrid = GridView.count(
      crossAxisCount: isLandscape ? 3 : 1,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(6),
      childAspectRatio: isLandscape ? 1.5 : 1.6,
      children: [
        MenuCard(
            icon: Icons.person_rounded,
            title: S.of(context).profile,
            route: AppRoutes.profile),
        MenuCard(
            icon: Icons.contact_page,
            title: S.of(context).contacts,
            route: AppRoutes.contacts),
        MenuCard(
            icon: Icons.link,
            title: S.of(context).pair,
            route: AppRoutes.nexmon),
      ],
    );

    return Scaffold(
      key: scaffoldKey,
      body: menuCardGrid,
      appBar: AppBar(
        title: Text(S.of(context).appName),
      ),
    );
  }
}
