import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';
import 'services/subscription_service.dart';
import 'services/review_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestione Chiamate Intermittenti',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      locale: const Locale('it', 'IT'),
      home: const SplashCheckScreen(),
    );
  }
}

/// Schermata che controlla stato abbonamento all'avvio
class SplashCheckScreen extends StatefulWidget {
  const SplashCheckScreen({Key? key}) : super(key: key);

  @override
  State<SplashCheckScreen> createState() => _SplashCheckScreenState();
}

class _SplashCheckScreenState extends State<SplashCheckScreen> {
  final _subscriptionService = SubscriptionService();
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    await _subscriptionService.initialize();

    // Inizializza data installazione per recensioni
    await ReviewService().initializeInstallDate();

    // Controlla se può usare l'app
    final canUse = _subscriptionService.canUseApp();

    if (mounted) {
      if (canUse) {
        // Può usare l'app - vai alla home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // Prova scaduta e non ha abbonamento - blocca
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SubscriptionScreen(isBlocked: true),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Caricamento...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}