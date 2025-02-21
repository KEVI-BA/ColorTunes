import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colortunes_beta/Modelos/share_songs.dart';
import 'package:colortunes_beta/Modelos/songs.dart';
import 'package:colortunes_beta/Screens/Feed.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:colortunes_beta/Screens/login.dart'; // Para cerrar sesión

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
  int _currentIndex = 0; // Índice de la canción actual
  int _navBarIndex = 1; // Índice del BottomNavigationBar

  List<SharedSong> _sharedSongs = [];
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _controller.dispose(); // Asegúrate de disponer del controlador de animación
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchSharedSongs();

    // Inicializa el controlador de animación
    _controller = AnimationController(
      duration: const Duration(seconds: 5), // Duración de un giro completo
      vsync: this,
    )..repeat(); // Repite la animación de forma infinita

    // Definir la animación de rotación
    _rotationAnimation = Tween<double>(
            begin: 0.0, end: 2 * 3.14159) // 2π para una rotación completa
        .animate(_controller);
  }

  // Obtener las canciones compartidas desde Firestore
  void _fetchSharedSongs() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('shared_songs')
        .orderBy('timestamp', descending: true)
        .get();

    final sharedSongs = snapshot.docs
        .map((doc) => SharedSong.fromMap(doc.data(), doc.id))
        .toList();

    setState(() {
      _sharedSongs = sharedSongs;
    });

    // Reproducir automáticamente la primera canción
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
      // Actualizar el estado para reflejar los cambios
      _fetchSharedSongs();
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
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Músicas Compartidas'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navBarIndex,
        onTap: (index) {
          if (index == 2) {
            // Cerrar sesión
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else {
            setState(() {
              _navBarIndex = index;
            });

            // Navegar a las pantallas correspondientes
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MusicSearchPage(user: widget.user),
                  ),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SharedSongsPage(user: widget.user, song: widget.song),
                  ),
                );
                break;
            }
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Compartir'),
          BottomNavigationBarItem(
              icon: Icon(Icons.music_note_rounded), label: 'Para ti'),
          BottomNavigationBarItem(
              icon: Icon(Icons.logout), label: 'Cerrar sesión'),
        ],
      ),
    );
  }

  Widget _buildSharedSongCard(SharedSong song) {
    final TextEditingController commentController = TextEditingController();

    // Función para obtener los comentarios
    Future<List<Map<String, dynamic>>> _getComments(String songId) async {
      final snapshot = await FirebaseFirestore.instance
          .collection('shared_songs')
          .doc(songId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    }

    // Función para mostrar el BottomSheet con los comentarios
    void _showCommentsBottomSheet(BuildContext context, String songId) {
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
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final comments = snapshot.data ?? [];

                      if (comments.isEmpty) {
                        return Center(child: Text('No hay comentarios.'));
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            title: Text(comment['comment'] ?? 'No Comment'),
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
                          decoration: InputDecoration(
                            hintText: 'Escribe tu comentario...',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
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
              // Icono de usuario
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(song.userAvatarUrl),
                  ),
                  const SizedBox(width: 8),
                  Text(song.username),
                ],
              ),
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
                          _likeSong(song.id); // Lógica para agregar "like"
                        },
                      ),
                      Text('${song.likes.length}'), // Recuento de likes
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.comment),
                    onPressed: () {
                      _showCommentsBottomSheet(context, song.id);
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
