//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

// https://github.com/muna-ai/fxnc

import "dart:ffi";
import "dart:io";

enum FXNStatus {
  ok(0),
  errorInvalidArgument(1),
  errorInvalidOperation(2),
  errorNotImplemented(3);

  final int code;
  const FXNStatus(this.code);

  static FXNStatus fromCode(int code) =>
    FXNStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => FXNStatus.ok,
    );
}

DynamicLibrary? _fxnc;

DynamicLibrary getFxnc() {
  _fxnc ??= _loadFxnc();
  return _fxnc!;
}

DynamicLibrary _loadFxnc() {
  if (Platform.isAndroid)
    return DynamicLibrary.open("libFunction.so");
  if (Platform.isIOS)
    return DynamicLibrary.process();
  if (Platform.isMacOS)
    return DynamicLibrary.open("Function.dylib");
  if (Platform.isWindows)
    return DynamicLibrary.open("Function.dll");
  if (Platform.isLinux)
    return DynamicLibrary.open("libFunction.so");
  throw UnsupportedError("Unsupported platform: ${Platform.operatingSystem}");
}

String statusToError(int status) {
  switch (FXNStatus.fromCode(status)) {
    case FXNStatus.errorInvalidArgument:
      return "FXN_ERROR_INVALID_ARGUMENT";
    case FXNStatus.errorInvalidOperation:
      return "FXN_ERROR_INVALID_OPERATION";
    case FXNStatus.errorNotImplemented:
      return "FXN_ERROR_NOT_IMPLEMENTED";
    default:
      return "";
  }
}
