import 'package:flutter/material.dart';
import '../../core/config/theme.dart';

/// Swipeable photos with page dots and a "2/5" counter.
class PhotoCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final String heroPrefix;
  final void Function(int index)? onTap;
  final VoidCallback? onDoubleTap;

  const PhotoCarousel({
    super.key,
    required this.images,
    required this.heroPrefix,
    this.height = 280,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  State<PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<PhotoCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final many = widget.images.length > 1;
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: widget.images.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: widget.onTap == null ? null : () => widget.onTap!(i),
                    onDoubleTap: widget.onDoubleTap,
                    child: Hero(
                      tag: '${widget.heroPrefix}-$i',
                      child: NetworkPhoto(url: widget.images[i]),
                    ),
                  ),
                ),
                if (many)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${_page + 1}/${widget.images.length}',
                        style: context.tt.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (many) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.images.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? cs.onSurface : cs.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Network image with a themed loading and error placeholder.
class NetworkPhoto extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const NetworkPhoto({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: cs.surfaceContainerHigh,
          alignment: Alignment.center,
          child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: cs.surfaceContainerHigh,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
      ),
    );
  }
}
