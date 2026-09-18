import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverRideHistoryScreen extends StatelessWidget {
  const DriverRideHistoryScreen({super.key});

  static const _finishedStatuses = {
    'finished',
    'completed',
    'done',
    'cancelled',
    'canceled',
  };

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2F80ED),
        title: const Text('Historico de corridas'),
      ),
      body: driverId == null
          ? const Center(child: Text('Motorista nao autenticado.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('driverId', isEqualTo: driverId)
                  .limit(60)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = [...?snapshot.data?.docs];
                docs.sort((a, b) {
                  final ad = _rideDate(a.data());
                  final bd = _rideDate(b.data());
                  return bd.compareTo(ad);
                });

                final finished = docs.where((doc) {
                  final status = _asText(
                    doc.data()['status'],
                  ).toLowerCase().trim();
                  return _finishedStatuses.contains(status);
                }).toList();

                if (finished.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.history,
                    title: 'Sem historico ainda',
                    text: 'As corridas finalizadas vao aparecer aqui.',
                  );
                }

                final total = finished.fold<double>(
                  0,
                  (sum, doc) => sum + _rideAmount(doc.data()),
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _SummaryCard(rides: finished.length, total: total),
                    const SizedBox(height: 14),
                    ...finished.map(
                      (doc) =>
                          _RideHistoryCard(rideId: doc.id, ride: doc.data()),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int rides;
  final double total;

  const _SummaryCard({required this.rides, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rides corridas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Total recebido: ${_money(total)}',
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

class _RideHistoryCard extends StatelessWidget {
  final String rideId;
  final Map<String, dynamic> ride;

  const _RideHistoryCard({required this.rideId, required this.ride});

  @override
  Widget build(BuildContext context) {
    final status = _asText(ride['status'], fallback: 'sem status');
    final origin = _addressFrom(ride['origin'], fallback: 'Origem');
    final destination = _addressFrom(ride['destination'], fallback: 'Destino');
    final passenger = _asText(ride['passengerName'], fallback: 'Passageiro');
    final date = _rideDate(ride);
    final amount = _rideAmount(ride);
    final payment = _asText(ride['paymentMethod'], fallback: 'pagamento');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_taxi_outlined,
                  color: Color(0xFF2F80ED),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(date),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                _money(amount),
                style: const TextStyle(
                  color: Color(0xFF0E9F6E),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AddressLine(icon: Icons.my_location, text: origin),
          const SizedBox(height: 8),
          _AddressLine(icon: Icons.flag_outlined, text: destination),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(text: _statusLabel(status), color: _statusColor(status)),
              _Tag(text: payment.toUpperCase(), color: const Color(0xFF2F80ED)),
              _Tag(
                text: rideId.substring(
                  0,
                  rideId.length < 6 ? rideId.length : 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AddressLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, this.color = const Color(0xFF6B7280)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _rideDate(Map<String, dynamic> ride) {
  final value =
      ride['finishedAt'] ??
      ride['completedAt'] ??
      ride['acceptedAt'] ??
      ride['timestamp'] ??
      ride['pix_created_at'];
  if (value is Timestamp) return value.toDate();
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _rideAmount(Map<String, dynamic> ride) {
  final value = ride['driver_amount'] ?? ride['price'] ?? ride['pix_amount'];
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

String _money(double value) {
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
}

String _addressFrom(dynamic value, {required String fallback}) {
  if (value is Map) return _asText(value['address'], fallback: fallback);
  return fallback;
}

String _asText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'finished':
    case 'completed':
    case 'done':
      return 'Finalizada';
    case 'cancelled':
    case 'canceled':
      return 'Cancelada';
    default:
      return status;
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'finished':
    case 'completed':
    case 'done':
      return const Color(0xFF0E9F6E);
    case 'cancelled':
    case 'canceled':
      return const Color(0xFFE11D48);
    default:
      return const Color(0xFF6B7280);
  }
}
