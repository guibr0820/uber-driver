import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../Helpers/validators.dart';
import '../../manager/user.dart';
import '../../manager/user_manager.dart';
import 'package:provider/provider.dart';

import '../../app_mode.dart';
import '../drivers/driver_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool _obscurePassword = true;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> _isDriver(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    return data['driver'] == true;
  }

  void _showChooseScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Escolha como deseja entrar",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              "VocÃª possui acesso como motorista.\nSelecione o modo de uso:",
              textAlign: TextAlign.center,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actions: [
            Row(
              children: [
                // =========================
                // MODO USUÃRIO
                // =========================
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await AppMode.save("user");
                      Navigator.pop(context);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DriverNavigationScreen(
                            destinoLat: 0,
                            destinoLng: 0,
                          ),
                        ),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.person, color: Colors.blueAccent),
                    label: const Text(
                      "UsuÃ¡rio",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // =========================
                // MODO MOTORISTA
                // =========================
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await AppMode.save("driver");
                      Navigator.pop(context);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const DriverNavigationScreen(
                            destinoLat: 0,
                            destinoLng: 0,
                          ),
                        ),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.directions_car),
                    label: const Text(
                      "Motorista",
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Entrar'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/signup');
            },
            child: const Text(
              'CRIAR CONTA',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: formKey,
            child: Consumer<UserManager>(
              builder: (_, userManager, __) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  children: <Widget>[
                    TextFormField(
                      controller: emailController,
                      enabled: !userManager.loading,
                      decoration: const InputDecoration(hintText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (email) {
                        if (email == null || email.isEmpty || !emailValid(email)) {
                          return 'E-mail invÃ¡lido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passController,
                      enabled: !userManager.loading,
                      decoration: InputDecoration(
                        hintText: 'Senha',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      autocorrect: false,
                      obscureText: _obscurePassword,
                      validator: (pass) {
                        if (pass == null || pass.isEmpty) {
                          return 'Senha invÃ¡lida';
                        } else if (pass.length < 6) {
                          return 'Senha deve ter no mÃ­nimo 6 caracteres';
                        }
                        if (!emailValid(emailController.text)) {
                          return 'E-mail invÃ¡lido';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // AÃ§Ã£o ao pressionar "Esqueci minha senha"
                        },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: userManager.loading
                            ? null
                            : () {
                          if (formKey.currentState!.validate()) {
                            userManager.signIn(
                              user: Users(
                                email: emailController.text,
                                password: passController.text,
                              ),
                              onFail: (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Falha ao entrar: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              onSucess: () async {
                                final currentUser = FirebaseAuth.instance.currentUser;
                                await currentUser?.reload();

                                /*if (currentUser != null && !currentUser.emailVerified) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Confirme seu e-mail antes de entrar.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  await FirebaseAuth.instance.signOut();
                                  return;
                                }*/

                                if (currentUser == null) return;

                                final isDriver = await _isDriver(currentUser.uid);

                                if (isDriver) {
                                  _showChooseScreenDialog(context);
                                } else {
                                  Navigator.of(context).pushReplacementNamed('/home');
                                }

                              },
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          disabledBackgroundColor: Theme.of(context).primaryColor.withAlpha(100),
                          foregroundColor: Colors.white,
                        ),
                        child: userManager.loading
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

