import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:io';

class EmailProvider {
  final String name;
  final String smtpServer;
  final int port;
  final bool useSsl;

  EmailProvider({
    required this.name,
    required this.smtpServer,
    required this.port,
    this.useSsl = true,
  });
}

class EmailService {
  // Lista provider predefiniti
  static final List<EmailProvider> providers = [
    // Italia
    // EmailProvider(name: 'Gmail', smtpServer: 'smtp.gmail.com', port: 587, useSsl: true),  // COMMENTATO
    EmailProvider(name: 'Outlook/Hotmail', smtpServer: 'smtp.office365.com', port: 587, useSsl: true),
    EmailProvider(name: 'Yahoo', smtpServer: 'smtp.mail.yahoo.com', port: 587, useSsl: true),
    EmailProvider(name: 'Libero', smtpServer: 'smtp.libero.it', port: 587, useSsl: true),
    EmailProvider(name: 'Virgilio', smtpServer: 'out.virgilio.it', port: 587, useSsl: true),
    EmailProvider(name: 'Tiscali', smtpServer: 'smtp.tiscali.it', port: 587, useSsl: true),
    EmailProvider(name: 'Fastweb', smtpServer: 'smtp.fastweb.it', port: 587, useSsl: true),
    EmailProvider(name: 'TIM/Alice', smtpServer: 'smtp.tim.it', port: 587, useSsl: true),
    EmailProvider(name: 'Vodafone', smtpServer: 'smtp.vodafone.it', port: 587, useSsl: true),
    EmailProvider(name: 'Wind', smtpServer: 'smtp.wind.it', port: 587, useSsl: true),

    // PEC - TUTTE COMMENTATE
    // EmailProvider(name: 'Aruba PEC', smtpServer: 'smtps.pec.aruba.it', port: 465, useSsl: true),
    // EmailProvider(name: 'Legalmail', smtpServer: 'smtp.legalmail.it', port: 465, useSsl: true),
    // EmailProvider(name: 'Namirial PEC', smtpServer: 'smtps.pec.namirial.com', port: 465, useSsl: true),
    // EmailProvider(name: 'Register PEC', smtpServer: 'smtps.pec.register.it', port: 465, useSsl: true),
    // EmailProvider(name: 'InfoCert PEC', smtpServer: 'smtps.pec.infocert.it', port: 465, useSsl: true),

    // Internazionali
    EmailProvider(name: 'AOL', smtpServer: 'smtp.aol.com', port: 587, useSsl: true),
    EmailProvider(name: 'iCloud', smtpServer: 'smtp.mail.me.com', port: 587, useSsl: true),
    EmailProvider(name: 'Zoho', smtpServer: 'smtp.zoho.com', port: 587, useSsl: true),
    EmailProvider(name: 'GMX', smtpServer: 'smtp.gmx.com', port: 587, useSsl: true),
    EmailProvider(name: 'Mail.com', smtpServer: 'smtp.mail.com', port: 587, useSsl: true),
    EmailProvider(name: 'Yandex', smtpServer: 'smtp.yandex.com', port: 587, useSsl: true),

    // Opzione manuale
    EmailProvider(name: 'Altro (Manuale)', smtpServer: '', port: 587, useSsl: true),
  ];

  // Metodo per inviare email
  static Future<bool> sendEmail({
    required String providerSmtp,
    required int providerPort,
    required String username,
    required String password,
    required String recipientEmail,
    required String subject,
    required String body,
    List<String>? additionalRecipients,
    List<String>? attachmentPaths,
  }) async {
    try {
      // DEBUG: Stampa tutti i parametri
      print('═══════════════════════════════════════');
      print('DEBUG EMAIL SERVICE:');
      print('SMTP Server: $providerSmtp');
      print('SMTP Port: $providerPort');
      print('Username: $username');
      print('Password: ${password.isNotEmpty ? "[PRESENTE]" : "[VUOTA]"}');
      print('Recipient: $recipientEmail');
      print('Subject: $subject');
      print('Body length: ${body.length}');
      print('Additional recipients: $additionalRecipients');
      print('Attachments: ${attachmentPaths?.length ?? 0}');
      print('═══════════════════════════════════════');

      // Verifica che i campi obbligatori non siano vuoti
      if (recipientEmail.isEmpty) {
        throw Exception('Email destinatario vuota!');
      }
      if (username.isEmpty) {
        throw Exception('Username email vuoto!');
      }
      if (password.isEmpty) {
        throw Exception('Password email vuota!');
      }
      if (providerSmtp.isEmpty) {
        throw Exception('Server SMTP vuoto!');
      }

      final smtpServer = SmtpServer(
        providerSmtp,
        port: providerPort,
        username: username,
        password: password,
        ssl: providerPort == 465,
        ignoreBadCertificate: true,
      );

      final message = Message()
        ..from = Address(username)
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..text = body;

      // Aggiungi destinatari aggiuntivi
      if (additionalRecipients != null && additionalRecipients.isNotEmpty) {
        for (var recipient in additionalRecipients) {
          if (recipient.isNotEmpty) {
            message.recipients.add(recipient);
          }
        }
      }

      // Aggiungi allegato se presente
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        for (var path in attachmentPaths) {
          message.attachments.add(FileAttachment(File(path)));
        }
      }

      print('Tentativo di invio email...');
      final sendReport = await send(message, smtpServer);
      print('✅ Email inviata: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('❌ Errore invio email: $e');
      rethrow;
    }
  }
}