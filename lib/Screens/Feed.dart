import 'package:colortunes_beta/Screens/share_songs.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:colortunes_beta/Api/music_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'package:colortunes_beta/Modelos/songs.dart';
import 'package:colortunes_beta/Screens/login.dart';

class MusicSearchPage extends StatefulWidget {
  final User user;

  const MusicSearchPage({super.key, required this.user});

  @override
  _MusicSearchPageState createState() => _MusicSearchPageState();
}

class _MusicSearchPageState extends State<MusicSearchPage>
    with SingleTickerProviderStateMixin {
  final MusicService _musicService = MusicService();
  List<Song> _songs = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Color> _gradientColors = [Colors.blue, Colors.purple, Colors.red];
  Timer? _colorChangeTimer;
  final Set<String> _likedSongs = {};
  int _currentIndex = 0;
  int _currentSongIndex = 0;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _loadSongs();
    _colorChangeTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _changeGradientColors();
    });

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _rotationAnimation = Tween(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (_songs.isNotEmpty) {
          _audioPlayer.play(UrlSource(_songs[0].previewUrl));
        }
      });
    });
  }

  @override
  void dispose() {
    _colorChangeTimer?.cancel();
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _loadSongs() async {
    try {
      final songs = await _musicService.getRandomSongs();
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      print("Error al cargar las canciones: $e");
    }
  }

  void _changeGradientColors() {
    final random = Random();
    setState(() {
      _gradientColors = [
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
        Color.fromRGBO(
            random.nextInt(256), random.nextInt(256), random.nextInt(256), 1),
      ];
    });
  }

  void _toggleLike(String songUrl) async {
    final docRef =
        FirebaseFirestore.instance.collection('likes').doc(widget.user.uid);
    setState(() {
      if (_likedSongs.contains(songUrl)) {
        _likedSongs.remove(songUrl);
        docRef.update({
          'likedSongs': FieldValue.arrayRemove([songUrl])
        });
      } else {
        _likedSongs.add(songUrl);
        docRef.set({
          'likedSongs': FieldValue.arrayUnion([songUrl]),
        }, SetOptions(merge: true));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 10),
            Text(widget.user.displayName ?? 'Usuario',
                style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
      body: _songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        return _buildSongCard(_songs[index]);
                      },
                      onPageChanged: (index) {
                        setState(() {
                          _currentSongIndex = index;
                          _audioPlayer
                              .play(UrlSource(_songs[index].previewUrl));
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // Cerrar sesión
            FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else {
            // Cambiar de página según el índice
            setState(() {
              _currentIndex = index;
            });

            // Navegar a las pantallas correspondientes
            switch (index) {
              case 0:
                // Navegar a la pantalla de MusicSearchPage (pasa el parámetro 'user')
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MusicSearchPage(user: widget.user), // Pasa 'user'
                  ),
                );
                break;
              case 1:
                // Navegar a la pantalla de canciones compartidas
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SharedSongsPage(
                      user: widget.user, // Pasa el parámetro 'user'
                      song: _songs[_currentSongIndex], // Pasa la canción actual
                    ),
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

  Widget _buildSongCard(Song song) {
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
                          song.imageUrl,
                          width: 130.0,
                          height: 130.0,
                          fit: BoxFit.cover,
                        ),
                      ));
                },
              ),
              const SizedBox(height: 10),
              Text(song.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(song.artist,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 10),
              IconButton(
                icon: Icon(
                  _likedSongs.contains(song.previewUrl)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: _likedSongs.contains(song.previewUrl)
                      ? Colors.red
                      : Colors.black,
                ),
                onPressed: () => _toggleLike(song.previewUrl),
                iconSize: 40,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  try {
                    Song song = _songs[_currentSongIndex];

                    // Agregar la canción compartida con los campos adicionales
                    await FirebaseFirestore.instance
                        .collection('shared_songs')
                        .add({
                      'songName': song.name,
                      'songUrl': song.previewUrl,
                      'sharedBy': widget
                          .user.uid, // ID del usuario que compartió la canción
                      'timestamp': FieldValue.serverTimestamp(),
                      'image': song.imageUrl,
                      'comments': "",
                      'likes': [],
                      'mood': "",
                      'artist': song.artist,
                      'color': "",
                      'created_at': FieldValue.serverTimestamp(),
                    });

                    // Navegar a la página de canciones compartidas
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SharedSongsPage(user: widget.user, song: song),
                      ),
                    );
                  } catch (e) {
                    print("Error sharing song: $e");
                    // Mostrar mensaje de error si es necesario
                  }
                },
                iconSize: 40,
              )
            ],
          ),
        ),
      ),
    );
  }
}
