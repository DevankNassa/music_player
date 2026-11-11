import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../theme/organic.dart';
import '../widgets/disc.dart';

/// Renders the app's record disc to a PNG for the media notification /
/// lock screen. Android 13+ draws the media card itself and tints it from
/// the artwork, so this is what gives the card the Organic look.
///
/// Rendered once and cached on disk; returns null if that fails, in which
/// case the notification just has no artwork.
Future<Uri?> discArtworkUri() async {
  try {
    final dir = await getApplicationSupportDirectory();
    // Bump the version when the artwork changes so stale files aren't reused.
    final file = File(p.join(dir.path, 'notification_disc_v1.png'));
    if (!file.existsSync()) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(await _renderPng(512));
    }
    return file.uri;
  } catch (_) {
    return null;
  }
}

Future<List<int>> _renderPng(int size) async {
  // The system draws this card itself, so it keeps the light palette's
  // colours whatever theme the app is in.
  const c = OrganicColors.light;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final full = ui.Size.square(size.toDouble());
  // Opaque brown ground (the card colour in mock 4b) so the system's colour
  // extraction lands on it rather than on a transparent edge.
  canvas.drawRect(ui.Offset.zero & full, ui.Paint()..color = c.accent800);
  // Disc at ~70% with one groove band and a brown hole, as in the mock.
  final inset = size * 0.15;
  canvas.translate(inset, inset);
  DiscPainter(
    bands: [(1, c.accent2_400), (20 / 32, c.accent2_300)],
    holeFraction: 8 / 32,
    holeColor: c.accent800,
  ).paint(canvas, ui.Size.square(size - 2 * inset));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}
