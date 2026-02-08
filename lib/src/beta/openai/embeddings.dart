//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:convert";
import "dart:typed_data";

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../../types/dtype.dart";
import "../../types/tensor.dart";
import "../remote/remote.dart";
import "../remote/types.dart";
import "schema.dart";
import "util.dart";

/// Function type for embedding delegates.
typedef _EmbeddingDelegate = Future<EmbeddingCreateResponse> Function({
  required List<String> input,
  required String model,
  int? dimensions,
  required String encodingFormat,
  required String acceleration,
});

/// Embedding service.
class EmbeddingService {
  final PredictorService _predictors;
  final PredictionService _predictions;
  final RemotePredictionService _remotePredictions;
  final Map<String, _EmbeddingDelegate> _cache = {};

  /// Create an [EmbeddingService].
  EmbeddingService(
    this._predictors,
    this._predictions,
    this._remotePredictions,
  );

  /// Create an embedding vector representing the input text.
  ///
  /// [input] is the text to embed (a single string or list of strings).
  /// [model] is the embedding model tag.
  /// [dimensions] is the number of dimensions for Matryoshka models.
  /// [encodingFormat] is the return format (`"float"` or `"base64"`).
  /// [acceleration] is the prediction acceleration.
  Future<EmbeddingCreateResponse> create({
    required Object input,
    required String model,
    int? dimensions,
    String encodingFormat = "float",
    String acceleration = "remote_auto",
  }) async {
    final inputList = input is String ? [input] : input as List<String>;
    if (!_cache.containsKey(model)) {
      _cache[model] = await _createDelegate(model);
    }
    return _cache[model]!(
      input: inputList,
      model: model,
      dimensions: dimensions,
      encodingFormat: encodingFormat,
      acceleration: acceleration,
    );
  }

  Future<_EmbeddingDelegate> _createDelegate(String tag) async {
    // Retrieve predictor
    final predictor = await _predictors.retrieve(tag);
    if (predictor == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI embedding API because "
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
        "$tag cannot be used with OpenAI embedding API because "
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
        "$tag cannot be used with OpenAI embedding API because "
        "it does not have a valid text embedding input parameter.",
      );
    }
    // Get the Matryoshka dim parameter (optional)
    final (_, matryoshkaParam) = getParameter(
      signature.inputs,
      dtype: {
        Dtype.int8, Dtype.int16, Dtype.int32, Dtype.int64,
        Dtype.uint8, Dtype.uint16, Dtype.uint32, Dtype.uint64,
      },
      denotation: "openai.embeddings.dims",
    );
    // Get the embedding output parameter index
    final (embeddingParamIdx, _) = getParameter(
      signature.outputs,
      dtype: {Dtype.float32},
      denotation: "embedding",
    );
    if (embeddingParamIdx == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI embedding API because "
        "it has no outputs with an `embedding` denotation.",
      );
    }
    // Get usage output param
    int? usageParamIdx;
    for (var i = 0; i < signature.outputs.length; i++) {
      final param = signature.outputs[i];
      if (param.schema != null && param.schema!["title"] == "Usage") {
        usageParamIdx = i;
        break;
      }
    }
    // Create delegate
    final capturedEmbIdx = embeddingParamIdx;
    final capturedUsageIdx = usageParamIdx;
    return ({
      required List<String> input,
      required String model,
      int? dimensions,
      required String encodingFormat,
      required String acceleration,
    }) async {
      // Build prediction input map
      final inputMap = <String, Object?>{inputParam.name: input};
      if (dimensions != null && matryoshkaParam != null) {
        inputMap[matryoshkaParam.name] = dimensions;
      }
      // Create prediction
      final prediction = acceleration.startsWith("remote_")
        ? await _remotePredictions.create(
            model,
            inputs: inputMap,
            acceleration: RemoteAcceleration.fromValue(acceleration),
          )
        : await _predictions.create(model, inputs: inputMap);
      // Check for error
      if (prediction.error != null) {
        throw StateError(prediction.error!);
      }
      // Check embedding return type
      final embeddingResult = prediction.results![capturedEmbIdx];
      if (embeddingResult is! Tensor) {
        throw StateError(
          "$tag returned object of type ${embeddingResult.runtimeType} "
          "instead of an embedding matrix",
        );
      }
      final embeddingTensor = embeddingResult;
      if (embeddingTensor.shape.length != 2) {
        throw StateError(
          "$tag returned embedding matrix with invalid shape: "
          "${embeddingTensor.shape}",
        );
      }
      // Parse usage
      final usage = capturedUsageIdx != null &&
              prediction.results!.length > capturedUsageIdx
        ? EmbeddingUsage.fromJson(
            prediction.results![capturedUsageIdx] as Map<String, dynamic>,
          )
        : const EmbeddingUsage(promptTokens: 0, totalTokens: 0);
      // Create embedding response
      final n = embeddingTensor.shape[0];
      final d = embeddingTensor.shape[1];
      final embeddings = List.generate(n, (i) {
        final rowData = embeddingTensor.data.sublist(i * d, (i + 1) * d);
        final Object embeddingData;
        if (encodingFormat == "base64") {
          final bytes = Float32List.fromList(
            List<double>.from(rowData),
          ).buffer.asUint8List();
          embeddingData = base64Encode(bytes);
        } else {
          embeddingData = List<double>.from(rowData);
        }
        return Embedding(
          object: "embedding",
          embedding: embeddingData,
          index: i,
        );
      });
      return EmbeddingCreateResponse(
        object: "list",
        model: model,
        data: embeddings,
        usage: usage,
      );
    };
  }
}
