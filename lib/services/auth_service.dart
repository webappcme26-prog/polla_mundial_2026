import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
        },
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        return 'No se pudo crear el usuario.';
      }

      if (session == null) {
        return 'Usuario creado, pero no hay sesión activa. Desactiva la confirmación de correo en Supabase para pruebas.';
      }

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'nombre': nombre,
        'email': email,
        'rol': 'jugador',
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword({
    required String email,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://polla-mundial-2026-blond.vercel.app/#/reset-password',
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}