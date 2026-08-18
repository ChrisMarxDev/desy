// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../asset_transfer.dart';
import '../widget_preview.dart';
import '../workbench_session.dart';

/// A specialized collection surface for consumer-owned packaged images.
class DesyAssetsScreen extends StatelessWidget {
  const DesyAssetsScreen({super.key, required this.session});

  final DesyWorkbenchSession session;

  @override
  Widget build(BuildContext context) {
    session.activeThemeIndex.watch(context);
    final assets = session.registry.allAssets;
    return ListView(
      key: const ValueKey('assets-screen'),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
      children: [
        Text('ATOMS / ASSETS', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text('Assets', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Approved bundled images, ready to preview, copy, or download.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 24),
        if (assets.isEmpty)
          Text(
            'No assets are registered.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 980
                  ? (constraints.maxWidth - 28) / 3
                  : constraints.maxWidth >= 640
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final asset in assets)
                    SizedBox(
                      width: width,
                      child: _AssetCard(
                        asset: asset,
                        theme: session.activeTheme,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.theme});

  final DesyAssetEntry asset;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => DesyCard(
    key: ValueKey('asset-card-${asset.id}'),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 190,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: DesyWidgetPreview(theme: theme, builder: asset.build),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                asset.fileName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              SelectableText(
                asset.id,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 12),
              Text(asset.description),
              const SizedBox(height: 16),
              _AssetActions(asset: asset),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AssetActions extends StatefulWidget {
  const _AssetActions({required this.asset});

  final DesyAssetEntry asset;

  @override
  State<_AssetActions> createState() => _AssetActionsState();
}

class _AssetActionsState extends State<_AssetActions> {
  String? _message;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, [String? success]) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) setState(() => _message = success);
    } catch (_) {
      if (mounted) setState(() => _message = 'Action unavailable');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (kIsWeb)
            DesyButton(
              key: ValueKey('asset-copy-${widget.asset.id}'),
              mainAxisSize: MainAxisSize.min,
              variant: DesyButtonVariant.outline,
              size: DesyButtonSize.sm,
              onPress: _busy
                  ? null
                  : () => unawaited(
                      _run(
                        () => copyDesyAssetImage(widget.asset),
                        'Image copied',
                      ),
                    ),
              child: const Text('Copy image'),
            ),
          DesyButton(
            key: ValueKey('asset-download-${widget.asset.id}'),
            mainAxisSize: MainAxisSize.min,
            size: DesyButtonSize.sm,
            onPress: _busy
                ? null
                : () => unawaited(
                    _run(() async {
                      await downloadDesyAsset(widget.asset);
                    }),
                  ),
            child: const Text('Download image'),
          ),
        ],
      ),
      if (_message case final message?) ...[
        const SizedBox(height: 8),
        Text(message, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}
