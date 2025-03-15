import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:colortunes_beta/Datos/message.dart';
import 'package:colortunes_beta/Datos/songs.dart';
import 'package:colortunes_beta/Presentacion/Widget/barra_menu.dart';

class ChatScreen extends StatefulWidget {
  final User currentUser;
  final String otherUserId;
  final String otherUserName;
  final Song song;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUserId,
    required this.otherUserName,
    required this.song,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PlayerState _currentState = PlayerState.stopped;

  String? _currentSongUrl;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String getChatRoomId() {
    List<String> ids = [widget.currentUser.uid, widget.otherUserId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage(String text) async {
    _textController.clear();
    if (text.trim().isEmpty) return;

    final chatRoomId = getChatRoomId();

    final newMessage = ChatMessage(
      text: text,
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.displayName ?? 'Usuario',
      time: DateTime.now(),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'text': newMessage.text,
      'senderId': newMessage.senderId,
      'senderName': newMessage.senderName,
      'timestamp': Timestamp.fromDate(newMessage.time), // Usar 'timestamp'
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickAndSendImage() async {
    final XFile? imageFile = await _imagePicker.pickImage(
      source: ImageSource.gallery, // O usa ImageSource.camera para la cámara
    );

    if (imageFile != null) {
      final File image = File(imageFile.path);
      await _sendImageMessage(image);
    }
  }

  Future<String> _encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _sendImageMessage(File image) async {
    final chatRoomId = getChatRoomId();

    // Convertir la imagen a Base64
    final imageBase64 = await _encodeImage(image);

    // Crear el mensaje con la imagen
    final newMessage = ChatMessage(
      text: '', // Mensaje vacío para imágenes
      senderId: widget.currentUser.uid,
      senderName: widget.currentUser.displayName ?? 'Usuario',
      time: DateTime.now(),
      imageUrl: imageBase64, // Guardar la imagen como Base64
    );

    // Guardar el mensaje en Firestore
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_currentSongUrl == url) {
        if (_currentState == PlayerState.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.resume();
        }
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(url));
        _currentSongUrl = url;
      }
    } catch (e) {
      debugPrint("Error al reproducir audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat con ${widget.otherUserName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(getChatRoomId())
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  debugPrint(
                      "Mensaje recibido: ${data['text']}, ${data['songName']}, ${data['imageUrl']}");
                  return ChatMessage.fromMap(data);
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageItem(messages[index]),
                );
              },
            ),
          ),
          _buildTextInput(),
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        user: widget.currentUser,
        song: widget.song,
        key: widget.key,
        currentIndex: 3,
        onTap: (index) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    bool isMe = message.senderId == widget.currentUser.uid;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) CircleAvatar(child: Text(message.senderName[0])),
          const SizedBox(width: 10.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(message.senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),

                  // Mostrar texto del mensaje (si no está vacío)
                  if (message.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(message.text),
                    ),

                  // Mostrar imagen si existe
                  if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: message.imageUrl!.startsWith('http')
                            ? Image.network(message.imageUrl!,
                                width: 200, height: 200)
                            : Image.memory(
                                base64Decode(message.imageUrl!),
                                width: 100,
                                height: 100,
                              )),

                  // Mostrar información de la canción si existe
                  if (message.songName != null &&
                      message.songName!.isNotEmpty &&
                      message.songUrl != null &&
                      message.songUrl!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Canción: ${message.songName}"),
                        ElevatedButton(
                          onPressed: () => _playAudio(message.songUrl!),
                          child: const Text('Escuchar'),
                        ),
                      ],
                    ),

                  // Mostrar hora del mensaje
                  Text(
                    "${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed:
                _pickAndSendImage, // Llama al método para seleccionar y enviar imágenes
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: "Enviar mensaje...",
                border: InputBorder.none,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
