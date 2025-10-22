import 'dart:io';
import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/chiamata.dart';
import '../models/datore_lavoro.dart';

class XmlService {
  // PRIMO METODO - quello originale per chiamata singola
  static Future<String> generaXmlChiamata({
    required DatoreLavoro datore,
    required Chiamata chiamata,
    required bool isAnnullamento,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    // Crea il builder XML
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('ComunicazioneIntermittenti', nest: () {
      // Attributi root
      builder.attribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
      builder.attribute('versione', '1.0');

      // Sezione Datore di Lavoro
      builder.element('DatoreLavoro', nest: () {
        builder.element('CodiceFiscale', nest: datore.codiceFiscale);
        builder.element('Email', nest: datore.email);
      });

      // Sezione Comunicazione
      builder.element('Comunicazione', nest: () {
        builder.element('TipoComunicazione', nest: isAnnullamento ? 'ANNULLAMENTO' : 'CHIAMATA');
        builder.element('DataInvio', nest: dateFormat.format(DateTime.now()));
        builder.element('OraInvio', nest: timeFormat.format(DateTime.now()));

        // Elenco Lavoratori
        builder.element('ElencoLavoratori', nest: () {
          builder.element('Lavoratore', nest: () {
            builder.element('CodiceFiscale', nest: chiamata.codiceFiscaleDipendente);
            builder.element('Nome', nest: chiamata.nomeDipendente);
            builder.element('CodiceComunicazione', nest: chiamata.codiceUnilav);
            builder.element('DataInizio', nest: dateFormat.format(chiamata.dataInizio));
            builder.element('DataFine', nest: dateFormat.format(chiamata.dataFine));

            if (isAnnullamento) {
              builder.element('DataAnnullamento', nest: dateFormat.format(DateTime.now()));
            }
          });
        });
      });

      // Sezione Note (opzionale)
      builder.element('Note', nest: () {
        if (isAnnullamento) {
          builder.text('Annullamento comunicazione per il periodo indicato');
        } else {
          builder.text('Comunicazione obbligatoria lavoratore intermittente');
        }
      });
    });

    // Costruisci il documento XML
    final document = builder.buildDocument();

    // Formatta l'XML con indentazione per leggibilità
    final xmlString = document.toXmlString(pretty: true);

    // Salva il file
    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = isAnnullamento
        ? 'annullamento_${chiamata.codiceUnilav}_$timestamp.xml'
        : 'chiamata_${chiamata.codiceUnilav}_$timestamp.xml';
    final file = File('${output.path}/$fileName');

    await file.writeAsString(xmlString, encoding: Encoding.getByName('utf-8')!);

    return file.path;
  }

  // SECONDO METODO - nuovo per chiamate multiple
  static Future<String> generaXmlChiamataMultipla({
    required DatoreLavoro datore,
    required List<Chiamata> chiamate,
    required bool isAnnullamento,
  }) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    // Crea il builder XML
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');

    builder.element('ComunicazioneIntermittenti', nest: () {
      // Attributi root
      builder.attribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
      builder.attribute('versione', '1.0');

      // Sezione Datore di Lavoro
      builder.element('DatoreLavoro', nest: () {
        builder.element('CodiceFiscale', nest: datore.codiceFiscale);
        builder.element('Email', nest: datore.email);
      });

      // Sezione Comunicazione
      builder.element('Comunicazione', nest: () {
        builder.element('TipoComunicazione', nest: isAnnullamento ? 'ANNULLAMENTO' : 'CHIAMATA');
        builder.element('DataInvio', nest: dateFormat.format(DateTime.now()));
        builder.element('OraInvio', nest: timeFormat.format(DateTime.now()));

        // Elenco Lavoratori - QUI METTIAMO TUTTI I DIPENDENTI
        builder.element('ElencoLavoratori', nest: () {
          // Loop per ogni chiamata/dipendente
          for (var chiamata in chiamate) {
            builder.element('Lavoratore', nest: () {
              builder.element('CodiceFiscale', nest: chiamata.codiceFiscaleDipendente);
              builder.element('Nome', nest: chiamata.nomeDipendente);
              builder.element('CodiceComunicazione', nest: chiamata.codiceUnilav);
              builder.element('DataInizio', nest: dateFormat.format(chiamata.dataInizio));
              builder.element('DataFine', nest: dateFormat.format(chiamata.dataFine));

              if (isAnnullamento) {
                builder.element('DataAnnullamento', nest: dateFormat.format(DateTime.now()));
              }
            });
          }
        });
      });

      // Sezione Note (opzionale)
      builder.element('Note', nest: () {
        if (isAnnullamento) {
          builder.text('Annullamento comunicazione per il periodo indicato - ${chiamate.length} dipendenti');
        } else {
          builder.text('Comunicazione obbligatoria lavoratori intermittenti - ${chiamate.length} dipendenti');
        }
      });
    });

    // Costruisci il documento XML
    final document = builder.buildDocument();

    // Formatta l'XML con indentazione per leggibilità
    final xmlString = document.toXmlString(pretty: true);

    // Salva il file
    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = isAnnullamento
        ? 'annullamento_intermittenti_$timestamp.xml'
        : 'chiamata_intermittenti_$timestamp.xml';
    final file = File('${output.path}/$fileName');

    await file.writeAsString(xmlString, encoding: Encoding.getByName('utf-8')!);

    return file.path;
  }
}