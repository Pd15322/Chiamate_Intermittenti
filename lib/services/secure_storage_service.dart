import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _keyEmailUsername = 'email_username';
  static const String _keyEmailPassword = 'email_password';
  static const String _keyEmailProvider = 'email_provider';
  static const String _keySmtpServer = 'smtp_server';
  static const String _keySmtpPort = 'smtp_port';
  static const String _keyCcDestinatario = 'cc_destinatario';
  static const String _keyCcCommercialista = 'cc_commercialista';
  static const String _keyAziendaAttiva = 'azienda_attiva_id';

  static Future<void> saveEmailCredentials({
    required String username,
    required String password,
    required String provider,
    required String smtpServer,
    required int smtpPort,
    required String ccDestinatario,
    required String ccCommercialista,
  }) async {
    await _storage.write(key: _keyEmailUsername, value: username);
    await _storage.write(key: _keyEmailPassword, value: password);
    await _storage.write(key: _keyEmailProvider, value: provider);
    await _storage.write(key: _keySmtpServer, value: smtpServer);
    await _storage.write(key: _keySmtpPort, value: smtpPort.toString());
    await _storage.write(key: _keyCcDestinatario, value: ccDestinatario);
    await _storage.write(key: _keyCcCommercialista, value: ccCommercialista);
  }

  static Future<String?> getEmailUsername() async {
    return await _storage.read(key: _keyEmailUsername);
  }

  static Future<String?> getEmailPassword() async {
    return await _storage.read(key: _keyEmailPassword);
  }

  static Future<String?> getCcDestinatario() async {
    final saved = await _storage.read(key: _keyCcDestinatario);
    if (saved == null || saved.isEmpty) {
      return 'intermittenti@pec.lavoro.gov.it';
    }
    return saved;
  }

  static Future<String?> getCcCommercialista() async {
    return await _storage.read(key: _keyCcCommercialista);
  }

  static Future<String?> getEmailProvider() async {
    return await _storage.read(key: _keyEmailProvider);
  }

  static Future<String?> getSmtpServer() async {
    return await _storage.read(key: _keySmtpServer);
  }

  static Future<int?> getSmtpPort() async {
    final port = await _storage.read(key: _keySmtpPort);
    return port != null ? int.tryParse(port) : null;
  }

  static Future<bool> hasCredentials() async {
    final username = await getEmailUsername();
    final password = await getEmailPassword();
    return username != null && password != null;
  }

  static Future<void> deleteAllCredentials() async {
    await _storage.delete(key: _keyEmailUsername);
    await _storage.delete(key: _keyEmailPassword);
    await _storage.delete(key: _keyEmailProvider);
    await _storage.delete(key: _keySmtpServer);
    await _storage.delete(key: _keySmtpPort);
    await _storage.delete(key: _keyCcDestinatario);
    await _storage.delete(key: _keyCcCommercialista);
  }

  static Future<void> saveAziendaAttiva(int aziendaId) async {
    await _storage.write(key: _keyAziendaAttiva, value: aziendaId.toString());
  }

  static Future<int?> getAziendaAttiva() async {
    final id = await _storage.read(key: _keyAziendaAttiva);
    return id != null ? int.tryParse(id) : null;
  }

  static Future<void> deleteAziendaAttiva() async {
    await _storage.delete(key: _keyAziendaAttiva);
  }
}