//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:typed_data";

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../remote/remote.dart";
import "schema.dart";

/// Transcription service.
///
/// This service is currently incomplete.
class TranscriptionService {
  // ignore: unused_field
  final PredictorService _predictors;
  // ignore: unused_field
  final PredictionService _predictions;
  // ignore: unused_field
  final RemotePredictionService _remotePredictions;

  /// Create a [TranscriptionService].
  TranscriptionService(
    this._predictors,
    this._predictions,
    this._remotePredictions,
  );

  /// Transcribe audio into the input language.
  ///
  /// [file] is the audio file bytes to transcribe.
  /// [model] is the transcription model tag.
  /// [language] is the language of the input audio.
  /// [prompt] is text to guide the model's style.
  /// [temperature] is the sampling temperature (0 to 1).
  /// [acceleration] is the prediction acceleration.
  Future<Transcription> create({
    required Uint8List file,
    required String model,
    String? language,
    String? prompt,
    double temperature = 0.0,
    String acceleration = "local_auto",
  }) async {
    // INCOMPLETE
    throw UnimplementedError("Transcription is not yet implemented");
  }
}
