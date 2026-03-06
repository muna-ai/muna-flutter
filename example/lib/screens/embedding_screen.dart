import "dart:math" as math;
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:muna/muna.dart";

class _SeedText {
  final String text;
  final String topic;
  const _SeedText(this.text, this.topic);
}

const _seeds = [
  _SeedText("Saturn's rings are made of ice and rock", "Space"),
  _SeedText("The Milky Way contains billions of stars", "Space"),
  _SeedText("Astronauts float in zero gravity", "Space"),
  _SeedText("Dolphins communicate with clicks and whistles", "Animals"),
  _SeedText("Eagles can spot prey from two miles away", "Animals"),
  _SeedText("Honeybees perform waggle dances to share locations", "Animals"),
  _SeedText("Sourdough bread requires a fermented starter", "Food"),
  _SeedText("Sushi originated in Southeast Asia as preserved fish", "Food"),
  _SeedText("Dark chocolate contains powerful antioxidants", "Food"),
  _SeedText("Neural networks learn by adjusting connection weights", "Technology"),
  _SeedText("Quantum computers use qubits instead of classical bits", "Technology"),
  _SeedText("Smartphones have more power than early space computers", "Technology"),
];

const _topicColors = {
  "Space": Colors.indigo,
  "Animals": Colors.teal,
  "Food": Colors.orange,
  "Technology": Colors.pink,
  "User": Colors.deepPurple,
};

/// A 3D point with its display metadata.
class _Point3D {
  final double x, y, z;
  final String label;
  final Color color;
  final bool isUser;
  const _Point3D(this.x, this.y, this.z, this.label, this.color, this.isUser);
}

class EmbeddingScreen extends StatefulWidget {
  const EmbeddingScreen({super.key});

  @override
  State<EmbeddingScreen> createState() => _EmbeddingScreenState();
}

class _EmbeddingScreenState extends State<EmbeddingScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late final Muna _muna;
  late final Ticker _ticker;
  bool _loading = false;
  String _status = "";
  final List<String> _texts = [];
  final List<String> _topics = [];
  final List<List<double>> _embeddings = [];
  List<_Point3D> _points3D = [];
  int _seedCount = 0;

  // Camera angles (radians)
  double _rotY = 0.4;
  double _rotX = 0.3;
  // Angular velocity (radians per second)
  double _velY = 0.4; // initial gentle spin
  double _velX = 0.0;
  bool _dragging = false;
  Duration _lastTick = Duration.zero;
  static const _friction = 0.97; // per-frame decay
  // Zoom (pinch)
  double _zoom = 1.0;
  double _zoomStart = 1.0;
  // Pulse highlight for newest user point
  int _pulseIndex = -1;
  double _pulseTime = 0.0; // seconds since pulse started
  static const _pulseDuration = 3.0;

  @override
  void initState() {
    super.initState();
    _muna = Muna();
    _ticker = createTicker(_onTick)..start();
    _embedSeeds();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 1.0 / 60.0
        : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    // Advance pulse
    bool needsRepaint = false;
    if (_pulseIndex >= 0) {
      _pulseTime += dt;
      if (_pulseTime >= _pulseDuration) {
        _pulseIndex = -1;
        _pulseTime = 0.0;
      }
      needsRepaint = true;
    }
    if (!_dragging) {
      _rotY += _velY * dt;
      _rotX = (_rotX + _velX * dt).clamp(-math.pi / 2, math.pi / 2);
      _velY *= _friction;
      _velX *= _friction;
      if (_velY.abs() > 0.001 || _velX.abs() > 0.001) {
        needsRepaint = true;
      }
    }
    if (needsRepaint) setState(() {});
  }

  @override
  void dispose() {
    _textController.dispose();
    _ticker.dispose();
    super.dispose();
  }

  void _reproject() {
    final raw = _pca3D(_embeddings);
    _points3D = List.generate(raw.length, (i) {
      final p = raw[i];
      return _Point3D(
        p[0],
        p[1],
        p[2],
        _texts[i],
        _topicColors[_topics[i]] ?? Colors.grey,
        i >= _seedCount,
      );
    });
  }

  Future<void> _embedSeeds() async {
    setState(() {
      _loading = true;
      _status = "Loading embedding model...";
    });
    try {
      final texts = _seeds.map((s) => s.text).toList();
      final response = await _muna.beta.openai.embeddings.create(
        input: texts,
        model: "@google/embedding-gemma",
      );
      _texts.addAll(texts);
      _topics.addAll(_seeds.map((s) => s.topic));
      for (final e in response.data) {
        _embeddings.add((e.embedding as List).cast<double>());
      }
      _seedCount = _seeds.length;
      _reproject();
      setState(() => _status = "${_texts.length} points");
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onEmbed() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {
      _loading = true;
      _status = "Embedding...";
    });
    try {
      final response = await _muna.beta.openai.embeddings.create(
        input: text,
        model: "@google/embedding-gemma",
      );
      final embedding = (response.data[0].embedding as List).cast<double>();
      _texts.add(text);
      _topics.add("User");
      _embeddings.add(embedding);
      _reproject();
      _pulseIndex = _texts.length - 1;
      _pulseTime = 0.0;
      setState(() => _status = "${_texts.length} points");
    } catch (e) {
      setState(() => _status = "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Embedding Space"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _points3D.isEmpty
                ? Center(
                    child: _loading
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                _status,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _status,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  )
                : GestureDetector(
                    onScaleStart: (details) {
                      _dragging = true;
                      _velY = 0;
                      _velX = 0;
                      _zoomStart = _zoom;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        // Rotation from focal point delta
                        _rotY += details.focalPointDelta.dx * 0.01;
                        _rotX = (_rotX + details.focalPointDelta.dy * 0.01)
                            .clamp(-math.pi / 2, math.pi / 2);
                        // Pinch zoom
                        _zoom = (_zoomStart * details.scale)
                            .clamp(0.3, 5.0);
                      });
                    },
                    onScaleEnd: (details) {
                      _dragging = false;
                      // Convert pixel velocity to angular velocity
                      _velY = details.velocity.pixelsPerSecond.dx * 0.003;
                      _velX = details.velocity.pixelsPerSecond.dy * 0.003;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) => CustomPaint(
                        size: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        painter: _EmbeddingPainter(
                          points: _points3D,
                          rotY: _rotY,
                          rotX: _rotX,
                          zoom: _zoom,
                          gridColor: colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                          axisColor: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          bgColor: colorScheme.surfaceContainerLowest,
                          pulseIndex: _pulseIndex,
                          pulsePhase: _pulseIndex >= 0
                              ? _pulseTime / _pulseDuration
                              : 0.0,
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: _topicColors.entries
                  .map(
                    (e) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: e.value,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(e.key, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_status.isNotEmpty && _points3D.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                "$_status · drag to rotate",
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _onEmbed(),
                      decoration: InputDecoration(
                        hintText: "Enter text to embed...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _onEmbed,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.scatter_plot),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PCA: extract top 3 components via power iteration
// ---------------------------------------------------------------------------

List<List<double>> _pca3D(List<List<double>> vectors) {
  final n = vectors.length;
  if (n < 2) return vectors.map((_) => [0.0, 0.0, 0.0]).toList();
  final d = vectors[0].length;
  // Center
  final mean = List.filled(d, 0.0);
  for (final v in vectors) {
    for (var j = 0; j < d; j++) mean[j] += v[j];
  }
  for (var j = 0; j < d; j++) mean[j] /= n;
  final centered =
      vectors.map((v) => List.generate(d, (j) => v[j] - mean[j])).toList();
  // Power iteration
  List<double> powerIter(List<List<double>>? deflateVecs) {
    var w = List.generate(d, (i) => math.sin(i * 1.7 + 0.3));
    for (var iter = 0; iter < 100; iter++) {
      final proj = centered.map((row) {
        var dot = 0.0;
        for (var j = 0; j < d; j++) dot += row[j] * w[j];
        return dot;
      }).toList();
      final wNew = List.filled(d, 0.0);
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < d; j++) wNew[j] += centered[i][j] * proj[i];
      }
      // Deflate against all previous eigenvectors
      if (deflateVecs != null) {
        for (final dv in deflateVecs) {
          var dot = 0.0;
          for (var j = 0; j < d; j++) dot += wNew[j] * dv[j];
          for (var j = 0; j < d; j++) wNew[j] -= dot * dv[j];
        }
      }
      var norm = 0.0;
      for (var j = 0; j < d; j++) norm += wNew[j] * wNew[j];
      norm = math.sqrt(norm);
      if (norm < 1e-10) break;
      for (var j = 0; j < d; j++) wNew[j] /= norm;
      w = wNew;
    }
    return w;
  }

  final pc1 = powerIter(null);
  final pc2 = powerIter([pc1]);
  final pc3 = powerIter([pc1, pc2]);
  // Project and normalize each axis to [-1, 1]
  final raw = centered.map((row) {
    var x = 0.0, y = 0.0, z = 0.0;
    for (var j = 0; j < d; j++) {
      x += row[j] * pc1[j];
      y += row[j] * pc2[j];
      z += row[j] * pc3[j];
    }
    return [x, y, z];
  }).toList();
  // Find ranges
  var mins = [raw[0][0], raw[0][1], raw[0][2]];
  var maxs = [raw[0][0], raw[0][1], raw[0][2]];
  for (final p in raw) {
    for (var a = 0; a < 3; a++) {
      if (p[a] < mins[a]) mins[a] = p[a];
      if (p[a] > maxs[a]) maxs[a] = p[a];
    }
  }
  // Normalize to [-1, 1]
  return raw.map((p) {
    return List.generate(3, (a) {
      final range = maxs[a] - mins[a];
      return range == 0 ? 0.0 : (p[a] - mins[a]) / range * 2.0 - 1.0;
    });
  }).toList();
}

// ---------------------------------------------------------------------------
// 3D painter with axes, grid, depth sorting, glow
// ---------------------------------------------------------------------------

class _EmbeddingPainter extends CustomPainter {
  final List<_Point3D> points;
  final double rotY;
  final double rotX;
  final Color gridColor;
  final Color axisColor;
  final Color bgColor;
  final int pulseIndex;
  final double pulsePhase; // 0..1

  _EmbeddingPainter({
    required this.points,
    required this.rotY,
    required this.rotX,
    required this.gridColor,
    required this.axisColor,
    required this.bgColor,
    this.pulseIndex = -1,
    this.pulsePhase = 0.0,
  });

  /// Rotate a 3D point by rotX (pitch) then rotY (yaw) and project.
  /// Returns (screenX, screenY, depth) where depth is used for sorting/sizing.
  (double, double, double) _project(
      double x, double y, double z, double cx, double cy, double scale) {
    // Rotate around X axis (pitch)
    final cosX = math.cos(rotX), sinX = math.sin(rotX);
    final y1 = y * cosX - z * sinX;
    final z1 = y * sinX + z * cosX;
    // Rotate around Y axis (yaw)
    final cosY = math.cos(rotY), sinY = math.sin(rotY);
    final x2 = x * cosY + z1 * sinY;
    final z2 = -x * sinY + z1 * cosY;
    // Perspective projection
    final perspective = 3.0 / (3.0 + z2);
    return (cx + x2 * scale * perspective, cy - y1 * scale * perspective, z2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = math.min(size.width, size.height) * 0.30;
    // --- Background ---
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bgColor,
    );
    // --- Grid planes (subtle) ---
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    // Draw grid lines on the XZ plane (y = -1)
    for (var i = -4; i <= 4; i++) {
      final t = i / 4.0;
      // Lines along X
      final (x1a, y1a, _) = _project(t, -1, -1, cx, cy, scale);
      final (x1b, y1b, _) = _project(t, -1, 1, cx, cy, scale);
      canvas.drawLine(Offset(x1a, y1a), Offset(x1b, y1b), gridPaint);
      // Lines along Z
      final (x2a, y2a, _) = _project(-1, -1, t, cx, cy, scale);
      final (x2b, y2b, _) = _project(1, -1, t, cx, cy, scale);
      canvas.drawLine(Offset(x2a, y2a), Offset(x2b, y2b), gridPaint);
    }
    // --- Axes ---
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Origin
    final (ox, oy, _) = _project(0, 0, 0, cx, cy, scale);
    // X axis (red)
    final (ax, ay, _) = _project(1.2, 0, 0, cx, cy, scale);
    canvas.drawLine(Offset(ox, oy), Offset(ax, ay),
        axisPaint..color = Colors.red.withValues(alpha: 0.7));
    _drawAxisLabel(canvas, "PC1", ax, ay, Colors.red.withValues(alpha: 0.7));
    // Y axis (green)
    final (bx, by, _) = _project(0, 1.2, 0, cx, cy, scale);
    canvas.drawLine(Offset(ox, oy), Offset(bx, by),
        axisPaint..color = Colors.green.withValues(alpha: 0.7));
    _drawAxisLabel(canvas, "PC2", bx, by, Colors.green.withValues(alpha: 0.7));
    // Z axis (blue)
    final (dx, dy, _) = _project(0, 0, 1.2, cx, cy, scale);
    canvas.drawLine(Offset(ox, oy), Offset(dx, dy),
        axisPaint..color = Colors.blue.withValues(alpha: 0.7));
    _drawAxisLabel(canvas, "PC3", dx, dy, Colors.blue.withValues(alpha: 0.7));
    // --- Data points (depth-sorted, back to front) ---
    final projected = <(double sx, double sy, double depth, int idx)>[];
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final (sx, sy, dz) = _project(p.x, p.y, p.z, cx, cy, scale);
      projected.add((sx, sy, dz, i));
    }
    projected.sort((a, b) => a.$3.compareTo(b.$3)); // far first
    for (final (sx, sy, dz, idx) in projected) {
      final pt = points[idx];
      // Depth-based sizing: further away = smaller
      final depthFactor = (3.0 / (3.0 + dz));
      final baseRadius = pt.isUser ? 10.0 : 7.0;
      final radius = baseRadius * depthFactor;
      // Depth-based alpha
      final alpha = (0.4 + 0.6 * depthFactor).clamp(0.3, 1.0);
      final color = pt.color.withValues(alpha: alpha);
      // Glow
      canvas.drawCircle(
        Offset(sx, sy),
        radius * 2.5,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      // Pulse rings for highlighted point
      if (idx == pulseIndex && pulsePhase < 1.0) {
        // Draw 3 expanding rings at staggered phases
        for (var ring = 0; ring < 3; ring++) {
          final ringPhase = (pulsePhase * 3.0 - ring * 0.3).clamp(0.0, 1.0);
          if (ringPhase <= 0 || ringPhase >= 1) continue;
          final ringRadius = radius + 30.0 * ringPhase;
          final ringAlpha = (1.0 - ringPhase) * 0.6;
          canvas.drawCircle(
            Offset(sx, sy),
            ringRadius,
            Paint()
              ..color = pt.color.withValues(alpha: ringAlpha)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 * (1.0 - ringPhase),
          );
        }
      }
      // Filled circle with border
      canvas.drawCircle(Offset(sx, sy), radius, Paint()..color = color);
      canvas.drawCircle(
        Offset(sx, sy),
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // Label
      final label = pt.label.length > 28
          ? "${pt.label.substring(0, 28)}..."
          : pt.label;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 9 * depthFactor,
            fontWeight: pt.isUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 140);
      final labelX = sx + radius + 4 + tp.width > size.width - 10
          ? sx - radius - 4 - tp.width
          : sx + radius + 4;
      tp.paint(canvas, Offset(labelX, sy - tp.height / 2));
    }
  }

  void _drawAxisLabel(
      Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + 4, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EmbeddingPainter old) =>
      points != old.points ||
      rotY != old.rotY ||
      rotX != old.rotX ||
      pulseIndex != old.pulseIndex ||
      pulsePhase != old.pulsePhase;
}
