// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../widget_preview.dart';
import '../workbench_annotation.dart';
import '../workbench_session.dart';
import 'prototype_widget_tree.dart';

/// A browseable comparison surface for consumer-owned visual experiments.
class DesyPrototypesScreen extends StatefulWidget {
  const DesyPrototypesScreen({
    super.key,
    required this.session,
    required this.prototypeSession,
  });

  final DesyWorkbenchSession session;
  final DesyPrototypeSession prototypeSession;

  @override
  State<DesyPrototypesScreen> createState() => _DesyPrototypesScreenState();
}

class _DesyPrototypesScreenState extends State<DesyPrototypesScreen> {
  late DesyPrototype _selectedPrototype;
  final _scopeKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _selectedPrototype = widget.prototypeSession.prototypes.first;
  }

  @override
  void didUpdateWidget(DesyPrototypesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.prototypeSession.prototypes.contains(_selectedPrototype)) {
      _selectedPrototype = widget.prototypeSession.prototypes.first;
    }
  }

  GlobalKey _scopeKeyFor(DesyPrototype prototype) =>
      _scopeKeys.putIfAbsent(prototype.id, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final themeIndex = widget.session.activeThemeIndex.watch(context);
    final theme = widget.session.registry.themes[themeIndex];
    final prototypes = widget.prototypeSession.prototypes;
    return Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROTOTYPES',
            style: context.theme.typography.body.xs.copyWith(
              color: context.theme.colors.mutedForeground,
              fontWeight: FontWeight.w800,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: DesyDesignSystemTokens.spaceXs),
          Text(
            widget.prototypeSession.name,
            style: context.theme.typography.display.sm,
          ),
          if (widget.prototypeSession.description case final description?) ...[
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            Text(
              description,
              style: context.theme.typography.body.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: DesyDesignSystemTokens.spaceLg),
          Expanded(
            flex: 3,
            child: prototypes.isEmpty
                ? const _EmptyPrototypes()
                : ListView.separated(
                    key: const ValueKey('prototypes-list'),
                    scrollDirection: Axis.horizontal,
                    itemCount: prototypes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                    itemBuilder: (context, index) => _PrototypeCard(
                      prototype: prototypes[index],
                      theme: theme,
                      scopeKey: _scopeKeyFor(prototypes[index]),
                      selected: prototypes[index].id == _selectedPrototype.id,
                      onSelect: () => setState(
                        () => _selectedPrototype = prototypes[index],
                      ),
                    ),
                  ),
          ),
          if (prototypes.isNotEmpty) ...[
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            Text(
              'WIDGET ANATOMY',
              style: context.theme.typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceXs),
            Expanded(
              child: DesyPrototypeWidgetTree(
                key: ValueKey(_selectedPrototype.id),
                prototypeId: _selectedPrototype.id,
                scopeKey: _scopeKeyFor(_selectedPrototype),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PrototypeCard extends StatelessWidget {
  const _PrototypeCard({
    required this.prototype,
    required this.theme,
    required this.scopeKey,
    required this.selected,
    required this.onSelect,
  });

  final DesyPrototype prototype;
  final DesyTheme theme;
  final GlobalKey scopeKey;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 380,
    child: Semantics(
      button: true,
      selected: selected,
      label: selected
          ? '${prototype.name}, selected prototype'
          : 'Select ${prototype.name} prototype',
      child: GestureDetector(
        key: ValueKey('prototype-card-${prototype.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? context.theme.colors.desy.signal
                  : context.theme.colors.border,
              width: selected ? 2 : DesyDesignSystemTokens.hairline,
            ),
            borderRadius: BorderRadius.circular(
              DesyDesignSystemTokens.radiusMd,
            ),
          ),
          child: DesyCard(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesyDesignSystemTokens.spaceMd,
                    DesyDesignSystemTokens.spaceMd,
                    DesyDesignSystemTokens.spaceMd,
                    DesyDesignSystemTokens.spaceSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prototype.name,
                        style: context.theme.typography.body.md,
                      ),
                      if (prototype.description case final description?) ...[
                        const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.theme.typography.body.xs.copyWith(
                            color: context.theme.colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    color:
                        theme.previewBackgroundColor ??
                        context.theme.colors.background,
                    child: ClipRect(
                      child: Center(
                        child: DesyWidgetPreview(
                          theme: theme,
                          builder: (previewContext) => DesyFittedPreview(
                            child: DesyWorkbenchInspectionScope(
                              key: scopeKey,
                              context: DesyWorkbenchInspectionContext(
                                artifactId: prototype.id,
                                kind: 'Prototype',
                                label: prototype.name,
                              ),
                              child: Builder(builder: prototype.builder),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ColoredBox(
                  color: context.theme.colors.border,
                  child: const SizedBox(
                    height: DesyDesignSystemTokens.hairline,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
                  child: Text(
                    prototype.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _EmptyPrototypes extends StatelessWidget {
  const _EmptyPrototypes();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'This prototype session has no directions yet.',
      style: context.theme.typography.body.sm.copyWith(
        color: context.theme.colors.mutedForeground,
      ),
    ),
  );
}
