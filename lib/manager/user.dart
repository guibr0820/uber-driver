import 'package:cloud_firestore/cloud_firestore.dart';


class Users { // invés de colocar "User" coloquei "Users" pois é usado no firebase o User

  Users({this.email, this.password, this.name, this.id});

  Users.fromDocument(DocumentSnapshot document) {
    var data = document.data() as Map<String, dynamic>?;

    // Se os dados estiverem nulos, você pode definir valores padrão ou lançar um erro.
    if (data == null) {
      throw Exception("Erro: Não foi possível carregar os dados do usuário.");
    }

    id = document.id;
    name = data['name'] as String?;
    email = data['email'] as String?;
    cpf = data['cpf'] as String?;
    telefone = data['tel'] as String?;

  }

  String? id;
  String? name;
  String? email;
  String? cpf;
  String? telefone;
  String? password;

  String? confirmPassword;

  bool? admin = false;


  DocumentReference get firestoreRef =>
      FirebaseFirestore.instance.doc('users/$id');


  void setTelefone(String telefone) {
    this.telefone = telefone;
    saveData();
  }

  Future<void> saveData() async { // vai transformar meus dados em mapa
    await firestoreRef.set(toMap());
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      if(cpf != null)
        'cpf'  : cpf,
      if(telefone != null)
        'tel'  : telefone
    };
  }

  void setCpf(String cpf){
    this.cpf = cpf;
    saveData();
  }
}
