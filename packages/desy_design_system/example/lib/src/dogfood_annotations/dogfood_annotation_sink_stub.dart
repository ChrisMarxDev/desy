import 'package:desy_agent_annotations/desy_agent_annotations.dart';

/// Creates the non-macOS dogfood callback.
DesyAgentAnnotationSubmit createDesyDogfoodAnnotationSubmit() {
  return (annotation) async => DesyAgentAnnotationReceipt(
    message: 'Captured a dogfood annotation for ${annotation.componentName}.',
  );
}
