import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';
import '../services/app_email_service.dart';
import '../models/dipendente.dart';
import '../models/chiamata.dart';
import '../models/datore_lavoro.dart';
import '../services/pdf_service.dart';
import '../services/xml_service.dart';
import '../services/email_service.dart';
import '../services/secure_storage_service.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart';
import '../services/review_service.dart';

class NuovaChiamataScreen extends StatefulWidget {
  const NuovaChiamataScreen({Key? key}) : super(key: key);

  @override
  State<NuovaChiamataScreen> createState() => _NuovaChiamataScreenState();
}

class _NuovaChiamataScreenState extends State<NuovaChiamataScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Dipendente> dipendenti = [];
  List<Dipendente> dipendentiSelezionati = [];
  bool usaStessaData = true;  // Checkbox per decidere se usare stessa data per tutti
  Map<int, DateTime?> dateInizio = {};  // Mappa: ID dipendente -> data inizio
  Map<int, DateTime?> dateFine = {};    // Mappa: ID dipendente -> data fine
  DateTime? dataInizioComune;  // Data comune quando usaStessaData = true
  DateTime? dataFineComune;    // Data comune quando usaStessaData = true
  bool isLoading = true;
  bool isSending = false;
  bool showDipendentiList = false;

  DatoreLavoro? aziendaAttiva;
  int? aziendaAttivaId;

  @override
  void initState() {
    super.initState();
    _caricaDipendenti();
  }

  Future<void> _caricaDipendenti() async {
    // Carica l'azienda attiva
    final idAttiva = await SecureStorageService.getAziendaAttiva();

    if (idAttiva == null) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleziona un\'azienda attiva nelle impostazioni del Datore di Lavoro'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Carica i dati dell'azienda attiva
    final azienda = await DatabaseHelper.instance.getAziendaById(idAttiva);

    if (azienda == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Carica SOLO i dipendenti di questa azienda
    final dipendentiAzienda = await DatabaseHelper.instance.getDipendentiDiAzienda(idAttiva);

    setState(() {
      aziendaAttivaId = idAttiva;
      aziendaAttiva = azienda;
      dipendenti = dipendentiAzienda;
      isLoading = false;
    });
  }

  Future<void> _selezionaData(bool isInizio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInizio
          ? (dataInizioComune ?? DateTime.now())
          : (dataFineComune ?? dataInizioComune ?? DateTime.now()),
      firstDate: isInizio ? DateTime.now() : (dataInizioComune ?? DateTime.now()),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isInizio) {
          dataInizioComune = picked;
          // Reset data fine se è prima della nuova data inizio
          if (dataFineComune != null && dataFineComune!.isBefore(picked)) {
            dataFineComune = null;
          }
        } else {
          dataFineComune = picked;
        }
      });
    }
  }

  Future<Map<String, DateTime>?> _mostraDialogDate(BuildContext context, Dipendente dipendente) async {
    DateTime? dataInizioTemp;
    DateTime? dataFineTemp;

    return await showDialog<Map<String, DateTime>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Date per ${dipendente.nome}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Data Inizio *'),
                  subtitle: Text(
                    dataInizioTemp != null
                        ? DateFormat('dd/MM/yyyy').format(dataInizioTemp!)
                        : 'Seleziona data',
                  ),
                  leading: const Icon(Icons.calendar_today, color: Colors.green),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataInizioTemp ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        dataInizioTemp = picked;
                        if (dataFineTemp != null && dataFineTemp!.isBefore(picked)) {
                          dataFineTemp = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('Data Fine *'),
                  subtitle: Text(
                    dataFineTemp != null
                        ? DateFormat('dd/MM/yyyy').format(dataFineTemp!)
                        : 'Seleziona data',
                  ),
                  leading: const Icon(Icons.calendar_today, color: Colors.green),
                  onTap: dataInizioTemp != null
                      ? () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataFineTemp ?? dataInizioTemp!,
                      firstDate: dataInizioTemp!,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        dataFineTemp = picked;
                      });
                    }
                  }
                      : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: (dataInizioTemp != null && dataFineTemp != null)
                    ? () {
                  Navigator.pop(context, {
                    'inizio': dataInizioTemp!,
                    'fine': dataFineTemp!,
                  });
                }
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Conferma'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _inviaChiamata() async {
    if (_formKey.currentState!.validate()) {
      if (dipendentiSelezionati.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona almeno un dipendente')),
        );
        return;
      }

// Validazione date in base alla modalità
      if (usaStessaData) {
        // Modalità "stessa data per tutti"
        if (dataInizioComune == null || dataFineComune == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleziona le date per tutti i dipendenti')),
          );
          return;
        }
      } else {
        // Modalità "date diverse"
        for (var dipendente in dipendentiSelezionati) {
          if (dateInizio[dipendente.id!] == null || dateFine[dipendente.id!] == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Mancano le date per ${dipendente.nome}')),
            );
            return;
          }
        }
      }

      setState(() => isSending = true);

      try {
        // Usa l'azienda attiva già caricata
        if (aziendaAttiva == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Seleziona un\'azienda attiva nelle impostazioni')),
          );
          setState(() => isSending = false);
          return;
        }

        // Verifica credenziali email
        final hasCredentials = await SecureStorageService.hasCredentials();
        if (!hasCredentials) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Configura prima le credenziali email nelle impostazioni')),
          );
          setState(() => isSending = false);
          return;
        }

        // Crea lista di chiamate per tutti i dipendenti selezionati
        List<Chiamata> chiamate = [];
        for (var dipendente in dipendentiSelezionati) {
          // Usa le date corrette in base alla modalità
          final DateTime inizioDipendente = usaStessaData
              ? dataInizioComune!
              : dateInizio[dipendente.id!]!;
          final DateTime fineDipendente = usaStessaData
              ? dataFineComune!
              : dateFine[dipendente.id!]!;

          chiamate.add(Chiamata(
            dipendenteId: dipendente.id!,
            nomeDipendente: dipendente.nome,
            codiceFiscaleDipendente: dipendente.codiceFiscale,
            nomeAzienda: aziendaAttiva!.nome,
            codiceUnilav: dipendente.codiceUnilav,
            dataInizio: inizioDipendente,
            dataFine: fineDipendente,
            stato: 'attiva',
            dataInvio: DateTime.now(),
          ));
        }

        // Genera UN SOLO PDF con tutti i dipendenti
        final pdfPath = await PdfService.generaPdfChiamataMultipla(
          datore: aziendaAttiva!,
          chiamate: chiamate,
          isAnnullamento: false,
        );

        // Genera UN SOLO XML con tutti i dipendenti
        final xmlPath = await XmlService.generaXmlChiamataMultipla(
          datore: aziendaAttiva!,
          chiamate: chiamate,
          isAnnullamento: false,
        );

        setState(() => isSending = false);

        // MOSTRA DIALOG SEMPLIFICATO SENZA ANTEPRIMA
        final tipoInvio = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Generati'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icona PDF e riquadro XML affiancati
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 20),
                    // Riquadro XML più piccolo
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade700, width: 1.5),
                      ),
                      child: const Text(
                        'XML',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  dipendentiSelezionati.length > 1
                      ? 'Sono stati generati PDF e XML per ${dipendentiSelezionati.length} dipendenti!'
                      : 'PDF e XML generati con successo!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () async {
                    await OpenFilex.open(pdfPath);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Visualizza PDF'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Scegli come inviare:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'app'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Invia con App Email'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'smtp'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Invia Diretto'),
              ),
            ],
          ),
        );

        if (tipoInvio == null) return;

        setState(() => isSending = true);

        // Carica destinatari aggiuntivi
        final ccDestinatario = await SecureStorageService.getCcDestinatario();
        final ccCommercialista = await SecureStorageService.getCcCommercialista();

        List<String> destinatari = [];
        if (ccDestinatario != null && ccDestinatario.isNotEmpty) {
          destinatari.add(ccDestinatario);
        }
        if (ccCommercialista != null && ccCommercialista.isNotEmpty) {
          destinatari.add(ccCommercialista);
        }

        bool emailInviata = false;

        if (tipoInvio == 'app') {
          // USA IL SERVIZIO AGGIORNATO - CAMPI EMAIL PRECOMPILATI
          await AppEmailService.sendEmailViaApp(
            recipientEmail: aziendaAttiva!.email,
            subject: dipendentiSelezionati.length > 1
                ? 'Comunicazione Obbligatoria Intermittenti - ${dipendentiSelezionati.length} dipendenti'
                : 'Comunicazione Obbligatoria Intermittenti - ${dipendentiSelezionati[0].nome}',
            body: dipendentiSelezionati.length > 1
                ? 'In allegato le comunicazioni obbligatorie per ${dipendentiSelezionati.length} dipendenti.\n\n'
                '${usaStessaData ? "Periodo comune: ${DateFormat('dd/MM/yyyy').format(dataInizioComune!)} - ${DateFormat('dd/MM/yyyy').format(dataFineComune!)}" : "Periodi specifici per ciascun dipendente"}'
                : 'In allegato la comunicazione obbligatoria per il dipendente ${dipendentiSelezionati[0].nome}.\n\n'
                'Periodo: ${DateFormat('dd/MM/yyyy').format(usaStessaData ? dataInizioComune! : dateInizio[dipendentiSelezionati[0].id!]!)} - ${DateFormat('dd/MM/yyyy').format(usaStessaData ? dataFineComune! : dateFine[dipendentiSelezionati[0].id!]!)}',
            attachmentPaths: [pdfPath, xmlPath],
            additionalRecipients: destinatari,
          );

          // DIALOG CONFERMA SALVATAGGIO
          final salvare = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Salvare nello storico?'),
              content: const Text('Hai inviato la chiamata? Vuoi salvarla nello storico?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Sì, salva'),
                ),
              ],
            ),
          );

          if (salvare == true) {
            for (var chiamata in chiamate) {
              await DatabaseHelper.instance.insertChiamata(chiamata);
            }
            await ReviewService().incrementConsecutiveSuccessCalls();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chiamata salvata nello storico')),
            );
          }

          Navigator.pop(context);

        } else {
          // INVIO CON SMTP
          final username = await SecureStorageService.getEmailUsername();
          final password = await SecureStorageService.getEmailPassword();
          final smtpServer = await SecureStorageService.getSmtpServer();
          final smtpPort = await SecureStorageService.getSmtpPort();

          // A: Destinatario principale (default: intermittenti)
          String emailDestinatarioPrincipale = ccDestinatario?.isNotEmpty == true
              ? ccDestinatario!
              : 'intermittenti@pec.lavoro.gov.it';

          // CC: Consulente + Email azienda
          List<String> ccList = [];
          if (ccCommercialista != null && ccCommercialista.isNotEmpty) {
            ccList.add(ccCommercialista);
          }
          if (aziendaAttiva?.email != null && aziendaAttiva!.email.isNotEmpty && aziendaAttiva!.email.contains('@')) {
            ccList.add(aziendaAttiva!.email);
          }

          emailInviata = await EmailService.sendEmail(
            providerSmtp: smtpServer!,
            providerPort: smtpPort!,
            username: username!,
            password: password!,
            recipientEmail: emailDestinatarioPrincipale,
            subject: dipendentiSelezionati.length > 1
                ? 'Comunicazione Obbligatoria Intermittenti - ${dipendentiSelezionati.length} dipendenti'
                : 'Comunicazione Obbligatoria Intermittenti - ${dipendentiSelezionati[0].nome}',
            body: dipendentiSelezionati.length > 1
                ? 'In allegato le comunicazioni obbligatorie per ${dipendentiSelezionati.length} dipendenti.\n\n'
                '${usaStessaData ? "Periodo comune: ${DateFormat('dd/MM/yyyy').format(dataInizioComune!)} - ${DateFormat('dd/MM/yyyy').format(dataFineComune!)}" : "Periodi specifici per ciascun dipendente"}'
                : 'In allegato la comunicazione obbligatoria per il dipendente ${dipendentiSelezionati[0].nome}.\n\n'
                'Periodo: ${DateFormat('dd/MM/yyyy').format(usaStessaData ? dataInizioComune! : dateInizio[dipendentiSelezionati[0].id!]!)} - ${DateFormat('dd/MM/yyyy').format(usaStessaData ? dataFineComune! : dateFine[dipendentiSelezionati[0].id!]!)}',
            attachmentPaths: [pdfPath, xmlPath],
            additionalRecipients: ccList,
          );

          if (emailInviata) {
            // Salva tutte le chiamate nel database
            for (var chiamata in chiamate) {
              await DatabaseHelper.instance.insertChiamata(chiamata);
            }

            await ReviewService().incrementConsecutiveSuccessCalls();

            setState(() => isSending = false);

            // NUOVO DIALOG DI SUCCESSO
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Chiamata inviata con successo!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      dipendentiSelezionati.length > 1
                          ? 'Comunicazione per ${dipendentiSelezionati.length} dipendenti inviata'
                          : 'Comunicazione inviata correttamente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            await ReviewService().resetConsecutiveSuccessCalls();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Errore nell\'invio dell\'email')),
            );
          }
        }

        setState(() => isSending = false);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore dettagliato: $e'),
            duration: const Duration(seconds: 10),
          ),
        );
        setState(() => isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova Chiamata'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dipendenti.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 20),
            Text(
              aziendaAttiva == null
                  ? 'Nessuna azienda attiva selezionata'
                  : 'Nessun dipendente per "${aziendaAttiva!.nome}"',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              aziendaAttiva == null
                  ? 'Seleziona un\'azienda nelle impostazioni'
                  : 'Aggiungi dipendenti per questa azienda',
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CHECKBOX - Usa stessa data per tutti
              CheckboxListTile(
                title: const Text(
                  'Usa stessa data per tutti i dipendenti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Se disattivato, potrai scegliere date diverse per ogni dipendente',
                  style: TextStyle(fontSize: 12),
                ),
                value: usaStessaData,
                onChanged: (bool? value) {
                  setState(() {
                    usaStessaData = value ?? true;
                    // Se attivi "stessa data", pulisci le date individuali
                    if (usaStessaData) {
                      dateInizio.clear();
                      dateFine.clear();
                    }
                  });
                },
                activeColor: Colors.green,
              ),
              const SizedBox(height: 10),
              // Pulsante per mostrare/nascondere la lista dipendenti
              InkWell(
                onTap: () {
                  setState(() {
                    showDipendentiList = !showDipendentiList;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dipendentiSelezionati.isEmpty
                              ? 'Seleziona Dipendenti *'
                              : '${dipendentiSelezionati.length} dipendenti selezionati',
                          style: TextStyle(
                            color: dipendentiSelezionati.isEmpty ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                      Icon(
                        showDipendentiList ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              // NUOVO CODICE - Pulsante "Seleziona tutti"
              if (showDipendentiList && usaStessaData)
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: CheckboxListTile(
                    title: const Text(
                      'Seleziona tutti i dipendenti',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    value: dipendentiSelezionati.length == dipendenti.length && dipendenti.isNotEmpty,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          dipendentiSelezionati = List.from(dipendenti);
                        } else {
                          dipendentiSelezionati.clear();
                        }
                      });
                    },
                    activeColor: Colors.green,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),


              // Lista con checkbox (visibile solo se showDipendentiList è true)
              if (showDipendentiList)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: dipendenti.length,
                    itemBuilder: (context, index) {
                      final dipendente = dipendenti[index];
                      final isSelected = dipendentiSelezionati.contains(dipendente);
                      return CheckboxListTile(
                        title: Text(dipendente.nome),
                        subtitle: Text('CF: ${dipendente.codiceFiscale}'),
                        value: isSelected,
                        onChanged: (bool? value) async {
                          if (value == true) {
                            // Se NON usa stessa data, apri dialog per scegliere date
                            if (!usaStessaData) {
                              final date = await _mostraDialogDate(context, dipendente);
                              if (date != null) {
                                setState(() {
                                  dipendentiSelezionati.add(dipendente);
                                  dateInizio[dipendente.id!] = date['inizio'];
                                  dateFine[dipendente.id!] = date['fine'];
                                });
                              }
                            } else {
                              // Se usa stessa data, aggiungi direttamente
                              setState(() {
                                dipendentiSelezionati.add(dipendente);
                              });
                            }
                          } else {
                            setState(() {
                              dipendentiSelezionati.remove(dipendente);
                              dateInizio.remove(dipendente.id!);
                              dateFine.remove(dipendente.id!);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              if (dipendentiSelezionati.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dipendenti selezionati:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ...dipendentiSelezionati.map((dip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ${dip.nome}'),
                              Text('  CF: ${dip.codiceFiscale}', style: const TextStyle(fontSize: 12)),
                              Text('  Unilav: ${dip.codiceUnilav}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ),
              ],
              // Mostra campi data SOLO se usa stessa data per tutti
              if (usaStessaData) ...[
                const SizedBox(height: 20),
                ListTile(
                  title: const Text('Data Inizio (per tutti) *'),
                  subtitle: Text(
                    dataInizioComune != null
                        ? DateFormat('dd/MM/yyyy').format(dataInizioComune!)
                        : 'Seleziona data',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _selezionaData(true),
                  tileColor: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),
                ListTile(
                  title: const Text('Data Fine (per tutti) *'),
                  subtitle: Text(
                    dataFineComune != null
                        ? DateFormat('dd/MM/yyyy').format(dataFineComune!)
                        : 'Seleziona data',
                  ),
                  leading: const Icon(Icons.calendar_today),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: dataInizioComune != null ? () => _selezionaData(false) : null,
                  tileColor: dataInizioComune != null ? Colors.grey[100] : Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isSending ? null : _inviaChiamata,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'INVIA CHIAMATA',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}