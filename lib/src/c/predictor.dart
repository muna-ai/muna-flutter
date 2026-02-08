//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:ffi";
import "package:ffi/ffi.dart";
import "configuration.dart";
import "fxnc.dart";
import "map.dart";
import "prediction.dart";
import "stream.dart";

typedef _FXNPredictorCreateNative = Int32 Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictorReleaseNative = Int32 Function(Pointer<Void>);
typedef _FXNPredictorCreatePredictionNative = Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictorStreamPredictionNative = Int32 Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Void>>);

typedef _FXNPredictorCreateDart = int Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictorReleaseDart = int Function(Pointer<Void>);
typedef _FXNPredictorCreatePredictionDart = int Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictorStreamPredictionDart = int Function(Pointer<Void>, Pointer<Void>, Pointer<Pointer<Void>>);

/// Native predictor.
class Predictor {
  Pointer<Void> _predictor;

  static final _create = getFxnc().lookupFunction<_FXNPredictorCreateNative, _FXNPredictorCreateDart>("FXNPredictorCreate");
  static final _release = getFxnc().lookupFunction<_FXNPredictorReleaseNative, _FXNPredictorReleaseDart>("FXNPredictorRelease");
  static final _createPrediction = getFxnc().lookupFunction<_FXNPredictorCreatePredictionNative, _FXNPredictorCreatePredictionDart>("FXNPredictorCreatePrediction");
  static final _streamPrediction = getFxnc().lookupFunction<_FXNPredictorStreamPredictionNative, _FXNPredictorStreamPredictionDart>("FXNPredictorStreamPrediction");

  /// Create a [Predictor] from a [Configuration].
  Predictor(Configuration configuration) : _predictor = nullptr {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _create(configuration.handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create predictor with error: ${statusToError(status)}");
      _predictor = ptr.value;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Create a prediction.
  Prediction createPrediction(ValueMap inputs) {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _createPrediction(_predictor, inputs.handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to create prediction with error: ${statusToError(status)}");
      return Prediction(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Stream a prediction.
  PredictionStream streamPrediction(ValueMap inputs) {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _streamPrediction(_predictor, inputs.handle, ptr);
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to stream prediction with error: ${statusToError(status)}");
      return PredictionStream(ptr.value);
    } finally {
      calloc.free(ptr);
    }
  }

  /// Release the predictor.
  void release() {
    if (_predictor != nullptr)
      _release(_predictor);
    _predictor = nullptr;
  }
}
