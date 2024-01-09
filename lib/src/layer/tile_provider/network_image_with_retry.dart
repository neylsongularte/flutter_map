import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart';
import 'package:http/retry.dart';
import 'package:flutter/services.dart';

class NetworkImageWithRetry extends ImageProvider<NetworkImageWithRetry> {
  /// The URL from which the image will be fetched.
  final String url;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;

  /// The http RetryClient that is used for the requests
  final RetryClient retryClient = RetryClient(Client());

  NetworkImageWithRetry(this.url, {this.scale = 1.0});

  @override
  ImageStreamCompleter loadImage(NetworkImageWithRetry key, decode) {
    return OneFrameImageStreamCompleter(_loadWithRetry(key, decode),
        informationCollector: () sync* {
      yield ErrorDescription('Image provider: $this');
      yield ErrorDescription('Image key: $key');
    });
  }

  @override
  Future<NetworkImageWithRetry> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImageWithRetry>(this);
  }

  Future<ImageInfo> _loadWithRetry(
      NetworkImageWithRetry key, ImageDecoderCallback decode) async {
    assert(key == this);

    final uri = Uri.parse(url);
    final response = await retryClient.get(uri);
    final codec = await decode(await ImmutableBuffer.fromUint8List(response.bodyBytes));
    final image = (await codec.getNextFrame()).image;

    return ImageInfo(
      image: image,
      scale: key.scale,
    );
  }
}
