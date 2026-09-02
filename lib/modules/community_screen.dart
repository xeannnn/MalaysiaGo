import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/cloudinary_service.dart';
import '../services/community_service.dart';
import 'mappage.dart';

enum CommunityFilter { all, mine, popular }

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    super.key,
    required this.onViewOnMap,
  });

  final ValueChanged<String> onViewOnMap;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  CommunityFilter _filter = CommunityFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Community', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              'Share your Malaysia journey',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Post'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search posts or heritage places',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<CommunityFilter>(
              segments: const <ButtonSegment<CommunityFilter>>[
                ButtonSegment<CommunityFilter>(
                  value: CommunityFilter.all,
                  icon: Icon(Icons.public),
                  label: Text('All'),
                ),
                ButtonSegment<CommunityFilter>(
                  value: CommunityFilter.mine,
                  icon: Icon(Icons.person_outline),
                  label: Text('My Posts'),
                ),
                ButtonSegment<CommunityFilter>(
                  value: CommunityFilter.popular,
                  icon: Icon(Icons.local_fire_department_outlined),
                  label: Text('Most Liked'),
                ),
              ],
              selected: <CommunityFilter>{_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _service.getPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _StateMessage(
                    icon: Icons.cloud_off_outlined,
                    title: 'Unable to load Community',
                    subtitle: '${snapshot.error}',
                  );
                }

                List<CommunityPost> posts =
                    List<CommunityPost>.from(snapshot.data ?? const <CommunityPost>[]);

                if (_filter == CommunityFilter.mine) {
                  posts = posts.where((post) => post.userId == currentUid).toList();
                } else if (_filter == CommunityFilter.popular) {
                  posts.sort((a, b) {
                    final byLikes = b.likeCount.compareTo(a.likeCount);
                    if (byLikes != 0) return byLikes;
                    return b.createdAt.compareTo(a.createdAt);
                  });
                }

                final String query = _query.toLowerCase();
                if (query.isNotEmpty) {
                  posts = posts.where((post) {
                    return post.content.toLowerCase().contains(query) ||
                        post.siteName.toLowerCase().contains(query) ||
                        post.userName.toLowerCase().contains(query);
                  }).toList();
                }

                if (posts.isEmpty) {
                  return _StateMessage(
                    icon: _query.isNotEmpty
                        ? Icons.search_off
                        : Icons.forum_outlined,
                    title: _query.isNotEmpty
                        ? 'No matching posts'
                        : _filter == CommunityFilter.mine
                            ? 'You have not posted yet'
                            : 'No posts yet',
                    subtitle: _query.isNotEmpty
                        ? 'Try another search term.'
                        : 'Be the first to share a heritage journey.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _PostCard(
                      post: post,
                      currentUid: currentUid,
                      service: _service,
                      onComments: () => _openComments(post),
                      onReport: () => _openReport(post),
                      onViewOnMap: () => widget.onViewOnMap(post.siteId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreatePost() async {
    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) => CreateCommunityPostSheet(service: _service),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared with the community.')),
      );
    }
  }

  Future<void> _openReport(CommunityPost post) async {
    const reasons = <String>[
      'Spam',
      'Inappropriate Content',
      'Incorrect Information',
      'Harassment',
      'Other',
    ];

    final String? reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Report Post',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('Why are you reporting this post?'),
              const SizedBox(height: 12),
              ...reasons.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: Text(item),
                  onTap: () => Navigator.pop(sheetContext, item),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (reason == null || !mounted) return;

    try {
      await _service.reportPost(post: post, reason: reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted. Thank you for helping keep Community safe.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void _openComments(CommunityPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CommentsSheet(post: post, service: _service),
    );
  }
}

class CreateCommunityPostSheet extends StatefulWidget {
  const CreateCommunityPostSheet({
    super.key,
    required this.service,
  });

  final CommunityService service;

  @override
  State<CreateCommunityPostSheet> createState() =>
      _CreateCommunityPostSheetState();
}

class _CreateCommunityPostSheetState
    extends State<CreateCommunityPostSheet> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  XFile? _selectedImage;
  HeritageMapSite? _selectedSite;
  bool _submitting = false;
  int _characterCount = 0;

  static const int _maxCharacters = 500;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null || !mounted) return;

      setState(() => _selectedImage = image);
    } catch (error) {
      if (mounted) {
        _message('Unable to select photo: $error');
      }
    }
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();

    if (_selectedSite == null) {
      _message('Please choose a heritage site.');
      return;
    }

    if (content.isEmpty) {
      _message('Write something about your visit.');
      return;
    }

    setState(() => _submitting = true);

    try {
      String imageUrl = '';

      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      }

      await widget.service.createPost(
        siteId: _selectedSite!.id,
        siteName: _selectedSite!.name,
        content: content,
        imageUrl: imageUrl,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _message('Unable to create post: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Create Post',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<HeritageMapSite>(
              initialValue: _selectedSite,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Heritage Site',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
                helperText: 'Choose a site already available in MalaysiaGo',
              ),
              items: heritageMapSites
                  .map(
                    (site) => DropdownMenuItem<HeritageMapSite>(
                      value: site,
                      child: Text('${site.icon} ${site.name} · ${site.location}'),
                    ),
                  )
                  .toList(),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _selectedSite = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              enabled: !_submitting,
              minLines: 4,
              maxLines: 7,
              maxLength: _maxCharacters,
              onChanged: (value) => setState(() => _characterCount = value.length),
              decoration: InputDecoration(
                labelText: 'Share your experience',
                hintText: 'What did you enjoy, learn, or recommend?',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                counterText: '$_characterCount/$_maxCharacters',
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedImage != null) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 180,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Image.memory(
                      snapshot.data!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  TextButton.icon(
                    onPressed: _submitting ? null : _pickImage,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Change Photo'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _selectedImage = null),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ],
              ),
            ] else
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Photo'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(_submitting ? 'Sharing...' : 'Share Post'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.post,
    required this.currentUid,
    required this.service,
    required this.onComments,
    required this.onReport,
    required this.onViewOnMap,
  });

  final CommunityPost post;
  final String currentUid;
  final CommunityService service;
  final VoidCallback onComments;
  final VoidCallback onReport;
  final VoidCallback onViewOnMap;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _liking = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final liked = post.isLikedBy(widget.currentUid);
    final own = post.userId == widget.currentUid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x0C000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _UserAvatar(name: post.userName, photoUrl: post.userPhotoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      post.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _relativeTime(post.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete Post?'),
                        content: const Text(
                          'This post and its comments will be permanently deleted.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await widget.service.deletePost(post.id);
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$error')),
                          );
                        }
                      }
                    }
                  } else if (value == 'report') {
                    widget.onReport();
                  }
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  if (own)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.flag_outlined),
                          SizedBox(width: 8),
                          Text('Report Post'),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F9EF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF1F8A5C),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    post.siteName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F8A5C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (post.imageUrl.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                post.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  height: 160,
                  alignment: Alignment.center,
                  color: const Color(0xFFF1F1F1),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.broken_image_outlined),
                      SizedBox(height: 6),
                      Text('Image unavailable'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onViewOnMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('View on Map'),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              TextButton.icon(
                onPressed: _liking
                    ? null
                    : () async {
                        setState(() => _liking = true);
                        try {
                          await widget.service.toggleLike(post.id);
                        } finally {
                          if (mounted) setState(() => _liking = false);
                        }
                      },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(liked),
                    color: liked ? Colors.red : null,
                  ),
                ),
                label: Text('${post.likeCount}'),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: widget.onComments,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('${post.commentCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({
    super.key,
    required this.post,
    required this.service,
  });

  final CommunityPost post;
  final CommunityService service;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    try {
      await widget.service.addComment(postId: widget.post.id, content: content);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.76,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Comments',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<CommunityComment>>(
                stream: widget.service.getComments(widget.post.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data ?? const <CommunityComment>[];
                  if (comments.isEmpty) {
                    return const _StateMessage(
                      icon: Icons.chat_bubble_outline,
                      title: 'No comments yet',
                      subtitle: 'Start the conversation.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final bool own = comment.userId == uid;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _UserAvatar(
                            name: comment.userName,
                            photoUrl: comment.userPhotoUrl,
                            radius: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          comment.userName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Text(
                                        _relativeTime(comment.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      if (own)
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          onSelected: (value) async {
                                            if (value == 'delete') {
                                              await widget.service.deleteComment(
                                                postId: widget.post.id,
                                                commentId: comment.id,
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              child: Text('Delete'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment.content),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.name,
    required this.photoUrl,
    this.radius = 21,
  });

  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photoUrl));
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE9F9EF),
      child: Text(
        name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF1F8A5C),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 54, color: Colors.grey[400]),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final Duration difference = DateTime.now().difference(date);
  if (difference.isNegative || difference.inSeconds < 45) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays == 1) return 'Yesterday';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
  return '${date.day}/${date.month}/${date.year}';
}