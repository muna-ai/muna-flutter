//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

/// Tensor.
class Tensor<T> {

  /// Tensor data.
  final List<T> data;

  /// Tensor shape.
  final List<int> shape;

  /// Create a tensor.
  const Tensor(this.data, this.shape);
}
