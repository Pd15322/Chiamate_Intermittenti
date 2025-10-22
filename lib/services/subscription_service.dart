import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'review_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // ID PRODOTTI - QUESTI LI USERAI NEL GOOGLE PLAY CONSOLE
  static const String semestraleId = 'premium_semestrale';
  static const String annualeId = 'premium_annuale';

  // Stato abbonamento
  bool _isPremium = false;
  DateTime? _dataInizioProva;
  bool _isInitialized = false;

  bool get isPremium => _isPremium;
  bool get isInitialized => _isInitialized;

  /// Inizializza il servizio e controlla stato abbonamento
  Future<void> initialize() async {
    // Carica data inizio prova
    final prefs = await SharedPreferences.getInstance();
    final dataInizioMillis = prefs.getInt('data_inizio_prova');

    if (dataInizioMillis == null) {
      // Prima volta che apre l'app - salva data inizio prova
      _dataInizioProva = DateTime.now();
      await prefs.setInt('data_inizio_prova', _dataInizioProva!.millisecondsSinceEpoch);
    } else {
      _dataInizioProva = DateTime.fromMillisecondsSinceEpoch(dataInizioMillis);
    }

    // Controlla se ha abbonamento attivo
    await _checkSubscriptionStatus();

    // Ascolta aggiornamenti acquisti
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Errore stream acquisti: $error'),
    );

    _isInitialized = true;
  }

  /// Controlla quanti giorni di prova rimangono
  int giorniProvaRimasti() {
    if (_dataInizioProva == null) return 14;

    final now = DateTime.now();
    final differenza = now.difference(_dataInizioProva!);
    final giorniTrascorsi = differenza.inDays;
    final rimasti = 14 - giorniTrascorsi;

    return rimasti > 0 ? rimasti : 0;
  }

  /// Verifica se la prova è scaduta
  bool isProvaScaduta() {
    return giorniProvaRimasti() == 0;
  }

  /// Verifica se può usare l'app (prova attiva O abbonamento attivo)
  bool canUseApp() {
    return !isProvaScaduta() || _isPremium;
  }

  /// Controlla stato abbonamento
  Future<void> _checkSubscriptionStatus() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      print('Store non disponibile');
      return;
    }

    // Ripristina acquisti
    await _inAppPurchase.restorePurchases();

    // Attendi un momento per processare
    await Future.delayed(Duration(milliseconds: 500));

    // In produzione, il purchaseStream riceverà gli acquisti
    // Per ora impostiamo isPremium in base al stream
  }

  /// Carica i prodotti disponibili
  Future<List<ProductDetails>> loadProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      return [];
    }

    const Set<String> ids = {semestraleId, annualeId};
    final ProductDetailsResponse response =
    await _inAppPurchase.queryProductDetails(ids);

    if (response.error != null) {
      print('Errore caricamento prodotti: ${response.error}');
      return [];
    }

    return response.productDetails;
  }

  /// Avvia acquisto abbonamento
  Future<bool> purchaseSubscription(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

    try {
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      print('Errore acquisto: $e');
      return false;
    }
  }

  /// Gestisce aggiornamenti acquisti
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Acquisto completato con successo
        _isPremium = true;
        await ReviewService().savePaymentDate();

        // Completa la transazione
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        print('Errore acquisto: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        print('Acquisto in attesa...');
      }
    }
  }

  /// Ripristina acquisti (per chi cambia dispositivo)
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      // Attendi che il purchaseStream processi gli acquisti
      await Future.delayed(Duration(seconds: 2));
      return _isPremium;
    } catch (e) {
      print('Errore ripristino: $e');
      return false;
    }
  }

  /// Pulisci risorse
  void dispose() {
    _subscription?.cancel();
  }

  /// SOLO PER TEST - Resetta prova (NON usare in produzione)
  Future<void> resetTrialForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('data_inizio_prova');
    _dataInizioProva = DateTime.now();
    await prefs.setInt('data_inizio_prova', _dataInizioProva!.millisecondsSinceEpoch);
  }
}