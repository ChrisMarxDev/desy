/// A finite, controller-driven canvas for arranging arbitrary Flutter widgets.
///
/// The library owns selection, gestures, snapping, transform handles, camera
/// control, z-order, undo and redo. Applications retain ownership of object
/// data and decide how each [CanvasObject] is rendered.
///
/// Create an [ObjectCanvasController], populate it with typed objects, and pass
/// that controller to an [ObjectCanvas]:
///
/// ```dart
/// final controller = ObjectCanvasController<MyElement>(
///   canvasSize: const Size(1200, 630),
/// );
///
/// controller.addObjects([
///   CanvasObject(
///     id: 'hero',
///     data: const MyElement(),
///     geometry: const CanvasObjectGeometry(
///       position: Offset(80, 64),
///       size: Size(640, 360),
///     ),
///   ),
/// ]);
///
/// ObjectCanvas<MyElement>(
///   controller: controller,
///   objectBuilder: (context, object) => buildElement(object.data),
/// );
/// ```
library;

export 'src/actions/canvas_action.dart';
export 'src/controller/object_canvas_controller.dart';
export 'src/model/canvas_object.dart';
export 'src/model/canvas_policy.dart';
export 'src/snapping/canvas_snap.dart';
export 'src/widgets/object_canvas.dart';
