import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/match_service.dart';
import '../services/prediction_service.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final MatchService _matchService = MatchService();
  final PredictionService _predictionService = PredictionService();

  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _matchService.getMatches();
  }

  String formatFecha(String fecha) {
    final date = DateTime.parse(fecha).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  bool _pronosticoAbierto(String fechaHora) {
    final fechaPartido = DateTime.parse(fechaHora).toLocal();
    final cierre = fechaPartido.subtract(const Duration(minutes: 5));
    return DateTime.now().isBefore(cierre);
  }

  Future<void> _mostrarDialogoPronostico(Map<String, dynamic> match) async {
    final localController = TextEditingController();
    final visitanteController = TextEditingController();

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    final prediction = await _predictionService.getPredictionByUserAndMatch(
      userId: user.id,
      matchId: match['id'],
    );

    if (prediction != null) {
      localController.text = prediction['goles_local_pred'].toString();
      visitanteController.text = prediction['goles_visitante_pred'].toString();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Pronóstico: ${match['equipo_local']} vs ${match['equipo_visitante']}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: localController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Goles ${match['equipo_local']}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: visitanteController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Goles ${match['equipo_visitante']}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final golesLocal = int.tryParse(localController.text.trim());
                final golesVisitante =
                    int.tryParse(visitanteController.text.trim());

                if (golesLocal == null || golesVisitante == null) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa números válidos')),
                  );
                  return;
                }

                final error = await _predictionService.savePrediction(
                  userId: user.id,
                  matchId: match['id'],
                  golesLocal: golesLocal,
                  golesVisitante: golesVisitante,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pronóstico guardado correctamente'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _recargarPartidos() async {
    setState(() {
      _matchesFuture = _matchService.getMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar partidos: ${snapshot.error}'),
            );
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(
              child: Text('No hay partidos registrados'),
            );
          }

          return RefreshIndicator(
            onRefresh: _recargarPartidos,
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                final abierto = _pronosticoAbierto(match['fecha_hora']);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        '${match['equipo_local']} vs ${match['equipo_visitante']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fecha: ${formatFecha(match['fecha_hora'])}'),
                            Text('Estado: ${match['estado']}'),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: abierto
                                  ? () => _mostrarDialogoPronostico(match)
                                  : null,
                              child: Text(
                                abierto
                                    ? 'Pronosticar / Editar'
                                    : 'Pronóstico cerrado',
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.sports_soccer),
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