import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isBlocked; // true se prova scaduta

  const SubscriptionScreen({Key? key, this.isBlocked = false}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  ProductDetails? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    final products = await _subscriptionService.loadProducts();

    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _purchase(ProductDetails product) async {
    setState(() => _isPurchasing = true);

    final success = await _subscriptionService.purchaseSubscription(product);

    if (success) {
      // Attendi che l'acquisto sia processato
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Abbonamento attivato con successo!'),
            backgroundColor: Colors.green,
          ),
        );

        // Torna alla home
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'acquisto'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    final restored = await _subscriptionService.restorePurchases();

    setState(() => _isLoading = false);

    if (restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abbonamento ripristinato!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun abbonamento trovato'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final giorniRimasti = _subscriptionService.giorniProvaRimasti();

    return WillPopScope(
      onWillPop: () async => !widget.isBlocked, // Non può tornare indietro se bloccato
      child: Scaffold(
        appBar: widget.isBlocked
            ? null
            : AppBar(
          title: const Text('Abbonamenti'),
          backgroundColor: Colors.purple,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // HEADER
              if (widget.isBlocked) ...[
                const SizedBox(height: 40),
                Icon(Icons.lock, size: 80, color: Colors.red[400]),
                const SizedBox(height: 20),
                const Text(
                  'Prova Gratuita Terminata',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scegli un abbonamento per continuare ad usare l\'app',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(Icons.star, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                Text(
                  'Passa a Premium',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (giorniRimasti > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      'Prova gratuita: $giorniRimasti giorni rimasti',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 30),

              // VANTAGGI PREMIUM
              Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ Funzionalità Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildFeature('Dipendenti illimitati'),
                      _buildFeature('Aziende illimitate'),
                      _buildFeature('Chiamate illimitate'),
                      _buildFeature('Storico completo'),
                      _buildFeature('Supporto prioritario'),
                      _buildFeature('Nessuna pubblicità'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // PIANI ABBONAMENTO
              if (_products.isEmpty)
                const Text(
                  'Caricamento abbonamenti...',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ..._products.map((product) {
                  final isSemestrale = product.id == SubscriptionService.semestraleId;
                  final isAnnuale = product.id == SubscriptionService.annualeId;
                  final isSelected = _selectedProduct?.id == product.id;

                  String durata = isSemestrale ? '6 MESI' : '12 MESI';
                  String risparmio = isAnnuale ? 'RISPARMIO 26%' : '';

                  return GestureDetector(
                    onTap: () => setState(() => _selectedProduct = product),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple[100] : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? Colors.purple : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Radio button
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.purple : Colors.grey,
                                width: 2,
                              ),
                              color: isSelected ? Colors.purple : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 15),

                          // Info piano
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      durata,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (risparmio.isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          risparmio,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  product.price,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                                Text(
                                  isSemestrale
                                      ? '${(19.90 / 6).toStringAsFixed(2)}€/mese'
                                      : '${(29.00 / 12).toStringAsFixed(2)}€/mese',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

              const SizedBox(height: 20),

              // BOTTONE ACQUISTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isPurchasing || _selectedProduct == null)
                      ? null
                      : () => _purchase(_selectedProduct!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isPurchasing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'ABBONATI ORA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // RIPRISTINA ACQUISTI
              TextButton(
                onPressed: _restorePurchases,
                child: const Text('Ripristina acquisti'),
              ),

              const SizedBox(height: 20),

              // NOTE LEGALI
              Text(
                '• L\'abbonamento si rinnova automaticamente\n'
                    '• Puoi annullare in qualsiasi momento\n'
                    '• I primi 14 giorni sono gratuiti',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}