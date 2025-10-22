import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // Chiavi storage
  static const String _keyInstallDate = 'install_date';
  static const String _keyPaymentDate = 'payment_date';
  static const String _keyConsecutiveSuccessCalls = 'consecutive_success_calls';
  static const String _keyGoldRequestCount = 'gold_request_count';
  static const String _keySilverRequested = 'silver_requested';
  static const String _keyLastRequestDate = 'last_request_date';
  static const String _keyHasReviewed = 'has_reviewed';

  /// Inizializza la data di installazione (solo la prima volta)
  Future<void> initializeInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyInstallDate)) {
      await prefs.setInt(_keyInstallDate, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Salva la data di pagamento
  Future<void> savePaymentDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPaymentDate, DateTime.now().millisecondsSinceEpoch);
  }

  /// Incrementa il contatore di chiamate consecutive OK
  Future<void> incrementConsecutiveSuccessCalls() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyConsecutiveSuccessCalls) ?? 0;
    await prefs.setInt(_keyConsecutiveSuccessCalls, current + 1);
  }

  /// Reset chiamate consecutive (quando c'è un errore)
  Future<void> resetConsecutiveSuccessCalls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConsecutiveSuccessCalls, 0);
  }

  /// Ottieni numero chiamate consecutive OK
  Future<int> getConsecutiveSuccessCalls() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyConsecutiveSuccessCalls) ?? 0;
  }

  /// Verifica se è passato abbastanza tempo dall'ultima richiesta
  Future<bool> canRequestAgain() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRequestMillis = prefs.getInt(_keyLastRequestDate);

    if (lastRequestMillis == null) return true;

    final lastRequest = DateTime.fromMillisecondsSinceEpoch(lastRequestMillis);
    final daysPassed = DateTime.now().difference(lastRequest).inDays;

    return daysPassed >= 30;
  }

  /// Verifica se deve mostrare richiesta GOLD
  Future<bool> shouldRequestGoldReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Controlla se ha già recensito
    if (prefs.getBool(_keyHasReviewed) == true) return false;

    // Controlla numero richieste GOLD (max 2)
    final goldRequests = prefs.getInt(_keyGoldRequestCount) ?? 0;
    if (goldRequests >= 2) return false;

    // Controlla se ha pagato
    final paymentMillis = prefs.getInt(_keyPaymentDate);
    if (paymentMillis == null) return false;

    // Controlla se sono passati 7 giorni dal pagamento
    final paymentDate = DateTime.fromMillisecondsSinceEpoch(paymentMillis);
    final daysSincePayment = DateTime.now().difference(paymentDate).inDays;

    if (daysSincePayment < 7) return false;

    // Se è la prima richiesta GOLD, ok
    if (goldRequests == 0) return true;

    // Se è la seconda richiesta, controlla i 30 giorni
    if (goldRequests == 1) {
      return await canRequestAgain();
    }

    return false;
  }

  /// Verifica se deve mostrare richiesta SILVER
  Future<bool> shouldRequestSilverReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Controlla se ha già recensito
    if (prefs.getBool(_keyHasReviewed) == true) return false;

    // Controlla se ha già fatto richiesta SILVER
    if (prefs.getBool(_keySilverRequested) == true) return false;

    // Controlla se ha pagato (se sì, passa a GOLD)
    final paymentMillis = prefs.getInt(_keyPaymentDate);
    if (paymentMillis != null) return false;

    // Controlla se è giorno 12
    final installMillis = prefs.getInt(_keyInstallDate);
    if (installMillis == null) return false;

    final installDate = DateTime.fromMillisecondsSinceEpoch(installMillis);
    final daysSinceInstall = DateTime.now().difference(installDate).inDays;

    if (daysSinceInstall != 12) return false;

    // Controlla se ha 2+ chiamate consecutive OK
    final consecutiveCalls = await getConsecutiveSuccessCalls();
    if (consecutiveCalls < 2) return false;

    return true;
  }

  /// Segna che è stata fatta una richiesta GOLD
  Future<void> markGoldRequested() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyGoldRequestCount) ?? 0;
    await prefs.setInt(_keyGoldRequestCount, current + 1);
    await prefs.setInt(_keyLastRequestDate, DateTime.now().millisecondsSinceEpoch);
  }

  /// Segna che è stata fatta una richiesta SILVER
  Future<void> markSilverRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySilverRequested, true);
    await prefs.setInt(_keyLastRequestDate, DateTime.now().millisecondsSinceEpoch);
  }

  /// Segna che l'utente ha recensito
  Future<void> markAsReviewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasReviewed, true);
  }

  /// Apre la pagina Play Store per la recensione
  Future<void> openPlayStore() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      // Fallback: apri direttamente lo store
      await _inAppReview.openStoreListing(
        appStoreId: '', // Non serve per Android
      );
    }
  }

  /// SOLO PER TEST - Reset tutto
  Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyInstallDate);
    await prefs.remove(_keyPaymentDate);
    await prefs.remove(_keyConsecutiveSuccessCalls);
    await prefs.remove(_keyGoldRequestCount);
    await prefs.remove(_keySilverRequested);
    await prefs.remove(_keyLastRequestDate);
    await prefs.remove(_keyHasReviewed);
  }
}