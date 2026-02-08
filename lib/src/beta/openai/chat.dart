//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../remote/remote.dart";
import "completions.dart";

/// Chat service.
class ChatService {
  /// Chat completions.
  final ChatCompletionService completions;

  /// Create a [ChatService].
  ChatService(
    PredictorService predictors,
    PredictionService predictions,
    RemotePredictionService remotePredictions,
  ) : completions = ChatCompletionService(
    predictors,
    predictions,
    remotePredictions,
  );
}
