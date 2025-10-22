import 'dart:io';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/chiamata.dart';
import '../models/datore_lavoro.dart';

class PdfService {
  // METODO 1 - chiamata singola
  static Future<String> generaPdfChiamata({
    required DatoreLavoro datore,
    required Chiamata chiamata,
    required bool isAnnullamento,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    try {
      final ByteData data = await rootBundle.load('assets/modello_intermittenti.pdf');
      final bytes = data.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfForm form = document.form;

      // Compila i campi usando i NOMI ESATTI per compilare SOLO la prima riga
      for (int i = 0; i < form.fields.count; i++) {
        final field = form.fields[i];
        final fieldName = field.name ?? '';

        if (field is PdfTextBoxField) {
          // Dati datore
          if (fieldName == "moduloIntermittenti[0].Campi[0].CFdatorelavoro[0]") {
            field.text = datore.codiceFiscale;
          }
          else if (fieldName == "moduloIntermittenti[0].Campi[0].EMmail[0]") {
            field.text = datore.email;
          }
          // SOLO prima riga - usa nomi ESATTI
          else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row1[0].CFlavoratore1[0]") {
            field.text = chiamata.codiceFiscaleDipendente;
          }
          else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row1[0].CCcodcomunicazione1[0]") {
            field.text = chiamata.codiceUnilav;
          }
          else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row1[0].DTdatainizio1[0]") {
            field.text = dateFormat.format(chiamata.dataInizio);
          }
          else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row1[0].DTdatafine1[0]") {
            field.text = dateFormat.format(chiamata.dataFine);
          }
        }
        else if (field is PdfCheckBoxField) {
          if (fieldName == "moduloIntermittenti[0].Campi[0].ANannullamento[0]") {
            field.isChecked = isAnnullamento;
          }
        }
      }

      form.setDefaultAppearance(true);
      final List<int> pdfBytes = await document.save();
      document.dispose();

      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = isAnnullamento
          ? 'annullamento_${chiamata.codiceUnilav}_$timestamp.pdf'
          : 'chiamata_${chiamata.codiceUnilav}_$timestamp.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      return file.path;

    } catch (e) {
      print('Errore generazione PDF: $e');
      rethrow;
    }
  }

  // METODO 2 - chiamate multiple
  static Future<String> generaPdfChiamataMultipla({
    required DatoreLavoro datore,
    required List<Chiamata> chiamate,
    required bool isAnnullamento,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');

    try {
      final ByteData data = await rootBundle.load('assets/modello_intermittenti.pdf');
      final bytes = data.buffer.asUint8List();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfForm form = document.form;

      // Compila i campi usando i NOMI ESATTI
      for (int i = 0; i < form.fields.count; i++) {
        final field = form.fields[i];
        final fieldName = field.name ?? '';

        if (field is PdfTextBoxField) {
          // Dati datore
          if (fieldName == "moduloIntermittenti[0].Campi[0].CFdatorelavoro[0]") {
            field.text = datore.codiceFiscale;
          }
          else if (fieldName == "moduloIntermittenti[0].Campi[0].EMmail[0]") {
            field.text = datore.email;
          }

          // COMPILA SOLO LE RIGHE NECESSARIE
          for (int row = 0; row < chiamate.length && row < 10; row++) {
            final chiamata = chiamate[row];
            final rowNum = row + 1;

            // USA NOMI ESATTI per ogni riga
            if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row$rowNum[0].CFlavoratore$rowNum[0]") {
              field.text = chiamata.codiceFiscaleDipendente;
            }
            else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row$rowNum[0].CCcodcomunicazione$rowNum[0]") {
              field.text = chiamata.codiceUnilav;
            }
            else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row$rowNum[0].DTdatainizio$rowNum[0]") {
              field.text = dateFormat.format(chiamata.dataInizio);
            }
            else if (fieldName == "moduloIntermittenti[0].Campi[0].Table1[0].Row$rowNum[0].DTdatafine$rowNum[0]") {
              field.text = dateFormat.format(chiamata.dataFine);
            }
          }
        }
        else if (field is PdfCheckBoxField) {
          if (fieldName == "moduloIntermittenti[0].Campi[0].ANannullamento[0]") {
            field.isChecked = isAnnullamento;
          }
        }
      }

      form.setDefaultAppearance(true);
      final List<int> pdfBytes = await document.save();
      document.dispose();

      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = isAnnullamento
          ? 'annullamento_intermittenti_$timestamp.pdf'
          : 'chiamata_intermittenti_$timestamp.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      return file.path;

    } catch (e) {
      print('Errore generazione PDF multiplo: $e');
      rethrow;
    }
  }
}