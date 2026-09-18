import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'TransactionCard.dart';
import 'TransactionItem.dart';

class TransactionHistoryWidget extends StatelessWidget {
  final String userId;

  const TransactionHistoryWidget({
    super.key,
    required this.userId,
  });

  DateTime _resolveTransactionDate(Map<String, dynamic> data) {
    final status = data['status'];

    if (status == 'approved' && data['paid_at'] != null) {
      return (data['paid_at'] as Timestamp).toDate().toLocal();
    }

    return (data['created_at'] as Timestamp).toDate().toLocal();
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('wallet_topups')
          .snapshots(),
      builder: (context, topupSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('withdraws')
              .snapshots(),
          builder: (context, withdrawSnap) {
            if (!topupSnap.hasData || !withdrawSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<TransactionItem> items = [];

            // 📥 Depósitos
            for (var doc in topupSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              items.add(
                TransactionItem(
                  type: 'deposit',
                  amount: (data['amount'] ?? 0).toDouble(),
                  createdAt: _resolveTransactionDate(data), // ✅ AQUI
                  status: data['status'] ?? 'pending',
                ),
              );
            }

            // 📤 Saques
            for (var doc in withdrawSnap.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              items.add(
                TransactionItem(
                  type: 'withdraw',
                  amount: (data['amount'] ?? 0).toDouble(),
                  createdAt: (data['created_at'] as Timestamp).toDate(),
                  status: data['status'] ?? 'pending',
                ),
              );
            }

            // 🔽 Ordena por data
            items.sort(
                  (a, b) => b.createdAt.compareTo(a.createdAt),
            );

            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text('Nenhuma transação encontrada'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Histórico de transações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return TransactionCard(item: items[index]);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
