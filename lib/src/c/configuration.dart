//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:ffi";
import "package:ffi/ffi.dart";
import "../types/prediction.dart";
import "fxnc.dart";

typedef _FXNConfigurationCreateNative = Int32 Function(Pointer<Pointer<Void>>);
typedef _FXNConfigurationReleaseNative = Int32 Function(Pointer<Void>);
typedef _FXNConfigurationGetTagNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef _FXNConfigurationSetTagNative = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef _FXNConfigurationGetTokenNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef _FXNConfigurationSetTokenNative = Int32 Function(Pointer<Void>, Pointer<Utf8>);
typedef _FXNConfigurationGetAccelerationNative = Int32 Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNConfigurationSetAccelerationNative = Int32 Function(Pointer<Void>, Int32);
typedef _FXNConfigurationGetDeviceNative = Int32 Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNConfigurationSetDeviceNative = Int32 Function(Pointer<Void>, Pointer<Void>);
typedef _FXNConfigurationAddResourceNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _FXNConfigurationGetUniqueIDNative = Int32 Function(Pointer<Utf8>, Int32);
typedef _FXNConfigurationGetClientIDNative = Int32 Function(Pointer<Utf8>, Int32);

typedef _FXNConfigurationCreateDart = int Function(Pointer<Pointer<Void>>);
typedef _FXNConfigurationReleaseDart = int Function(Pointer<Void>);
typedef _FXNConfigurationGetTagDart = int Function(Pointer<Void>, Pointer<Utf8>, int);
typedef _FXNConfigurationSetTagDart = int Function(Pointer<Void>, Pointer<Utf8>);
typedef _FXNConfigurationGetTokenDart = int Function(Pointer<Void>, Pointer<Utf8>, int);
typedef _FXNConfigurationSetTokenDart = int Function(Pointer<Void>, Pointer<Utf8>);
typedef _FXNConfigurationGetAccelerationDart = int Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNConfigurationSetAccelerationDart = int Function(Pointer<Void>, int);
typedef _FXNConfigurationGetDeviceDart = int Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNConfigurationSetDeviceDart = int Function(Pointer<Void>, Pointer<Void>);
typedef _FXNConfigurationAddResourceDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>);
typedef _FXNConfigurationGetUniqueIDDart = int Function(Pointer<Utf8>, int);
typedef _FXNConfigurationGetClientIDDart = int Function(Pointer<Utf8>, int);

/// Prediction configuration.
class Configuration {
  // ignore: public_member_api_docs
  Pointer<Void> handle;

  // Cached function pointers
  static final _create = getFxnc().lookupFunction<_FXNConfigurationCreateNative, _FXNConfigurationCreateDart>("FXNConfigurationCreate");
  static final _release = getFxnc().lookupFunction<_FXNConfigurationReleaseNative, _FXNConfigurationReleaseDart>("FXNConfigurationRelease");
  static final _getTag = getFxnc().lookupFunction<_FXNConfigurationGetTagNative, _FXNConfigurationGetTagDart>("FXNConfigurationGetTag");
  static final _setTag = getFxnc().lookupFunction<_FXNConfigurationSetTagNative, _FXNConfigurationSetTagDart>("FXNConfigurationSetTag");
  static final _getToken = getFxnc().lookupFunction<_FXNConfigurationGetTokenNative, _FXNConfigurationGetTokenDart>("FXNConfigurationGetToken");
  static final _setToken = getFxnc().lookupFunction<_FXNConfigurationSetTokenNative, _FXNConfigurationSetTokenDart>("FXNConfigurationSetToken");
  static final _getAcceleration = getFxnc().lookupFunction<_FXNConfigurationGetAccelerationNative, _FXNConfigurationGetAccelerationDart>("FXNConfigurationGetAcceleration");
  static final _setAcceleration = getFxnc().lookupFunction<_FXNConfigurationSetAccelerationNative, _FXNConfigurationSetAccelerationDart>("FXNConfigurationSetAcceleration");
  static final _getDevice = getFxnc().lookupFunction<_FXNConfigurationGetDeviceNative, _FXNConfigurationGetDeviceDart>("FXNConfigurationGetDevice");
  static final _setDevice = getFxnc().lookupFunction<_FXNConfigurationSetDeviceNative, _FXNConfigurationSetDeviceDart>("FXNConfigurationSetDevice");
  static final _addResource = getFxnc().lookupFunction<_FXNConfigurationAddResourceNative, _FXNConfigurationAddResourceDart>("FXNConfigurationAddResource");
  static final _getUniqueID = getFxnc().lookupFunction<_FXNConfigurationGetUniqueIDNative, _FXNConfigurationGetUniqueIDDart>("FXNConfigurationGetUniqueID");
  static final _getClientID = getFxnc().lookupFunction<_FXNConfigurationGetClientIDNative, _FXNConfigurationGetClientIDDart>("FXNConfigurationGetClientID");

  /// Create a [Configuration].
  Configuration() : handle = nullptr {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _create(ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create configuration with error: ${statusToError(status)}");
      handle = ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get the predictor tag.
  String? get tag {
    final buffer = calloc<Uint8>(2048).cast<Utf8>();
    try {
      final status = _getTag(handle, buffer, 2048);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get configuration tag with error: ${statusToError(status)}");
      final tag = buffer.toDartString();
      return tag.isNotEmpty ? tag : null;
    } finally {
      calloc.free(buffer);
    }
  }

  /// Set the predictor tag.
  set tag(String? value) {
    final tag = value != null ? value.toNativeUtf8() : nullptr;
    try {
      final status = _setTag(handle, tag.cast());
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to set configuration tag with error: ${statusToError(status)}");
    } finally {
      if (value != null) calloc.free(tag);
    }
  }

  /// Get the configuration token.
  String? get token {
    final buffer = calloc<Uint8>(2048).cast<Utf8>();
    try {
      final status = _getToken(handle, buffer, 2048);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get configuration token with error: ${statusToError(status)}");
      final token = buffer.toDartString();
      return token.isNotEmpty ? token : null;
    } finally {
      calloc.free(buffer);
    }
  }

  /// Set the configuration token.
  set token(String? value) {
    final token = value != null ? value.toNativeUtf8() : nullptr;
    try {
      final status = _setToken(handle, token.cast());
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to set configuration token with error: ${statusToError(status)}");
    } finally {
      if (value != null) calloc.free(token);
    }
  }

  /// Get the acceleration.
  Acceleration get acceleration {
    final ptr = calloc<Int32>();
    try {
      final status = _getAcceleration(handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get configuration acceleration with error: ${statusToError(status)}");
      return _toAcceleration(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Set the acceleration.
  set acceleration(Acceleration value) {
    final status = _setAcceleration(handle, _fromAcceleration(value));
    if (status != FXNStatus.ok.code)
      throw StateError("Failed to set configuration acceleration with error: ${statusToError(status)}");
  }

  /// Get the device pointer.
  Pointer<Void> get device {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _getDevice(handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get configuration device with error: ${statusToError(status)}");
      return ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Set the device pointer.
  set device(Pointer<Void>? value) {
    final status = _setDevice(handle, value ?? nullptr);
    if (status != FXNStatus.ok.code)
      throw StateError("Failed to set configuration device with error: ${statusToError(status)}");
  }

  /// Add a resource to the configuration.
  void addResource(String type, String path) {
    final nativeType = type.toNativeUtf8();
    final nativePath = path.toNativeUtf8();
    try {
      final status = _addResource(handle, nativeType, nativePath);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to add configuration resource with error: ${statusToError(status)}");
    } finally {
      calloc.free(nativeType);
      calloc.free(nativePath);
    }
  }

  /// Release the configuration.
  void release() {
    if (handle != nullptr)
      _release(handle);
    handle = nullptr;
  }

  /// Get the unique configuration ID.
  static String getUniqueId() {
    final buffer = calloc<Uint8>(2048).cast<Utf8>();
    try {
      final status = _getUniqueID(buffer, 2048);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to retrieve configuration identifier with error: ${statusToError(status)}");
      return buffer.toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  /// Get the client ID.
  static String getClientId() {
    final buffer = calloc<Uint8>(64).cast<Utf8>();
    try {
      final status = _getClientID(buffer, 64);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to retrieve client identifier with error: ${statusToError(status)}");
      return buffer.toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  static Acceleration _toAcceleration(int value) {
    switch (value) {
      case 0:   return Acceleration.localAuto;
      case 1:   return Acceleration.localCpu;
      case 2:   return Acceleration.localGpu;
      case 4:   return Acceleration.localNpu;
      default:  return Acceleration.localAuto;
    }
  }

  static int _fromAcceleration(Acceleration value) {
    switch (value) {
      case Acceleration.localAuto: return 0;
      case Acceleration.localCpu:  return 1;
      case Acceleration.localGpu:  return 2;
      case Acceleration.localNpu:  return 4;
    }
  }
}
