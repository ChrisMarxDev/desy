import 'package:desy_overlay/desy_overlay.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final _annotations = <DesyAnnotation>[];

  void _forwardAnnotation(DesyAnnotation annotation) {
    // Replace this callback with a repository service, MCP client, issue
    // tracker, clipboard prompt, or any other consumer-owned integration.
    setState(() => _annotations.add(annotation));
    debugPrint(
      '${annotation.target.sourceLocation ?? annotation.target.widgetPath}: '
      '${annotation.comment}',
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Desy Overlay Example',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
      useMaterial3: true,
    ),
    builder: DesyOverlay.builder(
      // The example intentionally demonstrates the explicit release opt-in.
      // Production consumers should keep the default debugOnly mode unless a
      // user-facing review surface is part of their product.
      mode: DesyOverlayMode.always,
      onAnnotationSubmitted: _forwardAnnotation,
    ),
    home: ExampleHome(
      annotationCount: _annotations.length,
      latestAnnotation: _annotations.lastOrNull,
    ),
  );
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({
    super.key,
    required this.annotationCount,
    required this.latestAnnotation,
  });

  final int annotationCount;
  final DesyAnnotation? latestAnnotation;

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  var _weeklySummary = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Delivery dashboard'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Chip(
              avatar: const Icon(Icons.rate_review_outlined, size: 16),
              label: Text('${widget.annotationCount} annotations'),
            ),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Good morning, Alex',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Track today’s releases and review what needs attention.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _MetricCard(
              semanticIdentifier: 'delivery.metric.inProgress',
              title: 'In progress',
              value: '12',
              icon: Icons.rocket_launch_outlined,
            ),
            _MetricCard(
              semanticIdentifier: 'delivery.metric.readyForReview',
              title: 'Ready for review',
              value: '4',
              icon: Icons.fact_check_outlined,
            ),
            _MetricCard(
              semanticIdentifier: 'delivery.metric.shippedThisWeek',
              title: 'Shipped this week',
              value: '28',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Weekly delivery summary'),
                  subtitle: const Text(
                    'Receive a digest every Friday morning.',
                  ),
                  value: _weeklySummary,
                  onChanged: (value) => setState(() => _weeklySummary = value),
                ),
              ],
            ),
          ),
        ),
        if (widget.latestAnnotation case final annotation?) ...[
          const SizedBox(height: 16),
          Text(
            'Latest: ${annotation.target.widgetType} — ${annotation.comment}',
            key: const ValueKey('latest-annotation'),
          ),
        ],
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      key: const ValueKey('delivery-new-release'),
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('New release'),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.semanticIdentifier,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String semanticIdentifier;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: semanticIdentifier,
    label: '$title: $value',
    child: SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
