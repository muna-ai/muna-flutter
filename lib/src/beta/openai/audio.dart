//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../remote/remote.dart";
import "speech.dart";
import "transcription.dart";

/// Audio service.
class AudioService {
  /// Speech generation.
  final SpeechService speech;

  /// Audio transcription.
  final TranscriptionService transcriptions;

  /// Create an [AudioService].
  AudioService(
    PredictorService predictors,
    PredictionService predictions,
    RemotePredictionService remotePredictions,
  ) : speech = SpeechService(predictors, predictions, remotePredictions),
      transcriptions = TranscriptionService(predictors, predictions, remotePredictions);
}
