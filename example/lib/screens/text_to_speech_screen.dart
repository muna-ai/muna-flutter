import "dart:math";
import "dart:typed_data";
import "package:audioplayers/audioplayers.dart";
import "package:flutter/material.dart";
import "package:muna/muna.dart";

class TextToSpeechScreen extends StatefulWidget {
  const TextToSpeechScreen({super.key});

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final _textController = TextEditingController();
  final _audioPlayer = AudioPlayer();
  late final Muna _muna;
  bool _loading = false;
  bool _playing = false;
  String _status = "";

  @override
  void initState() {
    super.initState();
    _muna = Muna();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _onGenerateSpeech() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _status = "Please enter some text");
      return;
    }
    setState(() {
      _loading = true;
      _status = "";
    });
    try {
      final response = await _muna.beta.openai.audio.speech.create(
        input: text,
        model: "@kitten-ml/kitten-tts-mini-0.8",
        voice: "Bella",
        acceleration: "local_auto",
      );
      final bytes = Uint8List.fromList(response.content);
      await _audioPlayer.play(BytesSource(bytes));
      setState(() => _status = "");
    } catch (e, st) {
      setState(() => _status = "Error: $e\n\n$st");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Text to Speech"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: "Text",
                hintText: "Enter text to speak...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _onGenerateSpeech,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.record_voice_over),
              label: Text(_loading ? "Generating..." : "Generate Speech"),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            if (_playing || _loading)
              _WaveformVisualizer(
                active: _playing,
                color: Theme.of(context).colorScheme.primary,
              ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated waveform visualizer
// ---------------------------------------------------------------------------

class _WaveformVisualizer extends StatefulWidget {
  final bool active;
  final Color color;
  const _WaveformVisualizer({required this.active, required this.color});

  @override
  State<_WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<_WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(_WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: const Size(double.infinity, 80),
          painter: _WaveformPainter(
            progress: _controller.value,
            color: widget.color,
            active: widget.active,
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool active;

  _WaveformPainter({
    required this.progress,
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 60;
    final barWidth = size.width / (barCount * 1.6);
    final gap = barWidth * 0.6;
    final totalWidth = barCount * (barWidth + gap) - gap;
    final startX = (size.width - totalWidth) / 2;
    final maxHeight = size.height * 0.9;
    final minHeight = size.height * 0.05;
    final centerY = size.height / 2;
    final t = progress * pi * 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;
    for (var i = 0; i < barCount; i++) {
      final x = startX + i * (barWidth + gap);
      final n = i / barCount;
      final wave1 = sin(n * pi * 2.5 + t) * 0.35;
      final wave2 = sin(n * pi * 4.0 - t * 1.4) * 0.2;
      final wave3 = sin(n * pi * 6.5 + t * 0.8) * 0.15;
      final wave4 = sin(n * pi * 9.0 - t * 0.5) * 0.1;
      final envelope = pow(sin(n * pi), 1.5).toDouble();
      final combined = active
          ? (0.25 + (wave1 + wave2 + wave3 + wave4) * envelope).clamp(0.03, 1.0)
          : 0.08;
      final barHeight = minHeight + (maxHeight - minHeight) * combined;
      final opacity = active ? 0.4 + 0.6 * combined : 0.25;
      paint.color = color.withValues(alpha: opacity);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.active != active;
}
