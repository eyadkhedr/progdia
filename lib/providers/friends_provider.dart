import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String username;
  final int coins;
  final int streak;
  // Add other user properties you want to display
  // final String characterUrl;

  AppUser({
    required this.uid,
    required this.username,
    this.coins = 0,
    this.streak = 0,
    // required this.characterUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      username: data['username'] ?? '',
      coins: data['coins'] ?? 0,
      streak: data['dayStreak'] ?? 0,
      // characterUrl: data['characterUrl'] ?? '',
    );
  }
}

class FriendsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<AppUser> _friends = [];
  List<AppUser> get friends => _friends;

  List<DocumentSnapshot> _friendRequests = [];
  List<DocumentSnapshot> get friendRequests => _friendRequests;

  Future<AppUser?> searchUserByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return AppUser.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error searching for user: $e');
      return null;
    }
  }

  Future<void> sendFriendRequest(String recipientId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Add to recipient's friend requests
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('friend_requests')
          .doc(currentUser.uid)
          .set({
        'senderId': currentUser.uid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending friend request: $e');
    }
  }

  Future<void> fetchFriendRequests() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      
      _friendRequests = snapshot.docs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching friend requests: $e');
    }
  }

  Future<void> acceptFriendRequest(String senderId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Add to current user's friends list
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(senderId)
          .set({'friendId': senderId});

      // Add to sender's friends list
      await _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUser.uid)
          .set({'friendId': currentUser.uid});

      // Update the request status
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .doc(senderId)
          .update({'status': 'accepted'});

      fetchFriends();
      fetchFriendRequests();
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
    }
  }

  Future<void> rejectFriendRequest(String senderId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friend_requests')
          .doc(senderId)
          .update({'status': 'rejected'});

      fetchFriendRequests();
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
    }
  }

  Future<void> fetchFriends() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .get();

      final friendIds = snapshot.docs.map((doc) => doc.id).toList();
      if (friendIds.isEmpty) {
        _friends = [];
        notifyListeners();
        return;
      }
      
      final friendsSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();
      
      _friends = friendsSnapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching friends: $e');
    }
  }

  Future<void> deleteFriend(String friendId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Delete from current user's friends list
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('friends')
          .doc(friendId)
          .delete();

      // Delete from the other user's friends list
      await _firestore
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(currentUser.uid)
          .delete();

      // Refresh the local friends list
      fetchFriends();
    } catch (e) {
      debugPrint('Error deleting friend: $e');
    }
  }
} 