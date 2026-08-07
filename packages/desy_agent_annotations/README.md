# Desy Agent Annotations

An optional `DesyDetailExtension` that collects a comment while a registry
entry is open and hands one immutable, entry-scoped submission to the consuming
application:

```dart
DesyAgentAnnotationsExtension(
  onSubmit: (annotation) async {
    final result = await myServerSideIssueFunction(annotation);
    return DesyAgentAnnotationReceipt(
      message: 'Created GitHub issue ${result.number}.',
      location: result.url,
    );
  },
)
```

The package has no persistence, GitHub client, token, backend, or platform IO.
The callback host decides whether to write a repository file or call an
authenticated server-side issue function.

The composer keeps plain Enter available for multiline comments. Command+Enter
and Control+Enter submit through the same blank and single-flight guards as the
button. Callback failures are reported through Flutter diagnostics while the
visible UI shows a bounded retry message and retains the draft; raw exception
text is never rendered.
