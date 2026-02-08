//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../remote/remote.dart";
import "audio.dart";
import "chat.dart";
import "embeddings.dart";

/// Experimental client mimicking the official OpenAI client.
class OpenAIClient {
  /// Chat service.
  final ChatService chat;

  /// Embeddings service.
  final EmbeddingService embeddings;

  /// Audio service.
  final AudioService audio;

  /// Create an [OpenAIClient].
  OpenAIClient(
    PredictorService predictors,
    PredictionService predictions,
    RemotePredictionService remotePredictions,
  ) : chat = ChatService(predictors, predictions, remotePredictions),
      embeddings = EmbeddingService(predictors, predictions, remotePredictions),
      audio = AudioService(predictors, predictions, remotePredictions);
}
