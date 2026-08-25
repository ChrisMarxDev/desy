import 'package:desy_genui_example/experiments/local_data/sample_ticket_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'each local ticket request reveals exactly one additional ticket',
    () async {
      final loader = SampleTicketLoader(latency: Duration.zero);

      final first = await loader.loadNext();
      expect(first.tickets.map((ticket) => ticket['key']), ['APP-1']);

      final second = await loader.loadNext();
      expect(second.tickets.map((ticket) => ticket['key']), ['APP-1', 'APP-2']);

      final third = await loader.loadNext();
      expect(third.tickets.map((ticket) => ticket['key']), [
        'APP-1',
        'APP-2',
        'APP-3',
      ]);
      expect(third.statusLabels, ['Ready', 'In progress', 'Blocked']);
      expect(third.statusValues, [1, 1, 1]);
    },
  );
}
