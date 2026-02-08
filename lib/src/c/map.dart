//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:ffi";
import "package:ffi/ffi.dart";
import "fxnc.dart";
import "value.dart";

typedef _FXNValueMapCreateNative = Int32 Function(Pointer<Pointer<Void>>);
typedef _FXNValueMapReleaseNative = Int32 Function(Pointer<Void>);
typedef _FXNValueMapGetSizeNative = Int32 Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNValueMapGetKeyNative = Int32 Function(Pointer<Void>, Int32, Pointer<Utf8>, Int32);
typedef _FXNValueMapGetValueNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueMapSetValueNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Void>);

typedef _FXNValueMapCreateDart = int Function(Pointer<Pointer<Void>>);
typedef _FXNValueMapReleaseDart = int Function(Pointer<Void>);
typedef _FXNValueMapGetSizeDart = int Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNValueMapGetKeyDart = int Function(Pointer<Void>, int, Pointer<Utf8>, int);
typedef _FXNValueMapGetValueDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Pointer<Void>>);
typedef _FXNValueMapSetValueDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Void>);

/// Native value map.
class ValueMap {
  // ignore: public_member_api_docs
  Pointer<Void> handle;
  final bool _owner;

  // Cached function pointers
  static final _create = getFxnc().lookupFunction<_FXNValueMapCreateNative, _FXNValueMapCreateDart>("FXNValueMapCreate");
  static final _release = getFxnc().lookupFunction<_FXNValueMapReleaseNative, _FXNValueMapReleaseDart>("FXNValueMapRelease");
  static final _getSize = getFxnc().lookupFunction<_FXNValueMapGetSizeNative, _FXNValueMapGetSizeDart>("FXNValueMapGetSize");
  static final _getKey = getFxnc().lookupFunction<_FXNValueMapGetKeyNative, _FXNValueMapGetKeyDart>("FXNValueMapGetKey");
  static final _getValue = getFxnc().lookupFunction<_FXNValueMapGetValueNative, _FXNValueMapGetValueDart>("FXNValueMapGetValue");
  static final _setValue = getFxnc().lookupFunction<_FXNValueMapSetValueNative, _FXNValueMapSetValueDart>("FXNValueMapSetValue");

  /// Create an empty [ValueMap].
  ValueMap() : handle = nullptr, _owner = true {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _create(ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create value map with error: ${statusToError(status)}");
      handle = ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Create a [ValueMap] from a native pointer.
  ValueMap.fromPointer(this.handle, {bool owner = true}) : _owner = owner;

  /// Get the number of entries in the map.
  int get length {
    final ptr = calloc<Int32>();
    try {
      final status = _getSize(handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get value map size with error: ${statusToError(status)}");
      return ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get the key at a given index.
  String key(int index) {
    final buffer = calloc<Uint8>(256).cast<Utf8>();
    try {
      final status = _getKey(handle, index, buffer, 256);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get value map key at index $index with error: ${statusToError(status)}");
      return buffer.toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  /// Get the value for a given key.
  Value operator [](String key) {
    final nativeKey = key.toNativeUtf8();
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _getValue(handle, nativeKey, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get value map value for key '$key' with error: ${statusToError(status)}");
      return Value(ptr.value, owner: false);
    } finally {
      calloc.free(nativeKey);
      calloc.free(ptr);
    }
  }

  /// Set the value for a given key.
  void operator []=(String key, Value value) {
    final nativeKey = key.toNativeUtf8();
    try {
      final status = _setValue(handle, nativeKey, value.handle);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to set value map value for key '$key' with error: ${statusToError(status)}");
    } finally {
      calloc.free(nativeKey);
    }
  }

  /// Release the value map.
  void release() {
    if (handle != nullptr && _owner)
      _release(handle);
    handle = nullptr;
  }

  /// Create a [ValueMap] from a [Map] of Dart objects.
  static ValueMap fromDict(Map<String, Object?> inputs) {
    final map = ValueMap();
    for (final entry in inputs.entries)
      map[entry.key] = Value.fromObject(entry.value);
    return map;
  }
}
