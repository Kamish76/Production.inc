import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'screens/main_menu_screen.dart';
import 'screens/buy_materials_screen.dart';
import 'screens/build_products_screen.dart';
import 'screens/sell_products_screen.dart';
import 'screens/settings_screen.dart';
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
      GoRoute(
        path: '/',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/buy',
        builder: (context, state) => const BuyMaterialsScreen(),
      ),
      GoRoute(
        path: '/build',
        builder: (context, state) => const BuildProductsScreen(),
      ),
      GoRoute(
        path: '/sell',
        builder: (context, state) => const SellProductsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
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
