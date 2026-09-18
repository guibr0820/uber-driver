import 'package:driver/screens/driver_drawer/driver_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app_mode.dart';
import '../../../screens/Carteira/Wallet_balance.dart';
import '../../../screens/driver_drawer/driver_messages_screen.dart';
import '../../../screens/driver_drawer/driver_profile_screen.dart';
import '../../../screens/driver_drawer/driver_ride_history_screen.dart';
import 'components/drawer_menu_items.dart';

class DriverDrawer extends StatelessWidget {
  const DriverDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final String motoristaId = FirebaseAuth.instance.currentUser!.uid;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ajuste Move: mantem a barra de notificacao legivel enquanto o drawer esta aberto.
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF2F80ED),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Drawer(
      width: MediaQuery.of(context).size.width * 0.84,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: SafeArea(
        top: false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('drivers')
              .doc(motoristaId)
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? <String, dynamic>{};
            final photoUrl = _asText(data['selfieUrl'] ?? data['photoUrl']);
            final userName = _asText(data['name'], fallback: 'Motorista');
            final carModel = _asText(data['carModel'], fallback: 'Veiculo');
            final carColor = _asText(data['carColor']);
            final plate = _asText(data['plate']);
            final rating = _asText(data['rating'], fallback: '4.8');
            final online = data['online'] == true;
            final available = data['available'] == true;
            final hasPhoto = photoUrl.startsWith('http');

            return Container(
              color: const Color(0xFFF4F7FB),
              child: Column(
                children: [
                  _DrawerHeader(
                    name: userName,
                    photoUrl: photoUrl,
                    hasPhoto: hasPhoto,
                    carText: _vehicleText(carModel, carColor, plate),
                    rating: rating,
                    online: online,
                    available: available,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      children: [
                        _StatusStrip(online: online, available: available),
                        const SizedBox(height: 14),
                        const _SectionLabel(title: 'Painel'),
                        const SizedBox(height: 8),
                        _DriverDrawerMenu(motoristaId: motoristaId),
                      ],
                    ),
                  ),
                  _DrawerFooter(
                    onLogout: () async {
                      await FirebaseAuth.instance.signOut();
                      await AppMode.clear();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final String name;
  final String photoUrl;
  final bool hasPhoto;
  final String carText;
  final String rating;
  final bool online;
  final bool available;

  const _DrawerHeader({
    required this.name,
    required this.photoUrl,
    required this.hasPhoto,
    required this.carText,
    required this.rating,
    required this.online,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 14,
        12,
        18,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF2F80ED),
        borderRadius: BorderRadius.only(topRight: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_taxi_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Move Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Recolher menu',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.keyboard_arrow_left_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white.withOpacity(0.18),
                backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                child: hasPhoto
                    ? null
                    : const Icon(Icons.person, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      carText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _HeaderPill(
                          icon: Icons.star_rounded,
                          text: rating,
                          color: const Color(0xFFFFC857),
                        ),
                        _HeaderPill(
                          icon: online ? Icons.wifi_tethering : Icons.wifi_off,
                          text: online ? 'Online' : 'Offline',
                          color: Colors.white,
                        ),
                        _HeaderPill(
                          icon: Icons.route_outlined,
                          text: available ? 'Livre' : 'Em corrida',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  final bool online;
  final bool available;

  const _StatusStrip({required this.online, required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Row(
        children: [
          _StatusDot(color: online ? const Color(0xFF0E9F6E) : Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              online ? 'Voce esta online' : 'Voce esta offline',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: (available ? const Color(0xFF0E9F6E) : const Color(0xFFE11D48))
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              available ? 'Disponivel' : 'Ocupado',
              style: TextStyle(
                color: available ? const Color(0xFF0E9F6E) : const Color(0xFFE11D48),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverDrawerMenu extends StatelessWidget {
  final String motoristaId;

  const _DriverDrawerMenu({required this.motoristaId});

  @override
  Widget build(BuildContext context) {
    // Ajuste Move: o badge do drawer aparece quando existe chat em alguma ride do motorista.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rides')
          .where('driverId', isEqualTo: motoristaId)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        final rideDocs = snapshot.data?.docs ?? [];

        return FutureBuilder<int>(
          future: _countRidesWithMessages(rideDocs),
          builder: (context, countSnapshot) {
            final messageCount = countSnapshot.data ?? 0;

            return DrawerMenuItems(
              hasMessages: messageCount > 0,
              messageCount: messageCount,
              onWalletTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => WalletScreen()),
                );
              },
              onProfileTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DriverProfileScreen(),
                  ),
                );
              },
              onRideHistoryTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DriverRideHistoryScreen(),
                  ),
                );
              },
              onMessagesTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DriverMessagesScreen(),
                  ),
                );
              },
              onSettingsTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DriverSettingsScreens(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<int> _countRidesWithMessages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rideDocs,
  ) async {
    var count = 0;

    for (final rideDoc in rideDocs) {
      final chat = await rideDoc.reference.collection('chat').limit(1).get();
      if (chat.docs.isNotEmpty) count++;
    }

    return count;
  }
}

class _DrawerFooter extends StatelessWidget {
  final Future<void> Function() onLogout;

  const _DrawerFooter({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EAF0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Move',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Motorista',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE11D48),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeaderPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

String _vehicleText(String model, String color, String plate) {
  final parts = [model, color, plate].where((part) => part.trim().isNotEmpty);
  return parts.join(' - ');
}

String _asText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}







