import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  String _getOptimizedUrl(String url) {
    if (url.isEmpty) return url;
    // Check if it is a Cloudinary URL
    if (url.contains('res.cloudinary.com')) {
      // Find where "/upload/" is in the url
      final uploadIndex = url.indexOf('/upload/');
      if (uploadIndex != -1) {
        // Insert quality and format auto, with max width of 800px
        final insertionPoint = uploadIndex + '/upload/'.length;
        final optimizedUrl =
            '${url.substring(0, insertionPoint)}q_auto,f_auto,w_800/${url.substring(insertionPoint)}';
        return optimizedUrl;
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final optimizedUrl = _getOptimizedUrl(imageUrl);
    
    if (optimizedUrl.isEmpty) {
      return errorWidget ?? _defaultErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
      ),
    );
  }
}
