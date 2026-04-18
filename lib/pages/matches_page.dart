import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/flag_helper.dart';
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
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _matchService.getMatches();
  }

  String formatFecha(String fecha) {
    final date = DateTime.parse(fecha).toLocal();
    return DateFormat('dd/MM/yyyy hh:mm a').format(date);
  }

  String formatSoloFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  DateTime parseFechaLocal(String fecha) {
    return DateTime.parse(fecha).toLocal();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

  Future<void> _seleccionarFecha(List<Map<String, dynamic>> matches) async {
    if (matches.isEmpty) return;

    final fechas = matches
        .map((m) => parseFechaLocal(m['fecha_hora']))
        .toList()
      ..sort();

    final primeraFecha = DateTime(
      fechas.first.year,
      fechas.first.month,
      fechas.first.day,
    );
    final ultimaFecha = DateTime(
      fechas.last.year,
      fechas.last.month,
      fechas.last.day,
    );

    final initialDate = _selectedDate ?? primeraFecha;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(primeraFecha)
          ? primeraFecha
          : initialDate.isAfter(ultimaFecha)
              ? ultimaFecha
              : initialDate,
      firstDate: primeraFecha,
      lastDate: ultimaFecha,
      locale: const Locale('es', 'CO'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  List<Map<String, dynamic>> _filtrarPorFecha(
    List<Map<String, dynamic>> matches,
  ) {
    if (_selectedDate == null) return matches;

    return matches.where((match) {
      final fecha = parseFechaLocal(match['fecha_hora']);
      return fecha.year == _selectedDate!.year &&
          fecha.month == _selectedDate!.month &&
          fecha.day == _selectedDate!.day;
    }).toList();
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
                  fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _estadoChip(bool abierto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: abierto
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        abierto ? 'Pronóstico abierto' : 'Pronóstico cerrado',
        style: TextStyle(
          color: abierto ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoChip({
    required String texto,
    required Color colorFondo,
    required Color colorTexto,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: colorTexto,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Partidos'),
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
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar partidos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final matches = snapshot.data ?? [];

                if (matches.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay partidos registrados',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final filteredMatches = _filtrarPorFecha(matches);

                return RefreshIndicator(
                  onRefresh: _recargarPartidos,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.92),
                                  foregroundColor: const Color(0xFF0B3D91),
                                  side: BorderSide.none,
                                ),
                                onPressed: () => _seleccionarFecha(matches),
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                  _selectedDate == null
                                      ? 'Seleccionar fecha'
                                      : formatSoloFecha(_selectedDate!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (_selectedDate != null)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Quitar filtro',
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Los horarios se muestran en tu hora local.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.92),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredMatches.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay partidos para esta fecha',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 20),
                                itemCount: filteredMatches.length,
                                itemBuilder: (context, index) {
                                  final match = filteredMatches[index];
                                  final abierto =
                                      _pronosticoAbierto(match['fecha_hora']);

                                  return Card(
                                    color: Colors.white.withOpacity(0.95),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (match['fase'] != null ||
                                              match['grupo'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 10),
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  if (match['fase'] != null)
                                                    _infoChip(
                                                      texto: '${match['fase']}',
                                                      colorFondo: Colors.blue
                                                          .withOpacity(0.10),
                                                      colorTexto:
                                                          Colors.blue.shade800,
                                                    ),
                                                  if (match['grupo'] != null)
                                                    _infoChip(
                                                      texto:
                                                          'Grupo ${match['grupo']}',
                                                      colorFondo: Colors.orange
                                                          .withOpacity(0.10),
                                                      colorTexto:
                                                          Colors.orange.shade800,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          Row(
                                            children: [
                                              _buildEquipo(
                                                nombre: match['equipo_local'],
                                                alineadoDerecha: false,
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8),
                                                child: Text(
                                                  'VS',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              _buildEquipo(
                                                nombre:
                                                    match['equipo_visitante'],
                                                alineadoDerecha: true,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            'Fecha: ${formatFecha(match['fecha_hora'])}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _estadoChip(abierto),
                                          const SizedBox(height: 14),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: abierto
                                                  ? () =>
                                                      _mostrarDialogoPronostico(
                                                          match)
                                                  : null,
                                              icon: const Icon(
                                                  Icons.edit_note_rounded),
                                              label: Text(
                                                abierto
                                                    ? 'Pronosticar / Editar'
                                                    : 'Pronóstico cerrado',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
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