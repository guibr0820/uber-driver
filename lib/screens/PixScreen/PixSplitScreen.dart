import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:provider/provider.dart';
import '../../manager/user_manager.dart';

class MercadoPagoConnectScreen extends StatefulWidget {
  const MercadoPagoConnectScreen({super.key});

  @override
  State<MercadoPagoConnectScreen> createState() =>
      _MercadoPagoConnectScreenState();
}

class _MercadoPagoConnectScreenState extends State<MercadoPagoConnectScreen> {
  bool conectado = false;
  String? accessToken;

  @override
  void initState() {
    super.initState();
    carregarStatus();
  }

  Future<void> carregarStatus() async {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final uid = userManager.user?.id;

    if (uid == null) return;

    final snap =
    await FirebaseFirestore.instance.collection("drivers").doc(uid).get();

    if (snap.exists &&
        snap.data()!["mp_access_token"] != null &&
        snap.data()!["mp_access_token"] != "") {
      setState(() {
        conectado = true;
        accessToken = snap.data()!["mp_access_token"];
      });
    }
  }

  Future<void> conectarMercadoPago() async {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final uid = userManager.user?.id;

    if (uid == null) return;

    const clientId = "3697495262331828";

    final redirectUri = Uri.encodeComponent(
        "https://us-central1-app-motorista-c39e4.cloudfunctions.net/mpOAuthCallback");

    final url = Uri.parse(
        "https://auth.mercadopago.com.br/authorization?client_id=$clientId&response_type=code&platform_id=mp&redirect_uri=$redirectUri&state=$uid");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw "Não foi possível abrir a URL";
    }
  }

  Future<void> criarPagamentoPix() async {
    final userManager = Provider.of<UserManager>(context, listen: false);
    final uid = userManager.user?.id;

    if (uid == null) return;

    final callable =
    FirebaseFunctions.instance.httpsCallable('createPixPayment');

    final result = await callable.call({
      "driverUid": uid,
      "valor": 1.0,
      "taxaApp": 0.10, // 20% app fica com 4 reais
    });

    final qr =
    result.data["point_of_interaction"]["transaction_data"]["qr_code"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("QR Code gerado"),
        content: SelectableText(qr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mercado Pago - Split"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            conectado
                ? Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 10),
                Text("Conta Mercado Pago conectada!",
                    style: TextStyle(fontSize: 18)),
              ],
            )
                : Column(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 60),
                SizedBox(height: 10),
                Text(
                    "Você ainda não conectou sua conta Mercado Pago.",
                    style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: conectarMercadoPago,
              child: Text("Conectar Mercado Pago"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: conectado ? criarPagamentoPix : null,
              child: Text("Criar Pagamento PIX (Teste)"),
            ),
          ],
        ),
      ),
    );
  }
}
