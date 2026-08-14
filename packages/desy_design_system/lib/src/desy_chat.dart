import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_button.dart';
import 'desy_design_system_scope.dart';
import 'desy_icons.dart';
import 'desy_text_field.dart';
import 'desy_visual_tokens.dart';

/// The author of one message in a Desy agent conversation.
enum DesyChatRole {
  /// A request entered by the person operating the workbench.
  user,

  /// A response produced by the connected agent.
  agent,
}

/// One message in a Desy workbench agent conversation.
///
/// Agent output uses the signal color as an inspection trace. User prompts use
/// the recessed panel surface so commands remain distinct without adopting a
/// consumer-messenger bubble vocabulary.
class DesyChatMessage extends StatelessWidget {
  /// Creates a message with consumer-owned [child] content.
  const DesyChatMessage({
    super.key,
    required this.role,
    required this.child,
    this.label,
    this.pending = false,
  });

  /// The author represented by this message.
  final DesyChatRole role;

  /// The message content or generated surface.
  final Widget child;

  /// Optional author label overriding the role default.
  final String? label;

  /// Whether the agent is still producing this message.
  final bool pending;

  @override
  Widget build(BuildContext context) => switch (role) {
    DesyChatRole.user => _buildUser(context),
    DesyChatRole.agent => _buildAgent(context),
  };

  Widget _buildUser(BuildContext context) {
    final colors = context.theme.colors;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.desy.panelSubtle,
            border: Border.all(color: colors.desy.divider),
            borderRadius: BorderRadius.circular(
              DesyDesignSystemTokens.radiusMd,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageLabel(label: label ?? 'YOU'),
                const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgent(BuildContext context) {
    final colors = context.theme.colors;
    return Semantics(
      liveRegion: pending,
      label: label ?? 'GENUI AGENT',
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.desy.signal,
                borderRadius: BorderRadius.circular(
                  DesyDesignSystemTokens.radiusSm,
                ),
              ),
              child: const SizedBox(width: 2),
            ),
            const SizedBox(width: DesyDesignSystemTokens.spaceMd),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        DesyIcons.sparkles,
                        size: 14,
                        color: colors.desy.signal,
                      ),
                      const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                      Expanded(
                        child: _MessageLabel(label: label ?? 'GENUI AGENT'),
                      ),
                      if (pending)
                        SizedBox.square(
                          dimension: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: colors.desy.signal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceMd),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageLabel extends StatelessWidget {
  const _MessageLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.theme.typography.body.xs.copyWith(
      color: context.theme.colors.mutedForeground,
      fontWeight: FontWeight.w700,
      letterSpacing: .7,
    ),
  );
}

/// A structural conversation surface for Desy's agent workflows.
class DesyChatThread extends StatelessWidget {
  /// Creates a thread from ordered [messages] and an optional [composer].
  const DesyChatThread({
    super.key,
    required this.messages,
    this.composer,
    this.title = 'GENUI AGENT',
    this.detail,
  });

  /// Short stable name for the connected agent or workflow.
  final String title;

  /// Secondary provider, model, or catalog context.
  final String? detail;

  /// Ordered conversation content.
  final List<Widget> messages;

  /// Optional text-entry control shown after the conversation.
  final Widget? composer;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.desy.panel,
        border: Border.all(color: colors.desy.divider),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusLg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesyDesignSystemTokens.spaceBase,
                vertical: DesyDesignSystemTokens.spaceMd,
              ),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.desy.signalSurface,
                      borderRadius: BorderRadius.circular(
                        DesyDesignSystemTokens.radiusSm,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        DesyDesignSystemTokens.spaceSm,
                      ),
                      child: Icon(
                        DesyIcons.sparkles,
                        size: 15,
                        color: colors.desy.signal,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.theme.typography.body.sm.copyWith(
                            color: colors.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (detail case final detail?)
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.theme.typography.body.xs.copyWith(
                              color: colors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: colors.desy.divider),
            Padding(
              padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < messages.length; index++) ...[
                    if (index > 0)
                      const SizedBox(height: DesyDesignSystemTokens.spaceXl),
                    messages[index],
                  ],
                ],
              ),
            ),
            if (composer case final composer?) ...[
              Divider(height: 1, thickness: 1, color: colors.desy.divider),
              Padding(
                padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceBase),
                child: composer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Native text entry and a Desy action for sending an agent request.
class DesyChatComposer extends StatefulWidget {
  /// Creates an agent prompt composer.
  const DesyChatComposer({
    super.key,
    required this.onSubmit,
    this.value = '',
    this.onChanged,
    this.hintText = 'Describe the interface you need',
    this.submitLabel = 'Generate UI',
    this.enabled = true,
    this.loading = false,
    this.errorText,
    this.clearOnSubmit = false,
  });

  /// Current externally controlled text.
  final String value;

  /// Called whenever native editing changes the prompt.
  final ValueChanged<String>? onChanged;

  /// Called with trimmed, non-empty text when the action is activated.
  final ValueChanged<String> onSubmit;

  /// Empty-state guidance shown inside the field.
  final String hintText;

  /// Visible label for the primary action.
  final String submitLabel;

  /// Whether the composer accepts input.
  final bool enabled;

  /// Whether an agent request is currently running.
  final bool loading;

  /// Accessible validation guidance for the field.
  final String? errorText;

  /// Whether successful submission clears the local value.
  final bool clearOnSubmit;

  @override
  State<DesyChatComposer> createState() => _DesyChatComposerState();
}

class _DesyChatComposerState extends State<DesyChatComposer> {
  late String _value = widget.value;

  @override
  void didUpdateWidget(covariant DesyChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _value) {
      _value = widget.value;
    }
  }

  bool get _canSubmit =>
      widget.enabled && !widget.loading && _value.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    final value = _value.trim();
    widget.onSubmit(value);
    if (widget.clearOnSubmit) {
      setState(() => _value = '');
      widget.onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DesyTextField(
        label: 'Agent prompt',
        hintText: widget.hintText,
        errorText: widget.errorText,
        value: _value,
        enabled: widget.enabled && !widget.loading,
        minLines: 2,
        maxLines: 5,
        textInputAction: TextInputAction.newline,
        onChanged: (value) {
          setState(() => _value = value);
          widget.onChanged?.call(value);
        },
      ),
      const SizedBox(height: DesyDesignSystemTokens.spaceMd),
      Align(
        alignment: Alignment.centerRight,
        child: DesyButton(
          onPress: _canSubmit ? _submit : null,
          mainAxisSize: MainAxisSize.min,
          prefix: widget.loading
              ? SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: context.theme.colors.primaryForeground,
                  ),
                )
              : const Icon(DesyIcons.send, size: 15),
          child: Text(widget.loading ? 'Generating…' : widget.submitLabel),
        ),
      ),
    ],
  );
}
