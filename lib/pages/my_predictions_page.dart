import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/flag_helper.dart';
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

    if (user != null) {
      _predictionsFuture = _predictionService.getMyPredictions(user.id);
    } else {
      _predictionsFuture = Future.value([]);
    }
  }

  String formatFecha(String fecha) {
    final date = DateTime.parse(fecha).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  Future<void> _recargarPronosticos() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      setState(() {
        _predictionsFuture = _predictionService.getMyPredictions(user.id);
      });
    }
  }

  Widget _buildEquipo({
    required String nombre,
    required bool alineadoDerecha,
  }) {
    final bandera = FlagHelper.getFlagEmoji(nombre);

    if (alineadoDerecha) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                nombre,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              bandera,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: Row(
        children: [
          Text(
            bandera,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

  Widget _chip({
    required String texto,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'finalizado':
        return Colors.green;
      case 'en_juego':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
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

          return RefreshIndicator(
            onRefresh: _recargarPronosticos,
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
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus registros',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Consulta y revisa tus pronósticos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...predictions.map((prediction) {
                  final match = prediction['matches'];
                  final estado = (match['estado'] ?? 'pendiente').toString();

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip(
                                texto: estado.toUpperCase(),
                                color: _estadoColor(estado),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildEquipo(
                                nombre: match['equipo_local'],
                                alineadoDerecha: false,
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              _buildEquipo(
                                nombre: match['equipo_visitante'],
                                alineadoDerecha: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Fecha: ${formatFecha(match['fecha_hora'])}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.update, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Actualizado: ${formatFecha(prediction['updated_at'])}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tu marcador',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _scoreBox(
                                '${prediction['goles_local_pred']}',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 20,
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