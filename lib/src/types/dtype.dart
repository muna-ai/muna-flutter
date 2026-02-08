//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

/// Value data type.
enum Dtype {
  /// Null type.
  // ignore: constant_identifier_names
  null_("null"),

  /// Brain floating point 16-bit.
  bfloat16("bfloat16"),

  /// Floating point 16-bit.
  float16("float16"),

  /// Floating point 32-bit.
  float32("float32"),

  /// Floating point 64-bit.
  float64("float64"),

  /// Signed integer 8-bit.
  int8("int8"),

  /// Signed integer 16-bit.
  int16("int16"),

  /// Signed integer 32-bit.
  int32("int32"),

  /// Signed integer 64-bit.
  int64("int64"),

  /// Unsigned integer 8-bit.
  uint8("uint8"),

  /// Unsigned integer 16-bit.
  uint16("uint16"),

  /// Unsigned integer 32-bit.
  uint32("uint32"),

  /// Unsigned integer 64-bit.
  uint64("uint64"),

  /// Boolean.
  bool_("bool"),

  /// String.
  string("string"),

  /// List.
  list("list"),

  /// Dictionary.
  dict("dict"),

  /// Image.
  image("image"),

  /// Image list.
  imageList("image_list"),

  /// Binary data.
  binary("binary");

  /// The string value of this dtype.
  final String value;

  const Dtype(this.value);

  /// Create a [Dtype] from a string value.
  static Dtype? fromValue(String? value) {
    if (value == null)
      return null;
    for (final dtype in Dtype.values) {
      if (dtype.value == value)
        return dtype;
    }
    return null;
  }

  /// Serialize to JSON.
  String toJson() => value;

  /// Deserialize from JSON.
  static Dtype? fromJson(String? json) => fromValue(json);
}