//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

/// Chat completion reasoning effort.
enum ChatCompletionReasoningEffort {
  minimal("minimal"),
  low("low"),
  medium("medium"),
  high("high"),
  xhigh("xhigh");

  final String value;
  const ChatCompletionReasoningEffort(this.value);
  String toJson() => value;
}

/// Speech response format.
enum SpeechResponseFormat {
  mp3("mp3"),
  opus("opus"),
  aac("aac"),
  flac("flac"),
  wav("wav"),
  pcm("pcm");

  final String value;
  const SpeechResponseFormat(this.value);
  String toJson() => value;
}

/// Speech stream format.
enum SpeechStreamFormat {
  audio("audio"),
  sse("sse");

  final String value;
  const SpeechStreamFormat(this.value);
  String toJson() => value;
}

/// Chat completion usage.
class ChatCompletionUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const ChatCompletionUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory ChatCompletionUsage.fromJson(Map<String, dynamic> json) =>
    ChatCompletionUsage(
      promptTokens: json["prompt_tokens"] as int,
      completionTokens: json["completion_tokens"] as int,
      totalTokens: json["total_tokens"] as int,
    );

  Map<String, dynamic> toJson() => {
    "prompt_tokens": promptTokens,
    "completion_tokens": completionTokens,
    "total_tokens": totalTokens,
  };
}

/// Chat message.
class Message {
  final String role;
  final String? content;

  const Message({required this.role, this.content});

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    role: json["role"] as String,
    content: json["content"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "role": role,
    if (content != null) "content": content,
  };
}

/// Streaming delta message.
class DeltaMessage {
  final String? role;
  final String? content;

  const DeltaMessage({this.role, this.content});

  factory DeltaMessage.fromJson(Map<String, dynamic> json) => DeltaMessage(
    role: json["role"] as String?,
    content: json["content"] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (role != null) "role": role,
    if (content != null) "content": content,
  };
}

/// Chat completion choice.
class Choice {
  final int index;
  final Message message;
  final String? finishReason;

  const Choice({
    required this.index,
    required this.message,
    this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) => Choice(
    index: json["index"] as int,
    message: Message.fromJson(json["message"] as Map<String, dynamic>),
    finishReason: json["finish_reason"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "index": index,
    "message": message.toJson(),
    if (finishReason != null) "finish_reason": finishReason,
  };
}

/// Streaming chat completion choice.
class StreamChoice {
  final int index;
  final DeltaMessage? delta;
  final String? finishReason;

  const StreamChoice({
    required this.index,
    this.delta,
    this.finishReason,
  });

  factory StreamChoice.fromJson(Map<String, dynamic> json) => StreamChoice(
    index: json["index"] as int,
    delta: json["delta"] != null
      ? DeltaMessage.fromJson(json["delta"] as Map<String, dynamic>)
      : null,
    finishReason: json["finish_reason"] as String?,
  );

  Map<String, dynamic> toJson() => {
    "index": index,
    if (delta != null) "delta": delta!.toJson(),
    if (finishReason != null) "finish_reason": finishReason,
  };
}

/// Chat completion.
class ChatCompletion {
  final String object;
  final String id;
  final int created;
  final String model;
  final List<Choice> choices;
  final ChatCompletionUsage usage;

  const ChatCompletion({
    this.object = "chat.completion",
    required this.id,
    required this.created,
    required this.model,
    required this.choices,
    required this.usage,
  });

  factory ChatCompletion.fromJson(Map<String, dynamic> json) => ChatCompletion(
    object: json["object"] as String? ?? "chat.completion",
    id: json["id"] as String,
    created: json["created"] as int,
    model: json["model"] as String,
    choices: (json["choices"] as List<dynamic>)
      .map((e) => Choice.fromJson(e as Map<String, dynamic>))
      .toList(),
    usage: ChatCompletionUsage.fromJson(json["usage"] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    "object": object,
    "id": id,
    "created": created,
    "model": model,
    "choices": choices.map((e) => e.toJson()).toList(),
    "usage": usage.toJson(),
  };
}

/// Streaming chat completion chunk.
class ChatCompletionChunk {
  final String object;
  final String id;
  final int created;
  final String model;
  final List<StreamChoice> choices;
  final ChatCompletionUsage? usage;

  const ChatCompletionChunk({
    this.object = "chat.completion.chunk",
    required this.id,
    required this.created,
    required this.model,
    required this.choices,
    this.usage,
  });

  factory ChatCompletionChunk.fromJson(Map<String, dynamic> json) =>
    ChatCompletionChunk(
      object: json["object"] as String? ?? "chat.completion.chunk",
      id: json["id"] as String,
      created: json["created"] as int,
      model: json["model"] as String,
      choices: (json["choices"] as List<dynamic>)
        .map((e) => StreamChoice.fromJson(e as Map<String, dynamic>))
        .toList(),
      usage: json["usage"] != null
        ? ChatCompletionUsage.fromJson(json["usage"] as Map<String, dynamic>)
        : null,
    );

  Map<String, dynamic> toJson() => {
    "object": object,
    "id": id,
    "created": created,
    "model": model,
    "choices": choices.map((e) => e.toJson()).toList(),
    if (usage != null) "usage": usage!.toJson(),
  };
}

/// Embedding.
class Embedding {
  final String object;
  final Object embedding;
  final int index;

  const Embedding({
    this.object = "embedding",
    required this.embedding,
    required this.index,
  });

  factory Embedding.fromJson(Map<String, dynamic> json) => Embedding(
    object: json["object"] as String? ?? "embedding",
    embedding: json["embedding"] as Object,
    index: json["index"] as int,
  );

  Map<String, dynamic> toJson() => {
    "object": object,
    "embedding": embedding,
    "index": index,
  };
}

/// Embedding usage.
class EmbeddingUsage {
  final int promptTokens;
  final int totalTokens;

  const EmbeddingUsage({
    required this.promptTokens,
    required this.totalTokens,
  });

  factory EmbeddingUsage.fromJson(Map<String, dynamic> json) => EmbeddingUsage(
    promptTokens: json["prompt_tokens"] as int,
    totalTokens: json["total_tokens"] as int,
  );

  Map<String, dynamic> toJson() => {
    "prompt_tokens": promptTokens,
    "total_tokens": totalTokens,
  };
}

/// Embedding create response.
class EmbeddingCreateResponse {
  final String object;
  final String model;
  final List<Embedding> data;
  final EmbeddingUsage usage;

  const EmbeddingCreateResponse({
    this.object = "list",
    required this.model,
    required this.data,
    required this.usage,
  });

  factory EmbeddingCreateResponse.fromJson(Map<String, dynamic> json) =>
    EmbeddingCreateResponse(
      object: json["object"] as String? ?? "list",
      model: json["model"] as String,
      data: (json["data"] as List<dynamic>)
        .map((e) => Embedding.fromJson(e as Map<String, dynamic>))
        .toList(),
      usage: EmbeddingUsage.fromJson(json["usage"] as Map<String, dynamic>),
    );

  Map<String, dynamic> toJson() => {
    "object": object,
    "model": model,
    "data": data.map((e) => e.toJson()).toList(),
    "usage": usage.toJson(),
  };
}

/// Speech create response.
class SpeechCreateResponse {
  final List<int> content;
  final String contentType;

  const SpeechCreateResponse({
    required this.content,
    required this.contentType,
  });
}

/// Transcription.
class Transcription {
  final String text;

  const Transcription({required this.text});

  factory Transcription.fromJson(Map<String, dynamic> json) =>
    Transcription(text: json["text"] as String);

  Map<String, dynamic> toJson() => {"text": text};
}
