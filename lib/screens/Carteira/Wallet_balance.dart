import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Formatters/CurrentInputFormatter.dart';
import '../../Models/transaction_history_widget.dart';
import '../../manager/user_manager.dart'; // ✅ Import UserManager

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String? _currentTopupId;
  String? _qrCode;
  String? _pixCopiaECola;
  bool _gerandoPix = false;
  bool _pagamentoConfirmado = false;

  String? _currentWithdrawId;
  String? _withdrawPixQr;
  bool _sacando = false;

  // ✅ UserId vindo do UserManager
  String get _userId => UserManager.instance.user?.id ?? '';

  Future<double?> _showAmountDialog(BuildContext context) async {
    final controller = TextEditingController();

    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar saldo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              hintText: '0,00',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                Navigator.pop(context, value);
              },
              child: const Text('Gerar PIX'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget connectMpButton(bool connected) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.account_balance),
          label: Text(
            connected ? 'Reconectar Mercado Pago' : 'Conectar Mercado Pago',
          ),
          onPressed: _userId.isEmpty
              ? null
              : () async {
                  final uri = Uri.parse(
                    'https://us-central1-app-motorista-c39e4.cloudfunctions.net/mpOAuthStart?state=$_userId',
                  );

                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nao foi possivel abrir o Mercado Pago'),
                      ),
                    );
                  }
                },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Carteira não encontrada'),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final rawBalance = data['walletBalance'] ?? 0;
          final double balance = rawBalance is num
              ? rawBalance.toDouble()
              : double.tryParse(rawBalance.toString()) ?? 0.0;
          final connectedMp =
              (data['mp_access_token']?.toString().isNotEmpty ?? false);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _balanceCard(balance),
                  const SizedBox(height: 16),
                  connectMpButton(connectedMp),
                  const SizedBox(height: 14),
                  _addBalanceButton(context),
                  const SizedBox(height: 12),
                  _withdrawButton(context, balance),
                  _pixView(),
                  _paymentStatusCard(),
                  _withdrawStatusListener(),
                  TransactionHistoryWidget(userId: _userId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _balanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Saldo disponível',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addBalanceButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Adicionar saldo'),
        onPressed: _gerandoPix
            ? null
            : () async {
          final amount = await _showAmountDialog(context);
          if (amount == null || amount <= 0) return;

          try {
            setState(() => _gerandoPix = true);

            final callable = FirebaseFunctions.instance
                .httpsCallable('createWalletPix');

            final result = await callable.call({
              'amount': amount,
            });
            setState(() {
              _qrCode = result.data['pix_qr_code']?.toString();
              _pixCopiaECola = result.data['pix_id']?.toString();
              _currentTopupId = result.data['topup_id']?.toString();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIX gerado com sucesso'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao gerar PIX')),
            );
          } finally {
            setState(() => _gerandoPix = false);
          }
        },
      ),
    );
  }

  Widget _withdrawButton(BuildContext context, double balance) {
    final bool enabled = balance > 0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.arrow_downward, color: Colors.white),
        label: const Text(
          'Sacar saldo',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? Colors.lightGreen : Colors.grey,
        ),
        onPressed: !enabled || _sacando
            ? null
            : () async {
          try {
            setState(() => _sacando = true);

            final callable =
            FirebaseFunctions.instance.httpsCallable('requestWithdraw');

            final result = await callable.call({
              'amount': balance,
            });

            setState(() {
              _currentWithdrawId = result.data['withdraw_id']?.toString();
              _withdrawPixQr = result.data['pix_qr_code']?.toString();
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saque solicitado. PIX gerado.'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          } finally {
            setState(() => _sacando = false);
          }
        },
      ),
    );
  }

  Widget _pixView() {
    if (_qrCode == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Pague com PIX',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        QrImageView(
          data: _qrCode!,
          size: 200,
        ),
        const SizedBox(height: 12),
        SelectableText(
          _qrCode!,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copiar código PIX'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _qrCode!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Código PIX copiado')),
            );
          },
        ),
      ],
    );
  }

  Widget _paymentStatusCard() {
    if (_currentTopupId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('wallet_topups')
          .doc(_currentTopupId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'];

        if (status == 'pending') {
          return Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Aguardando pagamento do PIX...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        if (status == 'approved') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_pagamentoConfirmado) {
              setState(() {
                _pagamentoConfirmado = true;
                _qrCode = null;
                _pixCopiaECola = null;
              });
            }
          });

          return Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Pagamento confirmado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _withdrawStatusListener() {
    if (_currentWithdrawId == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('withdraws')
          .doc(_currentWithdrawId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'];

        if (status == 'completed') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _withdrawPixQr = null;
              _currentWithdrawId = null;
            });
          });

          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Saque concluído',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: 16),
          child: const Text(
            'Aguardando transferencia do saque…',
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
