import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colortunes_beta/Datos/songs.dart';
import 'package:colortunes_beta/Presentacion/Widget/barra_menu.dart';
import 'package:colortunes_beta/Presentacion/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FollowingListScreen extends StatefulWidget {
  final User user;
  final Song song;

  const FollowingListScreen(
      {super.key, required this.user, required this.song});

  @override
  _FollowingListScreenState createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  List<Map<String, dynamic>> _followingUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  //lista de usuarios
  void _fetchFollowing() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .collection("following")
        .get();

    List<Map<String, dynamic>> users = [];

    for (var doc in snapshot.docs) {
      var userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(doc.id)
          .get();

      if (userData.exists) {
        users.add({
          "uid": userData.id,
          "displayName": userData["displayName"],
          "photoURL": userData["photoURL"] ?? '',
        });
      }
    }

    setState(() {
      _followingUsers = users;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Center(
        child: Text("Chatea con: "),
      )),
      body: _followingUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _followingUsers.length,
              itemBuilder: (context, index) {
                final user = _followingUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user["photoURL"].isNotEmpty
                        ? NetworkImage(user["photoURL"])
                        : null,
                    child: user["photoURL"].isEmpty
                        ? Text(user['displayName'][0])
                        : null,
                  ),
                  title: Text(user['displayName']),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChatScreen(
                                  currentUser: widget.user,
                                  otherUserId: user["uid"],
                                  otherUserName: user["displayName"],
                                  song: widget.song,
                                )));
                  },
                );
              },
            ),
      bottomNavigationBar: CustomNavBar(
        user: widget.user,
        song: widget.song,
        currentIndex: 3,
        onTap: (index) {
          setState(() {});
        },
      ),
    );
  }
}
