import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session stores typed knob values under their declared definition', () {
    final definition = KnobDefinition(
      id: 'trailing',
      name: 'Trailing',
      kind: DesyKnobKind.string,
      initial: 'status.clear',
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Session',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      ),
    );

    session.setKnob(definition, 'status.clear');
    expect(session.knobValues.value['trailing'], 'status.clear');

    session.dispose();
  });

  test(
    'agent brief resolves the current registry artifact without copying it',
    () {
      final registry = DesyRegistry(
        name: 'Workspace registry',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        components: [
          DesyStaticComponent(
            id: 'actions.primary',
            name: 'Primary action',
            path: '/actions',
            description: 'The default high-emphasis action.',
            instances: {'default': (_) => const SizedBox()},
          ),
        ],
      );

      final focus = DesyWorkspaceFocus.resolve(
        registry: registry,
        activeTheme: registry.themes.single,
        route: '/entries/actions.primary',
        artifactId: 'actions.primary',
      );
      final brief = DesyWorkspaceAgentBrief(
        focus: focus,
        annotations: const [],
      );

      expect(focus.artifact?.id, 'actions.primary');
      expect(focus.artifact?.path, '/actions');
      expect(brief.summary, 'Primary action · Light');
      expect(
        brief.toMarkdown(),
        allOf(
          contains(
            'Focused registry artifact: actions.primary — Primary action',
          ),
          contains('Declared intent: The default high-emphasis action.'),
        ),
      );
    },
  );

  test('hot reload detaches existing visual annotation bounds', () {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Annotation session',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      ),
    );
    session.addWorkbenchAnnotation(
      target: const DesyWorkbenchWidgetTarget(
        screenId: '/atlas',
        widgetType: 'FilledButton',
        description: 'Primary action',
        widgetPath: 'Actions > FilledButton',
        bounds: Rect.fromLTWH(12, 24, 120, 48),
      ),
      comment: 'Make the tap target larger.',
    );

    session.detachWorkbenchAnnotationsAfterReload();

    expect(
      session.workbenchAnnotations.value.single.attachment,
      DesyWorkbenchAnnotationAttachment.detached,
    );
    expect(
      session.workbenchAnnotations.value.single.target.widgetType,
      'FilledButton',
      reason: 'The agent still receives durable target evidence.',
    );
    session.dispose();
  });
}

Widget _wrap(BuildContext context, Widget child) => child;
