import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/leaderboard_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<Map<String, dynamic>>> _leaderboardFuture;
  final String? _currentUserId = Supabase.instance.client.auth.currentUser?.id;

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

  Color _positionColor(int posicion) {
    if (posicion == 1) return const Color(0xFFD4AF37);
    if (posicion == 2) return Colors.grey;
    if (posicion == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF0B3D91);
  }

  IconData _positionIcon(int posicion) {
    if (posicion == 1) return Icons.emoji_events;
    if (posicion == 2) return Icons.workspace_premium;
    if (posicion == 3) return Icons.military_tech;
    return Icons.person;
  }

  Widget _positionBadge(int posicion) {
    final color = _positionColor(posicion);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _positionIcon(posicion),
            color: color,
            size: 18,
          ),
          const SizedBox(height: 2),
          Text(
            '$posicion',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required String label,
    required dynamic value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _puntosBox(dynamic puntos, {bool destacar = false}) {
    return Container(
      width: 74,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: destacar
              ? const [Color(0xFFD4AF37), Color(0xFFFFC107)]
              : const [Color(0xFF0B3D91), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Puntos',
            style: TextStyle(
              color: destacar ? Colors.black87 : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$puntos',
            style: TextStyle(
              color: destacar ? Colors.black87 : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tabla de posiciones'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mundial.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.28),
          child: SafeArea(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar la tabla: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final jugadores = snapshot.data ?? [];

                if (jugadores.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no hay datos en la tabla de posiciones',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _recargarTabla,
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
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ranking general',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Consulta cómo va la clasificación',
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
                      ...jugadores.asMap().entries.map((entry) {
                        final index = entry.key;
                        final jugador = entry.value;
                        final posicion = index + 1;
                        final esUsuarioActual =
                            jugador['user_id'] == _currentUserId;

                        return Card(
                          color: esUsuarioActual
                              ? const Color(0xFFFFF8E1)
                              : Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: esUsuarioActual
                                ? const BorderSide(
                                    color: Color(0xFFFFC107),
                                    width: 1.4,
                                  )
                                : BorderSide.none,
                          ),
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _positionBadge(posicion),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        jugador['nombre'] ?? 'Sin nombre',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: esUsuarioActual
                                              ? const Color(0xFF8A5A00)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (esUsuarioActual)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD54F)
                                                .withOpacity(0.25),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: const Text(
                                            'Tú',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF8A5A00),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _statChip(
                                            label: 'Exactos',
                                            value: jugador['exactos'] ?? 0,
                                            color: Colors.green,
                                          ),
                                          _statChip(
                                            label: 'Resultado',
                                            value: jugador[
                                                    'aciertos_resultado'] ??
                                                0,
                                            color: Colors.orange,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _puntosBox(
                                  jugador['puntos_totales'] ?? 0,
                                  destacar: esUsuarioActual,
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
          ),
        ),
      ),
    );
  }
}