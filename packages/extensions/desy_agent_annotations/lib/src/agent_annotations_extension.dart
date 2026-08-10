import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'agent_annotation.dart';

/// A registry-entry detail comment composer backed by a consumer-owned callback.
final class DesyAgentAnnotationsExtension extends DesyDetailExtension {
  /// Creates the optional agent-annotation detail extension.
  const DesyAgentAnnotationsExtension({required this.onSubmit})
    : super(
        id: 'desy.agent-annotations',
        name: 'Agent annotation',
        description: 'Send an entry-scoped observation to an agent.',
      );

  /// The only required integration point. Persistence and authentication stay
  /// in the consuming application.
  final DesyAgentAnnotationSubmit onSubmit;

  @override
  Widget build(BuildContext context, DesyDetailExtensionContext extension) =>
      _AgentAnnotationComposer(extensionContext: extension, onSubmit: onSubmit);
}

class _AgentAnnotationComposer extends StatefulWidget {
  const _AgentAnnotationComposer({
    required this.extensionContext,
    required this.onSubmit,
  });

  final DesyDetailExtensionContext extensionContext;
  final DesyAgentAnnotationSubmit onSubmit;

  @override
  State<_AgentAnnotationComposer> createState() =>
      _AgentAnnotationComposerState();
}

class _AgentAnnotationComposerState extends State<_AgentAnnotationComposer> {
  String _draft = '';
  bool _submitting = false;
  bool _failed = false;
  DesyAgentAnnotationReceipt? _receipt;

  bool get _canSubmit => !_submitting && _draft.trim().isNotEmpty;

  void _onChanged(String value) {
    setState(() {
      _draft = value;
      _failed = false;
      _receipt = null;
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final comment = _draft.trim();
    final annotation = DesyAgentAnnotation.fromContext(
      context: widget.extensionContext,
      comment: comment,
      createdAt: DateTime.now().toUtc(),
    );
    setState(() {
      _submitting = true;
      _failed = false;
      _receipt = null;
    });

    try {
      final receipt = await widget.onSubmit(annotation);
      if (!mounted) return;
      setState(() {
        _draft = '';
        _submitting = false;
        _receipt = receipt;
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'desy_agent_annotations',
          context: ErrorDescription(
            'while submitting detail extension "desy.agent-annotations"',
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _submitting
        ? 'Sending'
        : _failed
        ? 'Failed'
        : _receipt != null
        ? 'Sent'
        : _draft.trim().isNotEmpty
        ? 'Draft'
        : 'Ready';
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
      },
      child: DesyAccordion(
        key: const ValueKey('agent-annotation-composer'),
        children: [
          DesyAccordionItem(
            key: const ValueKey('agent-annotation-ledger-item'),
            initiallyExpanded: true,
            title: _AnnotationLedgerSummary(
              entryName: widget.extensionContext.entry.name,
              source:
                  widget.extensionContext.component?.source ??
                  widget.extensionContext.entry.id,
              state: state,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DesyTextField(
                    key: const ValueKey('agent-annotation-comment'),
                    label: 'Comment for agent',
                    hintText: 'Describe the change.',
                    value: _draft,
                    enabled: !_submitting,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 3,
                    maxLines: 8,
                    onChanged: _onChanged,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DesyButton(
                      key: const ValueKey('agent-annotation-submit'),
                      semanticsLabel: _submitting
                          ? 'Submitting agent annotation'
                          : 'Send annotation to agent',
                      size: DesyButtonSize.sm,
                      mainAxisSize: MainAxisSize.min,
                      onPress: _canSubmit ? _submit : null,
                      child: Text(_submitting ? 'Sending…' : 'Send'),
                    ),
                  ),
                  if (_submitting) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      key: const ValueKey('agent-annotation-busy'),
                      container: true,
                      liveRegion: true,
                      label: 'Submitting agent annotation',
                      child: Text('Submitting annotation…'),
                    ),
                  ],
                  if (_failed) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      key: const ValueKey('agent-annotation-error'),
                      container: true,
                      liveRegion: true,
                      label:
                          'Annotation failed. The comment was preserved for retry.',
                      child: Text(
                        'Could not send the annotation. Check the destination and try again.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  if (_receipt case final receipt?) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      key: const ValueKey('agent-annotation-receipt'),
                      container: true,
                      liveRegion: true,
                      label: 'Annotation sent. ${receipt.message}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(receipt.message),
                          if (receipt.location case final location?)
                            SelectableText(location.toString()),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnotationLedgerSummary extends StatelessWidget {
  const _AnnotationLedgerSummary({
    required this.entryName,
    required this.source,
    required this.state,
  });

  final String entryName;
  final String source;
  final String state;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            entryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.body.sm.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            source,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.body.xs.copyWith(
              color: colors.mutedForeground,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          state,
          style: typography.body.xs.copyWith(
            color: state == 'Failed'
                ? Theme.of(context).colorScheme.error
                : colors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
