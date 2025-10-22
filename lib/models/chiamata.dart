class Chiamata {
  int? id;
  String? gruppoId;
  int dipendenteId;
  String nomeDipendente;
  String? nomeAzienda;
  String codiceFiscaleDipendente;
  String codiceUnilav;
  DateTime dataInizio;
  DateTime dataFine;
  String stato; // 'attiva' o 'annullata'
  DateTime dataInvio;
  DateTime? dataAnnullamento;

  Chiamata({
    this.id,
    this.gruppoId,
    required this.dipendenteId,
    required this.nomeDipendente,
    this.nomeAzienda,
    required this.codiceFiscaleDipendente,
    required this.codiceUnilav,
    required this.dataInizio,
    required this.dataFine,
    required this.stato,
    required this.dataInvio,
    this.dataAnnullamento,
  });

  // Converte da Map (database) a oggetto
  factory Chiamata.fromMap(Map<String, dynamic> map) {
    return Chiamata(
      id: map['id'],
      gruppoId: map['gruppoId'],
      dipendenteId: map['dipendenteId'],
      nomeAzienda: map['nomeAzienda'],
      nomeDipendente: map['nomeDipendente'],
      codiceFiscaleDipendente: map['codiceFiscaleDipendente'],
      codiceUnilav: map['codiceUnilav'],
      dataInizio: DateTime.parse(map['dataInizio']),
      dataFine: DateTime.parse(map['dataFine']),
      stato: map['stato'],
      dataInvio: DateTime.parse(map['dataInvio']),
      dataAnnullamento: map['dataAnnullamento'] != null
          ? DateTime.parse(map['dataAnnullamento'])
          : null,
    );
  }

  // Converte da oggetto a Map (per salvare nel database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gruppoId': gruppoId,
      'dipendenteId': dipendenteId,
      'nomeDipendente': nomeDipendente,
      'codiceFiscaleDipendente': codiceFiscaleDipendente,
      'nomeAzienda': nomeAzienda,
      'codiceUnilav': codiceUnilav,
      'dataInizio': dataInizio.toIso8601String(),
      'dataFine': dataFine.toIso8601String(),
      'stato': stato,
      'dataInvio': dataInvio.toIso8601String(),
      'dataAnnullamento': dataAnnullamento?.toIso8601String(),
    };
  }
}