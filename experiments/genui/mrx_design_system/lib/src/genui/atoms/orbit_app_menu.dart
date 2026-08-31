// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppMenu extends StatefulWidget {
  const OrbitAppMenu({super.key, required this.label, required this.items});
  final String label;
  final List<OrbitMenuItem> items;
  @override
  State<OrbitAppMenu> createState() => _OrbitAppMenuState();
}

class _OrbitAppMenuState extends State<OrbitAppMenu> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final duration = OrbitMotion.standard(context);
    return OrbitAppStack(
      gap: OrbitTokens.spaceXs,
      children: [
        OrbitAppIconButton(
          label: widget.label,
          icon: 'more',
          onPressed: () => setState(() => _open = !_open),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: duration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            heightFactor: _open ? 1 : 0,
            child: IgnorePointer(
              ignoring: !_open,
              child: ExcludeSemantics(
                excluding: !_open,
                child: AnimatedOpacity(
                  duration: duration,
                  curve: Curves.easeOut,
                  opacity: _open ? 1 : 0,
                  child: OrbitSurface(
                    tone: OrbitSurfaceTone.raised,
                    padding: const EdgeInsets.all(OrbitTokens.spaceXs),
                    child: OrbitAppStack(
                      gap: OrbitTokens.space2xs,
                      children: [
                        for (final item in widget.items)
                          OrbitAppButton(
                            label: item.label,
                            intent: item.destructive
                                ? OrbitActionIntent.destructive
                                : OrbitActionIntent.tertiary,
                            expand: true,
                            onPressed: item.onPressed == null
                                ? null
                                : () {
                                    setState(() => _open = false);
                                    item.onPressed!();
                                  },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
