import 'package:driver/Home/components/drawer/driver_drawer.dart';
import 'package:driver/screens/Carteira/Wallet_balance.dart';
import 'screens/drivers/driver_navigation_screen.dart';
import 'package:driver/screens/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'Home/components/drawer/user_drawer.dart';
import 'manager/RideManager.dart';
import 'manager/driver_manager.dart';
import 'app_mode.dart';
import 'manager/user_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MoveApp());
}

class MoveApp extends StatelessWidget {
  const MoveApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [

        /// âœ… UserManager
        ChangeNotifierProvider(
          create: (_) => UserManager(),
        ),

        /// ðŸ”¥ RideManager recebendo UserManager automaticamente
        ProxyProvider<UserManager, RideManager>(
          update: (_, userManager, __) => RideManager(userManager),
        ),

        /// âœ… DriverManager
        ChangeNotifierProvider(
          create: (_) => DriverManager(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Move',
        theme: ThemeData(
          primaryColor: Colors.blueAccent,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.blue,
          ).copyWith(
            secondary: Colors.blueAccent,
          ),
        ),

        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/home':
              return MaterialPageRoute(
                builder: (_) => const DriverNavigationScreen(
                  destinoLat: 0,
                  destinoLng: 0,
                ),
              );

            case '/driver_screen':
              return MaterialPageRoute(
                builder: (_) => const DriverNavigationScreen(
                  destinoLat: 0,
                  destinoLng: 0,
                ),
              );
            case '/login':
              return MaterialPageRoute(
                builder: (_) => LoginScreen(),
              );
            case '/driver_drawer':
              return MaterialPageRoute(builder: (_) => DriverDrawer()
              );
            case '/wallet_screen':
              return MaterialPageRoute(
                builder: (_) => WalletScreen(),
              );
          }

          return null;
        },

        home: FutureBuilder<String?>(
          future: AppMode.get(),
          builder: (context, snapshot) {
            final user = FirebaseAuth.instance.currentUser;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            /// âŒ NÃ£o logado
            if (user == null) {
              return LoginScreen();
            }

            /// âœ… Logado
            final mode = snapshot.data;

            if (mode == "driver") {
              return const DriverNavigationScreen(
                destinoLat: 0,
                destinoLng: 0,
              );
            }

            /// ðŸ”¥ Sempre retornar algo
            return LoginScreen();
          },
        ),
      ),
    );
  }
}
