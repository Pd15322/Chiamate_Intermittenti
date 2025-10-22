import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/datore_lavoro.dart';
import '../services/email_service.dart';
import '../services/secure_storage_service.dart';
import 'aggiungi_azienda_screen.dart';
import 'dettaglio_azienda_screen.dart';

class ImpostazioniScreen extends StatefulWidget {
  const ImpostazioniScreen({Key? key}) : super(key: key);

  @override
  State<ImpostazioniScreen> createState() => _ImpostazioniScreenState();
}

class _ImpostazioniScreenState extends State<ImpostazioniScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers Email SMTP
  final _emailUsernameController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  final _ccDestinatarioController = TextEditingController();
  final _ccCommercialistaController = TextEditingController();
  final _smtpServerController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _searchController = TextEditingController();

  EmailProvider? providerSelezionato;
  bool _obscurePassword = true;
  bool isLoading = true;
  bool isSaving = false;

  // Lista aziende e azienda attiva
  List<DatoreLavoro> aziende = [];
  List<DatoreLavoro> aziendeFiltrate = [];
  int? aziendaAttivaId;

  @override
  void initState() {
    super.initState();
    _caricaDati();
  }

  @override
  void dispose() {
    _emailUsernameController.dispose();
    _emailPasswordController.dispose();
    _ccDestinatarioController.dispose();
    _ccCommercialistaController.dispose();
    _smtpServerController.dispose();
    _smtpPortController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _caricaDati() async {
    setState(() => isLoading = true);

    // Carica credenziali email
    final username = await SecureStorageService.getEmailUsername();
    final password = await SecureStorageService.getEmailPassword();
    final provider = await SecureStorageService.getEmailProvider();
    final smtpServer = await SecureStorageService.getSmtpServer();
    final smtpPort = await SecureStorageService.getSmtpPort();

    if (username != null) {
      _emailUsernameController.text = username;
    }
    if (password != null) {
      _emailPasswordController.text = password;
    }
    if (smtpServer != null) {
      _smtpServerController.text = smtpServer;
    }
    if (smtpPort != null) {
      _smtpPortController.text = smtpPort.toString();
    }
    if (provider != null) {
      providerSelezionato = EmailService.providers.firstWhere(
            (p) => p.name == provider,
        orElse: () => EmailService.providers.last,
      );
    }

    final ccDestinatario = await SecureStorageService.getCcDestinatario();
    final ccCommercialista = await SecureStorageService.getCcCommercialista();

    if (ccDestinatario != null) {
      _ccDestinatarioController.text = ccDestinatario;
    }
    if (ccCommercialista != null) {
      _ccCommercialistaController.text = ccCommercialista;
    }

    // Carica aziende e azienda attiva
    final aziendeCaricate = await DatabaseHelper.instance.getAllAziende();
    final aziendaAttivaCaricata = await SecureStorageService.getAziendaAttiva();

    setState(() {
      aziende = aziendeCaricate;
      aziendeFiltrate = aziendeCaricate;
      aziendaAttivaId = aziendaAttivaCaricata;
      isLoading = false;
    });
  }

  Future<void> _salvaDati() async {
    if (_formKey.currentState!.validate()) {
      if (providerSelezionato == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un provider email')),
        );
        return;
      }

      setState(() => isSaving = true);

      try {
        // Salva credenziali email
        await SecureStorageService.saveEmailCredentials(
          username: _emailUsernameController.text.trim(),
          password: _emailPasswordController.text,
          provider: providerSelezionato!.name,
          smtpServer: _smtpServerController.text.trim(),
          smtpPort: int.parse(_smtpPortController.text.trim()),
          ccDestinatario: _ccDestinatarioController.text.trim(),
          ccCommercialista: _ccCommercialistaController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni salvate con successo!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio: $e')),
        );
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  void _onProviderChanged(EmailProvider? provider) {
    setState(() {
      providerSelezionato = provider;
      if (provider != null && provider.name != 'Altro (Manuale)') {
        _smtpServerController.text = provider.smtpServer;
        _smtpPortController.text = provider.port.toString();
      }
    });
  }

  void _filtraAziende(String query) {
    setState(() {
      if (query.isEmpty) {
        aziendeFiltrate = aziende;
      } else {
        aziendeFiltrate = aziende.where((azienda) {
          return azienda.nome.toLowerCase().contains(query.toLowerCase()) ||
              azienda.codiceFiscale.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _impostaAziendaAttiva(int? aziendaId) async {
    if (aziendaId == null) {
      await SecureStorageService.deleteAziendaAttiva();
      aziendaAttivaId = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Azienda deselezionata'), backgroundColor: Colors.grey),
        );
      }
    } else {
      await SecureStorageService.saveAziendaAttiva(aziendaId);
      aziendaAttivaId = aziendaId;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Azienda attiva impostata'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _eliminaAzienda(int id, String nome) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Azienda'),
        content: Text('Vuoi eliminare "$nome"?'),
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
      await DatabaseHelper.instance.deleteAzienda(id);

      if (aziendaAttivaId == id) {
        await SecureStorageService.deleteAziendaAttiva();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Azienda eliminata')),
      );
      _caricaDati();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datore di Lavoro'),
        backgroundColor: Colors.grey,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================== SEZIONE AZIENDA ATTIVA ====================
              const Text(
                '🏢 CONFIGURAZIONE AZIENDA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 10),

              // BARRA DI RICERCA
              if (aziende.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cerca azienda per nome o CF',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtraAziende('');
                        },
                      )
                          : null,
                    ),
                    onChanged: _filtraAziende,
                  ),
                ),

              if (aziende.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'Nessuna azienda inserita',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Clicca sul bottone qui sotto per aggiungere la tua prima azienda',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                StatefulBuilder(
                  builder: (context, setStateList) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: aziendeFiltrate.map((azienda) {
                          final isAttiva = aziendaAttivaId == azienda.id;
                          return Card(
                            key: ValueKey(azienda.id),
                            color: isAttiva ? Colors.blue[50] : Colors.white,
                            margin: const EdgeInsets.only(bottom: 5),
                            elevation: isAttiva ? 3 : 1,
                            child: Stack(
                              children: [
                                ListTile(
                                  leading: GestureDetector(
                                    onTap: () async {
                                      if (aziendaAttivaId == azienda.id) {
                                        await _impostaAziendaAttiva(null);
                                      } else {
                                        await _impostaAziendaAttiva(azienda.id!);
                                      }
                                      setStateList(() {});
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isAttiva ? Colors.blue : Colors.grey,
                                          width: 2,
                                        ),
                                        color: isAttiva ? Colors.blue : Colors.transparent,
                                      ),
                                      child: isAttiva
                                          ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                          : null,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isAttiva ? Colors.blue : Colors.grey,
                                        radius: 16,
                                        child: Text(
                                          azienda.nome[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          azienda.nome,
                                          style: TextStyle(
                                            fontWeight: isAttiva ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'CF: ${azienda.codiceFiscale}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DettaglioAziendaScreen(azienda: azienda),
                                            ),
                                          );
                                          _caricaDati();
                                        },
                                        tooltip: 'Modifica',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () => _eliminaAzienda(azienda.id!, azienda.nome),
                                        tooltip: 'Elimina',
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    if (aziendaAttivaId == azienda.id) {
                                      await _impostaAziendaAttiva(null);
                                    } else {
                                      await _impostaAziendaAttiva(azienda.id!);
                                    }
                                    setStateList(() {});
                                  },
                                ),
                                // Badge ATTIVA in alto a destra con icona V
                                if (isAttiva)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

              // MESSAGGIO SE NESSUN RISULTATO TROVATO
              if (aziende.isNotEmpty && aziendeFiltrate.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Nessuna azienda trovata per "${_searchController.text}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),

              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AggiungiAziendaScreen()),
                  );
                  _caricaDati();
                },
                icon: const Icon(Icons.add),
                label: const Text('AGGIUNGI NUOVA AZIENDA'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              const SizedBox(height: 40),

              // ==================== SEZIONE CONFIGURAZIONE EMAIL ====================
              const Text(
                'CONFIGURAZIONE EMAIL DATORE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              DropdownButtonFormField<EmailProvider>(
                decoration: const InputDecoration(
                  labelText: 'Provider Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                value: providerSelezionato,
                items: EmailService.providers.map((provider) {
                  return DropdownMenuItem(
                    value: provider,
                    child: Text(provider.name),
                  );
                }).toList(),
                onChanged: _onProviderChanged,
                validator: (value) {
                  if (value == null) return 'Seleziona un provider';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailUsernameController,
                decoration: const InputDecoration(
                  labelText: 'Email mittente *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
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
              const SizedBox(height: 15),
              TextFormField(
                controller: _emailPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci la password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'La password viene salvata in modo sicuro e criptato',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ==================== SEZIONE DESTINATARI ====================
              const Text(
                'DESTINATARI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Divider(thickness: 2),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ccDestinatarioController,
                decoration: const InputDecoration(
                  labelText: 'Destinatario Principale',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_add),
                  hintText: 'Email destinatario',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ccCommercialistaController,
                decoration: const InputDecoration(
                  labelText: 'Email Consulente',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_center),
                  hintText: 'Email Consulente (opzionale)',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: isSaving ? null : _salvaDati,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'SALVA CONFIGURAZIONE EMAIL',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}