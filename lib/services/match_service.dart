import 'package:supabase_flutter/supabase_flutter.dart';

class MatchService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMatches() async {
    final response = await _supabase
        .from('matches')
        .select()
        .order('fecha_hora', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }
}