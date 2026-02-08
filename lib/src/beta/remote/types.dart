//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../types/dtype.dart";

/// Remote prediction acceleration.
enum RemoteAcceleration {
  /// Automatically select the best remote acceleration.
  remoteAuto("remote_auto"),

  /// Use a remote CPU.
  remoteCpu("remote_cpu"),

  /// Use a remote NVIDIA A10 GPU.
  remoteA10("remote_a10"),

  /// Use a remote NVIDIA A100 GPU.
  remoteA100("remote_a100"),

  /// Use a remote NVIDIA H200 GPU.
  remoteH200("remote_h200"),

  /// Use a remote NVIDIA B200 GPU.
  remoteB200("remote_b200");

  /// The string value of this acceleration.
  final String value;

  const RemoteAcceleration(this.value);

  /// Create a [RemoteAcceleration] from a string value.
  static RemoteAcceleration fromValue(String value) =>
    RemoteAcceleration.values.firstWhere((e) => e.value == value);

  /// Serialize to JSON.
  String toJson() => value;
}

/// Remote value for serialization over the API.
class RemoteValue {
  /// Value URL. This is a remote or data URL.
  final String? data;

  /// Value type.
  final Dtype dtype;

  /// Create a [RemoteValue].
  const RemoteValue({
    this.data,
    required this.dtype,
  });

  /// Create a [RemoteValue] from a JSON map.
  factory RemoteValue.fromJson(Map<String, dynamic> json) => RemoteValue(
    data: json["data"] as String?,
    dtype: Dtype.fromValue(json["dtype"] as String?) ?? Dtype.null_,
  );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "data": data,
    "dtype": dtype.value,
  };
}

/// Remote prediction.
class RemotePrediction {
  final String id;
  final String tag;
  final String? configuration;
  final List<RemoteValue>? results;
  final double? latency;
  final String? error;
  final String? logs;
  final String created;

  const RemotePrediction({
    required this.id,
    required this.tag,
    this.configuration,
    this.results,
    this.latency,
    this.error,
    this.logs,
    required this.created,
  });

  static RemotePrediction fromJson(Map<String, dynamic> json) => RemotePrediction(
    id: json["id"] as String,
    tag: json["tag"] as String,
    configuration: json["configuration"] as String?,
    results: (json["results"] as List<dynamic>?)
      ?.map((e) => RemoteValue.fromJson(e as Map<String, dynamic>))
      .toList(),
    latency: (json["latency"] as num?)?.toDouble(),
    error: json["error"] as String?,
    logs: json["logs"] as String?,
    created: json["created"] as String,
  );
}
