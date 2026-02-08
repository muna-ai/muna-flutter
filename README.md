# Muna for Flutter

Run AI models in Flutter. Register at [muna.ai](https://muna.ai).

## Installing Muna

Add `muna` to your `pubspec.yaml`:

```yaml
dependencies:
  muna: ^0.0.1
```

## Quickstart

```dart
import "package:muna/muna.dart";

// Create the Muna client
final muna = Muna(accessKey: "your_access_key");

// Retrieve the current user
final user = await muna.users.retrieve();
print(user?.username);

// Retrieve a predictor
final predictor = await muna.predictors.retrieve("@owner/predictor-tag");
print(predictor?.name);

// Create a remote prediction
final prediction = await muna.beta.predictions.create(
  "@owner/predictor-tag",
  inputs: { "prompt": "Hello world!" },
);
print(prediction.results);

// Stream a remote prediction
await for (final prediction in muna.beta.predictions.stream(
  "@owner/predictor-tag",
  inputs: { "prompt": "Hello world!" },
)) {
  print(prediction.results);
}
```

___

## Useful Links
- [Check out several AI models we've compiled](https://github.com/muna-ai/muna-predictors).
- [Join our Slack community](https://muna.ai/slack).
- [Check out our docs](https://docs.muna.ai).
- Learn more about us [on our blog](https://blog.muna.ai).
- Reach out to us at [hi@muna.ai](mailto:hi@muna.ai).

Muna is a product of [NatML Inc](https://github.com/natmlx).
