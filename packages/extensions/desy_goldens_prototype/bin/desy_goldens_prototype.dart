// PROTOTYPE: throwaway terminal shell for the dogfood golden runner.
import 'dart:convert';
import 'dart:io';

const _planPath = '.dart_tool/desy_goldens_prototype/plan.json';
const _testPath = 'test/dogfood_goldens_test.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    await _interactive();
    return;
  }

  final command = arguments.first;
  final accepted = arguments.contains('--accept');
  if (command == 'update' && !accepted) {
    stderr.writeln('Refusing to update goldens without --accept.');
    exitCode = 64;
    return;
  }
  if (!const {'plan', 'verify', 'update'}.contains(command)) {
    stderr.writeln(
      'Usage: desy_goldens_prototype [plan|verify|update --accept]',
    );
    exitCode = 64;
    return;
  }
  exitCode = await _run(command);
}

Future<void> _interactive() async {
  var lastAction = 'none';
  int? lastExitCode;

  while (true) {
    _render(lastAction: lastAction, lastExitCode: lastExitCode);
    stdout.write('Choose an action: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    switch (input) {
      case 'p':
      case 'plan':
        lastAction = 'plan';
        lastExitCode = await _run('plan');
      case 'v':
      case 'verify':
        lastAction = 'verify';
        lastExitCode = await _run('verify');
      case 'u':
      case 'update':
        stdout.write('Type ACCEPT to generate or replace baselines: ');
        if (stdin.readLineSync()?.trim() != 'ACCEPT') {
          lastAction = 'update cancelled';
          lastExitCode = null;
          continue;
        }
        lastAction = 'update';
        lastExitCode = await _run('update');
      case 'q':
      case 'quit':
        return;
      default:
        lastAction = 'unknown input: ${input ?? 'EOF'}';
        lastExitCode = null;
    }
  }
}

Future<int> _run(String command) async {
  _clear();
  stdout.writeln('Running dogfood golden $command through headless Flutter…');
  final arguments = <String>[
    'test',
    if (command == 'update') '--update-goldens',
    _testPath,
    '--dart-define=DESY_GOLDEN_MODE=$command',
  ];
  final process = await Process.start('flutter', arguments);
  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .forEach(stdout.write);
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .forEach(stderr.write);
  final code = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  return code;
}

void _render({required String lastAction, required int? lastExitCode}) {
  _clear();
  final plan = _readPlan();
  stdout.writeln('\x1b[1mDESY DOGFOOD GOLDENS — PROTOTYPE\x1b[0m');
  stdout.writeln(
    '\x1b[2mRegistry-derived; no app route and no target list.\x1b[0m',
  );
  stdout.writeln();
  stdout.writeln('\x1b[1mLast action\x1b[0m   $lastAction');
  stdout.writeln('\x1b[1mExit code\x1b[0m     ${lastExitCode ?? '—'}');
  stdout.writeln(
    '\x1b[1mCases\x1b[0m         ${plan?['caseCount'] ?? 'not planned'}',
  );
  stdout.writeln('\x1b[1mPlan digest\x1b[0m   ${plan?['digest'] ?? '—'}');
  stdout.writeln('\x1b[1mPlan file\x1b[0m     $_planPath');
  stdout.writeln();
  stdout.writeln(
    '\x1b[1m[p]\x1b[0m plan  '
    '\x1b[1m[v]\x1b[0m verify  '
    '\x1b[1m[u]\x1b[0m update  '
    '\x1b[1m[q]\x1b[0m quit',
  );
  stdout.writeln();
}

Map<String, Object?>? _readPlan() {
  final file = File(_planPath);
  if (!file.existsSync()) return null;
  final value = jsonDecode(file.readAsStringSync());
  return value is Map ? Map<String, Object?>.from(value) : null;
}

void _clear() {
  if (stdout.hasTerminal) stdout.write('\x1b[2J\x1b[H');
}
