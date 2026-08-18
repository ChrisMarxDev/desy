import 'dart:io';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_widget_workshop/desy_widget_workshop.dart';
import 'package:desy_widget_workshop/src/workshop_runtime.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('candidate snapshots its optional component drill-down', () {
    final components = <DesyWorkshopCandidateComponent>[
      const DesyWorkshopCandidateComponent.registry(
        instanceId: 'fixture.button.primary',
      ),
    ];
    final candidate = DesyWorkshopCandidate(
      id: 'focused',
      title: 'Focused',
      description: 'Selected direction',
      builder: _candidate,
      components: components,
    );

    components.clear();

    expect(candidate.components, hasLength(1));
    expect(candidate.components.single.isInRegistry, isTrue);
    expect(
      () => candidate.components.add(
        const DesyWorkshopCandidateComponent.registry(
          instanceId: 'fixture.button.secondary',
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test(
    'clears submitted feedback and resumes the same Codex conversation',
    () async {
      if (!Platform.isMacOS && !Platform.isLinux) return;

      final directory = await Directory.systemTemp.createTemp(
        'desy-workshop-runtime-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final calls = File('${directory.path}/calls.txt');
      final prompts = File('${directory.path}/prompts.txt');
      final executable = File('${directory.path}/fake-codex');
      await executable.writeAsString('''#!/bin/sh
printf '%s\\n' '---' "\$@" >> '${calls.path}'
cat >> '${prompts.path}'
printf '\\n<<<END>>>\\n' >> '${prompts.path}'
printf '%s\\n' \\
  '{"type":"thread.started","thread_id":"workshop-thread-1"}' \\
  '{"type":"turn.started"}' \\
  '{"type":"item.completed","item":{"type":"agent_message","text":"Done"}}'
''');
      final chmod = await Process.run('chmod', ['+x', executable.path]);
      expect(chmod.exitCode, 0);

      final runtime = createDesyWorkshopRuntime(
        DesyWidgetWorkshopConfiguration(
          projectDirectory: directory.path,
          candidateSourcePath: 'candidates.dart',
          flutterPidFile: 'missing.pid',
          codexExecutable: executable.path,
          candidates: () => const [],
        ),
      );
      addTearDown(runtime.dispose);
      final candidates = [
        DesyWorkshopCandidate(
          id: 'focused',
          title: 'Focused',
          description: 'Selected direction',
          builder: _candidate,
          components: const [
            DesyWorkshopCandidateComponent.prototype(
              id: 'focused.new-part',
              title: 'New part',
              description: 'Still being designed',
              prototypeBuilder: _candidate,
            ),
            DesyWorkshopCandidateComponent.registry(
              instanceId: 'fixture.button.primary',
            ),
          ],
        ),
        DesyWorkshopCandidate(
          id: 'rejected',
          title: 'Rejected',
          description: 'Direction to remove',
          builder: _candidate,
        ),
      ];

      runtime.setPrompt('First feedback');
      await runtime.run(
        candidates: candidates,
        agentBrief: _agentBrief([
          DesyWorkbenchAnnotation(
            id: 1,
            target: const DesyWorkbenchWidgetTarget(
              screenId: '/atlas',
              widgetType: 'DesyButton',
              description: 'Text("Continue")',
              widgetPath: 'DesyAtlasScreen > DesyButton',
              bounds: Rect.fromLTWH(0, 0, 120, 48),
              sourceLocation: DesyWorkbenchSourceLocation(
                sourcePath: 'lib/src/continue_button.dart',
                line: 42,
                column: 7,
              ),
              inspectionContext: DesyWorkbenchInspectionContext(
                artifactId: 'homepage.focused',
                kind: 'Workshop candidate',
                label: 'Focused homepage',
              ),
            ),
            comment: 'Make the label 10 percent larger.',
            createdAt: DateTime.utc(2026, 8, 10),
          ),
        ]),
      );

      expect(runtime.prompt, isEmpty);
      expect(runtime.sessionId, 'workshop-thread-1');

      runtime.setPrompt('Second feedback');
      await runtime.run(
        candidates: candidates,
        agentBrief: _agentBrief(const []),
      );

      expect(runtime.prompt, isEmpty);
      expect(runtime.sessionId, 'workshop-thread-1');
      expect(
        await calls.readAsString(),
        allOf(
          isNot(contains('--ephemeral')),
          contains('resume\nworkshop-thread-1\n-'),
        ),
      );
      final submittedPrompts = await prompts.readAsString();
      expect(submittedPrompts, contains('First feedback'));
      expect(submittedPrompts, contains('Second feedback'));
      expect(
        submittedPrompts,
        contains(
          'Current proposals (refer to their number, id, or title in plain text):',
        ),
      );
      expect(submittedPrompts, contains('1. focused — Focused'));
      expect(submittedPrompts, contains('Desy workspace brief:'));
      expect(submittedPrompts, contains('Registry: Dogfood system'));
      expect(submittedPrompts, contains('Theme: Light (dogfood.light)'));
      expect(
        submittedPrompts,
        contains(
          'The user committed these global workbench annotations as JSON',
        ),
      );
      expect(submittedPrompts, contains('Make the label 10 percent larger.'));
      expect(submittedPrompts, contains('"attachment": "attached"'));
      expect(
        submittedPrompts,
        contains('"path": "lib/src/continue_button.dart"'),
      );
      expect(submittedPrompts, contains('"id": "homepage.focused"'));
      expect(submittedPrompts, contains('it is not an edit boundary'));
      expect(submittedPrompts, contains("consumer's actual design system"));
      expect(submittedPrompts, contains('Do not infer a chosen direction'));
      expect(
        submittedPrompts,
        contains('Registry component instance: fixture.button.primary'),
      );
      expect(submittedPrompts, isNot(contains('Edit only candidates.dart')));
      expect(
        runtime.logs.where((line) => line == 'Codex conversation started.'),
        hasLength(1),
      );
      expect(
        runtime.logs.where((line) => line == 'Codex conversation resumed.'),
        hasLength(1),
      );
    },
  );
}

Widget _candidate(BuildContext context) => const SizedBox.shrink();

DesyWorkspaceAgentBrief _agentBrief(
  List<DesyWorkbenchAnnotation> annotations,
) => DesyWorkspaceAgentBrief(
  focus: const DesyWorkspaceFocus(
    route: '/workspace/widget-workshop',
    registryName: 'Dogfood system',
    themeId: 'dogfood.light',
    themeName: 'Light',
  ),
  annotations: annotations,
);
