import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2F80ED),
        title: const Text('Meus dados'),
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

                final data = snapshot.data?.data() ?? {};
                final photoUrl = _asText(data['selfieUrl'] ?? data['photoUrl']);
                final name = _asText(data['name'], fallback: 'Motorista');
                final email = _asText(data['email'], fallback: 'Sem email');
                final carModel = _asText(data['carModel'], fallback: '-');
                final carColor = _asText(data['carColor'], fallback: '-');
                final plate = _asText(data['plate'], fallback: '-');
                final rating = _asText(data['rating'], fallback: '0.0');
                final online = data['online'] == true;
                final available = data['available'] == true;
                final mpConnected = _asText(data['mp_access_token']).isNotEmpty;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _ProfileHeader(
                      name: name,
                      email: email,
                      photoUrl: photoUrl,
                      rating: rating,
                      online: online,
                      available: available,
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Veiculo principal',
                      icon: Icons.directions_car_filled_outlined,
                      children: [
                        _InfoRow(
                          icon: Icons.drive_eta_outlined,
                          label: 'Modelo',
                          value: carModel,
                        ),
                        _InfoRow(
                          icon: Icons.palette_outlined,
                          label: 'Cor',
                          value: carColor,
                        ),
                        _InfoRow(
                          icon: Icons.pin_outlined,
                          label: 'Placa',
                          value: plate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Conta',
                      icon: Icons.verified_user_outlined,
                      children: [
                        _InfoRow(
                          icon: Icons.mail_outline,
                          label: 'Email',
                          value: email,
                        ),
                        _InfoRow(
                          icon: Icons.payments_outlined,
                          label: 'Mercado Pago',
                          value: mpConnected ? 'Conectado' : 'Nao conectado',
                          valueColor: mpConnected
                              ? const Color(0xFF0E9F6E)
                              : const Color(0xFFE11D48),
                        ),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'ID',
                          value: driverId,
                          small: true,
                        ),
                      ],
                    ),
                    if (data['vehicles'] is List &&
                        (data['vehicles'] as List).isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _VehiclesCard(vehicles: data['vehicles'] as List),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String photoUrl;
  final String rating;
  final bool online;
  final bool available;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.rating,
    required this.online,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.startsWith('http');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: const Color(0xFFE8EEF8),
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: hasPhoto
                ? null
                : const Icon(Icons.person, size: 40, color: Color(0xFF2F80ED)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.star_rounded,
                      text: rating,
                      color: const Color(0xFFF59E0B),
                    ),
                    _Pill(
                      icon: online ? Icons.wifi_tethering : Icons.wifi_off,
                      text: online ? 'Online' : 'Offline',
                      color: online
                          ? const Color(0xFF0E9F6E)
                          : const Color(0xFF6B7280),
                    ),
                    _Pill(
                      icon: Icons.local_taxi_outlined,
                      text: available ? 'Disponivel' : 'Em corrida',
                      color: available
                          ? const Color(0xFF2F80ED)
                          : const Color(0xFFE11D48),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF2F80ED)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool small;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 21, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: small ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.grey.shade900,
                fontSize: small ? 12 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclesCard extends StatelessWidget {
  final List vehicles;

  const _VehiclesCard({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Veiculos cadastrados',
      icon: Icons.two_wheeler_outlined,
      children: vehicles.map<Widget>((vehicle) {
        final data = vehicle is Map ? vehicle : {};
        return _InfoRow(
          icon: Icons.label_outline,
          label: _asText(data['type'], fallback: 'Veiculo'),
          value:
              '${_asText(data['model'], fallback: '-')} - ${_asText(data['color'], fallback: '-')}',
        );
      }).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Pill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

String _asText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
