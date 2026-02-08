//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../../types/dtype.dart";
import "../../types/prediction.dart" as types;
import "../remote/remote.dart";
import "../remote/types.dart";
import "schema.dart";
import "util.dart";

/// Function type for chat completion delegates.
typedef _ChatCompletionDelegate = Future<List<Object>> Function({
  required List<Message> messages,
  required String model,
  Map<String, Object?>? responseFormat,
  ChatCompletionReasoningEffort? reasoningEffort,
  int? maxCompletionTokens,
  double? temperature,
  double? topP,
  double? frequencyPenalty,
  double? presencePenalty,
  required String acceleration,
});

/// Create chat completions.
class ChatCompletionService {
  final PredictorService _predictors;
  final PredictionService _predictions;
  final RemotePredictionService _remotePredictions;
  final Map<String, _ChatCompletionDelegate> _cache = {};

  /// Create a [ChatCompletionService].
  ChatCompletionService(
    this._predictors,
    this._predictions,
    this._remotePredictions,
  );

  /// Create a chat completion.
  ///
  /// [messages] are the messages for the conversation so far.
  /// [model] is the chat model tag.
  /// [responseFormat] is the response format.
  /// [reasoningEffort] is the reasoning effort for reasoning models.
  /// [maxCompletionTokens] is the maximum completion tokens.
  /// [temperature] is the sampling temperature.
  /// [topP] is the nucleus sampling coefficient.
  /// [frequencyPenalty] is the token frequency penalty.
  /// [presencePenalty] is the token presence penalty.
  /// [acceleration] is the prediction acceleration.
  ///
  /// Returns a [ChatCompletion].
  Future<ChatCompletion> create({
    required List<Message> messages,
    required String model,
    Map<String, Object?>? responseFormat,
    ChatCompletionReasoningEffort? reasoningEffort,
    int? maxCompletionTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String acceleration = "remote_auto",
  }) async {
    final outputs = await _predict(
      messages: messages,
      model: model,
      responseFormat: responseFormat,
      reasoningEffort: reasoningEffort,
      maxCompletionTokens: maxCompletionTokens,
      temperature: temperature,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      acceleration: acceleration,
    );
    return _parseChatCompletion(outputs);
  }

  /// Stream a chat completion.
  ///
  /// [messages] are the messages for the conversation so far.
  /// [model] is the chat model tag.
  /// [responseFormat] is the response format.
  /// [reasoningEffort] is the reasoning effort for reasoning models.
  /// [maxCompletionTokens] is the maximum completion tokens.
  /// [temperature] is the sampling temperature.
  /// [topP] is the nucleus sampling coefficient.
  /// [frequencyPenalty] is the token frequency penalty.
  /// [presencePenalty] is the token presence penalty.
  /// [acceleration] is the prediction acceleration.
  ///
  /// Returns a [List] of [ChatCompletionChunk].
  Future<List<ChatCompletionChunk>> stream({
    required List<Message> messages,
    required String model,
    Map<String, Object?>? responseFormat,
    ChatCompletionReasoningEffort? reasoningEffort,
    int? maxCompletionTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    String acceleration = "remote_auto",
  }) async {
    final outputs = await _predict(
      messages: messages,
      model: model,
      responseFormat: responseFormat,
      reasoningEffort: reasoningEffort,
      maxCompletionTokens: maxCompletionTokens,
      temperature: temperature,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      acceleration: acceleration,
    );
    return outputs.map(_parseChatCompletionChunk).toList();
  }

  Future<List<Object>> _predict({
    required List<Message> messages,
    required String model,
    Map<String, Object?>? responseFormat,
    ChatCompletionReasoningEffort? reasoningEffort,
    int? maxCompletionTokens,
    double? temperature,
    double? topP,
    double? frequencyPenalty,
    double? presencePenalty,
    required String acceleration,
  }) async {
    if (!_cache.containsKey(model)) {
      _cache[model] = await _createDelegate(model);
    }
    return _cache[model]!(
      messages: messages,
      model: model,
      responseFormat: responseFormat,
      reasoningEffort: reasoningEffort,
      maxCompletionTokens: maxCompletionTokens,
      temperature: temperature,
      topP: topP,
      frequencyPenalty: frequencyPenalty,
      presencePenalty: presencePenalty,
      acceleration: acceleration,
    );
  }

  Future<_ChatCompletionDelegate> _createDelegate(String tag) async {
    // Retrieve predictor
    final predictor = await _predictors.retrieve(tag);
    if (predictor == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI chat completions API because "
        "the predictor could not be found. Check that your access key "
        "is valid and that you have access to the predictor.",
      );
    }
    // Check that there is only one required input parameter
    final signature = predictor.signature;
    final requiredInputs = signature.inputs
      .where((p) => p.optional != true)
      .toList();
    if (requiredInputs.length != 1) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI chat completions API because "
        "it has more than one required input parameter.",
      );
    }
    // Check that the input parameter is `list`
    final (_, inputParam) = getParameter(
      requiredInputs,
      dtype: {Dtype.list},
    );
    if (inputParam == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI chat completions API because "
        "it does not have a valid chat messages input parameter.",
      );
    }
    // Get optional inputs
    final (_, responseFormatParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.dict},
      denotation: "openai.chat.completions.response_format",
    );
    final (_, reasoningEffortParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.string},
      denotation: "openai.chat.completions.reasoning_effort",
    );
    final (_, maxOutputTokensParam) = getParameter(
      signature.inputs,
      dtype: {
        Dtype.int8, Dtype.int16, Dtype.int32, Dtype.int64,
        Dtype.uint8, Dtype.uint16, Dtype.uint32, Dtype.uint64,
      },
      denotation: "openai.chat.completions.max_output_tokens",
    );
    final (_, temperatureParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.float32, Dtype.float64},
      denotation: "openai.chat.completions.temperature",
    );
    final (_, topPParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.float32, Dtype.float64},
      denotation: "openai.chat.completions.top_p",
    );
    final (_, frequencyPenaltyParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.float32, Dtype.float64},
      denotation: "openai.chat.completions.frequency_penalty",
    );
    final (_, presencePenaltyParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.float32, Dtype.float64},
      denotation: "openai.chat.completions.presence_penalty",
    );
    // Get chat completion output param
    int? completionParamIdx;
    for (var i = 0; i < signature.outputs.length; i++) {
      final param = signature.outputs[i];
      if (param.dtype == Dtype.dict &&
          param.schema != null &&
          (param.schema!["title"] == "ChatCompletion" ||
           param.schema!["title"] == "ChatCompletionChunk")) {
        completionParamIdx = i;
        break;
      }
    }
    if (completionParamIdx == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI chat completions API because "
        "it does not have a valid chat completion output parameter.",
      );
    }
    // Create delegate
    final capturedIdx = completionParamIdx;
    return ({
      required List<Message> messages,
      required String model,
      Map<String, Object?>? responseFormat,
      ChatCompletionReasoningEffort? reasoningEffort,
      int? maxCompletionTokens,
      double? temperature,
      double? topP,
      double? frequencyPenalty,
      double? presencePenalty,
      required String acceleration,
    }) async {
      // Build prediction input map
      final inputMap = <String, Object?>{
        inputParam.name: messages.map((m) => m.toJson()).toList(),
      };
      if (responseFormatParam != null && responseFormat != null) {
        inputMap[responseFormatParam.name] = responseFormat;
      }
      if (reasoningEffortParam != null && reasoningEffort != null) {
        inputMap[reasoningEffortParam.name] = reasoningEffort.value;
      }
      if (maxOutputTokensParam != null && maxCompletionTokens != null) {
        inputMap[maxOutputTokensParam.name] = maxCompletionTokens;
      }
      if (temperatureParam != null && temperature != null) {
        inputMap[temperatureParam.name] = temperature;
      }
      if (topPParam != null && topP != null) {
        inputMap[topPParam.name] = topP;
      }
      if (frequencyPenaltyParam != null && frequencyPenalty != null) {
        inputMap[frequencyPenaltyParam.name] = frequencyPenalty;
      }
      if (presencePenaltyParam != null && presencePenalty != null) {
        inputMap[presencePenaltyParam.name] = presencePenalty;
      }
      // Stream prediction
      final outputs = <Object>[];
      if (acceleration.startsWith("remote_")) {
        await for (final prediction in _remotePredictions.stream(
          model,
          inputs: inputMap,
          acceleration: RemoteAcceleration.fromValue(acceleration),
        )) {
          _collectOutput(prediction, capturedIdx, outputs);
        }
      } else {
        final predictions = await _predictions.stream(
          model,
          inputs: inputMap,
        );
        for (final prediction in predictions) {
          _collectOutput(prediction, capturedIdx, outputs);
        }
      }
      return outputs;
    };
  }
}

void _collectOutput(
  types.Prediction prediction,
  int completionParamIdx,
  List<Object> outputs,
) {
  if (prediction.error != null) {
    throw StateError(prediction.error!);
  }
  if (prediction.results != null &&
      prediction.results!.length > completionParamIdx) {
    final result = prediction.results![completionParamIdx];
    if (result != null) {
      outputs.add(result);
    }
  }
}

ChatCompletion _parseChatCompletion(List<Object> outputs) {
  if (outputs.isEmpty) {
    throw StateError(
      "Failed to parse chat completion because model did not return any outputs",
    );
  }
  // Try parsing as ChatCompletion directly
  try {
    final completions = outputs
      .map((o) => ChatCompletion.fromJson(o as Map<String, dynamic>))
      .toList();
    return completions.last;
  } catch (_) {}
  // Try parsing as chunks and assembling
  try {
    final chunks = outputs
      .map((o) => ChatCompletionChunk.fromJson(o as Map<String, dynamic>))
      .toList();
    final choicesMap = <int, List<StreamChoice>>{};
    for (final chunk in chunks) {
      for (final choice in chunk.choices) {
        choicesMap.putIfAbsent(choice.index, () => []).add(choice);
      }
    }
    final choices = choicesMap.entries.map((entry) {
      return _createChatCompletionChoice(entry.key, entry.value);
    }).toList();
    final chunkUsages = chunks
      .where((c) => c.usage != null)
      .map((c) => c.usage!)
      .toList();
    final usage = ChatCompletionUsage(
      promptTokens: chunkUsages.fold(0, (sum, u) => sum + u.promptTokens),
      completionTokens: chunkUsages.fold(0, (sum, u) => sum + u.completionTokens),
      totalTokens: chunkUsages.fold(0, (sum, u) => sum + u.totalTokens),
    );
    return ChatCompletion(
      id: chunks.first.id,
      created: chunks.first.created,
      model: chunks.first.model,
      choices: choices,
      usage: usage,
    );
  } catch (_) {}
  throw StateError(
    "Failed to parse chat completion from model outputs: $outputs",
  );
}

ChatCompletionChunk _parseChatCompletionChunk(Object data) {
  final json = data as Map<String, dynamic>;
  // Try as ChatCompletionChunk
  try {
    return ChatCompletionChunk.fromJson(json);
  } catch (_) {}
  // Try as ChatCompletion -> convert to chunk
  try {
    final completion = ChatCompletion.fromJson(json);
    return ChatCompletionChunk(
      id: completion.id,
      created: completion.created,
      model: completion.model,
      choices: completion.choices.map((choice) => StreamChoice(
        index: choice.index,
        delta: DeltaMessage(
          role: choice.message.role,
          content: choice.message.content,
        ),
        finishReason: choice.finishReason,
      )).toList(),
      usage: completion.usage,
    );
  } catch (_) {}
  throw StateError(
    "Failed to parse streaming chat completion chunk from model output: $data",
  );
}

Choice _createChatCompletionChoice(int index, List<StreamChoice> choices) {
  final role = choices.first.delta?.role ?? "assistant";
  final content = choices
    .where((c) => c.delta?.content != null)
    .map((c) => c.delta!.content!)
    .join();
  final finishReason = choices
    .where((c) => c.finishReason != null)
    .map((c) => c.finishReason)
    .firstOrNull;
  return Choice(
    index: index,
    message: Message(role: role, content: content),
    finishReason: finishReason,
  );
}
