//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dtype.dart";

/// Parameter enumeration member.
class EnumerationMember {
  /// Enumeration member name.
  final String name;

  /// Enumeration member value.
  final Object value;

  /// Create an [EnumerationMember].
  const EnumerationMember({
    required this.name,
    required this.value,
  });

  /// Create an [EnumerationMember] from a JSON map.
  factory EnumerationMember.fromJson(Map<String, dynamic> json) =>
    EnumerationMember(
      name: json["name"] as String,
      value: json["value"] as Object,
    );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "name": name,
    "value": value,
  };
}

/// Predictor parameter.
class Parameter {
  /// Parameter name.
  final String name;

  /// Parameter type.
  ///
  /// This is `null` if the type is unknown or unsupported by Muna.
  final Dtype? dtype;

  /// Parameter description.
  final String? description;

  /// Parameter denotation for specialized data types.
  final String? denotation;

  /// Whether the parameter is optional.
  final bool? optional;

  /// Parameter value choices for enumeration parameters.
  final List<EnumerationMember>? enumeration;

  /// Parameter JSON schema.
  ///
  /// This is only populated for `list` and `dict` parameters.
  final Map<String, dynamic>? schema;

  /// Parameter minimum value.
  final num? min;

  /// Parameter maximum value.
  final num? max;

  /// Audio sample rate in Hertz.
  final int? sampleRate;

  /// Create a [Parameter].
  const Parameter({
    required this.name,
    this.dtype,
    this.description,
    this.denotation,
    this.optional,
    this.enumeration,
    this.schema,
    this.min,
    this.max,
    this.sampleRate,
  });

  /// Create a [Parameter] from a JSON map.
  factory Parameter.fromJson(Map<String, dynamic> json) => Parameter(
    name: json["name"] as String,
    dtype: Dtype.fromValue(json["dtype"] as String? ?? json["type"] as String?),
    description: json["description"] as String?,
    denotation: json["denotation"] as String?,
    optional: json["optional"] as bool?,
    enumeration: (json["enumeration"] as List<dynamic>?)
      ?.map((e) => EnumerationMember.fromJson(e as Map<String, dynamic>))
      .toList(),
    schema: json["schema"] as Map<String, dynamic>?,
    min: json["min"] as num?,
    max: json["max"] as num?,
    sampleRate: json["sampleRate"] as int?,
  );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "name": name,
    if (dtype != null) "dtype": dtype!.value,
    if (description != null) "description": description,
    if (denotation != null) "denotation": denotation,
    if (optional != null) "optional": optional,
    if (enumeration != null) "enumeration": enumeration!.map((e) => e.toJson()).toList(),
    if (schema != null) "schema": schema,
    if (min != null) "min": min,
    if (max != null) "max": max,
    if (sampleRate != null) "sampleRate": sampleRate,
  };

  @override
  String toString() => "Parameter(name: $name, dtype: ${dtype?.value})";
}