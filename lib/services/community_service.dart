import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models.dart';

class CommunityService {
  CommunityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('communityPosts');

  User? get currentUser => _firebaseAuth.currentUser;

  // ============================================================
  // LIVE COMMUNITY POSTS
  // ============================================================

  Stream<List<CommunityPost>> getPosts() {
    return _posts
        .orderBy(
      'createdAt',
      descending: true,
    )
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs.map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();

            return CommunityPost(
              id: doc.id,
              userId:
              data['userId']?.toString() ?? '',
              userName:
              data['userName']?.toString() ??
                  'MalaysiaGo User',
              userPhotoUrl:
              data['userPhotoUrl']?.toString() ?? '',
              siteId:
              data['siteId']?.toString() ?? '',
              siteName:
              data['siteName']?.toString() ?? '',
              content:
              data['content']?.toString() ?? '',
              imageUrl:
              data['imageUrl']?.toString() ?? '',
              createdAt: _dateFromFirestore(
                data['createdAt'],
              ),
              likedBy: List<String>.from(
                data['likedBy'] ?? const [],
              ),
              commentCount:
              (data['commentCount'] as num?)?.toInt() ?? 0,
            );
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // POSTS BY HERITAGE SITE
  // ============================================================

  Stream<List<CommunityPost>> getPostsBySite(
      String siteId,
      ) {
    return _posts
        .where(
      'siteId',
      isEqualTo: siteId,
    )
        .orderBy(
      'createdAt',
      descending: true,
    )
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs.map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();

            return CommunityPost(
              id: doc.id,
              userId:
              data['userId']?.toString() ?? '',
              userName:
              data['userName']?.toString() ??
                  'MalaysiaGo User',
              userPhotoUrl:
              data['userPhotoUrl']?.toString() ?? '',
              siteId:
              data['siteId']?.toString() ?? '',
              siteName:
              data['siteName']?.toString() ?? '',
              content:
              data['content']?.toString() ?? '',
              imageUrl:
              data['imageUrl']?.toString() ?? '',
              createdAt: _dateFromFirestore(
                data['createdAt'],
              ),
              likedBy: List<String>.from(
                data['likedBy'] ?? const [],
              ),
              commentCount:
              (data['commentCount'] as num?)?.toInt() ?? 0,
            );
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // CURRENT USER POSTS
  // ============================================================

  Stream<List<CommunityPost>> getMyPosts() {
    final User? user = currentUser;

    if (user == null) {
      return Stream<List<CommunityPost>>.value(
        const [],
      );
    }

    return _posts
        .where(
      'userId',
      isEqualTo: user.uid,
    )
        .orderBy(
      'createdAt',
      descending: true,
    )
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs.map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();

            return CommunityPost(
              id: doc.id,
              userId:
              data['userId']?.toString() ?? '',
              userName:
              data['userName']?.toString() ??
                  'MalaysiaGo User',
              userPhotoUrl:
              data['userPhotoUrl']?.toString() ?? '',
              siteId:
              data['siteId']?.toString() ?? '',
              siteName:
              data['siteName']?.toString() ?? '',
              content:
              data['content']?.toString() ?? '',
              imageUrl:
              data['imageUrl']?.toString() ?? '',
              createdAt: _dateFromFirestore(
                data['createdAt'],
              ),
              likedBy: List<String>.from(
                data['likedBy'] ?? const [],
              ),
              commentCount:
              (data['commentCount'] as num?)?.toInt() ?? 0,
            );
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Future<void> createPost({
    required String siteId,
    required String siteName,
    required String content,
    String imageUrl = '',
  }) async {
    final User? user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'You must be logged in to create a post.',
      );
    }

    final String trimmedContent =
    content.trim();

    if (trimmedContent.isEmpty) {
      throw ArgumentError(
        'Post content cannot be empty.',
      );
    }

    String userName =
        user.displayName?.trim() ?? '';

    String userPhotoUrl =
        user.photoURL ?? '';

    try {
      final DocumentSnapshot<Map<String, dynamic>>
      profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (profile.exists) {
        final Map<String, dynamic>? data =
        profile.data();

        final String firestoreName =
            data?['name']?.toString().trim() ?? '';

        final String firestorePhoto =
            data?['photoUrl']?.toString() ?? '';

        if (firestoreName.isNotEmpty) {
          userName = firestoreName;
        }

        if (firestorePhoto.isNotEmpty) {
          userPhotoUrl = firestorePhoto;
        }
      }
    } catch (_) {
      // Firebase Auth information will be used as fallback.
    }

    if (userName.isEmpty) {
      userName = 'MalaysiaGo User';
    }

    await _posts.add({
      'userId': user.uid,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'siteId': siteId,
      'siteName': siteName,
      'content': trimmedContent,
      'imageUrl': imageUrl.trim(),
      'likedBy': <String>[],
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE OWN POST
  // ============================================================

  Future<void> deletePost(
      String postId,
      ) async {
    final User? user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'You must be logged in.',
      );
    }

    final DocumentReference<Map<String, dynamic>> postRef =
    _posts.doc(postId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
    await postRef.get();

    if (!snapshot.exists) {
      return;
    }

    final String ownerId =
        snapshot.data()?['userId']?.toString() ?? '';

    if (ownerId != user.uid) {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'You can only delete your own posts.',
      );
    }

    final QuerySnapshot<Map<String, dynamic>> comments =
    await postRef
        .collection('comments')
        .get();

    final WriteBatch batch =
    _firestore.batch();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> comment
    in comments.docs) {
      batch.delete(comment.reference);
    }

    batch.delete(postRef);

    await batch.commit();
  }

  // ============================================================
  // LIKE / UNLIKE POST
  // ============================================================

  Future<void> toggleLike(
      String postId,
      ) async {
    final User? user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'You must be logged in to like a post.',
      );
    }

    final DocumentReference<Map<String, dynamic>> postRef =
    _posts.doc(postId);

    await _firestore.runTransaction(
          (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await transaction.get(
          postRef,
        );

        if (!snapshot.exists) {
          return;
        }

        final List<String> likedBy =
        List<String>.from(
          snapshot.data()?['likedBy'] ?? const [],
        );

        if (likedBy.contains(user.uid)) {
          likedBy.remove(user.uid);
        } else {
          likedBy.add(user.uid);
        }

        transaction.update(
          postRef,
          {
            'likedBy': likedBy,
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // COMMENTS STREAM
  // ============================================================

  Stream<List<CommunityComment>> getComments(
      String postId,
      ) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy(
      'createdAt',
    )
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs.map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final Map<String, dynamic> data = doc.data();

            return CommunityComment(
              id: doc.id,
              postId: postId,
              userId:
              data['userId']?.toString() ?? '',
              userName:
              data['userName']?.toString() ??
                  'MalaysiaGo User',
              userPhotoUrl:
              data['userPhotoUrl']?.toString() ?? '',
              content:
              data['content']?.toString() ?? '',
              createdAt: _dateFromFirestore(
                data['createdAt'],
              ),
            );
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // ADD COMMENT
  // ============================================================

  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-signed-in',
        message: 'You must be logged in to comment.',
      );
    }

    final String trimmedContent =
    content.trim();

    if (trimmedContent.isEmpty) {
      return;
    }

    String userName =
        user.displayName?.trim() ?? '';

    String userPhotoUrl =
        user.photoURL ?? '';

    try {
      final DocumentSnapshot<Map<String, dynamic>>
      profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (profile.exists) {
        final Map<String, dynamic>? data =
        profile.data();

        final String firestoreName =
            data?['name']?.toString().trim() ?? '';

        final String firestorePhoto =
            data?['photoUrl']?.toString() ?? '';

        if (firestoreName.isNotEmpty) {
          userName = firestoreName;
        }

        if (firestorePhoto.isNotEmpty) {
          userPhotoUrl = firestorePhoto;
        }
      }
    } catch (_) {
      // Use Firebase Authentication profile as fallback.
    }

    if (userName.isEmpty) {
      userName = 'MalaysiaGo User';
    }

    final DocumentReference<Map<String, dynamic>> postRef =
    _posts.doc(postId);

    final DocumentReference<Map<String, dynamic>> commentRef =
    postRef
        .collection('comments')
        .doc();

    final WriteBatch batch =
    _firestore.batch();

    batch.set(
      commentRef,
      {
        'userId': user.uid,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': trimmedContent,
        'createdAt':
        FieldValue.serverTimestamp(),
      },
    );

    batch.update(
      postRef,
      {
        'commentCount':
        FieldValue.increment(1),
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ============================================================
  // DELETE OWN COMMENT
  // ============================================================

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    final User? user = currentUser;

    if (user == null) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> postRef =
    _posts.doc(postId);

    final DocumentReference<Map<String, dynamic>> commentRef =
    postRef
        .collection('comments')
        .doc(commentId);

    final DocumentSnapshot<Map<String, dynamic>> comment =
    await commentRef.get();

    if (!comment.exists) {
      return;
    }

    final String ownerId =
        comment.data()?['userId']?.toString() ?? '';

    if (ownerId != user.uid) {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message:
        'You can only delete your own comments.',
      );
    }

    final WriteBatch batch =
    _firestore.batch();

    batch.delete(commentRef);

    batch.update(
      postRef,
      {
        'commentCount':
        FieldValue.increment(-1),
        'updatedAt':
        FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ============================================================
  // DATE CONVERSION
  // ============================================================

  static DateTime _dateFromFirestore(
      dynamic value,
      ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }
}