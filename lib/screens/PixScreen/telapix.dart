/*
import 'package:flutter/material.dart';

class PixSplitScreen extends StatefulWidget {

  const PixSplitScreen({super.key});

  @override
  State<PixSplitScreen> createState() =>
      _PixSplitScreenState();
}

class _PixSplitScreenState extends State<PixSplitScreen> {


  @override
  void initState() {
    super.initState();
    carregarStatus();
  }

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
                Text(
                  "Conta Mercado Pago conectada!",
                  style: TextStyle(fontSize: 18),
                ),
              ],
            )
                : Column(
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 60),
                SizedBox(height: 10),
                Text(
                  "Você ainda não conectou sua conta Mercado Pago.",
                  style: TextStyle(fontSize: 18),
                ),
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
*/
