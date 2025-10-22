import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/dipendente.dart';
import 'aggiungi_dipendente_screen.dart';

class DipendentiScreen extends StatefulWidget {
  const DipendentiScreen({Key? key}) : super(key: key);

  @override
  State<DipendentiScreen> createState() => _DipendentiScreenState();
}

class _DipendentiScreenState extends State<DipendentiScreen> {
  List<Dipendente> dipendenti = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _caricaDipendenti();
  }

  Future<void> _caricaDipendenti() async {
    setState(() => isLoading = true);
    final result = await DatabaseHelper.instance.getAllDipendenti();
    setState(() {
      dipendenti = result;
      isLoading = false;
    });
  }

  Future<void> _eliminaDipendente(int id) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text('Sei sicuro di voler eliminare questo dipendente?'),
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
      await DatabaseHelper.instance.deleteDipendente(id);
      _caricaDipendenti();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dipendente eliminato')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Dipendenti'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dipendenti.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Nessun dipendente inserito',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            const Text('Clicca sul + per aggiungerne uno'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: dipendenti.length,
        itemBuilder: (context, index) {
          final dipendente = dipendenti[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  dipendente.nome[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                dipendente.nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CF: ${dipendente.codiceFiscale}'),
                  Text('Unilav: ${dipendente.codiceUnilav}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AggiungiDipendenteScreen(
                            dipendente: dipendente,
                          ),
                        ),
                      );
                      _caricaDipendenti();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminaDipendente(dipendente.id!),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AggiungiDipendenteScreen()),
          );
          _caricaDipendenti();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}