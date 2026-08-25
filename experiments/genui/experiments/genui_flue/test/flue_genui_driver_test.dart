import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_flue/genui_flue.dart';

void main() {
  test('decodes Flue data and control SSE events', () async {
    final lines = Stream<String>.fromIterable(const [
      'event: data',
      'data: [{"type":"message-delta","kind":"text","delta":"{"}]',
      '',
      'event: control',
      'data: {"streamNextOffset":"0001"}',
      '',
    ]);

    final events = await FlueGenUiDriver.decodeFlueSse(lines).toList();

    expect(events, hasLength(2));
    expect(events.first.name, 'data');
    expect(events.first.data, contains('message-delta'));
    expect(events.last.name, 'control');
    expect(events.last.data, '{"streamNextOffset":"0001"}');
  });

  test('flushes an SSE event when a finite stream closes', () async {
    final controller = StreamController<String>();
    final events = FlueGenUiDriver.decodeFlueSse(controller.stream).toList();
    controller
      ..add('event: data')
      ..add('data: [{"type":"submission-settled"}]');
    await controller.close();

    final decoded = await events;
    expect(decoded.single.name, 'data');
    expect(decoded.single.data, contains('submission-settled'));
  });
}
