import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app_mode.dart';
import 'components/drawer_menu_items.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    return Drawer(
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            String? photoUrl;
            String userName = "Usuário";

            if (snapshot.hasData &&
                snapshot.data!.exists &&
                snapshot.data!.data() != null) {
              final data =
              snapshot.data!.data() as Map<String, dynamic>;

              photoUrl = data['photoUrl'];
              userName = data['name'] ?? "Usuário";
            }

            bool hasPhoto = photoUrl != null &&
                photoUrl.isNotEmpty &&
                photoUrl.startsWith('http');

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================
                // HEADER
                // ==========================
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage:
                        hasPhoto ? NetworkImage(photoUrl!) : null,
                        child: hasPhoto
                            ? null
                            : const Icon(
                          Icons.person,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          userName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Sair da conta",
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          await AppMode.clear();

                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                                (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                DrawerMenuItems(
                  onWalletTap: () {
                    Navigator.of(context).pushNamed('/wallet');
                  },
                  onProfileTap: () {
                    Navigator.of(context).pushNamed('/profile');
                  },
                  onRideHistoryTap: () {
                    Navigator.of(context).pushNamed('/ride-history');
                  },
                  onMessagesTap: () {
                    Navigator.of(context).pushNamed('/messages');
                  },
                ),

                const Spacer(),

                // ==========================
                // FOOTER
                // ==========================
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Move • Usuário",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
