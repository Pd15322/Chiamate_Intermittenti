import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/dipendente.dart';

class AggiungiDipendenteScreen extends StatefulWidget {
  final Dipendente? dipendente;

  const AggiungiDipendenteScreen({Key? key, this.dipendente}) : super(key: key);

  @override
  State<AggiungiDipendenteScreen> createState() => _AggiungiDipendenteScreenState();
}

class _AggiungiDipendenteScreenState extends State<AggiungiDipendenteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cfController = TextEditingController();
  final _unilavController = TextEditingController();

  bool isModifica = false;

  @override
  void initState() {
    super.initState();
    if (widget.dipendente != null) {
      isModifica = true;
      _nomeController.text = widget.dipendente!.nome;
      _cfController.text = widget.dipendente!.codiceFiscale;
      _unilavController.text = widget.dipendente!.codiceUnilav;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cfController.dispose();
    _unilavController.dispose();
    super.dispose();
  }

  Future<void> _salvaDipendente() async {
    if (_formKey.currentState!.validate()) {
      final dipendente = Dipendente(
        id: widget.dipendente?.id,
        nome: _nomeController.text.trim(),
        codiceFiscale: _cfController.text.trim().toUpperCase(),
        codiceUnilav: _unilavController.text.trim(),
      );

      if (isModifica) {
        await DatabaseHelper.instance.updateDipendente(dipendente);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dipendente aggiornato')),
        );
      } else {
        await DatabaseHelper.instance.insertDipendente(dipendente);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dipendente aggiunto')),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isModifica ? 'Modifica Dipendente' : 'Aggiungi Dipendente'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nomeController,
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _cfController,
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
                  if (value.trim().length != 16) {
                    return 'Il codice fiscale deve essere di 16 caratteri';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _unilavController,
                decoration: const InputDecoration(
                  labelText: 'Codice Unilav *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il codice Unilav';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _salvaDipendente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  isModifica ? 'AGGIORNA' : 'SALVA',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}