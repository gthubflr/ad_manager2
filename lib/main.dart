import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/ad_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart'; 
import 'providers/computer_provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // --- FEHLER-DIAGNOSE FÜR APK ---
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red.shade900,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              const Text(
                'FLUTTER FEHLER (DEBUG INFO):',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white),
              Text(
                details.exception.toString(),
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 20),
              const Text(
                'Stacktrace:',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              Text(
                details.stack.toString(),
                style: const TextStyle(color: Colors.white60, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  };
  // -------------------------------

  runApp(const ADManagerApp());
}

class ADManagerApp extends StatelessWidget {
  const ADManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // HIER GEÄNDERT: .loadPersistedConfig() wird sofort beim Erstellen aufgerufen
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..loadPersistedConfig(),
        ),
        ChangeNotifierProvider(create: (_) => ADProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => ComputerProvider()),
      ],
      child: MaterialApp(
        title: 'AD Manager',
        debugShowCheckedModeBanner: false, 
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<AuthProvider, ADProvider, GroupProvider, ComputerProvider>(
      builder: (context, auth, ad, group, computer, _) {
        if (auth.isAuthenticated && auth.adService != null) {
          final service = auth.adService!;
          
          // Allen Providern den ADService mitteilen
          ad.setADService(service);
          group.setADService(service);
          computer.setADService(service);

          return const HomeScreen();
        }
        
        // Wenn nicht authentifiziert, zeigen wir den LoginScreen.
        // Da der AuthProvider oben mit ..loadPersistedConfig() gestartet wurde,
        // wird der LoginScreen beim ersten Build oder kurz danach die Daten finden.
        return const LoginScreen();
      },
    );
  }
}