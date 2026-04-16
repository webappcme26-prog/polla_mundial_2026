import 'package:supabase_flutter/supabase_flutter.dart';

class PredictionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> savePrediction({
    required String userId,
    required int matchId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    try {
      await _supabase.from('predictions').upsert(
        {
          'user_id': userId,
          'match_id': matchId,
          'goles_local_pred': golesLocal,
          'goles_visitante_pred': golesVisitante,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,match_id',
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> getPredictionByUserAndMatch({
    required String userId,
    required int matchId,
  }) async {
    try {
      final response = await _supabase
          .from('predictions')
          .select()
          .eq('user_id', userId)
          .eq('match_id', matchId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMyPredictions(String userId) async {
    final response = await _supabase
        .from('predictions')
        .select('''
          id,
          goles_local_pred,
          goles_visitante_pred,
          updated_at,
          matches (
            equipo_local,
            equipo_visitante,
            fecha_hora,
            estado
          )
        ''')
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPredictionsByMatch(int matchId) async {
    final response = await _supabase
        .from('predictions')
        .select('''
          goles_local_pred,
          goles_visitante_pred,
          updated_at,
          profiles (
            nombre
          )
        ''')
        .eq('match_id', matchId)
        .order('updated_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}