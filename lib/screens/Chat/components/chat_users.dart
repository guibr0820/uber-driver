import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../manager/user.dart';

class ChatUsers {
  // Buscar informações do usuário atual
  static Future<Users?> buscarUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      return Users.fromDocument(userDoc);
    }
    return null;
  }

  // Enviar mensagem de texto
  static Future<void> enviarMensagem({
    required String texto,
    required String rideId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || texto.trim().isEmpty) return;

    final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    final rideSnapshot = await rideRef.get();

    if (!rideSnapshot.exists) return;

    final data = rideSnapshot.data();
    if (data != null && data['conversa'] == 'encerrada') return;

    final mensagensRef = rideRef.collection('chat');
    await mensagensRef.add({
      'user': uid,
      'mensagem': texto,
      'imagemUrl': null,
      'dataHora': FieldValue.serverTimestamp(),
      'status': 'pendente',
    });
  }

  // Enviar imagem e retornar a URL
  static Future<String?> enviarImagem({
    required ImageSource source,
    required String rideId,
  }) async {
    final picker = ImagePicker();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final rideRef = FirebaseFirestore.instance.collection('rides').doc(rideId);
    final rideSnapshot = await rideRef.get();

    if (!rideSnapshot.exists) return null;

    final data = rideSnapshot.data();
    if (data != null && data['conversa'] == 'encerrada') return null;

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final File imagem = File(pickedFile.path);

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(rideId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = await storageRef.putFile(imagem);
      final imageUrl = await uploadTask.ref.getDownloadURL();

      final mensagensRef = rideRef.collection('chat');
      await mensagensRef.add({
        'user': uid,
        'mensagem': '',
        'imagemUrl': imageUrl,
        'dataHora': FieldValue.serverTimestamp(),
        'status': 'pendente',
      });

      return imageUrl;
    }

    return null;
  }
}
