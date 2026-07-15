import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_coordinator_state.dart';
import 'package:pairfi/features/pairing/nexmon/ui/state/nexmon_participant_state.dart';
import 'package:pairfi/features/setup/services/permission_service.dart';
import 'package:pairfi/helper/ui/gui_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'features/profile/identity_service.dart';
import 'features/settings/settings_interface.dart';
import 'generated/l10n.dart';
import 'router/app_router.dart';
import 'router/app_routes.dart';
import 'service_locator.dart';
import 'storage/sembast_storage.dart';
import 'storage/sql_storage.dart';
import 'storage/storage_interface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupGetIt();
  var idService = getIt<IdentityService>();

  var deviceId = await idService.deviceId;
  debugPrint("Main: device ID is $deviceId");

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const PairFiApp());
}

class PairFiApp extends StatefulWidget {
  const PairFiApp({super.key});

  @override
  State<PairFiApp> createState() => _PairFiAppState();

  static void setLanguage(BuildContext context, String language) async {
    _PairFiAppState state =
    context.findAncestorStateOfType<_PairFiAppState>()!;
    state.setLanguage(language);
  }
}

class _PairFiAppState extends State<PairFiApp> {
  final SettingsService _settingsService = getIt<SettingsService>();
  final IdentityService _identityService = getIt<IdentityService>();

  Locale _language = const Locale('en'); //Default language

  _PairFiAppState() {
    _initDatabase(Database.sqlite);
  }

  ///Changes language of the app
  setLanguage(String language) {
    setState(() {
      if (_settingsService.getString("language") != null && S.delegate.supportedLocales.contains(Locale(_settingsService.getString("language")!))) {
        _language = Locale(_settingsService.getString("language")!);
      } else {
        _language = const Locale('en');
      }
      debugPrint("Language is set to ${_language.toString()}");
    });
  }

  @override
  Widget build(BuildContext context) {
    ///Sets the language to en if not set in preferences
    if (_settingsService.getString("language") != null &&
        S.delegate.supportedLocales.contains(Locale(_settingsService.getString("language")!))) {
      _language = Locale(_settingsService.getString("language")!);
    } else {
      _settingsService.setString("language", 'en');
    }

    return FutureBuilder(
        future: _getInitialRoute(),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            final initialRoute = snapshot.data;
            return MultiProvider(providers: [
              ChangeNotifierProvider(create: (context) => NexmonCoordinatorState()),
              ChangeNotifierProvider(create: (context) => NexmonParticipantState())
            ],
            child: MaterialApp(
              title: 'PairFi',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              locale: _language,
              onGenerateTitle: (BuildContext context) => 'PairFi',
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: const ColorScheme(
                  brightness: Brightness.light,
                  primary: Color.fromRGBO(157, 132, 236, 1.0),
                  onPrimary: Color.fromRGBO(255, 255, 255, 1.0),
                  secondary: Color.fromRGBO(97, 91, 113, 1.0),
                  onSecondary: Color.fromRGBO(255, 255, 255, 1.0),
                  tertiary: Color.fromRGBO(210, 210, 210, 1.0),
                  onTertiary: Colors.black,
                  error: Color.fromRGBO(186, 26, 26, 1.0),
                  onError: Color.fromRGBO(255, 255, 255, 1.0),
                  surface: Color.fromRGBO(236, 230, 240, 1.0),
                  onSurface: Color.fromRGBO(30, 28, 19, 1.0),
                ),
                scaffoldBackgroundColor: GuiConstants.scaffoldBackgroundColorLight,
                appBarTheme: const AppBarTheme(
                  color: GuiConstants.scaffoldBackgroundColorLight,
                ),
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: const ColorScheme(
                  brightness: Brightness.dark,
                  primary: Color.fromRGBO(157, 132, 236, 1.0),
                  onPrimary: Color.fromRGBO(255, 255, 255, 1.0),
                  secondary: Color.fromRGBO(97, 91, 113, 1.0),
                  onSecondary: Color.fromRGBO(255, 255, 255, 1.0),
                  tertiary: Color.fromRGBO(99, 99, 99, 1.0),
                  onTertiary: Colors.white,
                  error: Color.fromRGBO(186, 26, 26, 1.0),
                  onError: Color.fromRGBO(255, 255, 255, 1.0),
                  surface: Color.fromRGBO(56, 53, 56, 1.0),
                  onSurface: Color.fromRGBO(239, 232, 232, 1.0),
                ),
                scaffoldBackgroundColor: GuiConstants.scaffoldBackgroundColorDark,
                appBarTheme: const AppBarTheme(
                  color: GuiConstants.scaffoldBackgroundColorDark,
                ),
              ),
              initialRoute: initialRoute,
              routes: AppRouter.routes,
            )
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  Future<String> _getInitialRoute() async {
    if (await PermissionService.instance.checkPermissions().isGranted && _identityService.identitySet) {
      return AppRoutes.homePage;
    } else {
      return AppRoutes.welcome;
    }
  }

  void _initDatabase(Database database) async {
    StorageInterface databaseInterface;

    switch (database) {
      case Database.sembast:
        SembastDB sembastDB = SembastDB();
        databaseInterface = sembastDB;
        break;
      case Database.sqlite:
        SqlDB sqlDB = SqlDB();
        databaseInterface = sqlDB;
        break;
    }

    GetIt.instance.registerSingleton<StorageInterface>(databaseInterface);
  }
}
