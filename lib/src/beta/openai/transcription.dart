//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../../types/dtype.dart";
import "../../types/tensor.dart";
import "../remote/remote.dart";
import "../remote/types.dart";
import "schema.dart";
import "util.dart";

typedef _TranscriptionDelegate = Future<Transcription> Function({
  required Tensor audio,
  required String model,
  required String acceleration,
});

/// Transcription service.
class TranscriptionService {
  final PredictorService _predictors;
  final PredictionService _predictions;
  final RemotePredictionService _remotePredictions;
  final Map<String, _TranscriptionDelegate> _cache = {};

  /// Create a [TranscriptionService].
  TranscriptionService(
    this._predictors,
    this._predictions,
    this._remotePredictions,
  );

  /// Transcribe audio.
  ///
  /// [audio] is the audio tensor to transcribe (float32, mono, typically 16kHz).
  /// [model] is the transcription model tag.
  /// [acceleration] is the prediction acceleration.
  Future<Transcription> create({
    required Tensor audio,
    required String model,
    String? language,
    String? prompt,
    double temperature = 0.0,
    String acceleration = "local_auto",
  }) async {
    if (!_cache.containsKey(model)) {
      _cache[model] = await _createDelegate(model);
    }
    return _cache[model]!(
      audio: audio,
      model: model,
      acceleration: acceleration,
    );
  }

  Future<_TranscriptionDelegate> _createDelegate(String tag) async {
    final predictor = await _predictors.retrieve(tag);
    if (predictor == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI transcription API because "
        "the predictor could not be found.",
      );
    }
    final signature = predictor.signature;
    final (_, audioParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.float32},
      denotation: "audio",
    );
    final inputName = audioParam?.name ??
        getParameter(signature.inputs, dtype: {Dtype.float32}).$2?.name;
    if (inputName == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI transcription API because "
        "it does not have a float32 audio input parameter.",
      );
    }
    return ({
      required Tensor audio,
      required String model,
      required String acceleration,
    }) async {
      final prediction = acceleration.startsWith("remote_")
          ? await _remotePredictions.create(
              model,
              inputs: {inputName: audio},
              acceleration: RemoteAcceleration.fromValue(acceleration),
            )
          : await _predictions.create(model, inputs: {inputName: audio});
      if (prediction.error != null) {
        throw StateError(prediction.error!);
      }
      final text = prediction.results?[0] as String? ?? "";
      return Transcription(text: text);
    };
  }
}
