import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'admin_page.dart';
import '../services/prediction_service.dart';

class AdminMatchPredictionsPage extends StatefulWidget {
  final int matchId;
  final String equipoLocal;
  final String equipoVisitante;

  const AdminMatchPredictionsPage({
    super.key,
    required this.matchId,
    required this.equipoLocal,
    required this.equipoVisitante,
  });

  @override
  State<AdminMatchPredictionsPage> createState() =>
      _AdminMatchPredictionsPageState();
}

class _AdminMatchPredictionsPageState
    extends State<AdminMatchPredictionsPage> {
  final PredictionService _predictionService = PredictionService();
  late Future<List<Map<String, dynamic>>> _predictionsFuture;

  @override
  void initState() {
    super.initState();
    _predictionsFuture =
        _predictionService.getPredictionsByMatch(widget.matchId);
  }

  String formatFecha(String fecha) {
    final date = DateTime.parse(fecha).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  Future<void> _recargar() async {
    setState(() {
      _predictionsFuture =
          _predictionService.getPredictionsByMatch(widget.matchId);
    });
  }

  Widget _scoreBox(String value) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0B3D91).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0B3D91),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronósticos del partido'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _predictionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar pronósticos: ${snapshot.error}'),
            );
          }

          final predictions = snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B3D91), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Partido',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.equipoLocal} vs ${widget.equipoVisitante}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (predictions.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No hay pronósticos registrados para este partido'),
                      ),
                    ),
                  )
                else
                  ...predictions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final prediction = entry.value;
                    final profile = prediction['profiles'];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  const Color(0xFF0B3D91).withOpacity(0.10),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF0B3D91),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Registrado: ${formatFecha(prediction['updated_at'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _scoreBox(
                                  '${prediction['goles_local_pred']}',
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    '-',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _scoreBox(
                                  '${prediction['goles_visitante_pred']}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}