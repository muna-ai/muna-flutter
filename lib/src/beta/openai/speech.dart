//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:typed_data";

import "../../services/prediction.dart";
import "../../services/predictor.dart";
import "../../types/dtype.dart";
import "../../types/tensor.dart";
import "../remote/remote.dart";
import "../remote/types.dart";
import "schema.dart";
import "util.dart";

/// Function type for speech delegates.
typedef _SpeechDelegate = Future<SpeechCreateResponse> Function({
  required String input,
  required String model,
  required String voice,
  required SpeechResponseFormat responseFormat,
  required double speed,
  required SpeechStreamFormat streamFormat,
  required String acceleration,
});

/// Speech service.
class SpeechService {
  final PredictorService _predictors;
  final PredictionService _predictions;
  final RemotePredictionService _remotePredictions;
  final Map<String, _SpeechDelegate> _cache = {};

  /// Create a [SpeechService].
  SpeechService(
    this._predictors,
    this._predictions,
    this._remotePredictions,
  );

  /// Generate audio from the input text.
  ///
  /// [input] is the text to generate audio for.
  /// [model] is the speech generation model tag.
  /// [voice] is the voice to use when generating the audio.
  /// [responseFormat] is the audio output format.
  /// [speed] is the speed of the generated audio.
  /// [streamFormat] is the format to stream the audio in.
  /// [acceleration] is the prediction acceleration.
  Future<SpeechCreateResponse> create({
    required String input,
    required String model,
    required String voice,
    SpeechResponseFormat responseFormat = SpeechResponseFormat.mp3,
    double speed = 1.0,
    SpeechStreamFormat streamFormat = SpeechStreamFormat.audio,
    String acceleration = "remote_auto",
  }) async {
    if (!_cache.containsKey(model)) {
      _cache[model] = await _createDelegate(model);
    }
    return _cache[model]!(
      input: input,
      model: model,
      voice: voice,
      responseFormat: responseFormat,
      speed: speed,
      streamFormat: streamFormat,
      acceleration: acceleration,
    );
  }

  Future<_SpeechDelegate> _createDelegate(String tag) async {
    // Retrieve predictor
    final predictor = await _predictors.retrieve(tag);
    if (predictor == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI speech API because "
        "the predictor could not be found. Check that your access key "
        "is valid and that you have access to the predictor.",
      );
    }
    // Get required inputs
    final signature = predictor.signature;
    final requiredInputs = signature.inputs
      .where((p) => p.optional != true)
      .toList();
    if (requiredInputs.length != 2) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI speech API because "
        "it does not have exactly two required input parameters.",
      );
    }
    // Get the text input param
    final (_, inputParam) = getParameter(
      requiredInputs,
      dtype: {Dtype.string},
    );
    if (inputParam == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI speech API because "
        "it does not have the required speech input parameter.",
      );
    }
    // Get the voice input param
    final (_, voiceParam) = getParameter(
      requiredInputs,
      dtype: {Dtype.string},
      denotation: "openai.audio.speech.voice",
    );
    if (voiceParam == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI speech API because "
        "it does not have the required speech voice parameter.",
      );
    }
    // Get the speed input param (optional)
    final (_, speedParam) = getParameter(
      signature.inputs,
      dtype: {Dtype.float32, Dtype.float64},
      denotation: "openai.audio.speech.speed",
    );
    // Get the audio output parameter index
    final (audioParamIdx, audioParam) = getParameter(
      signature.outputs,
      dtype: {Dtype.float32},
      denotation: "audio",
    );
    if (audioParam == null) {
      throw ArgumentError(
        "$tag cannot be used with OpenAI speech API because "
        "it has no outputs with an `audio` denotation.",
      );
    }
    // Create delegate
    final capturedIdx = audioParamIdx!;
    final sampleRate = audioParam.sampleRate ?? 44100;
    return ({
      required String input,
      required String model,
      required String voice,
      required SpeechResponseFormat responseFormat,
      required double speed,
      required SpeechStreamFormat streamFormat,
      required String acceleration,
    }) async {
      // Check stream format
      if (streamFormat != SpeechStreamFormat.audio) {
        throw ArgumentError(
          "Cannot create speech with stream format `${streamFormat.value}` "
          "because only `audio` is currently supported.",
        );
      }
      // Build prediction input map
      final inputMap = <String, Object?>{
        inputParam.name: input,
        voiceParam.name: voice,
      };
      if (speedParam != null) {
        inputMap[speedParam.name] = speed;
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
      // Check returned audio
      final audio = prediction.results![capturedIdx];
      if (audio is! Tensor) {
        throw StateError(
          "$tag returned object of type ${audio.runtimeType} "
          "instead of an audio tensor",
        );
      }
      // Create response
      final (content, contentType) = _createResponseData(
        audio,
        sampleRate: sampleRate,
        responseFormat: responseFormat,
      );
      return SpeechCreateResponse(
        content: content,
        contentType: contentType,
      );
    };
  }
}

(List<int>, String) _createResponseData(
  Tensor audio, {
  required int sampleRate,
  required SpeechResponseFormat responseFormat,
}) {
  final channels = audio.shape.length == 2 ? audio.shape[1] : 1;
  if (responseFormat == SpeechResponseFormat.pcm) {
    final contentType = [
      "audio/pcm",
      "rate=$sampleRate",
      "channels=$channels",
      "encoding=float",
      "bits=32",
    ].join(";");
    final data = audio.data is Float32List
      ? (audio.data as Float32List).buffer.asUint8List()
      : Float32List.fromList(List<double>.from(audio.data))
          .buffer.asUint8List();
    return (data, contentType);
  }
  // For other formats, return raw PCM data with the requested content type
  // The C library's Value.serialize handles the conversion
  final contentType = "audio/${responseFormat.value};rate=$sampleRate";
  final data = audio.data is Float32List
    ? (audio.data as Float32List).buffer.asUint8List()
    : Float32List.fromList(List<double>.from(audio.data))
        .buffer.asUint8List();
  return (data, contentType);
}
