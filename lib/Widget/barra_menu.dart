import 'package:colortunes_beta/Screens/my_profile.dart';
import 'package:colortunes_beta/Screens/share_songs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:colortunes_beta/Screens/Feed.dart';
import 'package:colortunes_beta/Screens/login.dart';
import 'package:colortunes_beta/Modelos/songs.dart';

class CustomNavBar extends StatelessWidget {
  final User user;
  final Song song;
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavBar({
    Key? key,
    required this.user,
    required this.song,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 3) {
          // Cerrar sesión
          FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        } else {
          // Notificar al padre sobre el cambio de índice
          onTap(index);

          // Navegar a las pantallas correspondientes
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MusicSearchPage(user: user),
                ),
              );
              break;
            case 1:
              // Navegar a la pantalla de canciones compartidas
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SharedSongsPage(
                    user: user,
                    song: song,
                  ),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MyProfilePage(
                    user: user,
                    song: song,
                  ),
                ),
              );
              break;
          }
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore_rounded), label: 'Explorar'),
        BottomNavigationBarItem(
            icon: Icon(Icons.music_note_rounded), label: 'Para ti'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Mi perfil'),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Salir')
      ],
    );
  }
}
