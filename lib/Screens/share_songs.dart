import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colortunes_beta/Modelos/share_songs.dart';
import 'package:colortunes_beta/Modelos/songs.dart';
import 'package:colortunes_beta/Widget/barra_menu.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedSongsPage extends StatefulWidget {
  final User user;
  final Song song;

  const SharedSongsPage({super.key, required this.user, required this.song});

  @override
  _SharedSongsPageState createState() => _SharedSongsPageState();
}

class _SharedSongsPageState extends State<SharedSongsPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentIndex = 0;

  List<SharedSong> _sharedSongs = [];
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  // Lista de IDs de usuarios a los que sigue el usuario actual
  List<String> _following = [];

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchSharedSongs();
    _fetchFollowing(); // Obtener lista de usuarios seguidos

    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    _rotationAnimation =
        Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(_controller);
  }

  // Obtener lista de usuarios a los que sigue el usuario actual
  void _fetchFollowing() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('following')
        .get();

    setState(() {
      _following = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Obtener las canciones compartidas desde Firestore
  void _fetchSharedSongs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('shared_songs')
        .orderBy('timestamp', descending: true)
        .get();

    final sharedSongs = snapshot.docs
        .map((doc) => SharedSong.fromMap(doc.data(), doc.id))
        .where((song) => song.userId != widget.user.uid)
        .toList();

    setState(() {
      _sharedSongs = sharedSongs;
    });

    if (_sharedSongs.isNotEmpty) {
      _playSong(_sharedSongs[_currentIndex].songUrl);
    }
  }

  // Reproducir la canción seleccionada
  void _playSong(String url) async {
    try {
      if (url.isNotEmpty) {
        await _audioPlayer.play(UrlSource(url));
      } else {
        print('URL no válida');
      }
    } catch (e) {
      print('Error al reproducir la canción: $e');
    }
  }

  // Función para dar like a la canción
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
      _fetchSharedSongs();
    }
  }

  // Función para seguir/dejar de seguir a un usuario
  void _toggleFollow(String userId) async {
    if (userId == widget.user.uid) return; // No permitir seguirse a sí mismo

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final currentUserFollowing = firestore
          .collection('users')
          .doc(widget.user.uid)
          .collection('following')
          .doc(userId);

      final targetUserFollowers = firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .doc(widget.user.uid);

      // Si ya sigue al usuario, dejar de seguir
      if (_following.contains(userId)) {
        batch.delete(currentUserFollowing);
        batch.delete(targetUserFollowers);
        setState(() {
          _following.remove(userId);
        });
      }
      // Si no lo sigue, comenzar a seguir
      else {
        batch.set(currentUserFollowing, {
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.set(targetUserFollowers, {
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _following.add(userId);
        });
      }

      await batch.commit(); // Ejecutar todas las operaciones juntas
    } catch (e) {
      print("Error al seguir/dejar de seguir: $e");
      // Puedes mostrar un mensaje de error al usuario si lo deseas
    }
  }

  // Función para agregar comentario
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          padding: const EdgeInsets.only(
              top: 35.0), // Ajusta el valor según sea necesario
          child: const Center(
            child: Text(
              'Para ti',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
      body: _sharedSongs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: PageView.builder(
                itemCount: _sharedSongs.length,
                controller: PageController(initialPage: _currentIndex),
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _playSong(_sharedSongs[_currentIndex].songUrl);
                  });
                },
                itemBuilder: (context, index) {
                  return _buildSharedSongCard(_sharedSongs[index]);
                },
              ),
            ),
      bottomNavigationBar: CustomNavBar(
          user: widget.user,
          song: widget.song,
          currentIndex: 1,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          }),
    );
  }

  Widget _buildSharedSongCard(SharedSong song) {
    final TextEditingController commentController = TextEditingController();
    final bool isFollowing = _following.contains(song.userId);

    // Función para obtener los comentarios
    Future<List<Map<String, dynamic>>> getComments(String songId) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('shared_songs')
          .doc(songId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    }

    // Función para mostrar el BottomSheet con los comentarios
    void showCommentsBottomSheet(BuildContext context, String songId) {
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
                    future: getComments(songId),
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

    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: ClipOval(
                      child: Image.network(
                        song.image,
                        width: 130.0,
                        height: 130.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                song.songName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                song.artist,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              // Perfil de usuario con botón de seguir
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Información de usuario
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: song.userAvatarUrl.isNotEmpty
                            ? NetworkImage(song.userAvatarUrl)
                            : null, // Si está vacío, no intenta cargar la imagen
                        child: song.userAvatarUrl.isEmpty
                            ? const Icon(Icons.person,
                                size: 30) // Ícono si no hay imagen
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        song.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  // Botón seguir (si no es el usuario actual)
                  if (song.userId != widget.user.uid)
                    TextButton(
                      onPressed: () {
                        _toggleFollow(song.userId);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor:
                            isFollowing ? Colors.grey[300] : Colors.blue,
                        foregroundColor:
                            isFollowing ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(isFollowing ? 'Siguiendo' : 'Seguir'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Botón de like y comentarios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Botón de like con corazón
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: song.likes.contains(widget.user.uid)
                              ? Colors.red
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _likeSong(song.id);
                        },
                      ),
                      Text('${song.likes.length}'), // Recuento de likes
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () {
                      showCommentsBottomSheet(context, song.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
