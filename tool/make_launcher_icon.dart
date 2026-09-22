// Builds the square source images that flutter_launcher_icons needs from the
// Laranza wordmark (tool/brand/laranza_logo_1067x275.png — a wide 3.9:1
// "LARANZA / GERMAN TECH" lockup on an OPAQUE white background).
//
// The source is kept under tool/ so it is not bundled and is never one of the
// files this tool overwrites.
//
//   assets/icons/app_icon_foreground.png  transparent, wordmark full-bleed
//                                         -> adaptive foreground. The
//                                            adaptive_icon_foreground_inset in
//                                            pubspec.yaml shrinks it into the
//                                            66/108 safe zone, so do NOT pad
//                                            it here.
//   assets/icons/app_icon.png             white plate, wordmark at 72% width
//                                         -> legacy Android icon + iOS
//   android/playstore-icon.png            512x512 white plate for the Play
//                                         Console listing (never masked)
//
// Run from the project root:  dart run tool/make_launcher_icon.dart
// then:                       dart run flutter_launcher_icons

import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'tool/brand/laranza_logo_1067x275.png';
const _outDir = 'assets/icons';
const _canvas = 1024;

/// Fraction of the canvas the wordmark spans on the white plate.
const _plateFill = 0.72;

void main() {
  final raw = img.decodeImage(File(_source).readAsBytesSync());
  if (raw == null) {
    stderr.writeln('Could not decode $_source');
    exit(1);
  }

  // The wordmark sits on flat white, so lift it off: a pixel's opacity is how
  // far it is from white (alpha = 255 - min(r,g,b)), and its colour is then
  // un-premultiplied against white. Black stays black, the red R stays red,
  // anti-aliased edges become soft transparent edges, and white becomes clear.
  final keyed = _keyOutWhite(raw);
  final mark = img.trim(keyed, mode: img.TrimMode.transparent);
  stdout.writeln('source ${raw.width}x${raw.height} -> trimmed '
      '${mark.width}x${mark.height}');

  Directory(_outDir).createSync(recursive: true);

  _write('$_outDir/app_icon_foreground.png', _place(mark, 1.0, null, _canvas));
  final plate = _place(mark, _plateFill, img.ColorRgba8(255, 255, 255, 255), _canvas);
  _write('$_outDir/app_icon.png', plate);
  _write('android/playstore-icon.png',
      img.copyResize(plate, width: 512, height: 512, interpolation: img.Interpolation.cubic));
}

img.Image _keyOutWhite(img.Image src) {
  final out = img.Image(width: src.width, height: src.height, numChannels: 4);
  for (final p in src) {
    final r = p.r.toInt(), g = p.g.toInt(), b = p.b.toInt();
    final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
    var a = 255 - minC;
    if (a < 6) a = 0; // JPEG-ish noise in the white field
    if (a == 0) {
      out.setPixelRgba(p.x, p.y, 0, 0, 0, 0);
      continue;
    }
    final f = 255 / a;
    int un(int c) => ((c - (255 - a)) * f).round().clamp(0, 255);
    out.setPixelRgba(p.x, p.y, un(r), un(g), un(b), a);
  }
  return out;
}

/// Scales [mark] so its longer side covers [fill] of a square [size] canvas,
/// preserving aspect ratio, and centres it on [background] (transparent when
/// null).
img.Image _place(img.Image mark, double fill, img.Color? background, int size) {
  final target = (size * fill).round();
  final scale = target / (mark.width > mark.height ? mark.width : mark.height);

  final resized = img.copyResize(
    mark,
    width: (mark.width * scale).round(),
    height: (mark.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: size, height: size, numChannels: 4);
  if (background != null) {
    img.fill(canvas, color: background);
  }

  return img.compositeImage(
    canvas,
    resized,
    dstX: (size - resized.width) ~/ 2,
    dstY: (size - resized.height) ~/ 2,
  );
}

void _write(String path, img.Image image) {
  File(path).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path (${image.width}x${image.height})');
}
