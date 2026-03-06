import "dart:math";
import "dart:typed_data";
import "package:flutter/material.dart";
import "package:muna/muna.dart";
import "package:record/record.dart";

class SpeechToTextScreen extends StatefulWidget {
  const SpeechToTextScreen({super.key});

  @override
  State<SpeechToTextScreen> createState() => _SpeechToTextScreenState();
}

class _TranscriptionEntry {
  final String text;
  final Duration duration;
  _TranscriptionEntry({required this.text, required this.duration});
}

class _SpeechToTextScreenState extends State<SpeechToTextScreen> {
  late final Muna _muna;
  final _recorder = AudioRecorder();
  bool _recording = false;
  bool _transcribing = false;
  String? _error;
  final List<_TranscriptionEntry> _transcriptions = [];
  final List<int> _pcmSamples = [];
  DateTime? _recordingStart;
  static const _sampleRate = 16000;

  @override
  void initState() {
    super.initState();
    _muna = Muna();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      setState(() => _error = "Microphone permission denied");
      return;
    }
    setState(() {
      _error = null;
      _pcmSamples.clear();
    });
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: 1,
        sampleRate: _sampleRate,
      ),
    );
    _recordingStart = DateTime.now();
    setState(() => _recording = true);
    stream.listen((data) {
      // PCM16 little-endian bytes → signed 16-bit samples
      final bytes = data is Uint8List ? data : Uint8List.fromList(data);
      for (var i = 0; i + 1 < bytes.length; i += 2) {
        final sample = bytes[i] | (bytes[i + 1] << 8);
        _pcmSamples.add(sample > 32767 ? sample - 65536 : sample);
      }
    });
  }

  Future<void> _stopAndTranscribe() async {
    await _recorder.stop();
    final duration = _recordingStart != null
        ? DateTime.now().difference(_recordingStart!)
        : Duration.zero;
    setState(() {
      _recording = false;
      _transcribing = true;
      _error = null;
    });
    try {
      // Convert PCM16 samples to Float32 normalized to [-1, 1]
      final float32 = Float32List(_pcmSamples.length);
      for (var i = 0; i < _pcmSamples.length; i++) {
        float32[i] = _pcmSamples[i] / 32768.0;
      }
      final prediction = await _muna.predictions.create(
        "@moonshine/moonshine-base",
        inputs: {
          "audio": Tensor(float32, [_pcmSamples.length, 1]),
        },
      );
      if (prediction.error != null) {
        setState(() => _error = prediction.error);
        return;
      }
      final text = prediction.results?[0] as String? ?? "";
      setState(() {
        _transcriptions.insert(
          0,
          _TranscriptionEntry(text: text, duration: duration),
        );
      });
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _transcribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Speech to Text"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Waveform / status area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _recording
                ? _WaveformVisualizer(active: true, color: colorScheme.error)
                : _transcribing
                    ? Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            "Transcribing...",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : _transcriptions.isEmpty
                        ? Column(
                            children: [
                              Icon(
                                Icons.hearing,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Tap the button below to record\nand transcribe speech",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
          ),
          // Error
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ),
          // Transcription history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _transcriptions.length,
              itemBuilder: (context, index) {
                final entry = _transcriptions[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.text.isEmpty
                              ? "(no speech detected)"
                              : entry.text,
                          style: entry.text.isEmpty
                              ? TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${entry.duration.inSeconds}s recording",
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Record button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _transcribing
                      ? null
                      : _recording
                          ? _stopAndTranscribe
                          : _startRecording,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        _recording ? colorScheme.error : null,
                    foregroundColor:
                        _recording ? colorScheme.onError : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _transcribing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _recording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                        ),
                  label: Text(
                    _transcribing
                        ? "Transcribing..."
                        : _recording
                            ? "Stop & Transcribe"
                            : "Start Recording",
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated waveform visualizer (same as TTS screen)
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
          ? (0.25 + (wave1 + wave2 + wave3 + wave4) * envelope)
              .clamp(0.03, 1.0)
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
