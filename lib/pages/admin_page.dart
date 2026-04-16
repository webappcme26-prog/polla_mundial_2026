import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_match_predictions_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AdminService _adminService = AdminService();
  late Future<List<Map<String, dynamic>>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _adminService.getMatches();
  }

  Future<void> _recargar() async {
    setState(() {
      _matchesFuture = _adminService.getMatches();
    });
  }

  Future<void> _mostrarDialogoResultado(Map<String, dynamic> match) async {
    final localController = TextEditingController(
      text: match['goles_local_real']?.toString() ?? '',
    );
    final visitanteController = TextEditingController(
      text: match['goles_visitante_real']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Resultado: ${match['equipo_local']} vs ${match['equipo_visitante']}',
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

                final error = await _adminService.saveMatchResult(
                  matchId: match['id'],
                  golesLocal: golesLocal,
                  golesVisitante: golesVisitante,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Resultado guardado y puntos recalculados'),
                    ),
                  );
                  _recargar();
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

  String _marcadorReal(Map<String, dynamic> match) {
    final gl = match['goles_local_real'];
    final gv = match['goles_visitante_real'];

    if (gl == null || gv == null) {
      return 'Sin registrar';
    }

    return '$gl - $gv';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel administrador'),
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
            onRefresh: _recargar,
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${match['equipo_local']} vs ${match['equipo_visitante']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Marcador real: ${_marcadorReal(match)}'),
                        Text('Estado: ${match['estado']}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _mostrarDialogoResultado(match),
                              child: const Text('Resultado'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminMatchPredictionsPage(
                                      matchId: match['id'],
                                      equipoLocal: match['equipo_local'],
                                      equipoVisitante: match['equipo_visitante'],
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Pronósticos'),
                            ),
                          ],
                        ),
                      ],
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