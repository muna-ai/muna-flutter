//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:convert";
import "dart:typed_data";

import "package:http/http.dart" as http;

import "../../client.dart";
import "../../types/dtype.dart";
import "../../types/prediction.dart";
import "types.dart";

/// Make remote predictions.
class RemotePredictionService {
  final MunaClient _client;

  /// Create a [RemotePredictionService].
  RemotePredictionService(this._client);

  /// Create a remote prediction.
  ///
  /// [tag] is the predictor tag.
  /// [inputs] is a map of input names to values.
  /// [acceleration] is the prediction acceleration.
  ///
  /// Returns the created [Prediction].
  Future<Prediction> create(
    String tag, {
    required Map<String, Object?> inputs,
    RemoteAcceleration acceleration = RemoteAcceleration.remoteAuto,
  }) async {
    final inputMap = inputs.map(
      (name, value) => MapEntry(name, createRemoteValue(value).toJson()),
    );
    final remotePrediction = await _client.request<RemotePrediction>(
      method: "POST",
      path: "/predictions/remote",
      body: {
        "tag": tag,
        "inputs": inputMap,
        "acceleration": acceleration.value,
      },
      fromJson: RemotePrediction.fromJson,
    );
    return _parseRemotePrediction(remotePrediction!);
  }

  /// Stream a remote prediction.
  ///
  /// [tag] is the predictor tag.
  /// [inputs] is a map of input names to values.
  /// [acceleration] is the prediction acceleration.
  ///
  /// Returns a [Stream] of [Prediction] results.
  Stream<Prediction> stream(
    String tag, {
    required Map<String, Object?> inputs,
    RemoteAcceleration acceleration = RemoteAcceleration.remoteAuto,
  }) async* {
    final inputMap = inputs.map(
      (name, value) => MapEntry(name, createRemoteValue(value).toJson()),
    );
    await for (final event in _client.stream<_RemotePredictionEvent>(
      method: "POST",
      path: "/predictions/remote",
      body: {
        "tag": tag,
        "inputs": inputMap,
        "acceleration": acceleration.value,
        "stream": true,
      },
      fromJson: _RemotePredictionEvent.fromJson,
    )) {
      yield await _parseRemotePrediction(event.data);
    }
  }
}

/// Create a [RemoteValue] from a Dart object.
///
/// Supported types: `null`, [num], [bool], [String],
/// [List], [Map], [Uint8List].
RemoteValue createRemoteValue(Object? value) {
  if (value == null) {
    return const RemoteValue(data: null, dtype: Dtype.null_);
  }
  if (value is double) {
    return RemoteValue(
      data: _encodeDataUrl(
        utf8.encode(value.toString()),
        mime: "text/plain",
      ),
      dtype: Dtype.float32,
    );
  }
  if (value is int) {
    return RemoteValue(
      data: _encodeDataUrl(
        utf8.encode(value.toString()),
        mime: "text/plain",
      ),
      dtype: Dtype.int32,
    );
  }
  if (value is bool) {
    return RemoteValue(
      data: _encodeDataUrl(
        utf8.encode(value.toString()),
        mime: "text/plain",
      ),
      dtype: Dtype.bool_,
    );
  }
  if (value is String) {
    return RemoteValue(
      data: _encodeDataUrl(utf8.encode(value), mime: "text/plain"),
      dtype: Dtype.string,
    );
  }
  if (value is List) {
    final jsonBytes = utf8.encode(jsonEncode(value));
    return RemoteValue(
      data: _encodeDataUrl(jsonBytes, mime: "application/json"),
      dtype: Dtype.list,
    );
  }
  if (value is Map) {
    final jsonBytes = utf8.encode(jsonEncode(value));
    return RemoteValue(
      data: _encodeDataUrl(jsonBytes, mime: "application/json"),
      dtype: Dtype.dict,
    );
  }
  if (value is Uint8List) {
    return RemoteValue(
      data: _encodeDataUrl(value),
      dtype: Dtype.binary,
    );
  }
  throw ArgumentError(
    "Cannot serialize value of type '${value.runtimeType}' because it is not supported",
  );
}

/// Parse a [RemoteValue] back into a Dart object.
Future<Object?> parseRemoteValue(RemoteValue value) async {
  if (value.data == null) return null;
  final buffer = await _downloadValueData(value.data!);
  switch (value.dtype) {
    case Dtype.null_:
      return null;
    case Dtype.float16:
    case Dtype.float32:
    case Dtype.float64:
    case Dtype.bfloat16:
      return double.tryParse(utf8.decode(buffer));
    case Dtype.int8:
    case Dtype.int16:
    case Dtype.int32:
    case Dtype.int64:
    case Dtype.uint8:
    case Dtype.uint16:
    case Dtype.uint32:
    case Dtype.uint64:
      return int.tryParse(utf8.decode(buffer));
    case Dtype.bool_:
      return utf8.decode(buffer).toLowerCase() == "true";
    case Dtype.string:
      return utf8.decode(buffer);
    case Dtype.list:
    case Dtype.dict:
      return jsonDecode(utf8.decode(buffer));
    case Dtype.image:
    case Dtype.imageList:
      return buffer;
    case Dtype.binary:
      return buffer;
  }
}

/// Encode bytes as a base64 data URL.
String _encodeDataUrl(
  List<int> data, {
  String mime = "application/octet-stream",
}) {
  final encoded = base64Encode(data);
  return "data:$mime;base64,$encoded";
}

/// Download value data from a URL or data URL.
Future<Uint8List> _downloadValueData(String url) async {
  if (url.startsWith("data:")) {
    final commaIndex = url.indexOf(",");
    if (commaIndex == -1) {
      throw ArgumentError("Invalid data URL");
    }
    final meta = url.substring(0, commaIndex);
    final data = url.substring(commaIndex + 1);
    if (meta.endsWith(";base64")) {
      return base64Decode(data);
    }
    return utf8.encode(Uri.decodeComponent(data));
  }
  final response = await http.get(Uri.parse(url));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception("Failed to download value data (${response.statusCode})");
  }
  return response.bodyBytes;
}

/// Parse a remote prediction into a [Prediction].
Future<Prediction> _parseRemotePrediction(RemotePrediction prediction) async {
  List<Object?>? results;
  if (prediction.results != null) {
    results = [];
    for (final value in prediction.results!) {
      results.add(await parseRemoteValue(value));
    }
  }
  return Prediction(
    id: prediction.id,
    tag: prediction.tag,
    results: results,
    latency: prediction.latency,
    error: prediction.error,
    logs: prediction.logs,
    created: prediction.created,
  );
}

/// Remote prediction SSE event.
class _RemotePredictionEvent {
  final String event;
  final RemotePrediction data;

  const _RemotePredictionEvent({
    required this.event,
    required this.data,
  });

  static _RemotePredictionEvent fromJson(Map<String, dynamic> json) =>
    _RemotePredictionEvent(
      event: json["event"] as String,
      data: RemotePrediction.fromJson(json["data"] as Map<String, dynamic>),
    );
}