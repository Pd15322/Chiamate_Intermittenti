import 'package:flutter/material.dart';
import 'nuova_chiamata_screen.dart';
import 'storico_screen.dart';
import 'impostazioni_screen.dart';
import 'annulla_chiamata_screen.dart';
import 'info_screen.dart';
import 'subscription_screen.dart';
import '../services/subscription_service.dart';
import '../widgets/review_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _subscriptionService = SubscriptionService();

  @override
  void initState() {
    super.initState();
    // Controlla se mostrare recensione
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReviewChecker.checkAndShowReview(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Chiamate Intermittenti'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              _subscriptionService.isPremium ? Icons.star : Icons.star_border,
              color: _subscriptionService.isPremium ? Colors.amber : Colors.white,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(isBlocked: false),
                ),
              );
              if (result == true) {
                setState(() {});
              }
            },
            tooltip: _subscriptionService.isPremium ? 'Abbonamento attivo' : 'Passa a Premium',
          ),
        ],
      ),
      body: Column(
        children: [
          // BANNER PROVA GRATUITA
          if (!_subscriptionService.isPremium && _subscriptionService.giorniProvaRimasti() > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[400]!, Colors.purple[600]!],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.white, size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prova Gratuita',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_subscriptionService.giorniProvaRimasti()} giorni rimasti',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SubscriptionScreen(isBlocked: false),
                        ),
                      );
                      if (result == true) {
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('PREMIUM'),
                  ),
                ],
              ),
            ),

          // BANNER PREMIUM ATTIVO
          if (_subscriptionService.isPremium)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[600]!, Colors.amber[800]!],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Abbonamento Premium Attivo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // IL TUO MENU (non toccare nulla qui)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildMenuButton(
                    context,
                    'Nuova Chiamata',
                    Icons.add_box,
                    Colors.green,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NuovaChiamataScreen()),
                    ),
                  ),
                  _buildMenuButton(
                    context,
                    'Annulla Chiamata',
                    Icons.cancel,
                    Colors.red,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnnullaChiamataScreen()),
                    ),
                  ),
                  _buildMenuButton(
                    context,
                    'Storico',
                    Icons.history,
                    Colors.orange,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoricoScreen()),
                    ),
                  ),
                  _buildMenuButton(
                    context,
                    'Datore Di Lavoro',
                    Icons.person_outline,
                    Colors.black,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ImpostazioniScreen()),
                    ),
                  ),
                  _buildMenuButton(
                    context,
                    'Info App',
                    Icons.info,
                    Colors.purple,
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InfoScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}