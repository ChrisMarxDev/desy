// PROTOTYPE: this is a consumer bridge, not a package unit test.
import 'dart:convert';
import 'dart:io';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:desy_goldens_prototype/desy_goldens_prototype.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _mode = String.fromEnvironment(
  'DESY_GOLDEN_MODE',
  defaultValue: 'verify',
);
const _planPath = '.dart_tool/desy_goldens_prototype/plan.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final plan = DesyGoldenPrototypePlan.fromRegistry(desyDesignSystemRegistry);

  setUpAll(() async {
    await _loadDogfoodFonts();
    await _writePlan(plan);
  });

  if (_mode == 'plan') {
    test('derives the complete dogfood golden plan', () {
      stdout.writeln(
        'Derived ${plan.cases.length} cases from '
        '${desyDesignSystemRegistry.name}.',
      );
      stdout.writeln('Plan digest: ${plan.digest}');
      stdout.writeln('Plan receipt: $_planPath');
    });
    return;
  }

  for (final goldenCase in plan.cases) {
    testWidgets(goldenCase.id, (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = goldenCase.logicalSize;
      addTearDown(tester.view.reset);

      final captureKey = GlobalKey();
      final designTheme = goldenCase.theme.usesDarkWorkbench
          ? DesyDesignSystemTheme.dark
          : DesyDesignSystemTheme.light;
      final background =
          goldenCase.theme.previewBackgroundColor ?? Colors.transparent;

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: DesyDesignSystemFoundation.materialTheme(designTheme),
          supportedLocales: DesyDesignSystemFoundation.supportedLocales,
          localizationsDelegates:
              DesyDesignSystemFoundation.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: goldenCase.logicalSize,
              devicePixelRatio: 1,
              textScaler: TextScaler.noScaling,
              boldText: false,
              highContrast: false,
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: captureKey,
              child: ColoredBox(
                color: background,
                child: SizedBox.expand(
                  child: Center(
                    child: DesyWidgetPreview(
                      theme: goldenCase.theme,
                      builder: goldenCase.build,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await expectLater(
        find.byKey(captureKey),
        matchesGoldenFile(goldenCase.goldenPath),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

Future<void> _writePlan(DesyGoldenPrototypePlan plan) async {
  final file = File(_planPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(plan.toJson()),
    flush: true,
  );
}

Future<void> _loadDogfoodFonts() async {
  final loader = FontLoader(DesyDesignSystemTokens.fontFamily);
  for (final asset in const [
    'Roboto-Light.ttf',
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    loader.addFont(
      rootBundle.load('packages/desy_design_system/assets/fonts/$asset'),
    );
  }
  await loader.load();
}
