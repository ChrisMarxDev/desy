import 'package:desy_bench/src/workbench/issue_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a reviewable GitHub issue with workbench context', () {
    final uri = buildDesyIssueReportUri(
      const DesyIssueReportContext(
        registryName: 'Example system',
        themeName: 'Dark',
        themeId: 'dark',
        route: '/components/buttons/primary',
        platform: 'macOS',
      ),
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'github.com');
    expect(uri.path, '/ChrisMarxDev/desy/issues/new');
    expect(uri.queryParameters['title'], '[Desy] ');
    expect(
      uri.queryParameters['body'],
      allOf(
        contains('## What happened?'),
        contains('## What did you expect?'),
        contains('- Registry: `Example system`'),
        contains('- Theme: `Dark` (`dark`)'),
        contains('- Page: `/components/buttons/primary`'),
        contains('- Platform: `macOS`'),
      ),
    );
  });

  test('keeps consumer names on one safe Markdown line', () {
    final uri = buildDesyIssueReportUri(
      const DesyIssueReportContext(
        registryName: 'System\nwith `ticks`',
        themeName: 'Theme',
        themeId: 'theme',
        route: '/',
        platform: 'web',
      ),
    );

    expect(
      uri.queryParameters['body'],
      contains("- Registry: `System with 'ticks'`"),
    );
  });
}
