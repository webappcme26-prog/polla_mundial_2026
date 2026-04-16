import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final response = await _supabase
        .from('leaderboard')
        .select()
        .order('puntos_totales', ascending: false)
        .order('exactos', ascending: false)
        .order('aciertos_resultado', ascending: false)
        .order('nombre', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}