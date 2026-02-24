// 
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:convert";
import "dart:io";
import "package:http/http.dart" as http;
import "package:yaml/yaml.dart";
import "package:yaml_edit/yaml_edit.dart";

const _defaultApiUrl = "https://api.muna.ai/v1";
const _defaultAbis = ["armeabi-v7a", "arm64-v8a"];

String? _parseAccessKey(List<String> args) {
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == "--access-key" && i + 1 < args.length) {
      return args[i + 1];
    }
    if (arg.startsWith("--access-key=")) {
      return arg.substring("--access-key=".length);
    }
  }
  return null;
}

Map<String, String> _loadEnvFile() {
  final file = File(".env");
  if (!file.existsSync()) return {};
  final result = <String, String>{};
  for (final line in file.readAsStringSync().split("\n")) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith("#")) continue;
    final eq = trimmed.indexOf("=");
    if (eq <= 0) continue;
    final key = trimmed.substring(0, eq).trim();
    var value = trimmed.substring(eq + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    } else if (value.startsWith("'") && value.endsWith("'")) {
      value = value.substring(1, value.length - 1);
    }
    result[key] = value;
  }
  return result;
}

Future<void> main(List<String> args) async {
  final pubspecFile = File("pubspec.yaml");
  if (!pubspecFile.existsSync()) {
    stderr.writeln("Error: pubspec.yaml not found in current directory.");
    exit(1);
  }
  final pubspec = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
  final munaConfig = pubspec["muna"] as YamlMap?;
  if (munaConfig == null) {
    stderr.writeln('Error: No "muna" block found in pubspec.yaml.');
    exit(1);
  }
  final envFile = _loadEnvFile();
  final accessKey = _parseAccessKey(args)
      ?? Platform.environment["MUNA_ACCESS_KEY"]
      ?? envFile["MUNA_ACCESS_KEY"]
      ?? munaConfig["access_key"] as String?
      ?? "";
  final apiUrl = munaConfig["api_url"] as String? ?? _defaultApiUrl;
  final predictors = munaConfig["predictors"] as YamlList?;
  if (predictors == null || predictors.isEmpty) {
    print("No predictors to embed.");
    return;
  }
  final predictions = <Map<String, dynamic>>[];
  for (final predictor in predictors) {
    final tag = (predictor as YamlMap)["tag"] as String;
    print("Embedding $tag...");
    for (final abi in _defaultAbis) {
      final prediction = await _createPrediction(
        tag: tag,
        clientId: "android-$abi",
        accessKey: accessKey,
        apiUrl: apiUrl,
      );
      final resources = prediction["resources"] as List<dynamic>? ?? [];
      for (final resource in resources) {
        if (resource["type"] == "dso") {
          final url = resource["url"] as String;
          final hash = Uri.parse(url).pathSegments.last;
          final name = resource["name"] as String? ?? "lib$hash.so";
          final path = "android/app/src/main/jniLibs/$abi/$name";
          await _downloadFile(url, path);
          print("  Downloaded $name for $abi");
        }
      }
      predictions.add({
        "id": prediction["id"],
        "tag": prediction["tag"],
        "resources": resources,
        "clientId": abi,
        "created": prediction["created"],
      });
    }
  }
  final manifestDir = Directory("assets");
  if (!manifestDir.existsSync()) manifestDir.createSync(recursive: true);
  File("assets/muna.resolved").writeAsStringSync(
    const JsonEncoder.withIndent("  ").convert({"predictions": predictions}),
  );
  print("Wrote manifest to assets/muna.resolved");
  _ensureAssetDeclared(pubspecFile);
}

Future<Map<String, dynamic>> _createPrediction({
  required String tag,
  required String clientId,
  required String accessKey,
  required String apiUrl,
}) async {
  final response = await http.post(
    Uri.parse("$apiUrl/predictions"),
    headers: {
      "Authorization": "Bearer $accessKey",
      "Content-Type": "application/json",
    },
    body: jsonEncode({"tag": tag, "clientId": clientId}),
  );
  if (response.statusCode < 200 || response.statusCode >= 300) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }
    String message = response.body;
    if (data is Map) {
      final errors = data["errors"] as List?;
      if (errors != null && errors.isNotEmpty) {
        message = errors.first["message"] as String? ?? message;
      }
    }
    throw Exception("Failed to embed $tag: $message");
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

const _manifestAsset = "assets/muna.resolved";

void _ensureAssetDeclared(File pubspecFile) {
  final content = pubspecFile.readAsStringSync();
  final pubspec = loadYaml(content) as YamlMap;
  final flutter = pubspec["flutter"] as YamlMap?;
  final assets = flutter?["assets"] as YamlList?;
  if (assets != null && assets.contains(_manifestAsset)) return;
  final editor = YamlEditor(content);
  if (assets != null) {
    editor.appendToList(["flutter", "assets"], _manifestAsset);
  } else if (flutter != null) {
    editor.update(["flutter", "assets"], [_manifestAsset]);
  } else {
    editor.update(["flutter"], {"assets": [_manifestAsset]});
  }
  pubspecFile.writeAsStringSync(editor.toString());
  print("Added $_manifestAsset to pubspec.yaml flutter assets");
}

Future<void> _downloadFile(String url, String path) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception("Failed to download $url: ${response.statusCode}");
  }
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(response.bodyBytes);
}
