import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.siteId,
    required this.siteName,
    required this.content,
    required this.imageUrl,
    required this.createdAt,
    required this.likedBy,
    required this.commentCount,
  });

  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String siteId;
  final String siteName;
  final String content;
  final String imageUrl;
  final DateTime createdAt;
  final List<String> likedBy;
  final int commentCount;

  int get likeCount => likedBy.length;
  bool isLikedBy(String uid) => likedBy.contains(uid);

  factory CommunityPost.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CommunityPost(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'MalaysiaGo User',
      userPhotoUrl: data['userPhotoUrl']?.toString() ?? '',
      siteId: data['siteId']?.toString() ?? '',
      siteName: data['siteName']?.toString() ?? 'Malaysia',
      content: data['content']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      createdAt: _toDate(data['createdAt']),
      likedBy: List<String>.from(data['likedBy'] ?? const <String>[]),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final DateTime createdAt;

  factory CommunityComment.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return CommunityComment(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? 'MalaysiaGo User',
      userPhotoUrl: data['userPhotoUrl']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      createdAt: _toDate(data['createdAt']),
    );
  }
}

DateTime _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.now();
}

class CommunityService {
  CommunityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('communityPosts');

  User? get currentUser => _auth.currentUser;

  Stream<List<CommunityPost>> getPosts() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CommunityPost.fromDoc).toList());
  }

  Stream<List<CommunityComment>> getComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CommunityComment.fromDoc).toList());
  }

  Future<Map<String, String>> _userIdentity() async {
    final User? user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'Please sign in first.',
      );
    }

    String name = user.displayName?.trim() ?? '';
    String photo = user.photoURL?.trim() ?? '';

    if (!user.isAnonymous) {
      final snapshot = await _firestore.collection('users').doc(user.uid).get();
      final data = snapshot.data();
      if (data != null) {
        final firestoreName = data['name']?.toString().trim() ?? '';
        final firestorePhoto = data['photoUrl']?.toString().trim() ?? '';
        if (firestoreName.isNotEmpty) name = firestoreName;
        if (firestorePhoto.isNotEmpty) photo = firestorePhoto;
      }
    }

    if (name.isEmpty) {
      name = user.isAnonymous ? 'Guest Explorer' : 'MalaysiaGo User';
    }

    return <String, String>{'name': name, 'photo': photo};
  }

  Future<void> createPost({
    required String siteId,
    required String siteName,
    required String content,
    String imageUrl = '',
  }) async {
    final User? user = currentUser;
    if (user == null) return;

    final identity = await _userIdentity();
    await _posts.add(<String, dynamic>{
      'userId': user.uid,
      'userName': identity['name'],
      'userPhotoUrl': identity['photo'],
      'siteId': siteId,
      'siteName': siteName.trim().isEmpty ? 'Malaysia' : siteName.trim(),
      'content': content.trim(),
      'imageUrl': imageUrl,
      'likedBy': <String>[],
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String postId) async {
    final User? user = currentUser;
    if (user == null) return;

    final ref = _posts.doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) return;

      final likedBy = List<String>.from(data['likedBy'] ?? const <String>[]);
      if (likedBy.contains(user.uid)) {
        likedBy.remove(user.uid);
      } else {
        likedBy.add(user.uid);
      }

      transaction.update(ref, <String, dynamic>{
        'likedBy': likedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deletePost(String postId) async {
    final User? user = currentUser;
    if (user == null) return;

    final ref = _posts.doc(postId);
    final snapshot = await ref.get();
    final data = snapshot.data();
    if (data?['userId'] != user.uid) {
      throw StateError('You can only delete your own post.');
    }

    final comments = await ref.collection('comments').get();
    final batch = _firestore.batch();
    for (final comment in comments.docs) {
      batch.delete(comment.reference);
    }
    batch.delete(ref);
    await batch.commit();
  }

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final User? user = currentUser;
    if (user == null) return;

    final identity = await _userIdentity();
    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc();

    final batch = _firestore.batch();
    batch.set(commentRef, <String, dynamic>{
      'userId': user.uid,
      'userName': identity['name'],
      'userPhotoUrl': identity['photo'],
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, <String, dynamic>{
      'commentCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final User? user = currentUser;
    if (user == null) return;

    final postRef = _posts.doc(postId);
    final commentRef = postRef.collection('comments').doc(commentId);
    final snapshot = await commentRef.get();

    if (snapshot.data()?['userId'] != user.uid) {
      throw StateError('You can only delete your own comment.');
    }

    final batch = _firestore.batch();
    batch.delete(commentRef);
    batch.update(postRef, <String, dynamic>{
      'commentCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> reportPost({
    required CommunityPost post,
    required String reason,
  }) async {
    final User? user = currentUser;
    if (user == null) return;
    if (post.userId == user.uid) {
      throw StateError('You cannot report your own post.');
    }

    final reportId = '${post.id}_${user.uid}';
    await _firestore.collection('communityReports').doc(reportId).set(
      <String, dynamic>{
        'postId': post.id,
        'postOwnerId': post.userId,
        'reporterId': user.uid,
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }
}
