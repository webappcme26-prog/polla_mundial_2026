import 'package:flutter/material.dart';

import '../core/flag_helper.dart';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    const SnackBar(
                      content: Text('Ingresa números válidos'),
                    ),
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

  String _textoFecha(dynamic fechaHora) {
    if (fechaHora == null) return '';
    final fecha = DateTime.parse(fechaHora.toString()).toLocal();

    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year.toString();

    final hour12 = fecha.hour % 12 == 0 ? 12 : fecha.hour % 12;
    final min = fecha.minute.toString().padLeft(2, '0');
    final ampm = fecha.hour >= 12 ? 'p. m.' : 'a. m.';

    return '$d/$m/$y  $hour12:$min $ampm';
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
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                Container(
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
                        'Administrador',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Gestiona resultados y revisa pronósticos',
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
                ...matches.map((match) {
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
                              if (match['fase'] != null)
                                _chip(
                                  texto: '${match['fase']}',
                                  color: Colors.blue,
                                ),
                              if (match['grupo'] != null)
                                _chip(
                                  texto: 'Grupo ${match['grupo']}',
                                  color: Colors.orange,
                                ),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _textoFecha(match['fecha_hora']),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.scoreboard_outlined, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Marcador real: ${_marcadorReal(match)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _mostrarDialogoResultado(match),
                                icon: const Icon(Icons.edit_note_rounded),
                                label: const Text('Resultado'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminMatchPredictionsPage(
                                        matchId: match['id'],
                                        equipoLocal: match['equipo_local'],
                                        equipoVisitante:
                                            match['equipo_visitante'],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Pronósticos'),
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