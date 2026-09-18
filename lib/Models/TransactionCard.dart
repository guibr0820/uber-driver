import 'package:flutter/material.dart';
import 'TransactionItem.dart';

class TransactionCard extends StatelessWidget {
  final TransactionItem item;

  const TransactionCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWithdraw = item.type == 'withdraw';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(
          isWithdraw ? Icons.arrow_downward : Icons.arrow_upward,
          color: isWithdraw ? Colors.red : Colors.green,
        ),
        title: Text(
          isWithdraw ? 'Saque' : 'Depósito',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Status: ${item.status}\n'
              'Data: ${_formatDate(item.createdAt)}',
        ),
        trailing: Text(
          'R\$ ${item.amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isWithdraw ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final corrected = date.subtract(const Duration(hours: 3));

    return '${corrected.day.toString().padLeft(2, '0')}/'
        '${corrected.month.toString().padLeft(2, '0')}/'
        '${corrected.year} ${corrected.hour.toString().padLeft(2, '0')}:'
        '${corrected.minute.toString().padLeft(2, '0')}';
  }

}
