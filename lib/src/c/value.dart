//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:convert";
import "dart:ffi";
import "dart:typed_data";
import "package:ffi/ffi.dart";
import "../types/dtype.dart";
import "../types/image.dart" as types;
import "../types/tensor.dart";
import "fxnc.dart";

typedef _FXNValueGetDataNative = Int32 Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNValueGetTypeNative = Int32 Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNValueGetDimensionsNative = Int32 Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNValueGetShapeNative = Int32 Function(Pointer<Void>, Pointer<Int32>, Int32);
typedef _FXNValueReleaseNative = Int32 Function(Pointer<Void>);
typedef _FXNValueCreateNullNative = Int32 Function(Pointer<Pointer<Void>>);
typedef _FXNValueCreateArrayNative = Int32 Function(Pointer<Void>, Pointer<Int32>, Int32, Int32, Int32, Pointer<Pointer<Void>>);
typedef _FXNValueCreateStringNative = Int32 Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateListNative = Int32 Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateDictNative = Int32 Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateImageNative = Int32 Function(Pointer<Void>, Int32, Int32, Int32, Int32, Pointer<Pointer<Void>>);
typedef _FXNValueCreateBinaryNative = Int32 Function(Pointer<Void>, Int32, Int32, Pointer<Pointer<Void>>);
typedef _FXNValueCreateSerializedValueNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateFromSerializedValueNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Pointer<Void>>);

typedef _FXNValueGetDataDart = int Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNValueGetTypeDart = int Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNValueGetDimensionsDart = int Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNValueGetShapeDart = int Function(Pointer<Void>, Pointer<Int32>, int);
typedef _FXNValueReleaseDart = int Function(Pointer<Void>);
typedef _FXNValueCreateNullDart = int Function(Pointer<Pointer<Void>>);
typedef _FXNValueCreateArrayDart = int Function(Pointer<Void>, Pointer<Int32>, int, int, int, Pointer<Pointer<Void>>);
typedef _FXNValueCreateStringDart = int Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateListDart = int Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateDictDart = int Function(Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateImageDart = int Function(Pointer<Void>, int, int, int, int, Pointer<Pointer<Void>>);
typedef _FXNValueCreateBinaryDart = int Function(Pointer<Void>, int, int, Pointer<Pointer<Void>>);
typedef _FXNValueCreateSerializedValueDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueCreateFromSerializedValueDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Pointer<Void>>);

/// Value flags.
class ValueFlags {
  static const int none = 0;
  static const int copyData = 1;
}

/// Native value.
class Value {
  // ignore: public_member_api_docs
  Pointer<Void> handle;
  final bool _owner;

  // Cached function pointers
  static final _getData = getFxnc().lookupFunction<_FXNValueGetDataNative, _FXNValueGetDataDart>("FXNValueGetData");
  static final _getType = getFxnc().lookupFunction<_FXNValueGetTypeNative, _FXNValueGetTypeDart>("FXNValueGetType");
  static final _getDimensions = getFxnc().lookupFunction<_FXNValueGetDimensionsNative, _FXNValueGetDimensionsDart>("FXNValueGetDimensions");
  static final _getShape = getFxnc().lookupFunction<_FXNValueGetShapeNative, _FXNValueGetShapeDart>("FXNValueGetShape");
  static final _releaseValue = getFxnc().lookupFunction<_FXNValueReleaseNative, _FXNValueReleaseDart>("FXNValueRelease");
  static final _createNull = getFxnc().lookupFunction<_FXNValueCreateNullNative, _FXNValueCreateNullDart>("FXNValueCreateNull");
  static final _createArray = getFxnc().lookupFunction<_FXNValueCreateArrayNative, _FXNValueCreateArrayDart>("FXNValueCreateArray");
  static final _createString = getFxnc().lookupFunction<_FXNValueCreateStringNative, _FXNValueCreateStringDart>("FXNValueCreateString");
  static final _createList = getFxnc().lookupFunction<_FXNValueCreateListNative, _FXNValueCreateListDart>("FXNValueCreateList");
  static final _createDict = getFxnc().lookupFunction<_FXNValueCreateDictNative, _FXNValueCreateDictDart>("FXNValueCreateDict");
  static final _createImage = getFxnc().lookupFunction<_FXNValueCreateImageNative, _FXNValueCreateImageDart>("FXNValueCreateImage");
  static final _createBinary = getFxnc().lookupFunction<_FXNValueCreateBinaryNative, _FXNValueCreateBinaryDart>("FXNValueCreateBinary");
  static final _createSerializedValue = getFxnc().lookupFunction<_FXNValueCreateSerializedValueNative, _FXNValueCreateSerializedValueDart>("FXNValueCreateSerializedValue");
  static final _createFromSerializedValue = getFxnc().lookupFunction<_FXNValueCreateFromSerializedValueNative, _FXNValueCreateFromSerializedValueDart>("FXNValueCreateFromSerializedValue");

  /// Create a [Value] from a native pointer.
  Value(this.handle, {bool owner = true}) : _owner = owner;

  /// Get the data pointer.
  Pointer<Void> get data {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _getData(handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get value data with error: ${statusToError(status)}");
      return ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get the data type.
  Dtype get dtype {
    final ptr = calloc<Int32>();
    try {
      final status = _getType(handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get value data type with error: ${statusToError(status)}");
      return _dtypeFromC(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get the tensor shape, or `null` if this is not a tensor-ish value.
  List<int>? get shape {
    if (!_tensorIshDtypes.contains(dtype))
      return null;
    final dimsPtr = calloc<Int32>();
    try {
      final status = _getDimensions(handle, dimsPtr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get value dimensions with error: ${statusToError(status)}");
      final dims = dimsPtr.value;
      final shapePtr = calloc<Int32>(dims);
      try {
        final status2 = _getShape(handle, shapePtr, dims);
        if (status2 != FXNStatus.ok.code)
          throw StateError("Failed to get value shape with error: ${statusToError(status2)}");
        return List.generate(dims, (i) => shapePtr[i]);
      } finally {
        calloc.free(shapePtr);
      }
    } finally {
      calloc.free(dimsPtr);
    }
  }

  /// Convert this value to a Dart object.
  Object? toObject() {
    final type = dtype;
    switch (type) {
      case Dtype.null_: return null;
      case Dtype.string:
        return data.cast<Utf8>().toDartString();
      case Dtype.list:
      case Dtype.dict:
        return jsonDecode(data.cast<Utf8>().toDartString());
      case Dtype.binary:
        return data.cast<Uint8>().asTypedList(shape![0]);
      case Dtype.image:
        final s = shape!;
        final height = s[0];
        final width = s[1];
        final channels = s[2];
        final elementCount = height * width * channels;
        return types.Image(
          Uint8List.fromList(data.cast<Uint8>().asTypedList(elementCount)),
          width,
          height,
          channels,
        );
      default:
        if (_tensorDtypes.contains(type)) {
          return _readTensorData(type, data, shape!);
        }
        throw StateError("Failed to convert value with type `${type.value}` to object because it is not supported");
    }
  }

  /// Serialize this value.
  Uint8List serialize({String? mime}) {
    final mimePtr = mime != null ? mime.toNativeUtf8() : nullptr;
    final valuePtr = calloc<Pointer<Void>>();
    try {
      final status = _createSerializedValue(handle, mimePtr.cast(), valuePtr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to serialize value with error: ${statusToError(status)}");
      final serialized = Value(valuePtr.value);
      try {
        final dataPtr = serialized.data;
        final lengthPtr = calloc<Int32>();
        try {
          _getShape(valuePtr.value, lengthPtr, 1);
          return Uint8List.fromList(dataPtr.cast<Uint8>().asTypedList(lengthPtr.value));
        } finally {
          calloc.free(lengthPtr);
        }
      } finally {
        serialized.release();
      }
    } finally {
      if (mime != null) calloc.free(mimePtr);
      calloc.free(valuePtr);
    }
  }

  /// Release the value.
  void release() {
    if (handle != nullptr && _owner)
      _releaseValue(handle);
    handle = nullptr;
  }

  /// Create a null value.
  static Value createNull() {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _createNull(ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create null value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Create a string value.
  static Value createString(String str) {
    final nativeStr = str.toNativeUtf8();
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _createString(nativeStr, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create string value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      calloc.free(nativeStr);
      calloc.free(ptr);
    }
  }

  /// Create a list value from a JSON-encoded list.
  static Value createList(List<Object?> list) {
    final json = jsonEncode(list);
    final nativeJson = json.toNativeUtf8();
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _createList(nativeJson, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create list value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      calloc.free(nativeJson);
      calloc.free(ptr);
    }
  }

  /// Create a dict value from a JSON-encoded map.
  static Value createDict(Map<String, Object?> dict) {
    final json = jsonEncode(dict);
    final nativeJson = json.toNativeUtf8();
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _createDict(nativeJson, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create dict value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      calloc.free(nativeJson);
      calloc.free(ptr);
    }
  }

  /// Create a binary value.
  static Value createBinary(Uint8List bytes, {int flags = ValueFlags.none}) {
    final nativeData = calloc<Uint8>(bytes.length);
    final ptr = calloc<Pointer<Void>>();
    try {
      nativeData.asTypedList(bytes.length).setAll(0, bytes);
      final status = _createBinary(nativeData.cast(), bytes.length, flags, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create binary value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      if (flags & ValueFlags.copyData == 0) {} else { calloc.free(nativeData); }
      calloc.free(ptr);
    }
  }

  /// Create an array value.
  static Value createArray(
    Pointer<Void> data,
    List<int> shape,
    Dtype dtype, {
    int flags = ValueFlags.none,
  }) {
    final shapePtr = calloc<Int32>(shape.length);
    final ptr = calloc<Pointer<Void>>();
    try {
      for (var i = 0; i < shape.length; i++)
        shapePtr[i] = shape[i];
      final status = _createArray(
        data,
        shapePtr,
        shape.length,
        _dtypeToC(dtype),
        flags,
        ptr
      );
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create array value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      calloc.free(shapePtr);
      calloc.free(ptr);
    }
  }

  /// Create an image value.
  static Value createImage(
    Pointer<Void> data,
    int width,
    int height,
    int channels, {
    int flags = ValueFlags.none,
  }) {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _createImage(data, width, height, channels, flags, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create image value with error: ${statusToError(status)}");
      return Value(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Create a value from serialized bytes.
  static Value fromBytes(Uint8List data, String mime) {
    final nativeData = calloc<Uint8>(data.length);
    nativeData.asTypedList(data.length).setAll(0, data);
    final serializedPtr = calloc<Pointer<Void>>();
    try {
      final status = _createBinary(
        nativeData.cast(),
        data.length,
        ValueFlags.none,
        serializedPtr
      );
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to deserialize value because wrapping data failed with error: ${statusToError(status)}");
      final mimePtr = mime.toNativeUtf8();
      final valuePtr = calloc<Pointer<Void>>();
      try {
        final status2 = _createFromSerializedValue(serializedPtr.value, mimePtr, valuePtr);
        _releaseValue(serializedPtr.value);
        if (status2 != FXNStatus.ok.code)
          throw StateError("Failed to deserialize value with error: ${statusToError(status2)}");
        return Value(valuePtr.value);
      } finally {
        calloc.free(mimePtr);
        calloc.free(valuePtr);
      }
    } finally {
      calloc.free(nativeData);
      calloc.free(serializedPtr);
    }
  }

  /// Create a [Value] from a Dart object.
  static Value fromObject(Object? obj, {int flags = ValueFlags.none}) {
    if (obj == null)
      return createNull();
    if (obj is Tensor)
      return _createTensor(obj, flags: flags);
    if (obj is types.Image) {
      final nativeData = calloc<Uint8>(obj.data.length);
      nativeData.asTypedList(obj.data.length).setAll(0, obj.data);
      final value = createImage(
        nativeData.cast(),
        obj.width,
        obj.height,
        obj.channels,
        flags: flags | ValueFlags.copyData,
      );
      calloc.free(nativeData);
      return value;
    }
    if (obj is String)
      return createString(obj);
    if (obj is List)
      return createList(obj.cast<Object?>());
    if (obj is Map<String, Object?>)
      return createDict(obj);
    if (obj is Uint8List)
      return createBinary(obj, flags: flags | ValueFlags.copyData);
    if (obj is double) {
      final data = calloc<Float>(1);
      data.value = obj;
      final value = createArray(
        data.cast(),
        [],
        Dtype.float32,
        flags: flags | ValueFlags.copyData,
      );
      calloc.free(data);
      return value;
    }
    if (obj is int) {
      final data = calloc<Int32>(1);
      data.value = obj;
      final value = createArray(
        data.cast(),
        [],
        Dtype.int32,
        flags: flags | ValueFlags.copyData,
      );
      calloc.free(data);
      return value;
    }
    if (obj is bool) {
      final data = calloc<Uint8>(1);
      data.value = obj ? 1 : 0;
      final value = createArray(
        data.cast(),
        [],
        Dtype.bool_,
        flags: flags | ValueFlags.copyData,
      );
      calloc.free(data);
      return value;
    }
    throw ArgumentError("Failed to convert object to prediction value because object has an unsupported type: ${obj.runtimeType}");
  }

  static Value _createTensor(Tensor tensor, {int flags = ValueFlags.none}) {
    final tensorData = tensor.data;
    final shape = tensor.shape;
    final elementCount = shape.fold(1, (a, b) => a * b);
    if (tensorData is Float32List) {
      final data = calloc<Float>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.float32,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Float64List) {
      final data = calloc<Double>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.float64,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Int8List) {
      final data = calloc<Int8>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.int8,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Int16List) {
      final data = calloc<Int16>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.int16,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Int32List) {
      final data = calloc<Int32>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.int32,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Int64List) {
      final data = calloc<Int64>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.int64,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Uint8List) {
      final data = calloc<Uint8>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.uint8,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Uint16List) {
      final data = calloc<Uint16>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.uint16,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Uint32List) {
      final data = calloc<Uint32>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.uint32,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    if (tensorData is Uint64List) {
      final data = calloc<Uint64>(elementCount);
      data.asTypedList(elementCount).setAll(0, tensorData);
      final value = createArray(
        data.cast(),
        shape,
        Dtype.uint64,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    // List<bool> -> bool
    if (tensorData is List<bool>) {
      final data = calloc<Uint8>(elementCount);
      for (var i = 0; i < elementCount; i++)
        data[i] = tensorData[i] ? 1 : 0;
      final value = createArray(
        data.cast(),
        shape,
        Dtype.bool_,
        flags: flags | ValueFlags.copyData,
      );
      calloc.free(data);
      return value;
    }
    // Fallback: List<double> -> float32
    if (tensorData is List<double>) {
      final data = calloc<Float>(elementCount);
      for (var i = 0; i < elementCount; i++)
        data[i] = tensorData[i];
      final value = createArray(
        data.cast(),
        shape,
        Dtype.float32,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    // Fallback: List<int> -> int32
    if (tensorData is List<int>) {
      final data = calloc<Int32>(elementCount);
      for (var i = 0; i < elementCount; i++)
        data[i] = tensorData[i];
      final value = createArray(
        data.cast(),
        shape, Dtype.int32,
        flags: flags | ValueFlags.copyData
      );
      calloc.free(data);
      return value;
    }
    throw ArgumentError("Unsupported tensor data type: ${tensorData.runtimeType}");
  }
}

Object _readTensorData(
  Dtype dtype,
  Pointer<Void> data,
  List<int> shape
) {
  final elementCount = shape.fold(1, (a, b) => a * b);
  switch (dtype) {
    case Dtype.float32:
      final result = Float32List.fromList(data.cast<Float>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<double>(result, shape);
    case Dtype.float64:
      final result = Float64List.fromList(data.cast<Double>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<double>(result, shape);
    case Dtype.int8:
      final result = Int8List.fromList(data.cast<Int8>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.int16:
      final result = Int16List.fromList(data.cast<Int16>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.int32:
      final result = Int32List.fromList(data.cast<Int32>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.int64:
      final result = Int64List.fromList(data.cast<Int64>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.uint8:
      final result = Uint8List.fromList(data.cast<Uint8>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.uint16:
      final result = Uint16List.fromList(data.cast<Uint16>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.uint32:
      final result = Uint32List.fromList(data.cast<Uint32>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.uint64:
      final result = Uint64List.fromList(data.cast<Uint64>().asTypedList(elementCount));
      return elementCount == 1 ? result[0] : Tensor<int>(result, shape);
    case Dtype.bool_:
      final raw = data.cast<Uint8>().asTypedList(elementCount);
      if (elementCount == 1) return raw[0] != 0;
      return Tensor<bool>(raw.map((e) => e != 0).toList(), shape);
    default:
      throw StateError("Unsupported tensor dtype: ${dtype.value}");
  }
}

/// Dtype integer mapping (C enum values).
int _dtypeToC(Dtype type) {
  switch (type) {
    case Dtype.null_:     return 0;
    case Dtype.float16:   return 1;
    case Dtype.float32:   return 2;
    case Dtype.float64:   return 3;
    case Dtype.int8:      return 4;
    case Dtype.int16:     return 5;
    case Dtype.int32:     return 6;
    case Dtype.int64:     return 7;
    case Dtype.uint8:     return 8;
    case Dtype.uint16:    return 9;
    case Dtype.uint32:    return 10;
    case Dtype.uint64:    return 11;
    case Dtype.bool_:     return 12;
    case Dtype.string:    return 13;
    case Dtype.list:      return 14;
    case Dtype.dict:      return 15;
    case Dtype.image:     return 16;
    case Dtype.binary:    return 17;
    case Dtype.bfloat16:  return 18;
    case Dtype.imageList: return 19;
  }
}

Dtype _dtypeFromC(int type) {
  switch (type) {
    case 0:  return Dtype.null_;
    case 1:  return Dtype.float16;
    case 2:  return Dtype.float32;
    case 3:  return Dtype.float64;
    case 4:  return Dtype.int8;
    case 5:  return Dtype.int16;
    case 6:  return Dtype.int32;
    case 7:  return Dtype.int64;
    case 8:  return Dtype.uint8;
    case 9:  return Dtype.uint16;
    case 10: return Dtype.uint32;
    case 11: return Dtype.uint64;
    case 12: return Dtype.bool_;
    case 13: return Dtype.string;
    case 14: return Dtype.list;
    case 15: return Dtype.dict;
    case 16: return Dtype.image;
    case 17: return Dtype.binary;
    case 18: return Dtype.bfloat16;
    case 19: return Dtype.imageList;
    default: throw ArgumentError("Unsupported C dtype: $type");
  }
}

/// Tensor-like dtypes.
const _tensorDtypes = {
  Dtype.bfloat16, Dtype.float16, Dtype.float32, Dtype.float64,
  Dtype.int8, Dtype.int16, Dtype.int32, Dtype.int64,
  Dtype.uint8, Dtype.uint16, Dtype.uint32, Dtype.uint64,
  Dtype.bool_,
};

const _tensorIshDtypes = {
  ..._tensorDtypes,
  Dtype.image,
  Dtype.binary,
};
