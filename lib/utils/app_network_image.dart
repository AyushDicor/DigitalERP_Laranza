// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:digitalerp/utils/app_constant.dart';
// import 'package:flutter/material.dart';
//
// class AppNetworkImage extends StatelessWidget {
//   final String? image;
//   final double? height;
//   final double? width;
//   final Widget? errorWidget;
//   final BoxFit? fit;
//
//   const AppNetworkImage({
//     Key? key,
//     this.image,
//     this.height,
//     this.width,
//     this.errorWidget,
//     this.fit,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return CachedNetworkImage(
//       fit: fit,
//       height: height,
//       width: width,
//       placeholder: (context, url) => const Center(
//         child: CircularProgressIndicator(
//           valueColor: AlwaysStoppedAnimation<Color>(
//             purpleColor,
//           ),
//         ),
//       ),
//       errorWidget: (context, url, error) => const Icon(
//         Icons.error,
//         color: Colors.red,
//       ),
//       // imageBuilder: (context, image) => CircleAvatar(
//       //   backgroundImage: image,
//       //   radius: (height ?? width ?? 100) / 2,
//       // ),
//       imageUrl: image ?? '',
//     );
//   }
// }


import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class IgnoreSslCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'ignoreSslCache';
  static final IgnoreSslCacheManager _instance = IgnoreSslCacheManager._();
  factory IgnoreSslCacheManager() => _instance;

  IgnoreSslCacheManager._()
      : super(Config(
    key,
    fileService: HttpFileService(httpClient: _createClient()),
  ));

  static http.Client _createClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }
}

class AppNetworkImage extends StatelessWidget {
  final String? image;
  final double? height;
  final double? width;
  final Widget? errorWidget;
  final BoxFit? fit;

  const AppNetworkImage({
    Key? key,
    this.image,
    this.height,
    this.width,
    this.errorWidget,
    this.fit,
  }) : super(key: key);

  // static String _sanitize(String? raw) {
  //   if (raw == null || raw.trim().isEmpty) return '';
  //   const marker = 'https://';
  //   final lastIndex = raw.lastIndexOf(marker);
  //   String url = lastIndex > 0 ? raw.substring(lastIndex) : raw;
  //   if (url.startsWith('http://')) {
  //     url = url.replaceFirst('http://', 'https://');
  //   }
  //   return url.trim();
  // }
  static String _sanitize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';

    // Fix doubled URL only
    const marker = 'https://';
    final lastIndex = raw.lastIndexOf(marker);
    if (lastIndex > 0) return raw.substring(lastIndex).trim();

    return raw.trim();
  }

  /// URLs that have already failed this session.
  ///
  /// Flutter's image cache deliberately does not cache failures, so every
  /// rebuild of a widget showing a dead URL fired a fresh HTTP request, got
  /// the same 404, and logged it again. The home header's avatar rebuilds on
  /// every controller update, which flooded the console with one red line per
  /// rebuild and made real logs impossible to read. Remembering the failure
  /// stops both the repeat requests and the repeat logging.
  static final Set<String> _failedUrls = <String>{};

  @override
  Widget build(BuildContext context) {
    final safeUrl = _sanitize(image);

    if (safeUrl.isEmpty || _failedUrls.contains(safeUrl)) {
      return errorWidget ??
          SizedBox(
            height: height,
            width: width,
            child: Icon(
              safeUrl.isEmpty ? Icons.image_not_supported : Icons.broken_image,
              color: Colors.grey,
            ),
          );
    }

    // ✅ Use Image.network with custom HttpClient instead of CachedNetworkImage
    // This lets us bypass SSL at the Flutter engine level
    return SizedBox(
      height: height,
      width: width,
      child: Image(
        image: NetworkImage(safeUrl),
        fit: fit ?? BoxFit.cover,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height,
            width: width,
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(purpleColor),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          /// Log a dead URL once, then never request it again this session.
          if (_failedUrls.add(safeUrl)) {
            debugPrint('❌ Image.network error: $error');
          }
          return errorWidget ??
              SizedBox(
                height: height,
                width: width,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      ),
    );
  }
}