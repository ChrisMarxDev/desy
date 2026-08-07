// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../detail_extension.dart';
import '../../registry.dart';
import '../workbench_session.dart';

/// The single host-owned extension region in a component detail inspector.
///
/// It guards synchronous predicate and declaration-builder calls. Once a
/// declaration returns a widget, failures in that widget's element subtree use
/// Flutter's ordinary error reporting and ErrorWidget replacement.
class DesyDetailExtensionsRegion extends StatelessWidget {
  const DesyDetailExtensionsRegion({
    super.key,
    required this.session,
    required this.entry,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.component == null || session.detailExtensions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Establish an explicit dependency so a new read-only context is supplied
    // for the active theme without changing the stable section subtree keys.
    session.activeThemeIndex.watch(context);
    final extensions = <_ResolvedDetailExtension>[];
    for (final extension in session.detailExtensions) {
      // Resolve a fresh immutable context for each declaration. Extensions do
      // not share even an ephemeral host object.
      final extensionContext = session.detailExtensionContext(entry);
      try {
        if (extension.appliesTo(extensionContext)) {
          extensions.add(
            _ResolvedDetailExtension(
              extension: extension,
              context: extensionContext,
            ),
          );
        }
      } catch (error, stackTrace) {
        _reportExtensionFailure(
          extension: extension,
          phase: 'checking applicability for',
          error: error,
          stackTrace: stackTrace,
        );
        extensions.add(
          _ResolvedDetailExtension(
            extension: extension,
            context: extensionContext,
            failedApplicability: true,
          ),
        );
      }
    }
    if (extensions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final resolved in extensions) ...[
          const SizedBox(height: 24),
          _DetailExtensionSection(
            key: ValueKey(
              'detail-extension:${entry.id}:${resolved.extension.id}',
            ),
            resolved: resolved,
          ),
        ],
      ],
    );
  }
}

class _ResolvedDetailExtension {
  const _ResolvedDetailExtension({
    required this.extension,
    required this.context,
    this.failedApplicability = false,
  });

  final DesyDetailExtension extension;
  final DesyDetailExtensionContext context;
  final bool failedApplicability;
}

class _DetailExtensionSection extends StatelessWidget {
  const _DetailExtensionSection({super.key, required this.resolved});

  final _ResolvedDetailExtension resolved;

  @override
  Widget build(BuildContext context) {
    final extension = resolved.extension;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '${extension.name} detail extension',
      child: DesyCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  extension.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (extension.description case final description?) ...[
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 12),
              _buildBody(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final extension = resolved.extension;
    if (resolved.failedApplicability) {
      return _DetailExtensionFailure(extension: extension);
    }
    try {
      // Calling the declaration is the complete host error boundary. Building
      // the returned widget happens later in Flutter's element lifecycle and
      // deliberately retains Flutter's normal ErrorWidget behavior.
      return extension.build(context, resolved.context);
    } catch (error, stackTrace) {
      _reportExtensionFailure(
        extension: extension,
        phase: 'building',
        error: error,
        stackTrace: stackTrace,
      );
      return _DetailExtensionFailure(extension: extension);
    }
  }
}

class _DetailExtensionFailure extends StatelessWidget {
  const _DetailExtensionFailure({required this.extension});

  final DesyDetailExtension extension;

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('detail-extension-error:${extension.id}'),
    container: true,
    liveRegion: true,
    label: '${extension.name} could not be loaded',
    child: Text(
      'This extension could not be loaded.',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

void _reportExtensionFailure({
  required DesyDetailExtension extension,
  required String phase,
  required Object error,
  required StackTrace stackTrace,
}) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'desy_bench',
      context: ErrorDescription(
        'while $phase detail extension "${extension.id}"',
      ),
    ),
  );
}
