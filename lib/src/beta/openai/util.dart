//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "../types/dtype.dart";
import "../types/parameter.dart";

/// Get a parameter with the given data type and denotation.
///
/// Returns a tuple of `(index, parameter)`, where both are `null` if
/// no matching parameter was found.
(int?, Parameter?) getParameter(
  List<Parameter> parameters, {
  required Set<Dtype> dtype,
  String? denotation,
}) {
  for (var i = 0; i < parameters.length; i++) {
    final param = parameters[i];
    if (param.dtype != null &&
        dtype.contains(param.dtype!) &&
        (denotation == null || param.denotation == denotation)) {
      return (i, param);
    }
  }
  return (null, null);
}
