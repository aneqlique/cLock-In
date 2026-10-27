import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/theme.dart';
import '../../core/models/task_category.dart';
import '../../core/utils/date_utils.dart';
import 'avatar.dart';
import 'image_viewer.dart';
import 'photo_carousel.dart';
import 'task_card.dart';

/// A public post on the Feed.
class DiaryCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String currentUserId;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const DiaryCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> with SingleTickerProviderStateMixin {
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  bool _expanded = false;

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  bool get _isLiked {
    final likedBy = widget.post['likedBy'];
    return likedBy is List && likedBy.map((e) => e.toString()).contains(widget.currentUserId);
  }

  void _doubleTapLike() {
    HapticFeedback.lightImpact();
    _burst.forward(from: 0);
    if (!_isLiked) widget.onLike();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final post = widget.post;
    final postId = (post['_id'] ?? '').toString();
    final username = (post['username'] ?? 'User').toString();
    // Profile picture can be in post['profilePicture'] or post['userId']['profilePicture']
    var picture = (post['profilePicture'] ?? '').toString();
    if (picture.isEmpty && post['userId'] is Map) {
      picture = (post['userId']['profilePicture'] ?? '').toString();
    }
    final title = (post['taskTitle'] ?? '').toString();
    final category = (post['category'] ?? '').toString();
    final timeRange = (post['timeRange'] ?? '').toString();
    final description = (post['description'] ?? '').toString();
    final images = post['images'] is List ? (post['images'] as List).map((e) => e.toString()).toList() : <String>[];
    final likes = (post['likes'] ?? 0) as num;
    final comments = post['comments'] is List ? (post['comments'] as List).length : 0;
    final liked = _isLiked;
    final use24h = use24hOf(context);
    // Your own posts use your live categories; others carry a snapshot.
    final authorId = post['userId'] is Map ? (post['userId']['_id'] ?? '').toString() : (post['userId'] ?? '').toString();
    final label = (post['categoryLabel'] ?? '').toString();
    final snapshot = authorId == widget.currentUserId
        ? null
        : (label.isEmpty
            ? TaskCategory.fallback(category)
            : TaskCategory(
                key: category,
                name: label,
                color: post['categoryColor'] is num
                    ? (post['categoryColor'] as num).toInt() % kTintCount
                    : TaskCategory.fallback(category).color,
                icon: (post['categoryIcon'] ?? 'label').toString(),
              ));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Avatar(imageUrl: picture, name: username, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: context.tt.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        [timeAgo((post['createdAt'] ?? '').toString()), formatTimeRange(timeRange, use24h: use24h)]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: context.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (category.isNotEmpty) CategoryChip(category: category, dense: true, resolved: snapshot),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(title, style: context.tt.titleMedium),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final style = context.tt.bodyMedium!;
                  final tp = TextPainter(
                    text: TextSpan(text: description, style: style),
                    maxLines: 3,
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: constraints.maxWidth);
                  final overflow = tp.didExceedMaxLines;
                  return GestureDetector(
                    onTap: overflow ? () => setState(() => _expanded = !_expanded) : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          maxLines: _expanded ? null : 3,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: style,
                        ),
                        if (overflow)
                          Text(
                            _expanded ? 'less' : 'more',
                            style: style.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PhotoCarousel(
                    images: images,
                    heroPrefix: 'post-$postId',
                    height: 300,
                    onTap: (i) => ImageViewer.open(context, images, i, 'post-$postId'),
                    onDoubleTap: _doubleTapLike,
                  ),
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _burst,
                      builder: (context, _) {
                        final t = _burst.value;
                        if (t == 0 || t == 1) return const SizedBox.shrink();
                        final scale = Curves.elasticOut.transform((t * 1.6).clamp(0, 1));
                        return Opacity(
                          opacity: t < 0.7 ? 1 : (1 - (t - 0.7) / 0.3),
                          child: Transform.scale(
                            scale: scale,
                            child: const Icon(Icons.favorite_rounded, size: 96, color: Colors.white,
                                shadows: [Shadow(blurRadius: 24, color: Colors.black38)]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: liked ? 'Unlike' : 'Like',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    widget.onLike();
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(liked),
                      color: liked ? cs.error : cs.onSurface,
                    ),
                  ),
                ),
                Text('$likes', style: context.tt.labelLarge),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Comments',
                  onPressed: widget.onComment,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                Text('$comments', style: context.tt.labelLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
