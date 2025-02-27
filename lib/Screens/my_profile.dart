import 'package:colortunes_beta/Modelos/share_songs.dart';
import 'package:colortunes_beta/Modelos/songs.dart';
import 'package:colortunes_beta/Widget/barra_menu.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyProfilePage extends StatefulWidget {
  final User user;
  final Song song;

  const MyProfilePage({Key? key, required this.user, required this.song})
      : super(key: key);

  @override
  _MyProfilePageState createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  List<SharedSong> _mySharedSongs = [];
  bool _isLoading = true;
  String _username = "Cargando...";
  String _profileImage = "";
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchMySharedSongs();
    _getFollowersCount();
    _getFollowingCount();
    _loadUserProfile();
  }

  // Obtener datos del usuario desde Firestore
  Future<void> _getFollowersCount() async {
    try {
      // Acceder a la subcolección "followers" dentro del documento del usuario
      QuerySnapshot followersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('followers')
          .get();

      // Contar el número de documentos en la subcolección
      setState(() {
        _followersCount = followersSnapshot.docs.length;
      });
    } catch (e) {
      setState(() {
        _followersCount = 0;
      });
    }
  }

  // Obtener el recuento de usuarios seguidos
  Future<void> _getFollowingCount() async {
    try {
      // Acceder a la subcolección "following" dentro del documento del usuario
      QuerySnapshot followingSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('following')
          .get();

      // Contar el número de documentos en la subcolección
      setState(() {
        _followingCount = followingSnapshot.docs.length;
      });
    } catch (e) {
      print("Error al obtener seguidos: $e");
      setState(() {
        _followingCount = 0;
      });
    }
  }

  // Cargar nombre de usuario y foto de perfil
  Future<void> _loadUserProfile() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _username = userDoc['displayName'] ?? "Usuario";
          _profileImage = userDoc['photoURL'] ?? "";
        });
      }
    } catch (e) {
      print("Error al cargar perfil: $e");
    }
  }

  Future<void> _fetchMySharedSongs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shared_songs')
          .where('sharedBy', isEqualTo: widget.user.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final List<SharedSong> sharedSongs = snapshot.docs.map((doc) {
          return SharedSong.fromMap(doc.data(), doc.id);
        }).toList();

        setState(() {
          _mySharedSongs = sharedSongs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _mySharedSongs = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para dar like a una canción
  void _likeSong(String songId) async {
    final songRef =
        FirebaseFirestore.instance.collection('shared_songs').doc(songId);
    final snapshot = await songRef.get();
    if (snapshot.exists) {
      final currentLikes = snapshot.data()?['likes'] ?? [];
      if (!currentLikes.contains(widget.user.uid)) {
        await songRef.update({
          'likes': FieldValue.arrayUnion([widget.user.uid]),
        });
      } else {
        await songRef.update({
          'likes': FieldValue.arrayRemove([widget.user.uid])
        });
      }
      _fetchMySharedSongs(); // Actualizar la lista de canciones
    }
  }

  // Función para añadir comentario
  void _addComment(String songId, String comment) async {
    final commentsRef = FirebaseFirestore.instance
        .collection('shared_songs')
        .doc(songId)
        .collection('comments');
    await commentsRef.add({
      'comment': comment,
      'userId': widget.user.uid,
      'username': widget.user.displayName ?? 'Usuario',
      'userPhotoUrl': widget.user.photoURL ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Función para obtener comentarios
  Future<List<Map<String, dynamic>>> _getComments(String songId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('shared_songs')
        .doc(songId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Mostrar la hoja de comentarios
  void _showCommentsBottomSheet(BuildContext context, String songId) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Comentarios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getComments(songId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final comments = snapshot.data ?? [];

                    if (comments.isEmpty) {
                      return const Center(child: Text('No hay comentarios.'));
                    }

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(comment['userPhotoUrl'] ?? ''),
                            child: comment['userPhotoUrl'] == null ||
                                    comment['userPhotoUrl'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                comment['username'] ?? 'Usuario',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  comment['comment'] ?? 'No Comment',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            comment['timestamp']?.toDate().toString() ??
                                'Fecha no disponible',
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu comentario...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          _addComment(songId, commentController.text);
                          commentController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sección del perfil
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Foto de perfil
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImage.isNotEmpty
                            ? NetworkImage(_profileImage) as ImageProvider
                            : const AssetImage(
                                'assets/profile_placeholder.png'),
                      ),
                      const SizedBox(width: 16),
                      // Información del usuario
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text("Seguidores: $_followersCount"),
                              const SizedBox(width: 16),
                              Text("Siguiendo: $_followingCount"),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Lista de canciones compartidas
                Expanded(
                  child: _mySharedSongs.isEmpty
                      ? const Center(
                          child: Text('No has compartido ninguna canción.'))
                      : ListView.builder(
                          itemCount: _mySharedSongs.length,
                          itemBuilder: (context, index) {
                            final song = _mySharedSongs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Imagen de la canción
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            song.image,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                    Icons.music_note),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Detalles de la canción
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                song.songName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                              Text(
                                                song.artist,
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                              const SizedBox(height: 8),
                                              // Botones de interacción
                                              Row(
                                                children: [
                                                  // Botón de like
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.favorite,
                                                          color: song.likes
                                                                  .contains(
                                                                      widget
                                                                          .user
                                                                          .uid)
                                                              ? Colors.red
                                                              : Colors.grey,
                                                          size: 22,
                                                        ),
                                                        onPressed: () {
                                                          _likeSong(song.id);
                                                        },
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${song.likes.length}',
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 16),
                                                  // Botón de comentarios
                                                  InkWell(
                                                    onTap: () {
                                                      _showCommentsBottomSheet(
                                                          context, song.id);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.comment,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        FutureBuilder<
                                                            List<
                                                                Map<String,
                                                                    dynamic>>>(
                                                          future: _getComments(
                                                              song.id),
                                                          builder: (context,
                                                              snapshot) {
                                                            int commentCount =
                                                                0;
                                                            if (snapshot
                                                                .hasData) {
                                                              commentCount =
                                                                  snapshot.data!
                                                                      .length;
                                                            }
                                                            return Text(
                                                              '$commentCount',
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: CustomNavBar(
        user: widget.user,
        song: widget.song,
        currentIndex: 2, // 2 corresponde a "Mi perfil"
        onTap: (index) {
          setState(() {});
        },
      ),
    );
  }
}
