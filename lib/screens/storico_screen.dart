import 'dart:async';  // AGGIUNTO per il Timer
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';
import '../services/app_email_service.dart';
import '../models/chiamata.dart';
import '../models/datore_lavoro.dart';
import '../services/pdf_service.dart';
import '../services/xml_service.dart';
import '../services/email_service.dart';
import '../services/secure_storage_service.dart';
import 'package:open_filex/open_filex.dart';
import '../services/review_service.dart';


class StoricoScreen extends StatefulWidget {
  const StoricoScreen({Key? key}) : super(key: key);

  @override
  State<StoricoScreen> createState() => _StoricoScreenState();
}

class _StoricoScreenState extends State<StoricoScreen> {
  List<Chiamata> chiamate = [];
  List<Chiamata> chiamateFiltrate = [];
  Set<int> selectedIds = {}; // IDs selezionati
  bool isLoading = true;
  bool isSelectionMode = false;

  // Variabili per il filtro data
  DateTime? dataInizioFiltro;
  DateTime? dataFineFiltro;

  Timer? _timer;  // AGGIUNTO per aggiornare automaticamente

  @override
  void initState() {
    super.initState();
    _caricaChiamate();

    // AGGIUNTO: Aggiorna ogni minuto per vedere i minuti scorrere
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // Questo forza il rebuild della lista ogni minuto
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();  // AGGIUNTO: Cancella il timer quando esci dalla pagina
    super.dispose();
  }

  Future<void> _caricaChiamate() async {
    setState(() => isLoading = true);
    final result = await DatabaseHelper.instance.getAllChiamate();
    setState(() {
      chiamate = result;
      chiamateFiltrate = result;
      isLoading = false;
    });
  }

  // Funzione per selezionare la data
  Future<void> _selezionaData(bool isInizio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isInizio) {
          dataInizioFiltro = picked;
        } else {
          dataFineFiltro = picked;
        }
        _applicaFiltro();
      });
    }
  }

  // Applica il filtro data
  void _applicaFiltro() {
    if (dataInizioFiltro == null && dataFineFiltro == null) {
      setState(() {
        chiamateFiltrate = chiamate;
      });
      return;
    }

    setState(() {
      chiamateFiltrate = chiamate.where((chiamata) {
        // Controlla data inizio filtro
        if (dataInizioFiltro != null) {
          final dataInizioSoloData = DateTime(
            dataInizioFiltro!.year,
            dataInizioFiltro!.month,
            dataInizioFiltro!.day,
          );
          final dataInvioSoloData = DateTime(
            chiamata.dataInvio.year,
            chiamata.dataInvio.month,
            chiamata.dataInvio.day,
          );
          if (dataInvioSoloData.isBefore(dataInizioSoloData)) {
            return false;
          }
        }

        // Controlla data fine filtro
        if (dataFineFiltro != null) {
          final dataFineSoloData = DateTime(
            dataFineFiltro!.year,
            dataFineFiltro!.month,
            dataFineFiltro!.day,
          );
          final dataInvioSoloData = DateTime(
            chiamata.dataInvio.year,
            chiamata.dataInvio.month,
            chiamata.dataInvio.day,
          );
          if (dataInvioSoloData.isAfter(dataFineSoloData)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  // Reset filtro
  void _resetFiltro() {
    setState(() {
      dataInizioFiltro = null;
      dataFineFiltro = null;
      chiamateFiltrate = chiamate;
    });
  }

  Widget _buildFiltroData() {
    final bool hasFiltro = dataInizioFiltro != null || dataFineFiltro != null;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),  // Ridotto padding
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.orange[700], size: 24),  // Icona più piccola
          const SizedBox(width: 8),  // Spazio ridotto
          Expanded(
            child: InkWell(
              onTap: () => _selezionaData(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),  // Padding ridotto
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  dataInizioFiltro != null
                      ? DateFormat('dd/MM/yy').format(dataInizioFiltro!)  // Anno a 2 cifre
                      : 'Da...',
                  style: TextStyle(
                    fontSize: 18,  // Testo più piccolo
                    color: dataInizioFiltro != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),  // Spazio ridotto
          const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),  // Icona più piccola
          const SizedBox(width: 6),  // Spazio ridotto
          Expanded(
            child: InkWell(
              onTap: () => _selezionaData(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),  // Padding ridotto
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  dataFineFiltro != null
                      ? DateFormat('dd/MM/yy').format(dataFineFiltro!)  // Anno a 2 cifre
                      : 'A...',
                  style: TextStyle(
                    fontSize: 18,  // Testo più piccolo
                    color: dataFineFiltro != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),  // Spazio ridotto
          IconButton(
            icon: Icon(
              Icons.clear,
              size: 20,  // Icona più piccola
              color: hasFiltro ? Colors.red : Colors.grey,
            ),
            onPressed: hasFiltro ? _resetFiltro : null,
            tooltip: 'Reset filtro',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Elimina dalla memoria (senza email)
  Future<void> _eliminaDallaMemoria(int id) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina dalla memoria'),
        content: const Text('Vuoi eliminare questa chiamata dalla memoria? Non verrà inviata nessuna email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sì, elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (conferma == true) {
      await DatabaseHelper.instance.deleteChiamata(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chiamata eliminata dalla memoria')),
      );
      _caricaChiamate();
    }
  }

  // Elimina chiamate selezionate
  Future<void> _eliminaSelezionate() async {
    if (selectedIds.isEmpty) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina chiamate selezionate'),
        content: Text('Vuoi eliminare ${selectedIds.length} chiamate dalla memoria?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sì, elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (conferma == true) {
      for (var id in selectedIds) {
        await DatabaseHelper.instance.deleteChiamata(id);
      }
      setState(() {
        selectedIds.clear();
        isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chiamate eliminate dalla memoria')),
      );
      _caricaChiamate();
    }
  }

  // Visualizza PDF della chiamata
  Future<void> _visualizzaPDF(Chiamata chiamata) async {
    setState(() => isLoading = true);

    try {
      // Carica datore per generare il PDF
      final datore = await DatabaseHelper.instance.getDatore();
      if (datore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dati datore non trovati')),
        );
        setState(() => isLoading = false);
        return;
      }

      // Genera il PDF
      final pdfPath = await PdfService.generaPdfChiamata(
        datore: datore,
        chiamata: chiamata,
        isAnnullamento: chiamata.stato == 'annullata',
      );

      // Genera XML
      final xmlPath = await XmlService.generaXmlChiamata(
        datore: datore,
        chiamata: chiamata,
        isAnnullamento: true,
      );

      setState(() => isLoading = false);

      // Apri con il visualizzatore nativo del sistema
      final result = await OpenFilex.open(pdfPath);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore apertura PDF: ${result.message}')),
        );
      }

    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  // Annulla chiamata (invia email)
  Future<void> _annullaChiamata(Chiamata chiamata) async {
    // Verifica se sono passate più di 48 ore
    final now = DateTime.now();
    final scadenza = chiamata.dataInvio.add(Duration(hours: 48));
    final differenza = scadenza.difference(now);

    if (differenza.isNegative) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Impossibile annullare'),
          content: const Text('Sono passate più di 48 ore dall\'invio della chiamata. Non è più possibile annullarla.\n\nPuoi comunque eliminarla dalla memoria.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final oreRimaste = differenza.inHours;
    final minutiRimasti = differenza.inMinutes % 60;

    setState(() => isLoading = true);

    try {  // INIZIO TRY
      final datore = await DatabaseHelper.instance.getDatore();
      if (datore == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dati datore non trovati')),
        );
        setState(() => isLoading = false);
        return;
      }

      final hasCredentials = await SecureStorageService.hasCredentials();
      if (!hasCredentials) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenziali email non configurate')),
        );
        setState(() => isLoading = false);
        return;
      }

      final pdfPath = await PdfService.generaPdfChiamata(
        datore: datore,
        chiamata: chiamata,
        isAnnullamento: true,
      );

      final xmlPath = await XmlService.generaXmlChiamata(
        datore: datore,
        chiamata: chiamata,
        isAnnullamento: true,
      );

      setState(() => isLoading = false);

// DIALOG UNIFICATO: PDF E XML + SCELTA INVIO
      final tipoInvio = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Generati'),  // Cambiato da "PDF Generato"
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icona PDF e riquadro XML affiancati
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 60,  // Ridotto da 80
                    color: Colors.red,
                  ),
                  const SizedBox(width: 20),
                  // Riquadro XML
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
              // INFO TEMPO RIMANENTE (invariato)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: oreRimaste < 12 ? Colors.red[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: oreRimaste < 12 ? Colors.red : Colors.orange,
                  ),
                ),
                child: Text(
                  'Tempo per annullare: $oreRimaste ore e $minutiRimasti minuti',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: oreRimaste < 12 ? Colors.red : Colors.orange[800],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'PDF e XML di annullamento generati con successo!',  // Aggiunto "e XML"
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
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

      if (tipoInvio == null) {
        setState(() => isLoading = false);
        return;
      }

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

      if (tipoInvio == 'app') {
        // USA IL SERVIZIO AGGIORNATO - CAMPI EMAIL PRECOMPILATI
        await AppEmailService.sendEmailViaApp(
          recipientEmail: datore.email,
          subject: 'ANNULLAMENTO Comunicazione Intermittenti - ${chiamata.nomeDipendente}',
          body: 'In allegato l\'annullamento della comunicazione obbligatoria per il dipendente ${chiamata.nomeDipendente}.\n\n'
              'Periodo annullato: ${DateFormat('dd/MM/yyyy').format(chiamata.dataInizio)} - ${DateFormat('dd/MM/yyyy').format(chiamata.dataFine)}',
          attachmentPaths: [pdfPath, xmlPath],
          additionalRecipients: destinatari,
        );

        // Dialog conferma salvataggio
        final salvare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Salvare l\'annullamento?'),
            content: const Text('Hai inviato l\'annullamento? Vuoi aggiornarlo nello storico?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Sì, aggiorna'),
              ),
            ],
          ),
        );

        if (salvare == true) {
          chiamata.stato = 'annullata';
          chiamata.dataAnnullamento = DateTime.now();
          await DatabaseHelper.instance.updateChiamata(chiamata);
          await ReviewService().incrementConsecutiveSuccessCalls();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chiamata annullata con successo!')),
          );
          _caricaChiamate();
        }

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
        if (datore.email.isNotEmpty && datore.email.contains('@')) {
          ccList.add(datore.email);
        }

        final emailInviata = await EmailService.sendEmail(
          providerSmtp: smtpServer!,
          providerPort: smtpPort!,
          username: username!,
          password: password!,
          recipientEmail: emailDestinatarioPrincipale,
          subject: 'ANNULLAMENTO Comunicazione Intermittenti - ${chiamata.nomeDipendente}',
          body: 'In allegato l\'annullamento della comunicazione obbligatoria per il dipendente ${chiamata.nomeDipendente}.\n\n'
              'Periodo annullato: ${DateFormat('dd/MM/yyyy').format(chiamata.dataInizio)} - ${DateFormat('dd/MM/yyyy').format(chiamata.dataFine)}',
          additionalRecipients: ccList,
          attachmentPaths: [pdfPath, xmlPath],
        );

        if (emailInviata) {
          chiamata.stato = 'annullata';
          chiamata.dataAnnullamento = DateTime.now();
          await DatabaseHelper.instance.updateChiamata(chiamata);
          await ReviewService().incrementConsecutiveSuccessCalls();

          setState(() => isLoading = false);

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
                    'Chiamata annullata con successo!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Annullamento per ${chiamata.nomeDipendente} inviato',
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
                    Navigator.pop(context); // Chiude dialog
                    _caricaChiamate(); // Ricarica la lista
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
            const SnackBar(content: Text('Errore nell\'invio email')),
          );
          setState(() => isLoading = false);
        }
      }

      setState(() => isLoading = false);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode
            ? '${selectedIds.length} selezionate'
            : 'Storico Chiamate'),
        backgroundColor: Colors.orange,
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  if (selectedIds.length == chiamateFiltrate.length) {
                    // Se tutto è già selezionato, deseleziona tutto
                    selectedIds.clear();
                  } else {
                    // Seleziona tutto
                    selectedIds = chiamateFiltrate.map((c) => c.id!).toSet();
                  }
                });
              },
              tooltip: 'Seleziona/Deseleziona tutto',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminaSelezionate,
              tooltip: 'Elimina selezionate',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  isSelectionMode = false;
                  selectedIds.clear();
                });
              },
              tooltip: 'Annulla selezione',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() => isSelectionMode = true);
              },
              tooltip: 'Modalità selezione',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtro data
          _buildFiltroData(),

          // Contatore risultati
          if (dataInizioFiltro != null || dataFineFiltro != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 5),
                  Text(
                    '${chiamateFiltrate.length} risultati trovati',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Lista chiamate
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : chiamateFiltrate.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    chiamate.isEmpty
                        ? 'Nessuna chiamata nello storico'
                        : 'Nessuna chiamata trovata per il periodo selezionato',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  if (chiamate.isNotEmpty && chiamateFiltrate.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ElevatedButton.icon(
                        onPressed: _resetFiltro,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset filtro'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: chiamateFiltrate.length,
              itemBuilder: (context, index) {
                final chiamata = chiamateFiltrate[index];
                final isAnnullata = chiamata.stato == 'annullata';
                final isSelected = selectedIds.contains(chiamata.id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: isAnnullata ? Colors.red[50] : Colors.green[50],
                  child: Column(
                    children: [
                      ListTile(
                        leading: isSelectionMode
                            ? Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedIds.add(chiamata.id!);
                              } else {
                                selectedIds.remove(chiamata.id!);
                              }
                            });
                          },
                        )
                            : CircleAvatar(
                          backgroundColor: isAnnullata ? Colors.red : Colors.green,
                          child: Icon(
                            isAnnullata ? Icons.cancel : Icons.check_circle,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          chiamata.nomeDipendente,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isAnnullata ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (chiamata.nomeAzienda != null && chiamata.nomeAzienda!.isNotEmpty)
                              Text(
                                'Azienda: ${chiamata.nomeAzienda}',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
                              ),
                            Text('Unilav: ${chiamata.codiceUnilav}'),
                            Text(
                              'Periodo: ${DateFormat('dd/MM/yyyy').format(chiamata.dataInizio)} - '
                                  '${DateFormat('dd/MM/yyyy').format(chiamata.dataFine)}',
                            ),
                            Text(
                              'Inviata: ${DateFormat('dd/MM/yyyy HH:mm').format(chiamata.dataInvio)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isAnnullata && chiamata.dataAnnullamento != null)
                              Text(
                                'Annullata: ${DateFormat('dd/MM/yyyy HH:mm').format(chiamata.dataAnnullamento!)}',
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                              onPressed: () => _visualizzaPDF(chiamata),
                              tooltip: 'Visualizza PDF',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _eliminaDallaMemoria(chiamata.id!),
                              tooltip: 'Rimuovi dallo Storico',
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                      // MODIFICATO: Contatore preciso con ore e minuti
                      if (!isAnnullata) ...[
                        // Calcola tempo rimanente con precisione
                        Builder(
                          builder: (context) {
                            final now = DateTime.now();
                            final scadenza = chiamata.dataInvio.add(Duration(hours: 48));
                            final differenza = scadenza.difference(now);

                            final isScaduto = differenza.isNegative;
                            final oreRimaste = differenza.inHours;
                            final minutiRimasti = differenza.inMinutes % 60;

                            // Formatta il tempo rimanente
                            String tempoRimasto;
                            if (isScaduto) {
                              tempoRimasto = 'TEMPO SCADUTO';
                            } else if (oreRimaste > 0) {
                              tempoRimasto = '$oreRimaste ore e $minutiRimasti minuti';
                            } else if (minutiRimasti > 0) {
                              tempoRimasto = '$minutiRimasti minuti rimanenti!';
                            } else {
                              final secondiRimasti = differenza.inSeconds % 60;
                              tempoRimasto = '$secondiRimasti secondi rimanenti!';
                            }

                            // Determina il colore in base al tempo rimanente
                            Color getColor() {
                              if (isScaduto) return Colors.grey;
                              if (oreRimaste < 1) return Colors.red;  // Meno di 1 ora
                              if (oreRimaste < 6) return Colors.deepOrange;  // Meno di 6 ore
                              if (oreRimaste < 12) return Colors.orange;  // Meno di 12 ore
                              if (oreRimaste < 24) return Colors.amber;  // Meno di 24 ore
                              return Colors.green;  // Più di 24 ore
                            }

                            final color = getColor();

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                              child: Column(
                                children: [
                                  // Indicatore tempo rimanente
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: color),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isScaduto ? Icons.block : Icons.timer,
                                          size: 16,
                                          color: color,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          tempoRimasto,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Bottone annulla (disabilitato se scaduto)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: isScaduto ? null : () => _annullaChiamata(chiamata),
                                      icon: Icon(
                                        Icons.cancel_outlined,
                                        color: isScaduto ? Colors.grey : Colors.red,
                                      ),
                                      label: Text(
                                        isScaduto ? 'Non più annullabile' : 'Annulla Chiamata',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isScaduto ? Colors.grey : Colors.red,
                                        side: BorderSide(
                                          color: isScaduto ? Colors.grey : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}