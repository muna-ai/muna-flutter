//
//  Muna
//  Copyright © 2026 NatML Inc. All Rights Reserved.
//

import "dart:typed_data";

/// Image.
class Image {

  /// Image pixel buffer.
  /// This is always 8bpp interleaved by channel.
  final Uint8List data;

  /// Image width.
  final int width;

  /// Image height.
  final int height;

  /// Image channels.
  final int channels;

  /// Create an image.
  ///
  /// The [data] pixel buffer format MUST be `R8`, `RGB888`, or `RGBA8888`.
  const Image(this.data, this.width, this.height, this.channels);
}
