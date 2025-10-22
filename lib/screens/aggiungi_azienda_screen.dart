import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/datore_lavoro.dart';

class AggiungiAziendaScreen extends StatefulWidget {
  final DatoreLavoro? azienda;

  const AggiungiAziendaScreen({Key? key, this.azienda}) : super(key: key);

  @override
  State<AggiungiAziendaScreen> createState() => _AggiungiAziendaScreenState();
}

class _AggiungiAziendaScreenState extends State<AggiungiAziendaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cfController = TextEditingController();
  final _emailController = TextEditingController();

  bool isModifica = false;

  @override
  void initState() {
    super.initState();
    if (widget.azienda != null) {
      isModifica = true;
      _nomeController.text = widget.azienda!.nome;
      _cfController.text = widget.azienda!.codiceFiscale;
      _emailController.text = widget.azienda!.email;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cfController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _salvaAzienda() async {
    if (_formKey.currentState!.validate()) {
      final azienda = DatoreLavoro(
        id: widget.azienda?.id,
        nome: _nomeController.text.trim(),
        codiceFiscale: _cfController.text.trim().toUpperCase(),
        email: _emailController.text.trim(),
      );

      if (isModifica) {
        await DatabaseHelper.instance.updateAzienda(azienda);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Azienda aggiornata')),
        );
      } else {
        await DatabaseHelper.instance.insertAzienda(azienda);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Azienda aggiunta')),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isModifica ? 'Modifica Azienda' : 'Aggiungi Azienda'),
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
                  labelText: 'Nome Azienda *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                  hintText: 'es. Ristorante Da Mario',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il nome dell\'azienda';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cfController,
                decoration: const InputDecoration(
                  labelText: 'Codice Fiscale / P.IVA *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                  hintText: 'CF (16 caratteri) o P.IVA (11 cifre)',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci il codice fiscale o P.IVA';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Aziendale *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Inserisci l\'email';
                  }
                  if (!value.contains('@')) {
                    return 'Email non valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _salvaAzienda,
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