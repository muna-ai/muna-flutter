# Muna Flutter Example App

An example Flutter app demonstrating on-device chat completions, text-to-speech, speech-to-text, and more with [Muna](https://muna.ai).

## Getting Started

1. **Set up your access key.** Copy the template and add your key from [muna.ai](https://muna.ai/settings/developer):
   ```bash
   cp .env.example .env
   # Edit .env and add your MUNA_ACCESS_KEY
   ```

2. **Embed the models.** This downloads model resources for Android:
   ```bash
   # Run this in Terminal
   $ dart run muna:embed
   ```

3. **Run the app** on a connected Android or iOS device:
   ```bash
   # Build and run the app
   $ flutter run --dart-define-from-file=.env
   ```
