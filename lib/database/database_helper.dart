import '../services/secure_storage_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/datore_lavoro.dart';
import '../models/dipendente.dart';
import '../models/chiamata.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chiamate_intermittenti_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE datore_lavoro (
      id $idType,
      nome $textType,
      codiceFiscale $textType,
      email $textType
    )
  ''');

    await db.execute('''
    CREATE TABLE dipendenti (
      id $idType,
      nome $textType,
      codiceFiscale $textType,
      codiceUnilav $textType,
      aziendaId INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE azienda_dipendente (
      id $idType,
      aziendaId $intType,
      dipendenteId $intType,
      FOREIGN KEY (aziendaId) REFERENCES datore_lavoro (id) ON DELETE CASCADE,
      FOREIGN KEY (dipendenteId) REFERENCES dipendenti (id) ON DELETE CASCADE,
      UNIQUE(aziendaId, dipendenteId)
    )
  ''');

    await db.execute('''
    CREATE TABLE chiamate (
      id $idType,
      gruppoId TEXT,
      dipendenteId $intType,
      nomeDipendente $textType,
      codiceFiscaleDipendente $textType,
      codiceUnilav $textType,
      dataInizio $textType,
      dataFine $textType,
      stato $textType,
      dataInvio $textType,
      dataAnnullamento TEXT
    )
  ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE chiamate ADD COLUMN gruppoId TEXT');
    }

    if (oldVersion < 3) {
      await db.execute('ALTER TABLE datore_lavoro ADD COLUMN nome TEXT DEFAULT "Azienda Principale"');

      await db.execute('''
      CREATE TABLE IF NOT EXISTS azienda_dipendente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        aziendaId INTEGER NOT NULL,
        dipendenteId INTEGER NOT NULL,
        FOREIGN KEY (aziendaId) REFERENCES datore_lavoro (id) ON DELETE CASCADE,
        FOREIGN KEY (dipendenteId) REFERENCES dipendenti (id) ON DELETE CASCADE,
        UNIQUE(aziendaId, dipendenteId)
      )
    ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE dipendenti ADD COLUMN aziendaId INTEGER');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE chiamate ADD COLUMN nomeAzienda TEXT');
    }
  }

  // ==================== DATORE DI LAVORO ====================

  Future<DatoreLavoro?> getDatore() async {
    final db = await instance.database;

    // Prova a recuperare l'azienda attiva dal secure storage
    final aziendaAttivaId = await SecureStorageService.getAziendaAttiva();

    if (aziendaAttivaId != null) {
      // Se c'è un'azienda attiva, restituisci quella
      final maps = await db.query(
        'datore_lavoro',
        where: 'id = ?',
        whereArgs: [aziendaAttivaId],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DatoreLavoro.fromMap(maps.first);
      }
    }

    // Se non c'è azienda attiva, restituisci la prima disponibile
    final maps = await db.query('datore_lavoro', limit: 1);

    if (maps.isNotEmpty) {
      return DatoreLavoro.fromMap(maps.first);
    }
    return null;
  }

  // ==================== DIPENDENTI ====================

  Future<int> insertDipendente(Dipendente dipendente) async {
    final db = await instance.database;
    return await db.insert('dipendenti', dipendente.toMap());
  }

  Future<List<Dipendente>> getAllDipendenti() async {
    final db = await instance.database;
    final result = await db.query('dipendenti', orderBy: 'nome ASC');
    return result.map((map) => Dipendente.fromMap(map)).toList();
  }

  Future<Dipendente?> getDipendente(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'dipendenti',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Dipendente.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateDipendente(Dipendente dipendente) async {
    final db = await instance.database;
    return await db.update(
      'dipendenti',
      dipendente.toMap(),
      where: 'id = ?',
      whereArgs: [dipendente.id],
    );
  }

  Future<int> deleteDipendente(int id) async {
    final db = await instance.database;
    return await db.delete(
      'dipendenti',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== CHIAMATE ====================

  Future<int> insertChiamata(Chiamata chiamata) async {
    final db = await instance.database;
    return await db.insert('chiamate', chiamata.toMap());
  }

  Future<List<Chiamata>> getAllChiamate() async {
    final db = await instance.database;
    final result = await db.query('chiamate', orderBy: 'dataInvio DESC');
    return result.map((map) => Chiamata.fromMap(map)).toList();
  }

  Future<Chiamata?> getChiamata(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'chiamate',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Chiamata.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateChiamata(Chiamata chiamata) async {
    final db = await instance.database;
    return await db.update(
      'chiamate',
      chiamata.toMap(),
      where: 'id = ?',
      whereArgs: [chiamata.id],
    );
  }

  Future<List<Chiamata>> getChiamateDipendente(int dipendenteId) async {
    final db = await instance.database;
    final result = await db.query(
      'chiamate',
      where: 'dipendenteId = ?',
      whereArgs: [dipendenteId],
      orderBy: 'dataInvio DESC',
    );
    return result.map((map) => Chiamata.fromMap(map)).toList();
  }

  Future<int> deleteChiamata(int id) async {
    final db = await instance.database;
    return await db.delete(
      'chiamate',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== AZIENDE (NUOVI METODI) ====================

  Future<List<DatoreLavoro>> getAllAziende() async {
    final db = await instance.database;
    final result = await db.query('datore_lavoro', orderBy: 'nome ASC');
    return result.map((map) => DatoreLavoro.fromMap(map)).toList();
  }

  Future<DatoreLavoro?> getAzienda(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'datore_lavoro',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DatoreLavoro.fromMap(maps.first);
    }
    return null;
  }

  Future<DatoreLavoro?> getAziendaById(int id) async {
    return await getAzienda(id);
  }

  Future<int> insertAzienda(DatoreLavoro azienda) async {
    final db = await instance.database;
    return await db.insert('datore_lavoro', azienda.toMap());
  }

  Future<int> updateAzienda(DatoreLavoro azienda) async {
    final db = await instance.database;
    return await db.update(
      'datore_lavoro',
      azienda.toMap(),
      where: 'id = ?',
      whereArgs: [azienda.id],
    );
  }

  Future<int> deleteAzienda(int id) async {
    final db = await instance.database;
    return await db.delete(
      'datore_lavoro',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== RELAZIONE AZIENDA-DIPENDENTE ====================

  Future<void> associaDipendenteAdAzienda(int aziendaId, int dipendenteId) async {
    final db = await instance.database;
    await db.insert(
      'azienda_dipendente',
      {'aziendaId': aziendaId, 'dipendenteId': dipendenteId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> rimuoviDipendenteDaAzienda(int aziendaId, int dipendenteId) async {
    final db = await instance.database;
    await db.delete(
      'azienda_dipendente',
      where: 'aziendaId = ? AND dipendenteId = ?',
      whereArgs: [aziendaId, dipendenteId],
    );
  }

  Future<List<Dipendente>> getDipendentiDiAzienda(int aziendaId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT d.* FROM dipendenti d
      INNER JOIN azienda_dipendente ad ON d.id = ad.dipendenteId
      WHERE ad.aziendaId = ?
      ORDER BY d.nome ASC
    ''', [aziendaId]);
    return result.map((map) => Dipendente.fromMap(map)).toList();
  }

  Future<List<DatoreLavoro>> getAziendeDiDipendente(int dipendenteId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT a.* FROM datore_lavoro a
      INNER JOIN azienda_dipendente ad ON a.id = ad.aziendaId
      WHERE ad.dipendenteId = ?
      ORDER BY a.nome ASC
    ''', [dipendenteId]);
    return result.map((map) => DatoreLavoro.fromMap(map)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}  // ← LA CLASSE SI CHIUDE QUI ALLA FINE!}  // <-- Questa rimane la chiusura finale della classe