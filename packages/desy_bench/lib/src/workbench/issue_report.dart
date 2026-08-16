import 'package:flutter/foundation.dart';

/// Runtime context included in a user-reviewed Desy issue report.
@immutable
class DesyIssueReportContext {
  /// Creates the environment summary for a report.
  const DesyIssueReportContext({
    required this.registryName,
    required this.themeName,
    required this.themeId,
    required this.route,
    required this.platform,
  });

  /// The active consumer registry.
  final String registryName;

  /// The visible name of the active preview theme.
  final String themeName;

  /// The stable ID of the active preview theme.
  final String themeId;

  /// The current workbench route.
  final String route;

  /// The Flutter platform on which the report was started.
  final String platform;
}

/// Builds the GitHub composer URL without submitting an issue.
Uri buildDesyIssueReportUri(DesyIssueReportContext report) =>
    Uri.https('github.com', '/ChrisMarxDev/desy/issues/new', {
      'title': '[Desy] ',
      'body':
          '''
<!-- Thanks for taking the time to report an issue. -->

## What happened?

<!-- Describe the problem and the steps that led to it. -->

## What did you expect?

<!-- Tell us what you expected Desy to do instead. -->

## Additional context

<!-- Add anything else that could help us reproduce the issue. -->

## Desy environment

- Registry: `${_inlineMarkdown(report.registryName)}`
- Theme: `${_inlineMarkdown(report.themeName)}` (`${_inlineMarkdown(report.themeId)}`)
- Page: `${_inlineMarkdown(report.route)}`
- Platform: `${_inlineMarkdown(report.platform)}`
''',
    });

String _inlineMarkdown(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').replaceAll('`', "'").trim();
