import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //* get all chats
  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection("chats")
        .where("users", arrayContains: userId)
        .snapshots();
  }

  //* find users
  Stream<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection("users")
        .where("name", isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
 
  //* send message
  Future<void> sendMessage(
      String chatId, String message, String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      await _firestore
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .add(
        {
          "senderId": currentUser.uid,
          "receiverId": receiverId,
          "messageBody": message,
          "timestamp": FieldValue.serverTimestamp(),
        },
      );
    }

    await _firestore.collection("chats").doc(chatId).set(
      {
        "users": [currentUser?.uid, receiverId],
        "lastMessage": message,
        "timestamp": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<String?> getChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final chatQuery = await _firestore
          .collection("chats")
          .where("users", arrayContains: currentUser.uid)
          .get();
      final chats = chatQuery.docs.where(
        (chat) => (chat["users"] as List).contains(receiverId),
      );

      if (chats.isNotEmpty) {
        return chats.first.id;
      }
    }
    return null;
  }

  Future<String> createChatRoom(String receiverId) async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final chatRoom = await _firestore.collection("chats").add({
        "users": [currentUser.uid, receiverId],
        "lastMessage": "",
        "timestamp": FieldValue.serverTimestamp(),
      });

      return chatRoom.id;
    }
    throw Exception("Current User is Null");
  }
}
