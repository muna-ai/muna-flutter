//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:ffi";
import "package:ffi/ffi.dart";
import "fxnc.dart";
import "prediction.dart";

typedef _FXNPredictionStreamReadNextNative = Int32 Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictionStreamReleaseNative = Int32 Function(Pointer<Void>);

typedef _FXNPredictionStreamReadNextDart = int Function(Pointer<Void>, Pointer<Pointer<Void>>);
typedef _FXNPredictionStreamReleaseDart = int Function(Pointer<Void>);

/// Native prediction stream.
class PredictionStream implements Iterator<Prediction> {
  Pointer<Void> _stream;
  Prediction? _current;

  static final _readNext = getFxnc().lookupFunction<_FXNPredictionStreamReadNextNative, _FXNPredictionStreamReadNextDart>("FXNPredictionStreamReadNext");
  static final _release = getFxnc().lookupFunction<_FXNPredictionStreamReleaseNative, _FXNPredictionStreamReleaseDart>("FXNPredictionStreamRelease");

  /// Create a [PredictionStream] from a native pointer.
  PredictionStream(this._stream);

  @override
  Prediction get current => _current!;

  @override
  bool moveNext() {
    final ptr = calloc<Pointer<Void>>();
    try {
      final status = _readNext(_stream, ptr);
      if (status == FXNStatus.errorInvalidOperation.code)
        return false;
      if (status != FXNStatus.ok.code)
        throw StateError("Failed to read next prediction in stream with error: ${statusToError(status)}");
      _current = Prediction(ptr.value);
      return true;
    } finally {
      calloc.free(ptr);
    }
  }

  /// Release the stream.
  void release() {
    if (_stream != nullptr)
      _release(_stream);
    _stream = nullptr;
  }
}
