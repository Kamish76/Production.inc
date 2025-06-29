import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/main_menu_screen.dart';
import 'screens/main_game_screen.dart';
import 'services/production_game_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(ProductionIncApp());
}

class ProductionIncApp extends StatelessWidget {
  ProductionIncApp({super.key});

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
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductionGameService()..updateProductions(),
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
