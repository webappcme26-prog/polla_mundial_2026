import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/prediction_service.dart';

class MyPredictionsPage extends StatefulWidget {
  const MyPredictionsPage({super.key});

  @override
  State<MyPredictionsPage> createState() => _MyPredictionsPageState();
}

class _MyPredictionsPageState extends State<MyPredictionsPage> {
  final PredictionService _predictionService = PredictionService();
  late Future<List<Map<String, dynamic>>> _predictionsFuture;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _predictionsFuture = _predictionService.getMyPredictions(user!.id);
  }

  String formatFecha(String fecha) {
    final date = DateTime.parse(fecha).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pronósticos'),
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
              child: Text('Aún no has registrado pronósticos'),
            );
          }

          return ListView.builder(
            itemCount: predictions.length,
            itemBuilder: (context, index) {
              final prediction = predictions[index];
              final match = prediction['matches'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(
                    '${match['equipo_local']} vs ${match['equipo_visitante']}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha: ${formatFecha(match['fecha_hora'])}'),
                      Text(
                        'Tu pronóstico: ${prediction['goles_local_pred']} - ${prediction['goles_visitante_pred']}',
                      ),
                      Text('Estado: ${match['estado']}'),
                    ],
                  ),
                  trailing: const Icon(Icons.check_circle_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }
}