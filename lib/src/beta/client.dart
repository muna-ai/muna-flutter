//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../client.dart";
import "../services/prediction.dart";
import "../services/predictor.dart";
import "openai/openai.dart";
import "remote/prediction.dart" as beta;
import "remote/remote.dart";

/// Client for incubating features.
class BetaClient {
  /// Make predictions.
  final beta.PredictionService predictions;

  /// OpenAI-compatible client.
  final OpenAIClient openai;

  /// Create a [BetaClient].
  BetaClient(
    MunaClient client,
    PredictorService predictors,
    PredictionService predictions,
  ) : predictions = beta.PredictionService(client),
      openai = OpenAIClient(
        predictors,
        predictions,
        RemotePredictionService(client),
      );
}
