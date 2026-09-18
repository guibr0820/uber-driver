import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConectarMPPage extends StatelessWidget {
  final String motoristaId;

  ConectarMPPage({required this.motoristaId});

  Future<void> conectar() async {
    final url =
        "https://us-central1-app-motorista-c39e4.cloudfunctions.net/mpOAuthStart?state=$motoristaId";

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Conectar Mercado Pago")),
      body: Center(
        child: ElevatedButton(
          onPressed: conectar,
          child: Text("Conectar conta Mercado Pago"),
        ),
      ),
    );
  }
}
