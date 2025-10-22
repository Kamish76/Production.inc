import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/main_menu_screen.dart';
import 'screens/main_game_screen.dart';
import 'services/production_game_service.dart';
import 'services/game_persistence_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database factory for desktop platforms
  GamePersistenceService.initializeDatabaseFactory();

  // Set preferred orientations for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProductionIncApp());
}

class ProductionIncApp extends StatefulWidget {
  const ProductionIncApp({super.key});

  @override
  State<ProductionIncApp> createState() => _ProductionIncAppState();
}

class _ProductionIncAppState extends State<ProductionIncApp>
    with WidgetsBindingObserver {
  late final ProductionGameService _gameService;

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final indexParam = state.uri.queryParameters['index'];
          final initialIndex =
              indexParam != null ? int.tryParse(indexParam) ?? 0 : 0;
          return MainGameScreen(initialIndex: initialIndex);
        },
      ),
      // Legacy routes - redirect to main game screen with appropriate tab
      GoRoute(path: '/buy', redirect: (context, state) => '/game?index=0'),
      GoRoute(path: '/build', redirect: (context, state) => '/game?index=1'),
      GoRoute(path: '/sell', redirect: (context, state) => '/game?index=2'),
      GoRoute(path: '/shipping', redirect: (context, state) => '/game?index=3'),
      GoRoute(path: '/settings', redirect: (context, state) => '/game?index=4'),
      GoRoute(path: '/control', redirect: (context, state) => '/game?index=4'),
    ],
  );

  @override
  void initState() {
    super.initState();
    _gameService = ProductionGameService();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Use the optimized lifecycle management in game service
    _gameService.handleAppLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _gameService,
      child: MaterialApp.router(
        title: 'Production.INC',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
        ),
        routerConfig: _router,
      ),
    );
  }
}
