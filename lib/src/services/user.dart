//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../client.dart";
import "../types/user.dart";

/// Manage users.
class UserService {
  final MunaClient _client;

  /// Create a [UserService].
  UserService(this._client);

  /// Retrieve the current user.
  ///
  /// Returns the [User], or `null` if the access key is invalid.
  Future<User?> retrieve() async {
    try {
      return await _client.request(
        method: "GET",
        path: "/users",
        fromJson: User.fromJson,
      );
    } on MunaAPIError catch (error) {
      if (error.statusCode == 401)
        return null;
      rethrow;
    }
  }
}