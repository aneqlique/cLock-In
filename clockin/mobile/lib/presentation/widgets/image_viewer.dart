import 'package:flutter/material.dart';

/// Full-screen, pinch-to-zoom photo viewer.
class ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroPrefix;

  const ImageViewer({super.key, required this.images, required this.initialIndex, required this.heroPrefix});

  static void open(BuildContext context, List<String> images, int index, String heroPrefix) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => ImageViewer(images: images, initialIndex: index, heroPrefix: heroPrefix),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Hero(
                tag: '${widget.heroPrefix}-$index',
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 48)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
