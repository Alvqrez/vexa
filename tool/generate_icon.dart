// Run with: dart run tool/generate_icon.dart
// Generates assets/icon/icon.png — the Vexa checkmark logo (1024×1024)
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

void main() async {
  const size = 1024;
  final pixels = Uint8List(size * size * 4);

  // Corner radius: 23% of size (iOS style)
  const r = size * 0.23;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final idx = (y * size + x) * 4;
      if (_inRoundedRect(x, y, size, r)) {
        // Black background
        pixels[idx] = 9;
        pixels[idx + 1] = 9;
        pixels[idx + 2] = 15;
        pixels[idx + 3] = 255;
      } else {
        pixels[idx] = 0;
        pixels[idx + 1] = 0;
        pixels[idx + 2] = 0;
        pixels[idx + 3] = 0;
      }
    }
  }

  // Draw checkmark
  final strokeWidth = size * 0.072;
  final p1 = (x: size * 0.22, y: size * 0.52);
  final p2 = (x: size * 0.44, y: size * 0.72);
  final p3 = (x: size * 0.78, y: size * 0.28);

  _drawLine(pixels, size, p1.x, p1.y, p2.x, p2.y, strokeWidth);
  _drawLine(pixels, size, p2.x, p2.y, p3.x, p3.y, strokeWidth);

  final png = _encodePng(pixels, size, size);
  final outDir = Directory('assets/icon');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  File('assets/icon/icon.png').writeAsBytesSync(png);
  File('assets/icon/icon_foreground.png').writeAsBytesSync(png);
  stdout.writeln('✓ assets/icon/icon.png generated (${size}x$size)');
}

bool _inRoundedRect(int x, int y, int size, double r) {
  final dx = x.toDouble();
  final dy = y.toDouble();
  // Distance from each corner
  if (dx < r && dy < r) return _dist(dx, dy, r, r) <= r;
  if (dx > size - r && dy < r) return _dist(dx, dy, size - r, r) <= r;
  if (dx < r && dy > size - r) return _dist(dx, dy, r, size - r) <= r;
  if (dx > size - r && dy > size - r) {
    return _dist(dx, dy, size - r, size - r) <= r;
  }
  return true;
}

double _dist(double x1, double y1, double x2, double y2) {
  final dx = x1 - x2;
  final dy = y1 - y2;
  return math.sqrt(dx * dx + dy * dy);
}

void _drawLine(
  Uint8List pixels,
  int size,
  double x1,
  double y1,
  double x2,
  double y2,
  double width,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  final len = math.sqrt(dx * dx + dy * dy);
  final steps = (len * 2).ceil();

  for (int i = 0; i <= steps; i++) {
    final t = i / steps;
    final cx = x1 + dx * t;
    final cy = y1 + dy * t;
    _drawCircle(pixels, size, cx, cy, width / 2);
  }
}

void _drawCircle(Uint8List pixels, int size, double cx, double cy, double r) {
  final x0 = (cx - r).floor().clamp(0, size - 1);
  final x1 = (cx + r).ceil().clamp(0, size - 1);
  final y0 = (cy - r).floor().clamp(0, size - 1);
  final y1 = (cy + r).ceil().clamp(0, size - 1);

  for (int y = y0; y <= y1; y++) {
    for (int x = x0; x <= x1; x++) {
      final d = _dist(x.toDouble(), y.toDouble(), cx, cy);
      if (d <= r) {
        final idx = (y * size + x) * 4;
        // Anti-alias at edge
        final alpha = d > r - 1.5 ? ((r - d) / 1.5).clamp(0.0, 1.0) : 1.0;
        final existing = pixels[idx + 3] / 255.0;
        final combined = 1.0 - (1.0 - alpha) * (1.0 - existing);
        if (combined > existing) {
          final blend = combined > 0
              ? (existing * (existing / combined) +
                      alpha * (alpha / combined) * (1.0 - existing))
                  .clamp(0.0, 1.0)
              : 0.0;
          pixels[idx] = (255 * (blend < 0.5 ? blend * 2 : 1.0)).round();
          pixels[idx + 1] = (255 * (blend < 0.5 ? blend * 2 : 1.0)).round();
          pixels[idx + 2] = (255 * (blend < 0.5 ? blend * 2 : 1.0)).round();
          pixels[idx + 3] = (combined * 255).round();
        }
      }
    }
  }
}

Uint8List _encodePng(Uint8List pixels, int width, int height) {
  // Minimal PNG encoder (RGBA, unfiltered)
  final raw = <int>[];
  // PNG signature
  raw.addAll([137, 80, 78, 71, 13, 10, 26, 10]);
  // IHDR
  _addChunk(raw, 'IHDR', [
    ..._int32(width),
    ..._int32(height),
    8, // bit depth
    6, // colour type: RGBA
    0, 0, 0, // compression, filter, interlace
  ]);
  // IDAT
  final scanlines = <int>[];
  for (int y = 0; y < height; y++) {
    scanlines.add(0); // filter: None
    for (int x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      scanlines.addAll([pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3]]);
    }
  }
  _addChunk(raw, 'IDAT', _deflate(Uint8List.fromList(scanlines)));
  // IEND
  _addChunk(raw, 'IEND', []);
  return Uint8List.fromList(raw);
}

void _addChunk(List<int> out, String type, List<int> data) {
  out.addAll(_int32(data.length));
  final typeBytes = type.codeUnits;
  out.addAll(typeBytes);
  out.addAll(data);
  var crc = _crc32(typeBytes + data);
  out.addAll(_int32(crc));
}

List<int> _int32(int v) => [
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ];

List<int> _deflate(Uint8List data) {
  // zlib wrapping of uncompressed deflate blocks
  final out = <int>[];
  out.addAll([0x78, 0x01]); // zlib header: deflate, default compression
  int offset = 0;
  while (offset < data.length) {
    final blockSize = math.min(65535, data.length - offset);
    final isLast = offset + blockSize >= data.length;
    out.add(isLast ? 1 : 0); // BFINAL | BTYPE=00 (uncompressed)
    out.add(blockSize & 0xFF);
    out.add((blockSize >> 8) & 0xFF);
    out.add((~blockSize) & 0xFF);
    out.add(((~blockSize) >> 8) & 0xFF);
    out.addAll(data.sublist(offset, offset + blockSize));
    offset += blockSize;
  }
  // Adler-32 checksum
  int s1 = 1, s2 = 0;
  for (final b in data) {
    s1 = (s1 + b) % 65521;
    s2 = (s2 + s1) % 65521;
  }
  out.addAll(_int32((s2 << 16) | s1));
  return out;
}

int _crc32(List<int> data) {
  const poly = 0xEDB88320;
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ poly : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
