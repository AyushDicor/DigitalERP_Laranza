// Builds the two square source images that flutter_launcher_icons needs from
// the brand mark (assets/images/logo_new.png, which is 268x322 and transparent).
//
//   assets/icons/app_icon_foreground.png  transparent, mark full-bleed
//                                         -> adaptive foreground (the
//                                            adaptive_icon_foreground_inset in
//                                            pubspec.yaml does the safe-zone
//                                            shrink, so do NOT pad it here)
//   assets/icons/app_icon.png             white plate, mark at 72%
//                                         -> legacy Android icon + iOS
//
// Run from the project root:  dart run tool/make_launcher_icon.dart
// then:                       dart run flutter_launcher_icons

import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'assets/images/logo_new.png';
const _outDir = 'assets/icons';
const _canvas = 1024;

/// Fraction of the canvas the mark covers on the white plate.
const _plateFill = 0.72;

void main() {
  final raw = img.decodePng(File(_source).readAsBytesSync());
  if (raw == null) {
    stderr.writeln('Could not decode $_source');
    exit(1);
  }

  // Drop any transparent margin baked into the asset so the sizing below is
  // measured against the mark itself, not the artboard.
  final mark = img.trim(raw, mode: img.TrimMode.transparent);
  stdout.writeln('source ${raw.width}x${raw.height} -> trimmed '
      '${mark.width}x${mark.height}');

  Directory(_outDir).createSync(recursive: true);

  _write('$_outDir/app_icon_foreground.png', _place(mark, 1.0, null));
  _write('$_outDir/app_icon.png',
      _place(mark, _plateFill, img.ColorRgba8(255, 255, 255, 255)));
}

/// Scales [mark] to cover [fill] of a square canvas, preserving aspect ratio,
/// and centres it on [background] (transparent when null).
img.Image _place(img.Image mark, double fill, img.Color? background) {
  final target = (_canvas * fill).round();
  final scale = target / (mark.width > mark.height ? mark.width : mark.height);

  final resized = img.copyResize(
    mark,
    width: (mark.width * scale).round(),
    height: (mark.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: _canvas, height: _canvas, numChannels: 4);
  if (background != null) {
    img.fill(canvas, color: background);
  }

  return img.compositeImage(
    canvas,
    resized,
    dstX: (_canvas - resized.width) ~/ 2,
    dstY: (_canvas - resized.height) ~/ 2,
  );
}

void _write(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path (${image.width}x${image.height})');
}
