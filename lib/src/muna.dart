//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:io";

import "beta/client.dart";
import "client.dart";
import "services/prediction.dart";
import "services/predictor.dart";
import "services/user.dart";

/// Muna client.
class Muna {
  /// Muna API client.
  ///
  /// Do NOT use this unless you know what you are doing.
  final MunaClient client;

  /// Manage users.
  final UserService users;

  /// Manage predictors.
  final PredictorService predictors;

  /// Manage predictions.
  final PredictionService predictions;

  /// Beta client for incubating features.
  final BetaClient beta;

  /// Create a [Muna] client.
  ///
  /// [accessKey] is your Muna access key.
  ///
  /// [apiUrl] is the Muna API URL.
  factory Muna({
    String? accessKey,
    String? apiUrl,
  }) {
    final resolvedAccessKey = accessKey ??
      Platform.environment["MUNA_ACCESS_KEY"] ??
      Platform.environment["FXN_ACCESS_KEY"];
    final resolvedApiUrl = apiUrl ??
      Platform.environment["MUNA_API_URL"] ??
      Platform.environment["FXN_API_URL"];
    final client = MunaClient(resolvedAccessKey, resolvedApiUrl);
    return Muna._(client);
  }

  Muna._(this.client)
    : users = UserService(client),
      predictors = PredictorService(client),
      predictions = PredictionService(client),
      beta = BetaClient(
        client,
        PredictorService(client),
        PredictionService(client),
      );
}