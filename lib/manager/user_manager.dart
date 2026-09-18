import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/manager/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Helpers/firebase_errors.dart';

class UserManager extends ChangeNotifier {
  // Singleton
  static final UserManager instance = UserManager._internal();

  // Construtor interno privado
  UserManager._internal() {
    _loadCurrentUser();
  }

  // Factory pública retorna o singleton
  factory UserManager() => instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  Users? user;

  bool _loading = false;

  bool get loading => _loading;
  bool get isLoggedIn => user != null;

  // ---------- LOGIN COM EMAIL ----------
  Future<void> signIn({
    required Users user,
    required Function(String) onFail,
    required Function onSucess,
  }) async {
    loading = true;
    try {
      await auth.signInWithEmailAndPassword(
        email: user.email ?? '',
        password: user.password ?? '',
      );

      await _loadCurrentUser();
      onSucess();
    } on FirebaseAuthException catch (e) {
      onFail(getErrorString(e.code));
    }
    loading = false;
  }

  // ---------- LOGOUT ----------
  void signOut(BuildContext context) {
    auth.signOut();
    user = null;
    notifyListeners();
  }

  // ---------- CADASTRO ----------
  Future<void> signUp({
    Users? user,
    Function? onFail,
    Function? onSucess,
  }) async {
    loading = true;
    try {
      final UserCredential result = await auth.createUserWithEmailAndPassword(
        email: user!.email!,
        password: user.password!,
      );

      user.id = result.user?.uid;
      await user.saveData();

      this.user = user;
      onSucess?.call();
    } on FirebaseAuthException catch (e) {
      onFail?.call(getErrorString(e.code));
    }
    loading = false;
  }

  // ---------- LOADING ----------
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // ---------- CARREGAR USUÁRIO ATUAL ----------
  Future<void> _loadCurrentUser() async {
    final User? currentUser = auth.currentUser;
    if (currentUser == null) return;

    final DocumentSnapshot docUser =
    await firestore.collection('users').doc(currentUser.uid).get();

    if (!docUser.exists) {
      print("Usuário não encontrado no Firestore.");
      return;
    }

    this.user = Users.fromDocument(docUser);

    // Verifica se é admin
    final docAdmin =
    await firestore.collection('admins').doc(currentUser.uid).get();
    if (docAdmin.exists) {
      this.user!.admin = true;
    }

    notifyListeners();
  }

  bool get adminEnabled => user?.admin ?? false;
}