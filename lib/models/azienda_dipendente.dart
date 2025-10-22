class AziendaDipendente {
  int? id;
  int aziendaId;
  int dipendenteId;

  AziendaDipendente({
    this.id,
    required this.aziendaId,
    required this.dipendenteId,
  });

  factory AziendaDipendente.fromMap(Map<String, dynamic> map) {
    return AziendaDipendente(
      id: map['id'],
      aziendaId: map['aziendaId'],
      dipendenteId: map['dipendenteId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'aziendaId': aziendaId,
      'dipendenteId': dipendenteId,
    };
  }
}