import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../services/secure_storage_service.dart';
import 'dart:io';

class AppEmailService {
  static Future<bool> sendEmailViaApp({
    required String recipientEmail,
    required String subject,
    required String body,
    required List<String> attachmentPaths,
    List<String>? additionalRecipients,
  }) async {
    try {
      // TO: Leggi il destinatario principale dalle impostazioni
      final destinatarioPrincipale = await SecureStorageService.getCcDestinatario();
      List<String> allRecipients = [];
      if (destinatarioPrincipale != null) {
        allRecipients.add(destinatarioPrincipale);
      }

      // CC: Leggi il consulente dalle impostazioni
      final consulente = await SecureStorageService.getCcCommercialista();
      List<String> ccRecipients = [];
      if (consulente != null && consulente.isNotEmpty) {
        ccRecipients.add(consulente);
      }

      final Email email = Email(
        body: body,
        subject: subject,
        recipients: allRecipients,  // TO
        cc: ccRecipients,           // CC
        attachmentPaths: attachmentPaths,
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
      return true;
    } catch (e) {
      print('Errore invio email: $e');
      return false;
    }
  }
}