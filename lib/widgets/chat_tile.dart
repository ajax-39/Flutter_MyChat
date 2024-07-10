// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:mychat/screens/chat_screen.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.chatID,
    required this.lastMessage,
    required this.timestamp,
    required this.receiverData,
  });

  final String chatID;
  final String lastMessage;
  final DateTime timestamp;
  final Map<String, dynamic> receiverData;

  @override
  Widget build(BuildContext context) {
    return lastMessage != ""
        ? ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(
                receiverData["imageUrl"],
              ),
            ),
            title: Text(receiverData[
                "name"]), // Wrap receiverData["name"] with Text widget
            subtitle: Text(
              lastMessage,
              maxLines: 12,
            ),
            trailing: Text(
              '${timestamp.hour} : ${timestamp.minute}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatId: chatID,
                    receiverId: receiverData["uid"],
                  ),
                ),
              );
            },
          )
        : Container();
  }
}
