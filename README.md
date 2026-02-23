# Muna for Flutter

Run AI models in Flutter. Register at [muna.ai](https://muna.ai).

## Installing Muna

Add `muna` to your `pubspec.yaml`:

```yaml
dependencies:
  muna: ^0.0.2
```

## Making a Prediction
First, create a Muna client, specifying your access key ([create one here](https://muna.ai/settings/developer)):
```dart
import "package:muna/muna.dart";

// 💥 Create an OpenAI client
final openai = Muna(accessKey: "<ACCESS KEY>").beta.openai;
```

Next, make a prediction:
```dart
// 🔥 Make a prediction
final completion = await openai.chat.completions.create(
  model: "@openai/gpt-oss-20b",
  messages: [
    Message(role: "user", content: "What is the capital of France?"),
  ],
);
```

Before building and running your app, embed the model into your app by adding a `muna` block to your app's `pubspec.yaml`:
```yaml
muna:
  access_key: "<ACCESS KEY>"
  predictors:
    - tag: "@username/model"
```

Then run the embed command:
```sh
# Embed models for your app build (run in Terminal)
$ dart run muna:embed
```

Finally, run your app and use the results:
```dart
// 🚀 Use the results
print(completion.choices.first.message.content);
```

___

## Useful Links
- [Check out several AI models we've compiled](https://github.com/muna-ai/muna-predictors).
- [Join our Slack community](https://muna.ai/slack).
- [Check out our docs](https://docs.muna.ai).
- Learn more about us [on our blog](https://blog.muna.ai).
- Reach out to us at [hi@muna.ai](mailto:hi@muna.ai).

Muna is a product of [NatML Inc](https://github.com/natmlx).
