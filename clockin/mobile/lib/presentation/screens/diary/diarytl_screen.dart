import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clockin/core/config/theme.dart';
import 'package:clockin/core/services/api_service.dart';
import 'package:clockin/core/state/data_sync.dart';
import 'package:clockin/core/utils/date_utils.dart';
import 'package:clockin/presentation/widgets/avatar.dart';
import 'package:clockin/presentation/widgets/diary_card.dart';
import 'package:clockin/presentation/widgets/dialogs.dart';
import 'package:clockin/presentation/widgets/empty_state.dart';
import 'package:clockin/presentation/widgets/skeleton.dart';

/// The Feed tab: everyone's public journal entries.
class DiarytlScreen extends StatefulWidget {
  const DiarytlScreen({super.key});

  @override
  State<DiarytlScreen> createState() => _DiarytlScreenState();
}

class _DiarytlScreenState extends State<DiarytlScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  String _currentUserId = '';
  DataSync? _sync;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sync == null) {
      _sync = context.read<DataSync>();
      _sync!.addListener(_onSync);
    }
  }

  @override
  void dispose() {
    _sync?.removeListener(_onSync);
    super.dispose();
  }

  void _onSync() {
    if (_sync?.source != this) _fetchPosts(silent: true);
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchPosts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      // The logged-in user's id is stored under 'id' by UserService.saveUserData.
      _currentUserId = prefs.getString('id') ?? '';
      final posts = await ApiService.getPosts(token);
      if (!mounted) return;
      setState(() {
        _error = null;
        _posts = posts.map((e) => (e as Map).cast<String, dynamic>()).toList();
      });
    } catch (e) {
      if (mounted && !silent) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Optimistic like/unlike, reconciled with the server's response.
  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final postId = (post['_id'] ?? '').toString();
    final prevLikes = post['likes'];
    final prevLikedBy = post['likedBy'];
    final likedBy = (post['likedBy'] is List ? (post['likedBy'] as List).map((e) => e.toString()).toList() : <String>[]);
    final wasLiked = likedBy.contains(_currentUserId);
    setState(() {
      if (wasLiked) {
        likedBy.remove(_currentUserId);
      } else {
        likedBy.add(_currentUserId);
      }
      post['likedBy'] = likedBy;
      post['likes'] = ((prevLikes ?? 0) as num) + (wasLiked ? -1 : 1);
    });
    try {
      final result = await ApiService.toggleLike(await _token(), postId);
      if (!mounted) return;
      setState(() {
        post['likes'] = result['likes'];
        post['likedBy'] = result['likedBy'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        post['likes'] = prevLikes;
        post['likedBy'] = prevLikedBy;
      });
      showAppSnack(context, 'Failed to toggle like: ${friendlyError(e)}');
    }
  }

  Future<void> _showComments(int index) async {
    final postId = (_posts[index]['_id'] ?? '').toString();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _CommentsSheet(postId: postId),
    );
    _fetchPosts(silent: true); // Refresh posts to get updated comment counts
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Feed', style: context.tt.headlineMedium),
                            Text(
                              'What everyone has been clocking',
                              style: context.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const AppLogo(size: 30),
                    ],
                  ),
                ),
              ),
            ),
            if (_loading)
              SliverToBoxAdapter(child: _skeleton())
            else if (_error != null)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn\'t load the feed',
                  message: _error,
                  actionLabel: 'Try again',
                  onAction: _fetchPosts,
                ),
              )
            else if (_posts.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.dynamic_feed_rounded,
                  title: 'No public tasks yet',
                  message: 'Complete tasks and share them from your Journal to see them here.',
                ),
              )
            else
              SliverList.builder(
                itemCount: _posts.length,
                itemBuilder: (context, i) => DiaryCard(
                  key: ValueKey(_posts[i]['_id']),
                  post: _posts[i],
                  currentUserId: _currentUserId,
                  onLike: () => _toggleLike(i),
                  onComment: () => _showComments(i),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 24)),
          ],
        ),
      ),
    );
  }

  Widget _skeleton() {
    return Shimmer(
      child: Column(
        children: List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(children: [
                  SkeletonBox(height: 40, circle: true),
                  SizedBox(width: 10),
                  SkeletonBox(width: 120, height: 14),
                ]),
                SizedBox(height: 12),
                SkeletonBox(width: 200, height: 16),
                SizedBox(height: 12),
                SkeletonBox(height: 240, radius: AppRadius.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Comments for a post, with a sticky input bar.
class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _commentCtrl.addListener(() => setState(() {}));
    _fetchComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await ApiService.getComments(await _token(), widget.postId);
      if (!mounted) return;
      setState(() => _comments = comments.map((e) => (e as Map).cast<String, dynamic>()).toList());
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to load comments: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addComment() async {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final res = await ApiService.addComment(await _token(), widget.postId, comment);
      _commentCtrl.clear();
      final list = res['comments'];
      if (list is List && mounted) {
        setState(() => _comments = list.map((e) => (e as Map).cast<String, dynamic>()).toList());
      } else {
        await _fetchComments();
      }
    } catch (e) {
      if (mounted) showAppSnack(context, 'Failed to add comment: ${friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final media = MediaQuery.of(context);
    final canSend = _commentCtrl.text.trim().isNotEmpty && !_sending;
    return SizedBox(
      height: media.size.height * 0.72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Text('Comments', style: context.tt.titleLarge),
                const SizedBox(width: 8),
                if (!_loading) Text('${_comments.length}', style: context.tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No comments yet',
                          message: 'Be the first to comment!',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) {
                          final c = _comments[i];
                          final username = (c['username'] ?? 'User').toString();
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Avatar(imageUrl: (c['profilePicture'] ?? '').toString(), name: username, radius: 17),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHigh,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                      topLeft: Radius.circular(4),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(username, style: context.tt.labelLarge),
                                          const SizedBox(width: 6),
                                          Text(
                                            timeAgo((c['createdAt'] ?? '').toString()),
                                            style: context.tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text((c['comment'] ?? '').toString(), style: context.tt.bodyMedium),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, 8 + media.viewInsets.bottom),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant))),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _addComment(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cs.outlineVariant)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cs.outlineVariant)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cs.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: canSend ? _addComment : null,
                    style: IconButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
                    icon: _sending
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary))
                        : const Icon(Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
