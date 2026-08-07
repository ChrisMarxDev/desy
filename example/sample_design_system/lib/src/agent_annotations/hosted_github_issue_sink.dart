import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:flutter/foundation.dart';

/// A deployment-owned, authenticated server function that creates an issue.
typedef DesyHostedGitHubIssueFunction =
    Future<DesyHostedGitHubIssue> Function(DesyAgentAnnotation annotation);

/// Typed result returned by the hosted deployment's server-side function.
@immutable
final class DesyHostedGitHubIssue {
  /// Creates a hosted issue result.
  const DesyHostedGitHubIssue({required this.location, this.message});

  /// Browser-safe public issue URL returned by the server.
  final Uri location;

  /// Optional deployment-specific confirmation.
  final String? message;
}

/// Adapts a server-authenticated GitHub issue function to the extension seam.
///
/// Authentication, repository configuration, labels, and rate limiting remain
/// on the server; this browser-side adapter receives only the public result.
DesyAgentAnnotationSubmit createHostedGitHubIssueSubmit({
  required DesyHostedGitHubIssueFunction createIssue,
}) {
  return (annotation) async {
    final issue = await createIssue(annotation);
    return DesyAgentAnnotationReceipt(
      message: issue.message ?? 'Created a GitHub issue.',
      location: issue.location,
    );
  };
}

/// Safe default for the checked-in sample, which has no hosted function.
DesyAgentAnnotationSubmit createUnconfiguredHostedGitHubIssueSubmit() {
  return (annotation) => Future.error(
    StateError(
      'Configure an authenticated server-side GitHub issue function for this hosted deployment.',
    ),
  );
}
