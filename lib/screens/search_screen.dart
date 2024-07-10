import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mychat/screens/chat_screen.dart';
import 'package:provider/provider.dart';

import 'package:mychat/provider/chat_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  void handleSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search User'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search Here...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: handleSearch,
            ),
          ),
          Expanded(
            child: searchQuery.isEmpty
                ? const Center(child: Text('Enter a search query'))
                : StreamBuilder<QuerySnapshot>(
                    stream: chatProvider.searchUsers(searchQuery),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final users = snapshot.data!.docs;
                      List<UserTile> userWidgets = [];

                      for (var user in users) {
                        final userData = user.data() as Map<String, dynamic>;

                        if (userData["uid"] != loggedInUser?.uid) {
                          final userWidget = UserTile(
                            userId: userData["uid"],
                            name: userData["name"],
                            email: userData["email"],
                            imageUrl: userData["imageUrl"],
                          );
                          userWidgets.add(userWidget);
                        }
                      }

                      return ListView(
                        children: userWidgets,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  final String userId;
  final String name;
  final String email;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(name),
      subtitle: Text(email),
      onTap: () async {
        final chatId = await chatProvider.getChatRoom(userId) ??
            await chatProvider.createChatRoom(userId);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            receiverId: userId,
          ),
        ));
      },
    );
  }
}
