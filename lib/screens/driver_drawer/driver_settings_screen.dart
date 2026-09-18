import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverSettingsScreens extends StatelessWidget {
  const DriverSettingsScreens({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        title: const Text('Regras de pagamento'),
      ),
      body: driverId == null
          ? const Center(child: Text('Motorista nao autenticado.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(driverId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() ?? <String, dynamic>{};
                final pixBeforePickup = data['pixBeforePickup'] == true;
                final cardBeforePickup = data['cardBeforePickup'] == true;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _SettingsHeader(
                      pixBeforePickup: pixBeforePickup,
                      cardBeforePickup: cardBeforePickup,
                    ),
                    const SizedBox(height: 14),
                    _PaymentBeforePickupCard(
                      icon: Icons.pix_outlined,
                      iconColor: const Color(0xFF2F80ED),
                      title: 'Exigir Pix aprovado antes de buscar',
                      enabledText:
                          'Quando ligado, o app só libera a rota ate o passageiro depois que o Pix for aprovado.',
                      disabledText:
                          'Quando desligado, você pode buscar o passageiro mesmo com pagamento pendente.',
                      value: pixBeforePickup,
                      onChanged: (value) => _saveSetting(
                        context: context,
                        driverId: driverId,
                        field: 'pixBeforePickup',
                        value: value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PaymentBeforePickupCard(
                      icon: Icons.credit_card,
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Exigir cartao autorizado antes de buscar',
                      enabledText:
                          'Quando ligado, o app só libera a rota ate o passageiro depois que o cartão for autorizado.',
                      disabledText:
                          'Quando desligado, voce pode buscar o passageiro mesmo com pagamento pendente.',
                      value: cardBeforePickup,
                      onChanged: (value) => _saveSetting(
                        context: context,
                        driverId: driverId,
                        field: 'cardBeforePickup',
                        value: value,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoBox(
                      pixBeforePickup: pixBeforePickup,
                      cardBeforePickup: cardBeforePickup,
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _saveSetting({
    required BuildContext context,
    required String driverId,
    required String field,
    required bool value,
  }) async {
    try {
      // Ajuste Move: configura se cada tipo de pagamento trava a ida ate o passageiro.
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel salvar a configuracao.'),
          ),
        );
      }
    }
  }
}

class _SettingsHeader extends StatelessWidget {
  final bool pixBeforePickup;
  final bool cardBeforePickup;

  const _SettingsHeader({
    required this.pixBeforePickup,
    required this.cardBeforePickup,
  });

  @override
  Widget build(BuildContext context) {
    final lockedCount = [pixBeforePickup, cardBeforePickup]
        .where((enabled) => enabled)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Regras de pagamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lockedCount == 0
                      ? 'Busca liberada mesmo com pagamento pendente'
                      : '$lockedCount pagamento(s) exigem aprovacao antes de buscar',
                  style: const TextStyle(color: Color(0xFFD1D5DB)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBeforePickupCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String enabledText;
  final String disabledText;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PaymentBeforePickupCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.enabledText,
    required this.disabledText,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value ? enabledText : disabledText,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: value ? const Color(0xFFEAF8EF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: Checkbox(
              value: value,
              activeColor: const Color(0xFF16A34A),
              checkColor: Colors.white,
              side: const BorderSide(
                color: Color(0xFF64748B),
                width: 1.8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (checked) => onChanged(checked ?? false),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final bool pixBeforePickup;
  final bool cardBeforePickup;

  const _InfoBox({
    required this.pixBeforePickup,
    required this.cardBeforePickup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE1FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF2F80ED)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _description,
              style: const TextStyle(
                color: Color(0xFF1F3B63),
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _description {
    final pixText = pixBeforePickup
        ? 'Pix ligado: busca liberada somente apos aprovacao.'
        : 'Pix desligado: busca liberada mesmo pendente.';
    final cardText = cardBeforePickup
        ? 'Cartao ligado: busca liberada somente apos autorizacao.'
        : 'Cartao desligado: busca liberada mesmo pendente.';

    return '$pixText\n$cardText';
  }
}
