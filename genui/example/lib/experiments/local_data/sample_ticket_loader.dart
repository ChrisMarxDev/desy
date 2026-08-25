import 'dart:async';

/// Local stand-in for a ticket-provider endpoint.
///
/// Each request exposes one more record, starting with APP-1. It deliberately
/// has no network dependency so the GenUI data-update path is easy to inspect.
final class SampleTicketLoader {
  /// Creates a loader with a small optional delay that resembles an endpoint.
  SampleTicketLoader({this.latency = const Duration(milliseconds: 220)});

  /// Delay applied before each local result is returned.
  final Duration latency;
  var _visibleTicketCount = 0;

  /// Reveals one more local ticket and returns the complete visible snapshot.
  Future<SampleTicketSnapshot> loadNext() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (_visibleTicketCount < _allTickets.length) _visibleTicketCount++;
    final tickets = _allTickets
        .take(_visibleTicketCount)
        .toList(growable: false);
    return SampleTicketSnapshot(tickets: tickets);
  }

  static const _allTickets = <Map<String, Object?>>[
    {
      'key': 'APP-1',
      'summary': 'Show the release owner on the overview',
      'status': 'In progress',
    },
    {
      'key': 'APP-2',
      'summary': 'Clarify the approval handoff',
      'status': 'Ready',
    },
    {
      'key': 'APP-3',
      'summary': 'Investigate the blocked import',
      'status': 'Blocked',
    },
    {
      'key': 'APP-4',
      'summary': 'Add the audit note to the release brief',
      'status': 'Ready',
    },
  ];
}

/// JSON-safe projection consumed by the ticket-list and status-chart knobs.
final class SampleTicketSnapshot {
  /// Creates the JSON-safe ticket and chart projection for one loader result.
  SampleTicketSnapshot({required List<Map<String, Object?>> tickets})
    : tickets = List.unmodifiable(
        tickets.map(Map<String, Object?>.unmodifiable),
      );

  /// Tickets visible after this request, in provider handoff form.
  final List<Map<String, Object?>> tickets;

  /// Stable status labels for the accompanying chart.
  List<String> get statusLabels => const ['Ready', 'In progress', 'Blocked'];

  /// Ticket count for each [statusLabels] entry.
  List<double> get statusValues => [
    for (final status in statusLabels)
      tickets.where((ticket) => ticket['status'] == status).length.toDouble(),
  ];
}
