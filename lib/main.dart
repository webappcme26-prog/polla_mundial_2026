import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'pages/admin_page.dart';
import 'pages/leaderboard_page.dart';
import 'pages/login_page.dart';
import 'pages/matches_page.dart';
import 'pages/my_predictions_page.dart';
import 'pages/reset_password_page.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class AppColors {
  static const Color primary = Color(0xFF0B3D91);
  static const Color secondary = Color(0xFF16A34A);
  static const Color accent = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF4F6FB);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1F2937);
  static const Color textSoft = Color(0xFF6B7280);
  static const Color chipBg = Color(0xFFE8EEFF);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Polla Mundial 2026',
      locale: const Locale('es', 'CO'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.94),
          elevation: 6,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: AppColors.textSoft),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomePage(),
        '/reset-password': (context) => const ResetPasswordPage(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthChangeEvent? _lastEvent;

  @override
  void initState() {
    super.initState();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _lastEvent = data.event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (_lastEvent == AuthChangeEvent.passwordRecovery) {
      return const ResetPasswordPage();
    }

    if (session != null) {
      return const HomePage();
    }

    return const LoginPage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getMyProfile();
  }

  Future<void> _cerrarSesion() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Polla Mundial 2026'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _cerrarSesion,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF3B30),
                        Color(0xFFD50000),
                        Color(0xFFB71C1C),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SALIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final esAdmin = profile != null && profile['rol'] == 'admin';

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/fondo_mundial.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.36),
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _profileFuture = _profileService.getMyProfile();
                    });
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      _buildHeroCard(
                        nombre: profile?['nombre'] ?? 'Sin nombre',
                        email: user?.email ?? 'Sin correo',
                        rol: profile?['rol'] ?? 'jugador',
                      ),
                      const SizedBox(height: 22),
                      _buildSectionTitle(),
                      const SizedBox(height: 14),
                      _menuButton(
                        icon: Icons.sports_soccer_rounded,
                        title: 'Ver partidos',
                        subtitle:
                            'Consulta el calendario y registra tus pronósticos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MatchesPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _menuButton(
                        icon: Icons.fact_check_rounded,
                        title: 'Mis pronósticos',
                        subtitle: 'Revisa tus marcadores y aciertos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MyPredictionsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _menuButton(
                        icon: Icons.emoji_events_rounded,
                        title: 'Tabla de posiciones',
                        subtitle: 'Mira cómo va el ranking general',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaderboardPage(),
                            ),
                          );
                        },
                      ),
                      if (esAdmin) ...[
                        const SizedBox(height: 14),
                        _menuButton(
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Panel admin',
                          subtitle: 'Gestiona resultados y revisa pronósticos',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPage(),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildInfoBanner(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroCard({
    required String nombre,
    required String email,
    required String rol,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0B3D91).withOpacity(0.96),
            const Color(0xFF1D4ED8).withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    'Rol: $rol',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 2),
      child: Text(
        'Accesos rápidos',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: AppColors.textDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Los horarios se muestran en tu hora local y los cierres se validan con la hora del servidor.',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}