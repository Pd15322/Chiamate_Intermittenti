import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/datore_lavoro.dart';
import '../models/dipendente.dart';
import 'aggiungi_azienda_screen.dart';

class DettaglioAziendaScreen extends StatefulWidget {
  final DatoreLavoro azienda;

  const DettaglioAziendaScreen({Key? key, required this.azienda}) : super(key: key);

  @override
  State<DettaglioAziendaScreen> createState() => _DettaglioAziendaScreenState();
}

class _DettaglioAziendaScreenState extends State<DettaglioAziendaScreen> {
  List<Dipendente> dipendentiAssociati = [];
  bool isLoading = true;
  late DatoreLavoro aziendaCorrente;

  @override
  void initState() {
    super.initState();
    aziendaCorrente = widget.azienda;
    _caricaDati();
  }

  Future<void> _caricaDati() async {
    setState(() => isLoading = true);

    final associati = await DatabaseHelper.instance.getDipendentiDiAzienda(aziendaCorrente.id!);

    setState(() {
      dipendentiAssociati = associati;
      isLoading = false;
    });
  }

  Future<void> _mostraFormAggiungiDipendente() async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final cfController = TextEditingController();
    final unilavController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi Dipendente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome e Cognome *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: cfController,
                  decoration: const InputDecoration(
                    labelText: 'Codice Fiscale *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 16,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il codice fiscale';
                    }
                    if (value.length != 16) {
                      return 'Il CF deve essere di 16 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: unilavController,
                  decoration: const InputDecoration(
                    labelText: 'Codice Unilav *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il codice Unilav';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Crea il nuovo dipendente
                final nuovoDipendente = Dipendente(
                  nome: nomeController.text.trim(),
                  codiceFiscale: cfController.text.trim().toUpperCase(),
                  codiceUnilav: unilavController.text.trim(),
                  aziendaId: aziendaCorrente.id,
                );

                // Inserisci nel database
                final dipendenteId = await DatabaseHelper.instance.insertDipendente(nuovoDipendente);

                // Associa all'azienda
                await DatabaseHelper.instance.associaDipendenteAdAzienda(
                  aziendaCorrente.id!,
                  dipendenteId,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dipendente "${nomeController.text}" aggiunto'),
                    backgroundColor: Colors.green,
                  ),
                );

                _caricaDati();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminaDipendente(Dipendente dipendente) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Dipendente'),
        content: Text('Vuoi eliminare "${dipendente.nome}" da questa azienda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (conferma == true) {
      // Rimuovi l'associazione
      await DatabaseHelper.instance.rimuoviDipendenteDaAzienda(
        aziendaCorrente.id!,
        dipendente.id!,
      );

      // Elimina il dipendente dal database
      await DatabaseHelper.instance.deleteDipendente(dipendente.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dipendente eliminato'),
          backgroundColor: Colors.red,
        ),
      );

      _caricaDati();
    }
  }

  Future<void> _modificaDipendente(Dipendente dipendente) async {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: dipendente.nome);
    final cfController = TextEditingController(text: dipendente.codiceFiscale);
    final unilavController = TextEditingController(text: dipendente.codiceUnilav);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifica Dipendente'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome e Cognome *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: cfController,
                  decoration: const InputDecoration(
                    labelText: 'Codice Fiscale *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 16,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il codice fiscale';
                    }
                    if (value.length != 16) {
                      return 'Il CF deve essere di 16 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: unilavController,
                  decoration: const InputDecoration(
                    labelText: 'Codice Unilav *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Inserisci il codice Unilav';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final dipendenteAggiornato = Dipendente(
                  id: dipendente.id,
                  nome: nomeController.text.trim(),
                  codiceFiscale: cfController.text.trim().toUpperCase(),
                  codiceUnilav: unilavController.text.trim(),
                  aziendaId: aziendaCorrente.id,
                );

                await DatabaseHelper.instance.updateDipendente(dipendenteAggiornato);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dipendente aggiornato'),
                    backgroundColor: Colors.blue,
                  ),
                );

                _caricaDati();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Aggiorna'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(aziendaCorrente.nome),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Azienda
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Informazioni Azienda',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Modifica Azienda',
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AggiungiAziendaScreen(azienda: aziendaCorrente),
                              ),
                            );
                            // Ricarica i dati dell'azienda aggiornata
                            final aziendaAggiornata = await DatabaseHelper.instance.getAzienda(aziendaCorrente.id!);
                            if (aziendaAggiornata != null) {
                              setState(() {
                                aziendaCorrente = aziendaAggiornata;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow(Icons.business, 'Nome', aziendaCorrente.nome),
                    _buildInfoRow(Icons.badge, 'CF/P.IVA', aziendaCorrente.codiceFiscale),
                    _buildInfoRow(Icons.email, 'Email', aziendaCorrente.email),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Sezione Dipendenti
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dipendenti (${dipendentiAssociati.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _mostraFormAggiungiDipendente,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Aggiungi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (dipendentiAssociati.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Nessun dipendente associato.\nClicca su "Aggiungi" per inserirne uno.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...dipendentiAssociati.map((dip) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              dip.nome[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(dip.nome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CF: ${dip.codiceFiscale}'),
                              Text('Unilav: ${dip.codiceUnilav}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _modificaDipendente(dip),
                                tooltip: 'Modifica',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminaDipendente(dip),
                                tooltip: 'Elimina',
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}