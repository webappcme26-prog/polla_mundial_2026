import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = _leaderboardService.getLeaderboard();
  }

  Future<void> _recargarTabla() async {
    setState(() {
      _leaderboardFuture = _leaderboardService.getLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabla de posiciones'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar la tabla: ${snapshot.error}'),
            );
          }

          final jugadores = snapshot.data ?? [];

          if (jugadores.isEmpty) {
            return const Center(
              child: Text('Aún no hay datos en la tabla de posiciones'),
            );
          }

          return RefreshIndicator(
            onRefresh: _recargarTabla,
            child: ListView.builder(
              itemCount: jugadores.length,
              itemBuilder: (context, index) {
                final jugador = jugadores[index];
                final posicion = index + 1;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(posicion.toString()),
                    ),
                    title: Text(
                      jugador['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Exactos: ${jugador['exactos']} | Aciertos resultado: ${jugador['aciertos_resultado']}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Puntos',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${jugador['puntos_totales']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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