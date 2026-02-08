//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:crypto/crypto.dart";
import "package:http/http.dart" as http;

/// Muna API error.
class MunaAPIError implements Exception {
  /// Error message.
  final String message;

  /// HTTP status code.
  final int statusCode;

  /// Create a [MunaAPIError].
  const MunaAPIError(this.message, this.statusCode);

  @override
  String toString() => "$message (Status Code: $statusCode)";
}

/// Resource CDN base URL.
const _resourceUrlBase = "https://cdn.fxn.ai/resources";

/// Muna API client.
///
/// This handles HTTP communication with the Muna API.
/// Do NOT use this directly unless you know what you are doing.
class MunaClient {
  /// Muna access key.
  final String? accessKey;

  /// Muna API URL.
  final String apiUrl;

  /// Create a [MunaClient].
  MunaClient(this.accessKey, [String? apiUrl])
    : apiUrl = apiUrl ?? "https://api.muna.ai/v1";

  /// Make a request to a REST endpoint.
  ///
  /// [method] is the HTTP method (e.g., `GET`, `POST`).
  /// [path] is the endpoint path (e.g., `/users`).
  /// [body] is an optional request JSON body.
  /// [fromJson] is an optional function to parse the response JSON.
  ///
  /// Returns the parsed response, or `null` if no [fromJson] was provided.
  Future<T?> request<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final url = Uri.parse("$apiUrl$path");
    final headers = <String, String>{
      if (accessKey != null) "Authorization": "Bearer $accessKey",
      if (body != null) "Content-Type": "application/json",
    };
    final http.Response response;
    switch (method) {
      case "GET":
        response = await http.get(url, headers: headers);
      case "HEAD":
        response = await http.head(url, headers: headers);
      case "POST":
        response = await http.post(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case "PATCH":
        response = await http.patch(
          url,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case "DELETE":
        response = await http.delete(url, headers: headers);
      default:
        throw ArgumentError("Unsupported HTTP method: $method");
    }
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (fromJson != null && data is Map<String, dynamic>) {
        return fromJson(data);
      }
      return null;
    } else {
      throw MunaAPIError(_parseError(data), response.statusCode);
    }
  }

  /// Make a request to a REST endpoint and consume the response as a
  /// server-sent events (SSE) stream.
  ///
  /// [method] is the HTTP method (e.g., `POST`).
  /// [path] is the endpoint path.
  /// [body] is an optional request JSON body.
  /// [fromJson] is a function to parse each SSE event.
  ///
  /// Returns a [Stream] of parsed events.
  Stream<T> stream<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required T Function(Map<String, dynamic>) fromJson,
  }) async* {
    final url = Uri.parse("$apiUrl$path");
    final request = http.Request(method, url);
    request.headers.addAll({
      if (accessKey != null) "Authorization": "Bearer $accessKey",
      "Accept": "text/event-stream",
      if (body != null) "Content-Type": "application/json",
    });
    if (body != null) {
      request.body = jsonEncode(body);
    }
    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      if (streamedResponse.statusCode < 200 ||
          streamedResponse.statusCode >= 300) {
        final responseBody = await streamedResponse.stream.bytesToString();
        dynamic data;
        try {
          data = jsonDecode(responseBody);
        } catch (_) {
          data = responseBody;
        }
        throw MunaAPIError(
          _parseError(data),
          streamedResponse.statusCode,
        );
      }
      String? event;
      String data = "";
      await for (final line in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.startsWith("event:")) {
            event = trimmed.substring("event:".length).trim();
          } else if (trimmed.startsWith("data:")) {
            final lineData = trimmed.substring("data:".length).trim();
            data = data.isEmpty ? lineData : "$data\n$lineData";
          }
          continue;
        }
        if (event != null) {
          yield _parseSseEvent(event, data, fromJson);
        }
        event = null;
        data = "";
      }
      if (event != null || data.isNotEmpty) {
        yield _parseSseEvent(event ?? "", data, fromJson);
      }
    } finally {
      client.close();
    }
  }

  /// Download a resource to a file at [path].
  ///
  /// Returns the file path.
  Future<String> download(String url, String path) async {
    final uri = Uri.parse(url);
    final request = http.Request("GET", uri);
    if (accessKey != null) {
      request.headers["Authorization"] = "Bearer $accessKey";
    }
    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MunaAPIError(
          "Failed to download resource",
          response.statusCode,
        );
      }
      final file = File(path);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      return path;
    } finally {
      client.close();
    }
  }

  /// Upload a resource and return the resource URL.
  ///
  /// [data] is the raw bytes to upload.
  Future<String> upload(Uint8List data) async {
    final resourceHash = sha256.convert(data).toString();
    // Check if resource already exists
    try {
      await request(method: "HEAD", path: "/resources/$resourceHash");
      return "$_resourceUrlBase/$resourceHash";
    } on MunaAPIError catch (e) {
      if (e.statusCode != 404) rethrow;
    }
    // Create upload URL
    final createResponse = await request<_CreateResourceResponse>(
      method: "POST",
      path: "/resources/$resourceHash",
      fromJson: _CreateResourceResponse.fromJson,
    );
    // Upload
    final uploadUrl = Uri.parse(createResponse!.url);
    final uploadResponse = await http.put(uploadUrl, body: data);
    if (uploadResponse.statusCode < 200 ||
        uploadResponse.statusCode >= 300) {
      throw MunaAPIError(
        "Failed to upload resource",
        uploadResponse.statusCode,
      );
    }
    return "$_resourceUrlBase/$resourceHash";
  }

  /// Parse an error response into a message string.
  static String _parseError(dynamic data) {
    if (data is Map<String, dynamic>) {
      final errors = data["errors"] as List<dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final first = errors[0] as Map<String, dynamic>;
        return first["message"] as String? ?? "Unknown error";
      }
    }
    return data?.toString() ?? "Unknown error";
  }

  /// Parse a server-sent event.
  static T _parseSseEvent<T>(
    String event,
    String data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final parsed = jsonDecode(data) as Map<String, dynamic>;
    return fromJson({"event": event, "data": parsed});
  }
}

class _CreateResourceResponse {
  final String url;
  const _CreateResourceResponse({required this.url});

  static _CreateResourceResponse fromJson(Map<String, dynamic> json) =>
    _CreateResourceResponse(url: json["url"] as String);
}
