import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mychat/provider/chat_provider.dart';
import 'package:mychat/screens/login_screen.dart';
import 'package:mychat/screens/search_screen.dart';
import 'package:mychat/widgets/chat_tile.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchChatData(String chatId) async {
    final chatDoc =
        await FirebaseFirestore.instance.collection("chats").doc(chatId).get();
    final chatData = chatDoc.data();
    final users = chatData!['users'] as List<dynamic>;
    final receiverId = users.firstWhere((id) => id != loggedInUser!.uid);

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(receiverId)
        .get();

    final userData = userDoc.data()!;

    return {
      "chatId": chatId,
      "lastMessage": chatData["lastMessage"] ?? "",
      "timestamp": chatData["timestamp"].toDate() ?? DateTime.now(),
      "userData": userData,
    };
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
                onPressed: () async {
                  FirebaseAuth.instance.signOut();
                  setState(() {});
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                icon: const Icon(Icons.logout))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatProvider.getChats(
                  loggedInUser!.uid,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final chatDocs = snapshot.data!.docs;
                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: Future.wait(
                      chatDocs.map(
                        (chatDoc) => _fetchChatData(chatDoc.id),
                      ),
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final chatDataList = snapshot.data!;

                      return ListView.builder(
                        itemCount: chatDataList.length,
                        itemBuilder: (context, index) {
                          final chatData = chatDataList[index];
                          return ChatTile(
                            chatID: chatData["chatId"],
                            lastMessage: chatData["lastMessage"],
                            timestamp: chatData["timestamp"],
                            receiverData: chatData["userData"],
                          );
                        },
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SearchScreen()));
          },
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.search),
        ),
      ),
    );
  }
}
