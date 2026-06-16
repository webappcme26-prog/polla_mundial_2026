import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchPredictionPdfService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> downloadMatchPredictionsPdf({
    required int matchId,
    required String equipoLocal,
    required String equipoVisitante,
  }) async {
    final pdf = pw.Document();

    final predictions = await _supabase
        .from('predictions')
        .select('''
          goles_local_pred,
          goles_visitante_pred,
          updated_at,
          profiles (
            nombre
          )
        ''')
        .eq('match_id', matchId)
        .order('updated_at', ascending: true);

    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Polla Mundial 2026',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          pw.Text(
            '$equipoLocal vs $equipoVisitante',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy hh:mm a').format(now)}',
          ),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
            headers: const [
              '#',
              'Participante',
              'Pronóstico',
              'Registrado',
            ],
            data: List.generate(predictions.length, (index) {
              final p = predictions[index];

              return [
                '${index + 1}',
                '${p['profiles']?['nombre'] ?? ''}',
                '${p['goles_local_pred']} - ${p['goles_visitante_pred']}',
                DateFormat('dd/MM/yyyy hh:mm a').format(
                  DateTime.parse(
                    p['updated_at'].toString(),
                  ).toLocal(),
                ),
              ];
            }),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    final fileName =
        '${equipoLocal}_vs_${equipoVisitante}_${DateFormat('yyyyMMdd').format(now)}.pdf';

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }
}