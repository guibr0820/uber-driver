import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DriverManager extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  bool _loading = false;
  bool get loading => _loading;

  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// =======================
  /// Criar perfil do motorista (etapa 1)
  /// =======================
  Future<void> createBasicDriverProfile({
    required String uid,
    required String name,
    required String cpf,
    required String nascimento,
    required String email,
    required String telefone,
  }) async {
    loading = true;

    try {
      await firestore.collection('drivers').doc(uid).set({
        'name': name,
        'cpf': cpf,
        'nascimento': nascimento,
        'email': email,
        'telefone': telefone,
        'online': false,
        'avaiable': false,
        /// Status do cadastro
        'status': 'under_review',

        /// Flags futuras
        'documentsApproved': false,
        'vehicleApproved': false,

        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erro ao criar motorista: $e');
      rethrow;
    } finally {
      loading = false;
    }
  }

  Future<String> uploadDriverImage({
    required String uid,
    required File file,
    required String path,
  }) async {
    final ref = storage.ref('drivers/$uid/$path');

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }


  /// =======================
  /// Atualizar dados depois (documentos, veículo, etc)
  /// =======================
  Future<void> updateDriver(String uid, Map<String, dynamic> data) async {
    await firestore.collection('drivers').doc(uid).update(data);
  }

  Future<void> createDriverProfile(String uid, {
    required String name,
    required String photoUrl,
    required String carModel,
    required String carColor,
    required String plate,
  }) async {
    await firestore.collection('drivers').doc(uid).set({
      'name': name,
      'photoUrl': photoUrl,
      'carModel': carModel,
      'carColor': carColor,
      'plate': plate,
      'rating': 5.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// =======================
  /// Buscar motorista
  /// =======================
  Future<DocumentSnapshot> getDriver(String uid) async {
    return await firestore.collection('drivers').doc(uid).get();
  }
}
