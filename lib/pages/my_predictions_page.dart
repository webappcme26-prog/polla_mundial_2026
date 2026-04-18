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
    return DateFormat('dd/MM/yyyy  h:mm a').format(date);
  }

  Future<void> _recargarPronosticos() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _predictionsFuture = _predictionService.getMyPredictions(user.id);
      });
    }
  }

  bool _acertoResultado(Map<String, dynamic> prediction) {
    final match = prediction['matches'];

    final glPred = prediction['goles_local_pred'];
    final gvPred = prediction['goles_visitante_pred'];
    final glReal = match['goles_local_real'];
    final gvReal = match['goles_visitante_real'];

    if (glReal == null || gvReal == null) return false;

    final predDiff = glPred - gvPred;
    final realDiff = glReal - gvReal;

    if (predDiff == 0 && realDiff == 0) return true;
    if (predDiff > 0 && realDiff > 0) return true;
    if (predDiff < 0 && realDiff < 0) return true;

    return false;
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
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF14213D),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              bandera,
              style: const TextStyle(fontSize: 30),
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
            style: const TextStyle(fontSize: 30),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF14213D),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(
    String value, {
    Color bgColor = const Color(0xFF173E9A),
    Color textColor = Colors.white,
  }) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }

  Widget _statusChip(String estado) {
    Color bg;
    String texto;

    switch (estado) {
      case 'finalizado':
        bg = const Color(0xFF28A745);
        texto = 'FINALIZADO';
        break;
      case 'en_juego':
        bg = const Color(0xFF1E90FF);
        texto = 'EN JUEGO';
        break;
      default:
        bg = const Color(0xFFFF9800);
        texto = 'PRÓXIMO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String title, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF40C4FF), size: 26),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF041C4A),
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _predictionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar pronósticos: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final predictions = snapshot.data ?? [];

          int proximos = 0;
          int registrados = predictions.length;
          int evaluados = 0;
          int aciertos = 0;

          for (final p in predictions) {
            final match = p['matches'];
            final estado = (match?['estado'] ?? 'pendiente').toString();

            final glReal = match?['goles_local_real'];
            final gvReal = match?['goles_visitante_real'];

            if (estado != 'finalizado') {
              proximos++;
            }

            if (glReal != null && gvReal != null) {
              evaluados++;

              if (_acertoResultado(p)) {
                aciertos++;
              }
            }
          }

          final int porcentajeAcierto =
              evaluados == 0 ? 0 : ((aciertos / evaluados) * 100).round();

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo_mundial.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.28),
              child: RefreshIndicator(
                onRefresh: _recargarPronosticos,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF082A73).withOpacity(0.86),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mis pronósticos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Consulta y revisa tus pronósticos',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                _statItem(
                                  Icons.calendar_month,
                                  'Partidos Sin Finalizar',
                                  '$proximos',
                                ),
                                Container(
                                  width: 1,
                                  height: 34,
                                  color: Colors.white24,
                                ),
                                _statItem(
                                  Icons.fact_check,
                                  'Registrados',
                                  '$registrados',
                                ),
                                Container(
                                  width: 1,
                                  height: 34,
                                  color: Colors.white24,
                                ),
                                _statItem(
                                  Icons.star,
                                  'Aciertos',
                                  '$porcentajeAcierto%',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (predictions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'Aún no has registrado pronósticos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      ...predictions.map((prediction) {
                        final match = prediction['matches'];
                        final estado =
                            (match['estado'] ?? 'pendiente').toString();

                        final golesLocalReal = match['goles_local_real'];
                        final golesVisitanteReal = match['goles_visitante_real'];
                        final tieneResultadoOficial =
                            golesLocalReal != null && golesVisitanteReal != null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statusChip(estado),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildEquipo(
                                    nombre: match['equipo_local'],
                                    alineadoDerecha: false,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'VS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF173E9A),
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  _buildEquipo(
                                    nombre: match['equipo_visitante'],
                                    alineadoDerecha: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    size: 18,
                                    color: Color(0xFF173E9A),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      formatFecha(match['fecha_hora']),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF334155),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8EEFF),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Tu marcador',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF173E9A),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _scoreBox(
                                                '${prediction['goles_local_pred']}',
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10),
                                                child: Text(
                                                  '-',
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF173E9A),
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
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: tieneResultadoOficial
                                            ? const Color(0xFFE9F7EF)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            tieneResultadoOficial
                                                ? 'Resultado oficial'
                                                : 'Actualizado',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: tieneResultadoOficial
                                                  ? const Color(0xFF1E7E34)
                                                  : const Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          tieneResultadoOficial
                                              ? Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    _scoreBox(
                                                      '$golesLocalReal',
                                                      bgColor: const Color(
                                                          0xFFCFEFDC),
                                                      textColor: const Color(
                                                          0xFF1E7E34),
                                                    ),
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10),
                                                      child: Text(
                                                        '-',
                                                        style: TextStyle(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color:
                                                              Color(0xFF1E7E34),
                                                        ),
                                                      ),
                                                    ),
                                                    _scoreBox(
                                                      '$golesVisitanteReal',
                                                      bgColor: const Color(
                                                          0xFFCFEFDC),
                                                      textColor: const Color(
                                                          0xFF1E7E34),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  formatFecha(
                                                      prediction['updated_at']),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF334155),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}