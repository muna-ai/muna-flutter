import "package:flutter/material.dart";
import "screens/text_to_speech_screen.dart";

void main() {
  runApp(const MunaExamplesApp());
}

class _Example {
  final String title;
  final IconData icon;
  final Widget Function() builder;
  const _Example({
    required this.title,
    required this.icon,
    required this.builder,
  });
}

final _examples = [
  _Example(
    title: "Text to Speech",
    icon: Icons.record_voice_over,
    builder: () => const TextToSpeechScreen(),
  ),
];

class MunaExamplesApp extends StatelessWidget {
  const MunaExamplesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Muna Examples",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Muna Examples"),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: _examples.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final example = _examples[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: Icon(example.icon, color: colorScheme.primary),
              title: Text(
                example.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => example.builder()),
              ),
            ),
          );
        },
      ),
    );
  }
}
