//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../client.dart";
import "../types/predictor.dart";

/// Manage predictors.
class PredictorService {
  final MunaClient _client;

  /// Create a [PredictorService].
  PredictorService(this._client);

  /// Retrieve a predictor.
  ///
  /// [tag] is the predictor tag.
  ///
  /// Returns the [Predictor], or `null` if the predictor was not found.
  Future<Predictor?> retrieve(String tag) async {
    try {
      return await _client.request(
        method: "GET",
        path: "/predictors/$tag",
        fromJson: Predictor.fromJson,
      );
    } on MunaAPIError catch (error) {
      if (error.statusCode == 404)
        return null;
      rethrow;
    }
  }
}