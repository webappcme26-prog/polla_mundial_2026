import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

 Future<List<Map<String, dynamic>>> getLeaderboard() async {
  final response = await _supabase
      .from('leaderboard')
      .select('''
        user_id,
        nombre,
        puntos_totales,
        exactos,
        aciertos_resultado
      ''')
      .neq('user_id', 'e5f35cb4-7a3e-48b4-987e-1eaafa2544b8')
      .order('puntos_totales', ascending: false)
      .order('exactos', ascending: false)
      .order('aciertos_resultado', ascending: false)
      .order('nombre', ascending: true);

  return List<Map<String, dynamic>>.from(response);
}
}