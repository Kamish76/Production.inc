import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game1/utils/responsive_utils.dart';
import 'package:game1/providers/ui_settings_provider.dart';
import 'package:game1/widgets/ui_scale_wrapper.dart';
import 'package:game1/widgets/screen_header.dart';
import 'package:game1/widgets/quantity_selector_button.dart';
import 'package:game1/widgets/fleet_upgrade_card.dart';
import 'package:game1/widgets/prestige_card.dart';
import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    initializeTestEnvironment();
  });

  group('ResponsiveUtils Column & Layout Tests', () {
    test('Calculates safe columns across key mobile and tablet viewports', () {
      // Small compact phone (360 dp, available width ~328 dp)
      expect(ResponsiveUtils.getGridColumnCount(328), 2);

      // Samsung Galaxy A55 (412 dp, available width ~380 dp)
      // Must be 2 columns to prevent button/badge compression!
      expect(ResponsiveUtils.getGridColumnCount(380), 2);

      // Large Phone (iPhone Pro Max 430 dp, available width ~398 dp)
      expect(ResponsiveUtils.getGridColumnCount(398), 2);

      // Compact foldable / small tablet (available width 580 dp)
      expect(ResponsiveUtils.getGridColumnCount(580), 3);

      // Standard Tablet (available width 768 dp)
      expect(ResponsiveUtils.getGridColumnCount(768), 4);

      // Wide Desktop / Landscape (available width 1024 dp)
      expect(ResponsiveUtils.getGridColumnCount(1024), 6);

      // Zero or negative defensive handling
      expect(ResponsiveUtils.getGridColumnCount(0), 1);
      expect(ResponsiveUtils.getGridColumnCount(-50), 1);
    });

    testWidgets('Breakpoints identify compact vs tablet devices', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(ResponsiveUtils.isCompact(context), isFalse);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('UiSettingsProvider Logic & Persistence Tests', () {
    test('Default scale is 0.85 (85%)', () {
      final provider = UiSettingsProvider();
      expect(provider.uiScale, 0.85);
    });

    test('Clamps and updates scale correctly', () async {
      final provider = UiSettingsProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setUiScale(1.15);
      expect(provider.uiScale, 1.15);
      expect(notified, isTrue);

      // Test clamping below minimum (0.75)
      await provider.setUiScale(0.50);
      expect(provider.uiScale, 0.75);

      // Test clamping above maximum (1.25)
      await provider.setUiScale(1.50);
      expect(provider.uiScale, 1.25);

      // Test reset back to defaultScale (0.85)
      await provider.resetUiScale();
      expect(provider.uiScale, 0.85);
    });
  });

  group('UiScaleWrapper Widget Tests', () {
    testWidgets('Renders child directly at scale 1.0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UiScaleWrapper(
            scale: 1.0,
            child: Text('Test Scale 1.0'),
          ),
        ),
      );

      expect(find.text('Test Scale 1.0'), findsOneWidget);
      expect(find.byType(FittedBox), findsNothing);
    });

    testWidgets('Applies Transform and scaled MediaQuery at scale 0.85', (tester) async {
      late Size perceivedSize;

      await tester.pumpWidget(
        MaterialApp(
          home: UiScaleWrapper(
            scale: 0.85,
            child: Builder(
              builder: (context) {
                perceivedSize = MediaQuery.of(context).size;
                return const Text('Test Scale 0.85');
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Scale 0.85'), findsOneWidget);
      expect(find.byType(FittedBox), findsOneWidget);

      // Verify that virtual size is scaled inversely (800 / 0.85 > 800)
      expect(perceivedSize.width, greaterThan(800));
    });

    testWidgets('Allows pressing buttons at the bottom-right corner when zoomed out to 75%', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: UiScaleWrapper(
            scale: 0.75,
            child: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () {
                      buttonTapped = true;
                    },
                    child: const Text('Bottom Right Action'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.text('Bottom Right Action');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(buttonTapped, isTrue, reason: 'Button in bottom-right corner must receive tap events at 0.75x zoom');
    });

    testWidgets('Allows pressing all 4 corner buttons at 75% and 125% zoom', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final testScale in [0.75, 1.25]) {
        final tappedButtons = <String>{};

        await tester.pumpWidget(
          MaterialApp(
            home: UiScaleWrapper(
              scale: testScale,
              child: Scaffold(
                body: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: ElevatedButton(
                        onPressed: () => tappedButtons.add('top-left'),
                        child: const Text('TL'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: () => tappedButtons.add('top-right'),
                        child: const Text('TR'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                        onPressed: () => tappedButtons.add('bottom-left'),
                        child: const Text('BL'),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: () => tappedButtons.add('bottom-right'),
                        child: const Text('BR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('TL'));
        await tester.tap(find.text('TR'));
        await tester.tap(find.text('BL'));
        await tester.tap(find.text('BR'));
        await tester.pumpAndSettle();

        expect(tappedButtons, containsAll(['top-left', 'top-right', 'bottom-left', 'bottom-right']),
            reason: 'All four corner buttons must be tappable at scale $testScale');
      }
    });
  });

  group('Defensive UI Component Overflow Tests', () {
    testWidgets('ScreenHeader renders cleanly without overflow on narrow width', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScreenHeader(
              icon: Icons.local_shipping,
              title: 'Logistics & Dispatch Center Management Hub',
              iconColor: Colors.blue,
              actions: [
                Icon(Icons.filter_list),
                SizedBox(width: 8),
                Icon(Icons.more_vert),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Logistics & Dispatch Center Management Hub'), findsOneWidget);
    });

    testWidgets('QuantitySelectorButton renders without minimum constraint overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 40, // Narrow space that previously broke 64dp min size
              child: QuantitySelectorButton(
                quantity: 1,
                cost: 5.0,
                isSelected: true,
                canAfford: true,
                onPressed: () {},
                label: 'Buy 1',
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Buy 1'), findsOneWidget);
    });

    testWidgets('FleetUpgradeCard renders without stat pill overflow on Galaxy A55 width', (tester) async {
      // Galaxy A55: 412 logical width
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gameService = createTestGameService();
      addTearDown(() => cleanupTestEnvironment(gameService));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 412,
                child: FleetUpgradeCard(gameService: gameService),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FleetUpgradeCard), findsOneWidget);
    });

    testWidgets('PrestigeCard renders without IPO header overflow on Galaxy A55 width', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final gameService = createTestGameService();
      addTearDown(() => cleanupTestEnvironment(gameService));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 412,
                child: PrestigeCard(gameService: gameService),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PrestigeCard), findsOneWidget);
    });
  });
}
