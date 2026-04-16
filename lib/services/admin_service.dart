import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMatches() async {
    final response = await _supabase
        .from('matches')
        .select()
        .order('fecha_hora', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<String?> saveMatchResult({
    required int matchId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    try {
      await _supabase.from('matches').update({
        'goles_local_real': golesLocal,
        'goles_visitante_real': golesVisitante,
        'estado': 'finalizado',
      }).eq('id', matchId);

      await _supabase.rpc('recalcular_scores_partido', params: {
        'p_match_id': matchId,
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}