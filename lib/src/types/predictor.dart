//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "parameter.dart";
import "user.dart";

/// Predictor access level.
enum PredictorAccess {
  /// Public predictor.
  public_("public"),

  /// Private predictor.
  private_("private"),

  /// Unlisted predictor.
  unlisted("unlisted");

  final String value;
  const PredictorAccess(this.value);

  static PredictorAccess fromValue(String value) =>
    PredictorAccess.values.firstWhere((e) => e.value == value);

  String toJson() => value;
}

/// Predictor status.
enum PredictorStatus {
  /// Predictor is compiling.
  compiling("compiling"),

  /// Predictor is active.
  active("active"),

  /// Predictor is archived.
  archived("archived");

  final String value;
  const PredictorStatus(this.value);

  static PredictorStatus fromValue(String value) =>
    PredictorStatus.values.firstWhere((e) => e.value == value);

  String toJson() => value;
}

/// Predictor signature.
class Signature {
  /// Input parameters.
  final List<Parameter> inputs;

  /// Output parameters.
  final List<Parameter> outputs;

  /// Create a [Signature].
  const Signature({
    required this.inputs,
    required this.outputs,
  });

  /// Create a [Signature] from a JSON map.
  factory Signature.fromJson(Map<String, dynamic> json) => Signature(
    inputs: (json["inputs"] as List<dynamic>)
      .map((e) => Parameter.fromJson(e as Map<String, dynamic>))
      .toList(),
    outputs: (json["outputs"] as List<dynamic>)
      .map((e) => Parameter.fromJson(e as Map<String, dynamic>))
      .toList(),
  );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "inputs": inputs.map((e) => e.toJson()).toList(),
    "outputs": outputs.map((e) => e.toJson()).toList(),
  };
}

/// Predictor.
class Predictor {
  /// Predictor tag.
  final String tag;

  /// Predictor owner.
  final User owner;

  /// Predictor name.
  final String name;

  /// Predictor status.
  final PredictorStatus status;

  /// Predictor access level.
  final PredictorAccess access;

  /// Predictor signature.
  final Signature signature;

  /// Date created.
  final String created;

  /// Predictor description.
  final String? description;

  /// Predictor card (markdown).
  final String? card;

  /// Predictor media URL.
  final String? media;

  /// Predictor license URL.
  final String? license;

  /// Create a [Predictor].
  const Predictor({
    required this.tag,
    required this.owner,
    required this.name,
    required this.status,
    required this.access,
    required this.signature,
    required this.created,
    this.description,
    this.card,
    this.media,
    this.license,
  });

  /// Create a [Predictor] from a JSON map.
  factory Predictor.fromJson(Map<String, dynamic> json) => Predictor(
    tag: json["tag"] as String,
    owner: User.fromJson(json["owner"] as Map<String, dynamic>),
    name: json["name"] as String,
    status: PredictorStatus.fromValue(json["status"] as String),
    access: PredictorAccess.fromValue(json["access"] as String),
    signature: Signature.fromJson(json["signature"] as Map<String, dynamic>),
    created: json["created"] as String,
    description: json["description"] as String?,
    card: json["card"] as String?,
    media: json["media"] as String?,
    license: json["license"] as String?,
  );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "tag": tag,
    "owner": owner.toJson(),
    "name": name,
    "status": status.value,
    "access": access.value,
    "signature": signature.toJson(),
    "created": created,
    if (description != null) "description": description,
    if (card != null) "card": card,
    if (media != null) "media": media,
    if (license != null) "license": license,
  };

  @override
  String toString() => "Predictor(tag: $tag)";
}