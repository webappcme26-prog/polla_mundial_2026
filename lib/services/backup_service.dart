import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackupService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 📊 LEADERBOARD
  Future<List<Map<String, dynamic>>> getLeaderboardData() async {
    final response = await _supabase
        .from('leaderboard')
        .select('''
          user_id,
          nombre,
          puntos_totales,
          exactos,
          aciertos_resultado
        ''')
        .order('puntos_totales', ascending: false)
        .order('exactos', ascending: false)
        .order('aciertos_resultado', ascending: false)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // ⚽ MATCHES + PREDICCIONES (SIN FILTROS DE DÍA → EVITA BUG UTC)
  Future<List<Map<String, dynamic>>> getMatchesWithPredictions() async {

    final matches = await _supabase
        .from('matches')
        .select('''
          id,
          fase,
          grupo,
          equipo_local,
          equipo_visitante,
          fecha_hora,
          goles_local_real,
          goles_visitante_real,
          estado
        ''')
        .order('fecha_hora', ascending: true);

    final matchesList = List<Map<String, dynamic>>.from(matches);

    // 🔥 UNA SOLA CONSULTA (OPTIMIZADO PARA VERCEL)
    final allPredictions = await _supabase
        .from('predictions')
        .select('''
          match_id,
          goles_local_pred,
          goles_visitante_pred,
          updated_at,
          profiles (
            nombre
          )
        ''');

    // 🔥 AGRUPAR EN MEMORIA
    for (final match in matchesList) {
      match['predictions'] = allPredictions
          .where((p) => p['match_id'] == match['id'])
          .toList();
    }

    return matchesList;
  }

  // 🕒 FORMATO FECHA
  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '';
    final date = DateTime.parse(fecha.toString()).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  // 📄 GENERAR PDF
  Future<Uint8List> buildDailyBackupPdf() async {

    final pdf = pw.Document();

    final leaderboardRaw = await getLeaderboardData();

    final leaderboard = leaderboardRaw
    .where((user) => user['nombre'] != 'Administrador')
    .toList();
    final matches = await getMatchesWithPredictions();

    final now = DateTime.now();
    final fechaRespaldo = DateFormat('dd/MM/yyyy').format(now);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [

          pw.Text(
            'Respaldo diario - Polla Mundial 2026',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            'Fecha del respaldo: $fechaRespaldo',
            style: const pw.TextStyle(fontSize: 11),
          ),

          pw.Text(
            'Generado: ${DateFormat('dd/MM/yyyy hh:mm:ss a').format(now)}',
            style: const pw.TextStyle(fontSize: 11),
          ),

          pw.SizedBox(height: 20),

          // 🏆 LEADERBOARD
          pw.Text(
            'Tabla de posiciones',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: const ['Pos', 'Nombre', 'Puntos', 'Exactos', 'Resultado'],
            data: List.generate(leaderboard.length, (index) {
              final row = leaderboard[index];
              return [
                '${index + 1}',
                row['nombre'] ?? '',
                '${row['puntos_totales'] ?? 0}',
                '${row['exactos'] ?? 0}',
                '${row['aciertos_resultado'] ?? 0}',
              ];
            }),
          ),

          pw.SizedBox(height: 20),

          // ⚽ MATCHES
          pw.Text(
            'Partidos y pronósticos',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          if (matches.isEmpty)
            pw.Text('No hay partidos registrados.')
          else
            ...matches.map((match) {

              final predictions =
                  List<Map<String, dynamic>>.from(match['predictions'] ?? []);

              final marcadorOficial =
                  (match['goles_local_real'] != null &&
                          match['goles_visitante_real'] != null)
                      ? '${match['goles_local_real']} - ${match['goles_visitante_real']}'
                      : 'Sin resultado oficial';

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [

                    pw.Text(
                      '${match['equipo_local']} vs ${match['equipo_visitante']}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                    pw.Text('Fecha: ${_formatFecha(match['fecha_hora'])}'),
                    pw.Text('Fase: ${match['fase'] ?? ''}'),
                    pw.Text('Grupo: ${match['grupo'] ?? ''}'),
                    pw.Text('Estado: ${match['estado'] ?? ''}'),
                    pw.Text('Resultado: $marcadorOficial'),

                    pw.SizedBox(height: 8),

                    if (predictions.isEmpty)
                      pw.Text('Sin pronósticos')
                    else
                      pw.Table.fromTextArray(
                        headers: const [
                          'Usuario',
                          'Pronóstico',
                          'Actualizado'
                        ],
                        data: predictions.map((p) {
                          return [
                            p['profiles']?['nombre'] ?? '',
                            '${p['goles_local_pred']} - ${p['goles_visitante_pred']}',
                            _formatFecha(p['updated_at']),
                          ];
                        }).toList(),
                      ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );

    return pdf.save();
  }

  // 📤 DESCARGAR / COMPARTIR PDF
  Future<void> downloadDailyBackupPdf() async {
    final bytes = await buildDailyBackupPdf();

    final fileName =
        'respaldo_diario_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}