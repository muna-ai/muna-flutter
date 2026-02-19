//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:convert";
import "dart:io";
import "package:flutter/services.dart";
import "../c/configuration.dart" as c;
import "../c/map.dart" as c;
import "../c/prediction.dart" as c;
import "../c/predictor.dart" as c;
import "../client.dart";
import "../types/prediction.dart";

/// Manage predictions.
class PredictionService {
  final MunaClient _client;
  final Map<String, c.Predictor> _cache = {};
  final Directory _cacheDir;
  final List<_CachedPrediction> _predictionCache;

  /// Create a [PredictionService].
  PredictionService(this._client)
    : _cacheDir = _getCacheDir(),
      _predictionCache = [] {
    _cacheDir.createSync(recursive: true);
    _loadPredictionCache();
  }

  /// Create a prediction.
  ///
  /// [tag] is the predictor tag.
  /// [inputs] are the input values. When `null`, a raw cloud prediction
  /// is created (returning configuration and resources for edge predictions).
  /// [acceleration] is the prediction acceleration.
  /// [device] is an optional native device pointer.
  /// [clientId] is an optional Muna client identifier.
  /// [configurationId] is an optional configuration identifier.
  ///
  /// Returns the created [Prediction].
  Future<Prediction> create(
    String tag, {
    Map<String, Object?>? inputs,
    Acceleration acceleration = Acceleration.localAuto,
    dynamic device,
    String? clientId,
    String? configurationId,
  }) async {
    if (inputs == null) {
      return _createRawPrediction(
        tag: tag,
        clientId: clientId,
        configurationId: configurationId,
      );
    }
    final predictor = await _getPredictor(
      tag: tag,
      acceleration: acceleration,
      device: device,
      clientId: clientId,
      configurationId: configurationId,
    );
    final inputMap = c.ValueMap.fromDict(inputs);
    try {
      final prediction = predictor.createPrediction(inputMap);
      try {
        return _parseLocalPrediction(prediction, tag: tag);
      } finally {
        prediction.release();
      }
    } finally {
      inputMap.release();
    }
  }

  /// Stream a prediction.
  ///
  /// [tag] is the predictor tag.
  /// [inputs] are the input values.
  /// [acceleration] is the prediction acceleration.
  /// [device] is an optional native device pointer.
  ///
  /// Returns an [Iterable] of [Prediction] results.
  Future<Iterable<Prediction>> stream(
    String tag, {
    required Map<String, Object?> inputs,
    Acceleration acceleration = Acceleration.localAuto,
    dynamic device,
  }) async {
    final predictor = await _getPredictor(
      tag: tag,
      acceleration: acceleration,
      device: device,
    );
    final inputMap = c.ValueMap.fromDict(inputs);
    try {
      final stream = predictor.streamPrediction(inputMap);
      try {
        final results = <Prediction>[];
        while (stream.moveNext()) {
          final prediction = stream.current;
          try {
            results.add(_parseLocalPrediction(prediction, tag: tag));
          } finally {
            prediction.release();
          }
        }
        return results;
      } finally {
        stream.release();
      }
    } finally {
      inputMap.release();
    }
  }

  /// Delete a predictor that is loaded in memory.
  ///
  /// [tag] is the predictor tag.
  ///
  /// Returns whether the predictor was successfully deleted from memory.
  bool delete(String tag) {
    final predictor = _cache.remove(tag);
    if (predictor == null) {
      return false;
    }
    predictor.release();
    return true;
  }

  Future<Prediction> _createRawPrediction({
    required String tag,
    String? clientId,
    String? configurationId,
    String? predictionId,
  }) async {
    clientId ??= c.Configuration.getClientId();
    configurationId ??= c.Configuration.getUniqueId();
    final prediction = await _client.request(
      method: "POST",
      path: "/predictions",
      body: {
        "tag": tag,
        "clientId": clientId,
        "configurationId": configurationId,
        if (predictionId != null) "predictionId": predictionId,
      },
      fromJson: Prediction.fromJson,
    );
    return prediction!;
  }

  Future<c.Predictor> _getPredictor({
    required String tag,
    Acceleration acceleration = Acceleration.localAuto,
    dynamic device,
    String? clientId,
    String? configurationId,
  }) async {
    if (_cache.containsKey(tag)) {
      return _cache[tag]!;
    }
    final cachedPrediction = _predictionCache
        .where((p) => p.tag == tag)
        .firstOrNull;
    final prediction = await _createRawPrediction(
      tag: tag,
      clientId: clientId,
      configurationId: configurationId,
      predictionId: cachedPrediction?.id,
    );
    final configuration = c.Configuration();
    try {
      configuration.tag = prediction.tag;
      configuration.token = prediction.configuration;
      configuration.acceleration = acceleration;
      for (final resource in prediction.resources ?? []) {
        final path = _getResourcePath(resource);
        if (!File(path).existsSync()) {
          await _client.download(resource.url, path);
        }
        configuration.addResource(resource.type, path);
      }
      final predictor = c.Predictor(configuration);
      _cache[tag] = predictor;
      return predictor;
    } finally {
      configuration.release();
    }
  }

  Future<void> _loadPredictionCache() async {
    try {
      final json = await rootBundle.loadString("assets/muna.resolved");
      final data = jsonDecode(json) as Map<String, dynamic>;
      final predictions = (data["predictions"] as List<dynamic>)
          .map((e) => _CachedPrediction.fromJson(e as Map<String, dynamic>));
      String? abi;
      try {
        abi = _clientIdToAbi[c.Configuration.getClientId()];
      } catch (_) {}
      _predictionCache.addAll(
        abi != null
            ? predictions.where((p) => p.clientId == abi)
            : predictions,
      );
    } catch (_) {}
  }

  String _getResourcePath(PredictionResource resource) {
    final uri = Uri.parse(resource.url);
    final stem = uri.pathSegments.last;
    final basePath = "${_cacheDir.path}/$stem";
    if (resource.name != null) {
      return "$basePath/${resource.name}";
    }
    return basePath;
  }
}

Prediction _parseLocalPrediction(
  c.Prediction prediction, {
  required String tag,
}) {
  final outputMap = prediction.results;
  List<Object?>? results;
  if (outputMap != null) {
    final length = outputMap.length;
    results = List.generate(length, (i) {
      final key = outputMap.key(i);
      final value = outputMap[key];
      return value.toObject();
    });
  }
  return Prediction(
    id: prediction.id,
    tag: tag,
    results: results,
    latency: prediction.latency,
    error: prediction.error,
    logs: prediction.logs,
    created: DateTime.now().toUtc().toIso8601String(),
  );
}

Directory _getCacheDir() {
  try {
    final home = Platform.environment["HOME"] ??
      Platform.environment["USERPROFILE"] ??
      Directory.systemTemp.path;
    return Directory("$home/.fxn/cache");
  } catch (_) {
    return Directory("${Directory.systemTemp.path}/.fxn/cache");
  }
}

const _clientIdToAbi = {
  "android-armv7l": "armeabi-v7a",
  "android-armeabi-v7a": "armeabi-v7a",
  "android-arm64": "arm64-v8a",
  "android-arm64-v8a": "arm64-v8a",
  "android-aarch64": "arm64-v8a",
  "android-x86": "x86",
  "android-i386": "x86",
  "android-i686": "x86",
  "android-x86_64": "x86_64",
};

class _CachedPrediction {
  final String id;
  final String tag;
  final String? clientId;

  const _CachedPrediction({
    required this.id,
    required this.tag,
    this.clientId,
  });

  factory _CachedPrediction.fromJson(Map<String, dynamic> json) =>
    _CachedPrediction(
      id: json["id"] as String,
      tag: json["tag"] as String,
      clientId: json["clientId"] as String?,
    );
}
