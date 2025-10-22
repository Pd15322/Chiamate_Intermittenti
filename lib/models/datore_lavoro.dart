class DatoreLavoro {
  int? id;
  String nome;              // AGGIUNTO - per riconoscere l'azienda
  String codiceFiscale;
  String email;

  DatoreLavoro({
    this.id,
    required this.nome,     // AGGIUNTO
    required this.codiceFiscale,
    required this.email,
  });

  factory DatoreLavoro.fromMap(Map<String, dynamic> map) {
    return DatoreLavoro(
      id: map['id'],
      nome: map['nome'],                    // AGGIUNTO
      codiceFiscale: map['codiceFiscale'],
      email: map['email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,                         // AGGIUNTO
      'codiceFiscale': codiceFiscale,
      'email': email,
    };
  }
}