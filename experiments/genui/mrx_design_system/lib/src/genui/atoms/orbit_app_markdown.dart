// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppMarkdown extends StatelessWidget {
  const OrbitAppMarkdown({super.key, required this.markdown, this.maxDepth});

  final String markdown;
  final int? maxDepth;

  @override
  Widget build(BuildContext context) {
    final blocks = markdown.replaceAll('\r\n', '\n').split('\n\n');
    return OrbitAppStack(
      gap: OrbitTokens.spaceSm,
      children: [
        for (final block in blocks)
          if (block.trim().isNotEmpty)
            _MarkdownBlock(block: block, maxDepth: maxDepth),
      ],
    );
  }
}

class _MarkdownBlock extends StatelessWidget {
  const _MarkdownBlock({required this.block, this.maxDepth});

  final String block;
  final int? maxDepth;

  @override
  Widget build(BuildContext context) {
    final trimmed = block.trim();
    if (trimmed.startsWith('```') && trimmed.endsWith('```')) {
      final lines = trimmed.split('\n');
      return OrbitAppCode(
        code: lines.skip(1).take(lines.length - 2).join('\n'),
        language: lines.first.substring(3).trim(),
      );
    }
    final heading = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
    if (heading != null) {
      final depth = heading.group(1)!.length;
      return OrbitAppText(
        heading.group(2)!,
        role: depth == 1 && (maxDepth == null || depth <= maxDepth!)
            ? OrbitTextRole.titleLarge
            : OrbitTextRole.heading,
      );
    }
    if (trimmed.startsWith('>')) {
      return OrbitSurface(
        tone: OrbitSurfaceTone.muted,
        padding: const EdgeInsets.all(OrbitTokens.spaceMd),
        child: OrbitAppText(
          trimmed.substring(1).trim(),
          role: OrbitTextRole.bodySecondary,
        ),
      );
    }
    final lines = trimmed.split('\n');
    if (lines.length >= 2 && _isMarkdownTableSeparator(lines[1])) {
      final header = _markdownCells(lines.first);
      final rows = [
        for (final line in lines.skip(2))
          if (line.contains('|')) _markdownCells(line),
      ];
      return OrbitAppScrollView(
        horizontal: true,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              children: [
                for (final cell in header)
                  Padding(
                    padding: const EdgeInsets.all(OrbitTokens.spaceSm),
                    child: OrbitAppText(cell, role: OrbitTextRole.label),
                  ),
              ],
            ),
            for (final row in rows)
              TableRow(
                children: [
                  for (var index = 0; index < header.length; index++)
                    Padding(
                      padding: const EdgeInsets.all(OrbitTokens.spaceSm),
                      child: OrbitAppText(
                        index < row.length ? row[index] : '—',
                        role: OrbitTextRole.body,
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    }
    if (lines.every((line) => RegExp(r'^[-*]\s+').hasMatch(line))) {
      return OrbitAppStack(
        gap: OrbitTokens.spaceXs,
        children: [
          for (final line in lines)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OrbitAppText('•', role: OrbitTextRole.body),
                const SizedBox(width: OrbitTokens.spaceSm),
                Expanded(child: _InlineMarkdown(line.substring(2))),
              ],
            ),
        ],
      );
    }
    return _InlineMarkdown(trimmed);
  }
}

bool _isMarkdownTableSeparator(String value) => RegExp(
  r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$',
).hasMatch(value);

List<String> _markdownCells(String value) => value
    .trim()
    .replaceFirst(RegExp(r'^\|'), '')
    .replaceFirst(RegExp(r'\|$'), '')
    .split('|')
    .map((cell) => cell.trim())
    .toList(growable: false);

class _InlineMarkdown extends StatelessWidget {
  const _InlineMarkdown(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final expression = RegExp(r'(\*\*.+?\*\*|`.+?`|\[.+?\]\(.+?\))');
    var offset = 0;
    for (final match in expression.allMatches(value)) {
      if (match.start > offset) {
        spans.add(TextSpan(text: value.substring(offset, match.start)));
      }
      final token = match.group(0)!;
      if (token.startsWith('**')) {
        spans.add(
          TextSpan(
            text: token.substring(2, token.length - 2),
            style: OrbitType.body(
              context,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        );
      } else if (token.startsWith('`')) {
        spans.add(
          TextSpan(
            text: token.substring(1, token.length - 1),
            style: _textStyle(context, OrbitTextRole.code),
          ),
        );
      } else {
        final link = RegExp(r'^\[(.+)\]\((.+)\)$').firstMatch(token)!;
        spans.add(
          TextSpan(
            text: link.group(1),
            style: OrbitType.body(context).copyWith(
              color: OrbitTheme.of(context).colors.info,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      }
      offset = match.end;
    }
    if (offset < value.length) {
      spans.add(TextSpan(text: value.substring(offset)));
    }
    return RichText(
      text: TextSpan(style: OrbitType.body(context), children: spans),
    );
  }
}
