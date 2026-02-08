//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

/// Muna user profile.
class User {
  /// Username.
  final String username;

  /// User email address.
  final String? email;

  /// Date created.
  final String? created;

  /// User display name.
  final String? name;

  /// User avatar URL.
  final String? avatar;

  /// User bio.
  final String? bio;

  /// User website.
  final String? website;

  /// User GitHub handle.
  final String? github;

  /// Create a [User].
  const User({
    required this.username,
    this.email,
    this.created,
    this.name,
    this.avatar,
    this.bio,
    this.website,
    this.github,
  });

  /// Create a [User] from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => User(
    username: json["username"] as String,
    email: json["email"] as String?,
    created: json["created"] as String?,
    name: json["name"] as String?,
    avatar: json["avatar"] as String?,
    bio: json["bio"] as String?,
    website: json["website"] as String?,
    github: json["github"] as String?,
  );

  /// Serialize to a JSON map.
  Map<String, dynamic> toJson() => {
    "username": username,
    if (email != null) "email": email,
    if (created != null) "created": created,
    if (name != null) "name": name,
    if (avatar != null) "avatar": avatar,
    if (bio != null) "bio": bio,
    if (website != null) "website": website,
    if (github != null) "github": github,
  };

  @override
  String toString() => "User(username: $username)";
}