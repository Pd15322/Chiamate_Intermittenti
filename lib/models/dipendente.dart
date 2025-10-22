class Dipendente {
  int? id;
  String nome;
  String codiceFiscale;
  String codiceUnilav;
  int? aziendaId;

  Dipendente({
    this.id,
    required this.nome,
    required this.codiceFiscale,
    required this.codiceUnilav,
    this.aziendaId,
  });

  factory Dipendente.fromMap(Map<String, dynamic> map) {
    return Dipendente(
      id: map['id'],
      nome: map['nome'],
      codiceFiscale: map['codiceFiscale'],
      codiceUnilav: map['codiceUnilav'],
      aziendaId: map['aziendaId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'codiceFiscale': codiceFiscale,
      'codiceUnilav': codiceUnilav,
      'aziendaId': aziendaId,
    };
  }
}