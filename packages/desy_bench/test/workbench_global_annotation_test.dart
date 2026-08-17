import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('annotation controls select only scoped consumer content', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Annotation test',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            DesyStaticComponent(
              id: 'annotation.button',
              name: 'Annotation button',
              path: '/actions',
              instances: {
                'default': (_) => const SizedBox(
                  width: 120,
                  height: 48,
                  child: Text('A real registry widget'),
                ),
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reportIssue = find.byKey(
      const ValueKey('registry-spine-report-issue'),
    );
    expect(reportIssue, findsOneWidget);
    expect(
      tester.widget<DesyButton>(reportIssue).semanticsLabel,
      'Report an issue',
    );
    final inspectionToggle = find.byKey(
      const ValueKey('registry-spine-toggle-inspection'),
    );
    expect(
      tester.getCenter(reportIssue).dx,
      lessThan(tester.getCenter(inspectionToggle).dx),
      reason: 'the report action sits beside the top-right annotation toggle',
    );

    await tester.tap(inspectionToggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workbench-annotation-summary')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('workbench-annotation-summary')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Review your feedback'), findsOneWidget);
  });

  testWidgets('prototype canvas owns the annotation mode switch', (
    tester,
  ) async {
    const prototypeId = 'annotation.prototype.one';
    const sessionId = 'annotation.prototype.session';
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Canvas annotation test',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          prototypes: [
            DesyPrototypeSession(
              id: sessionId,
              name: 'Canvas directions',
              prototypes: [
                DesyPrototype(
                  id: prototypeId,
                  name: 'Annotation direction',
                  builder: _prototypePreview,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('prototype-session-$sessionId')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    const prefix = 'prototypes-canvas-$sessionId';
    expect(find.byKey(const ValueKey('$prefix-action-bar')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('$prefix-mode-select')),
        matching: find.text('⌘'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('$prefix-mode-annotate')),
        matching: find.text('⌘'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('registry-spine-toggle-inspection')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('$prefix-mode-annotate')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('$prefix-mode-select')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsNothing,
    );
  });

  testWidgets('prototype annotation is keyboard-first and batch-ready', (
    tester,
  ) async {
    const prototypeId = 'annotation.prototype.keyboard';
    const sessionId = 'annotation.prototype.keyboard.session';
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Keyboard annotation test',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          prototypes: [
            DesyPrototypeSession(
              id: sessionId,
              name: 'Keyboard directions',
              prototypes: [
                DesyPrototype(
                  id: prototypeId,
                  name: 'Keyboard direction',
                  builder: _prototypePreview,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('prototype-session-$sessionId')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsOneWidget,
    );

    await tester.tapAt(tester.getCenter(find.text('Prototype body')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-inspection-overlay')),
      findsNothing,
      reason: 'target picking is one-shot so the canvas can pan immediately',
    );
    expect(
      find.byKey(const ValueKey('workbench-annotation-dock')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('workbench-commit-annotation')),
        matching: find.text('↵'),
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('workbench-annotation-input')),
      'This needs a faster path',
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('workbench-annotation-dock')),
      findsOneWidget,
      reason: 'Shift+Enter remains available to the native multiline editor',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('workbench-annotation-dock')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('workbench-annotation-summary')),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 selected'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('workbench-annotation-select-all')),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 selected'), findsOneWidget);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _prototypePreview(BuildContext context) => const Text('Prototype body');
