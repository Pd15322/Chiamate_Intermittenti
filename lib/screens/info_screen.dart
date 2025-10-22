import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  void _copiaEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copiata: $email'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Info App'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo o Titolo
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 80,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gestione Chiamate\nIntermittenti',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Versione 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Descrizione App
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Cosa fa questa app',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Gestisce le comunicazioni obbligatorie per i lavoratori intermittenti, permettendo di:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text('• Registrare i dipendenti'),
                    Text('• Inviare nuove chiamate'),
                    Text('• Annullare chiamate entro 48 ore'),
                    Text('• Tenere uno storico completo'),
                    Text('• Generare PDF e XML automaticamente'),
                    Text('• Inviare via email diretta o app email'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Come Usare
            Card(
              color: Colors.green[50],
              child: const Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚀 Configurazione Iniziale',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1️⃣ DATORE DI LAVORO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('   Configura i tuoi dati e l\'email'),
                    SizedBox(height: 5),
                    Text(
                      '2️⃣ DIPENDENTI',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('   Aggiungi i lavoratori intermittenti'),
                    SizedBox(height: 5),
                    Text(
                      '3️⃣ NUOVA CHIAMATA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('   Seleziona dipendente e date'),
                    SizedBox(height: 5),
                    Text(
                      '5️⃣ ANNULLA CHIAMATA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('   Puoi annullare entro 48 ore'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Email Importante
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📧 Email Destinatario Importante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'intermittenti@pec.lavoro.gov.it',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.orange),
                            onPressed: () => _copiaEmail(
                              context,
                              'intermittenti@pec.lavoro.gov.it',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '⚠️ Tutte le comunicazioni devono essere inviate a questo indirizzo PEC',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Problemi con Gmail
            Card(
              color: Colors.red[50],
              child: const Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ Problemi con Gmail?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Gmail richiede password specifiche per app.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Usa "Invia con App Email" invece di "Invia Diretto" per evitare problemi.',
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Per altri provider (Libero, Outlook, ecc.) puoi usare "Invia Diretto" con la password che usi della tua stessa email.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Note Legali
            Card(
              color: Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚖️ Note Legali',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Questa app è uno strumento di supporto per la gestione delle comunicazioni obbligatorie. L\'utente è responsabile della correttezza dei dati inseriti e dell\'invio delle comunicazioni nei tempi previsti dalla legge.',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ricorda: gli annullamenti devono essere effettuati entro 48 ore dall\'invio della chiamata originale.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Supporto
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💬 Supporto',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Per assistenza contatta:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _copiaEmail(context, 'supporto@tuamail.com'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, size: 16, color: Colors.purple),
                            SizedBox(width: 5),
                            Text(
                              'assistenzachiamate0@gmail.com', // CAMBIA CON LA TUA EMAIL
                              style: TextStyle(
                                color: Colors.purple,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Copyright
            Center(
              child: Text(
                '© 2024 - Tutti i diritti riservati',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}