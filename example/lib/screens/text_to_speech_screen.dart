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
  String _status = "";

  @override
  void initState() {
    super.initState();
    _muna = Muna();
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
      setState(() {
        _status = "Playing ${response.content.length} bytes "
            "(${response.contentType})";
      });
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
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(_status, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
