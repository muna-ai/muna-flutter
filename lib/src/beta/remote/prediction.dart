//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../client.dart";
import "remote.dart";

/// Make predictions.
class PredictionService {

  /// Make remote predictions.
  final RemotePredictionService remote;

  /// Create a [PredictionService].
  PredictionService(MunaClient client)
    : remote = RemotePredictionService(client);
}
