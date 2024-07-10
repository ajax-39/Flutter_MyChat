// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:mychat/provider/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverId,
  });

  final String chatId;
  final String receiverId;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? loggedInUser;

  String? chatId;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    chatId = widget.chatId;
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final textController = TextEditingController();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection("users").doc(widget.receiverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final receiverData = snapshot.data!.data() as Map<String, dynamic>;

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(receiverData["imageUrl"]),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    receiverData["name"],
                  )
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: chatId != null && chatId!.isNotEmpty
                      ? MessageStream(chatId: chatId!)
                      : const Text('No Messages Yet!'),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: "Enter your Message...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                          onPressed: () async {
                            if (textController.text.isNotEmpty) {
                              if (chatId == null || chatId!.isEmpty) {
                                chatId = await chatProvider
                                    .createChatRoom(widget.receiverId);
                              }

                              if (chatId != null) {
                                chatProvider.sendMessage(chatId!,
                                    textController.text, widget.receiverId);
                                textController.clear();
                              }
                            }
                          },
                          icon: const Icon(Icons.send))
                    ],
                  ),
                )
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({
    super.key,
    required this.chatId,
  });
  final String chatId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final messages = snapshot.data!.docs;

        List<MessageBubble> messagesWidgets = [];

        for (var message in messages) {
          final messageData = message.data() as Map<String, dynamic>;
          final messageText = messageData["messageBody"];
          final messageSender = messageData["senderId"];
          final timeStamp =
              messageData["timestamp"] ?? FieldValue.serverTimestamp();

          final currentUser = FirebaseAuth.instance.currentUser!.uid;

          final messageWidget = MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: currentUser == messageSender,
            timestamp: timeStamp,
          );

          messagesWidgets.add(messageWidget);
        }
        return ListView(
          reverse: true,
          children: messagesWidgets,
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.sender,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  final String sender;
  final String text;
  final bool isMe;
  final dynamic timestamp;

  @override
  Widget build(BuildContext context) {
    final DateTime messageTime =
        (timestamp is Timestamp) ? timestamp.toDate() : DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: isMe ? Colors.blue : Colors.grey,
                  blurRadius: 1,
                  spreadRadius: 2,
                )
              ],
              borderRadius: isMe
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15))
                  : const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "${messageTime.hour} : ${messageTime.minute}",
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
