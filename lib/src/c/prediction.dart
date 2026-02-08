//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:ffi";
import "package:ffi/ffi.dart";
import "fxnc.dart";
import "map.dart";

typedef _FXNPredictionGetIDNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef _FXNPredictionGetLatencyNative = Int32 Function(Pointer<Void>, Pointer<Double>);
typedef _FXNPredictionGetResultsNative = Int32 Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictionGetErrorNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef _FXNPredictionGetLogLengthNative = Int32 Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNPredictionGetLogsNative = Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32);
typedef _FXNPredictionReleaseNative = Int32 Function(Pointer<Void>);

typedef _FXNPredictionGetIDDart = int Function(Pointer<Void>, Pointer<Utf8>, int);
typedef _FXNPredictionGetLatencyDart = int Function(Pointer<Void>, Pointer<Double>);
typedef _FXNPredictionGetResultsDart = int Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictionGetErrorDart = int Function(Pointer<Void>, Pointer<Utf8>, int);
typedef _FXNPredictionGetLogLengthDart = int Function(Pointer<Void>, Pointer<Int32>);
typedef _FXNPredictionGetLogsDart = int Function(Pointer<Void>, Pointer<Utf8>, int);
typedef _FXNPredictionReleaseDart = int Function(Pointer<Void>);

/// Native prediction.
class Prediction {
  Pointer<Void> _prediction;

  // Cached function pointers
  static final _getID = getFxnc().lookupFunction<_FXNPredictionGetIDNative, _FXNPredictionGetIDDart>("FXNPredictionGetID");
  static final _getLatency = getFxnc().lookupFunction<_FXNPredictionGetLatencyNative, _FXNPredictionGetLatencyDart>("FXNPredictionGetLatency");
  static final _getResults = getFxnc().lookupFunction<_FXNPredictionGetResultsNative, _FXNPredictionGetResultsDart>("FXNPredictionGetResults");
  static final _getError = getFxnc().lookupFunction<_FXNPredictionGetErrorNative, _FXNPredictionGetErrorDart>("FXNPredictionGetError");
  static final _getLogLength = getFxnc().lookupFunction<_FXNPredictionGetLogLengthNative, _FXNPredictionGetLogLengthDart>("FXNPredictionGetLogLength");
  static final _getLogs = getFxnc().lookupFunction<_FXNPredictionGetLogsNative, _FXNPredictionGetLogsDart>("FXNPredictionGetLogs");
  static final _release = getFxnc().lookupFunction<_FXNPredictionReleaseNative, _FXNPredictionReleaseDart>("FXNPredictionRelease");

  /// Create a [Prediction] from a native pointer.
  Prediction(this._prediction);

  /// Get the prediction ID.
  String get id {
    final buffer = calloc<Uint8>(256).cast<Utf8>();
    try {
      final status = _getID(_prediction, buffer, 256);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get prediction id with error: ${statusToError(status)}");
      return buffer.toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  /// Get the prediction latency in milliseconds.
  double get latency {
    final ptr = calloc<Double>();
    try {
      final status = _getLatency(_prediction, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get prediction latency with error: ${statusToError(status)}");
      return ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get the prediction results.
  ///
  /// Returns `null` if there are no results.
  ValueMap? get results {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _getResults(_prediction, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get prediction results with error: ${statusToError(status)}");
      final map = ValueMap.fromPointer(ptr.value, owner: false);
      return map.length > 0 ? map : null;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Get the prediction error, or `null` if successful.
  String? get error {
    final buffer = calloc<Uint8>(2048).cast<Utf8>();
    try {
      _getError(_prediction, buffer, 2048);
      final error = buffer.toDartString();
      return error.isNotEmpty ? error : null;
    } finally {
      calloc.free(buffer);
    }
  }

  /// Get the prediction logs.
  String get logs {
    final lengthPtr = calloc<Int32>();
    try {
      final status = _getLogLength(_prediction, lengthPtr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to get prediction log length with error: ${statusToError(status)}");
      final logLength = lengthPtr.value + 1;
      final buffer = calloc<Uint8>(logLength).cast<Utf8>();
      try {
        final status2 = _getLogs(_prediction, buffer, logLength);
        if (status2 != FXNStatus.ok.code)
          throw StateError("Failed to get prediction logs with error: ${statusToError(status2)}");
        return buffer.toDartString();
      } finally {
        calloc.free(buffer);
      }
    } finally {
      calloc.free(lengthPtr);
    }
  }

  /// Release the prediction.
  void release() {
    if (_prediction != nullptr)
      _release(_prediction);
    _prediction = nullptr;
  }
}
