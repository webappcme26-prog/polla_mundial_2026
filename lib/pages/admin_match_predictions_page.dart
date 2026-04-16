import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.equipoLocal} vs ${widget.equipoVisitante}'),
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

          if (predictions.isEmpty) {
            return const Center(
              child: Text('No hay pronósticos registrados para este partido'),
            );
          }

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView.builder(
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                final prediction = predictions[index];
                final profile = prediction['profiles'];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      profile?['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Pronóstico: ${prediction['goles_local_pred']} - ${prediction['goles_visitante_pred']}',
                    ),
                    trailing: Text(
                      formatFecha(prediction['updated_at']),
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.right,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}