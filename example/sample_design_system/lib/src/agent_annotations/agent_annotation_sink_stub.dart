import 'package:desy_agent_annotations/desy_agent_annotations.dart';

import 'hosted_github_issue_sink.dart';

/// The checked-in web sample intentionally contains no repository credential.
/// A hosted deployment replaces this callback with its authenticated function.
DesyAgentAnnotationSubmit createSampleAgentAnnotationSubmit() =>
    createUnconfiguredHostedGitHubIssueSubmit();
