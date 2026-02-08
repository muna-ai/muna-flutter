//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

/// Prediction acceleration.
enum Acceleration {
  /// Automatically select the best acceleration.
  localAuto("local_auto"),

  /// Use the CPU.
  localCpu("local_cpu"),

  /// Use the GPU.
  localGpu("local_gpu"),

  /// Use the NPU.
  localNpu("local_npu");

  final String value;
  const Acceleration(this.value);

  static Acceleration fromValue(String value) =>
    Acceleration.values.firstWhere((e) => e.value == value);

  String toJson() => value;
}

/// Prediction resource.
class PredictionResource {
  /// Resource type.
  final String type;

  /// Resource URL.
  final String url;

  /// Resource name.
  final String? name;

  /// Create a [PredictionResource].
  const PredictionResource({
    required this.type,
    required this.url,
    this.name,
  });

  /// Create a [PredictionResource] from a JSON map.
  factory PredictionResource.fromJson(Map<String, dynamic> json) =>
    PredictionResource(
      type: json["type"] as String,
      url: json["url"] as String,
      name: json["name"] as String?,
    );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "type": type,
    "url": url,
    if (name != null) "name": name,
  };
}

/// Prediction.
class Prediction {
  /// Prediction identifier.
  final String id;

  /// Predictor tag.
  final String tag;

  /// Prediction configuration token.
  final String? configuration;

  /// Prediction resources.
  final List<PredictionResource>? resources;

  /// Prediction results.
  final List<Object?>? results;

  /// Prediction latency in milliseconds.
  final double? latency;

  /// Prediction error.
  ///
  /// This is `null` if the prediction completed successfully.
  final String? error;

  /// Prediction logs.
  final String? logs;

  /// Date created.
  final String created;

  /// Create a [Prediction].
  const Prediction({
    required this.id,
    required this.tag,
    this.configuration,
    this.resources,
    this.results,
    this.latency,
    this.error,
    this.logs,
    required this.created,
  });

  /// Create a [Prediction] from a JSON map.
  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    id: json["id"] as String,
    tag: json["tag"] as String,
    configuration: json["configuration"] as String?,
    resources: (json["resources"] as List<dynamic>?)
      ?.map((e) => PredictionResource.fromJson(e as Map<String, dynamic>))
      .toList(),
    results: json["results"] as List<Object?>?,
    latency: (json["latency"] as num?)?.toDouble(),
    error: json["error"] as String?,
    logs: json["logs"] as String?,
    created: json["created"] as String,
  );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "id": id,
    "tag": tag,
    if (configuration != null) "configuration": configuration,
    if (resources != null) "resources": resources!.map((e) => e.toJson()).toList(),
    if (results != null) "results": results,
    if (latency != null) "latency": latency,
    if (error != null) "error": error,
    if (logs != null) "logs": logs,
    "created": created,
  };

  @override
  String toString() => "Prediction(id: $id, tag: $tag)";
}