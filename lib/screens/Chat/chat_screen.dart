import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'components/MessageBubble.dart';
import 'components/chat_users.dart';

class ChatScreen extends StatefulWidget {
  final String rideId;

  const ChatScreen({
    Key? key,
    required this.rideId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _mensagemController = TextEditingController();

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  // Enviar mensagem de texto
  void _enviarMensagem() async {
    final texto = _mensagemController.text.trim();
    if (texto.isEmpty) return;

    await ChatUsers.enviarMensagem(
      texto: texto,
      rideId: widget.rideId,
    );

    _mensagemController.clear();
  }

  // Enviar imagem usando ChatUsers
  Future<void> _enviarImagem(ImageSource source) async {
    final imageUrl = await ChatUsers.enviarImagem(
      source: source,
      rideId: widget.rideId,
    );

    if (imageUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagem enviada com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao enviar a imagem.')),
      );
    }
  }

  // Modal para escolher câmera ou galeria
  void _mostrarOpcoesImagem() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Tirar Foto'),
            onTap: () {
              Navigator.pop(context);
              _enviarImagem(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Escolher da Galeria'),
            onTap: () {
              Navigator.pop(context);
              _enviarImagem(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat da Corrida'),
      ),
      body: Column(
        children: [
          Expanded(
            child: currentUser == null
                ? Center(child: Text("Usuário não autenticado."))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .doc(widget.rideId)
                  .collection('chat')
                  .orderBy('dataHora', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Nenhuma mensagem.'));
                }

                final mensagens = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = mensagens[index];
                    final texto = mensagem['mensagem'] ?? '';
                    final imagemUrl = mensagem['imagemUrl'];
                    final uidMensagem = mensagem['user'];
                    final timestamp = mensagem['dataHora'] as Timestamp?;
                    final dataHora = timestamp?.toDate();

                    final isMinhaMensagem =
                        uidMensagem == currentUser.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Align(
                        alignment: isMinhaMensagem
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: MessageBubble(
                          texto: texto,
                          imagemUrl: imagemUrl,
                          isMinhaMensagem: isMinhaMensagem,
                          dataHora: dataHora,
                        ),
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
                IconButton(
                  icon: Icon(Icons.attach_file),
                  onPressed: _mostrarOpcoesImagem,
                  tooltip: 'Enviar imagem',
                ),
                Expanded(
                  child: TextField(
                    controller: _mensagemController,
                    decoration: InputDecoration(
                      hintText: 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _enviarMensagem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
