import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/community_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _communityService = CommunityService();

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'My Posts',
  ];

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Share your Malaysia journey',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ====================================================
          // FILTER
          // ====================================================

          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              14,
            ),
            child: Wrap(
              spacing: 8,
              children: _filters.map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // ====================================================
          // FEED
          // ====================================================

          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _selectedFilter == 'My Posts'
                  ? _communityService.getMyPosts()
                  : _communityService.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: snapshot.error.toString(),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<CommunityPost> posts =
                    snapshot.data ?? const [];

                if (posts.isEmpty) {
                  return _EmptyCommunity(
                    myPosts:
                    _selectedFilter == 'My Posts',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                      const Duration(
                        milliseconds: 400,
                      ),
                    );
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return CommunityPostCard(
                        post: posts[index],
                        currentUserId: user?.uid ?? '',
                        communityService:
                        _communityService,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ========================================================
      // CREATE POST BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreatePostDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
    );
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> _showCreatePostDialog() async {
    final TextEditingController siteController =
    TextEditingController();

    final TextEditingController contentController =
    TextEditingController();

    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return CreateCommunityPostSheet(
          siteController: siteController,
          contentController: contentController,
          communityService: _communityService,
        );
      },
    );

    siteController.dispose();
    contentController.dispose();

    if (!mounted) {
      return;
    }

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post shared with the community!',
          ),
        ),
      );
    }
  }
}

// ============================================================
// POST CARD
// ============================================================

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.communityService,
  });

  final CommunityPost post;
  final String currentUserId;
  final CommunityService communityService;

  @override
  Widget build(BuildContext context) {
    final bool liked =
    post.isLikedBy(currentUserId);

    final bool ownPost =
        post.userId == currentUserId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER
          Row(
            children: [
              _UserAvatar(
                photoUrl: post.userPhotoUrl,
                name: post.userName,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      _formatTime(post.createdAt),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (ownPost)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Post',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 14),

          // LOCATION
          if (post.siteName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F9EF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Color(0xFF1F8A5C),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.siteName,
                    style: const TextStyle(
                      color: Color(0xFF1F8A5C),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // POST CONTENT
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),

          // IMAGE - ready for later
          if (post.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],

          const SizedBox(height: 14),

          const Divider(height: 1),

          const SizedBox(height: 4),

          // LIKE + COMMENT
          Row(
            children: [
              TextButton.icon(
                onPressed: () async {
                  try {
                    await communityService.toggleLike(
                      post.id,
                    );
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          'Unable to like post: $error',
                        ),
                      ),
                    );
                  }
                },
                icon: Icon(
                  liked
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                  liked ? Colors.red : Colors.grey,
                ),
                label: Text(
                  post.likeCount == 0
                      ? 'Like'
                      : '${post.likeCount}',
                ),
              ),

              const SizedBox(width: 8),

              TextButton.icon(
                onPressed: () {
                  _showComments(context);
                },
                icon: const Icon(
                  Icons.chat_bubble_outline,
                ),
                label: Text(
                  post.commentCount == 0
                      ? 'Comment'
                      : '${post.commentCount}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE POST
  // ============================================================

  Future<void> _confirmDelete(
      BuildContext context,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await communityService.deletePost(
        post.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to delete post: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  void _showComments(
      BuildContext context,
      ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return CommunityCommentsSheet(
          post: post,
          communityService: communityService,
        );
      },
    );
  }

  static String _formatTime(
      DateTime date,
      ) {
    final Duration difference =
    DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// CREATE POST SHEET
// ============================================================

class CreateCommunityPostSheet extends StatefulWidget {
  const CreateCommunityPostSheet({
    super.key,
    required this.siteController,
    required this.contentController,
    required this.communityService,
  });

  final TextEditingController siteController;
  final TextEditingController contentController;
  final CommunityService communityService;

  @override
  State<CreateCommunityPostSheet> createState() =>
      _CreateCommunityPostSheetState();
}

class _CreateCommunityPostSheetState
    extends State<CreateCommunityPostSheet> {
  bool _posting = false;
  String? _error;

  Future<void> _createPost() async {
    final String site =
    widget.siteController.text.trim();

    final String content =
    widget.contentController.text.trim();

    if (site.isEmpty) {
      setState(() {
        _error =
        'Please enter the heritage place.';
      });
      return;
    }

    if (content.isEmpty) {
      setState(() {
        _error =
        'Write something about your experience.';
      });
      return;
    }

    setState(() {
      _posting = true;
      _error = null;
    });

    try {
      await widget.communityService.createPost(
        siteId: site.toLowerCase().replaceAll(
          ' ',
          '_',
        ),
        siteName: site,
        content: content,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _posting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        keyboardHeight + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Share Your Experience',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _posting
                      ? null
                      : () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 18),

            TextField(
              controller: widget.siteController,
              enabled: !_posting,
              decoration: const InputDecoration(
                labelText: 'Heritage Place',
                hintText: 'e.g. Batu Caves',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
              widget.contentController,
              enabled: !_posting,
              minLines: 4,
              maxLines: 7,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText:
                'Share your experience',
                hintText:
                'What did you enjoy about this place?',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                _posting ? null : _createPost,
                icon: _posting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _posting
                      ? 'Posting...'
                      : 'Share Post',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMMENTS SHEET
// ============================================================

class CommunityCommentsSheet
    extends StatefulWidget {
  const CommunityCommentsSheet({
    super.key,
    required this.post,
    required this.communityService,
  });

  final CommunityPost post;
  final CommunityService communityService;

  @override
  State<CommunityCommentsSheet> createState() =>
      _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState
    extends State<CommunityCommentsSheet> {
  final TextEditingController _controller =
  TextEditingController();

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await widget.communityService.addComment(
        postId: widget.post.id,
        content: _controller.text,
      );

      _controller.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to comment: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom:
          MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height:
          MediaQuery.of(context).size.height *
              0.75,
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                  BorderRadius.circular(20),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: StreamBuilder<
                    List<CommunityComment>>(
                  stream: widget.communityService
                      .getComments(
                    widget.post.id,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString(),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    final comments =
                    snapshot.data!;

                    if (comments.isEmpty) {
                      return const Center(
                        child: Text(
                          'No comments yet.\nBe the first to comment!',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding:
                      const EdgeInsets.all(16),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(
                        height: 14,
                      ),
                      itemBuilder: (context, index) {
                        final comment =
                        comments[index];

                        return Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            _UserAvatar(
                              photoUrl:
                              comment.userPhotoUrl,
                              name:
                              comment.userName,
                              radius: 18,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Container(
                                padding:
                                const EdgeInsets.all(
                                  12,
                                ),
                                decoration:
                                BoxDecoration(
                                  color: const Color(
                                    0xFFF5F5F7,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Text(
                                      comment.userName,
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    Text(
                                      comment.content,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (comment.userId ==
                                user?.uid)
                              IconButton(
                                onPressed: () async {
                                  try {
                                    await widget
                                        .communityService
                                        .deleteComment(
                                      postId:
                                      widget.post.id,
                                      commentId:
                                      comment.id,
                                    );
                                  } catch (error) {
                                    if (!context
                                        .mounted) {
                                      return;
                                    }

                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          error.toString(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        decoration:
                        const InputDecoration(
                          hintText:
                          'Write a comment...',
                          border:
                          OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    IconButton.filled(
                      onPressed:
                      _sending
                          ? null
                          : _sendComment,
                      icon: _sending
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(
                        Icons.send,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// USER AVATAR
// ============================================================

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.photoUrl,
    required this.name,
    this.radius = 21,
  });

  final String photoUrl;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage:
        NetworkImage(photoUrl),
      );
    }

    final String initial = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: radius,
      backgroundColor:
      const Color(0xFFE9F9EF),
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF1F8A5C),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyCommunity extends StatelessWidget {
  const _EmptyCommunity({
    required this.myPosts,
  });

  final bool myPosts;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              myPosts
                  ? 'You haven\'t posted yet'
                  : 'No community posts yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              myPosts
                  ? 'Share your first heritage experience!'
                  : 'Be the first traveller to share an experience.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load community',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}