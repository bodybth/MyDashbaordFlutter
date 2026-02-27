import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'screens/gpa_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/library_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final storage = StorageService();
  await storage.init();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<StorageService>(create: (_) => storage),
    ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
  ], child: const MyApp()));
}

const _kPrimary   = Color(0xFF667EEA);
const _kSecondary = Color(0xFF764BA2);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      title: 'My Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: themeService.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: _kPrimary, primary: _kPrimary,
            secondary: _kSecondary, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
        cardColor: Colors.white,
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: _kPrimary.withOpacity(0.15)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: _kPrimary, primary: _kPrimary,
            secondary: _kSecondary, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF1C2333),
        navigationBarTheme: NavigationBarThemeData(
            backgroundColor: const Color(0xFF161B27),
            indicatorColor: _kPrimary.withOpacity(0.25)),
      ),
      home: const SplashScreen(),
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFF1A237E), Color(0xFF0D1F3C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 180, height: 180,
                  child: Image.asset('assets/icon.png', fit: BoxFit.contain)),
              const SizedBox(height: 28),
              const Text('My Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 30,
                      fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              const Text('Engineering Student',
                  style: TextStyle(color: Colors.white54, fontSize: 15, letterSpacing: 1.0)),
              const SizedBox(height: 48),
              SizedBox(width: 40,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.6)),
                  )),
            ]),
          ),
        ),
      ),
    ),
  );
}

// ── Main Shell ────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _idx = 0;

  final List<Widget> _screens = const [
    GpaScreen(),
    AssignmentsScreen(),
    TimerScreen(),
    ScheduleScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  final List<NavigationDestination> _dests = const [
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'GPA'),
    NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tasks'),
    NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Timer'),
    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Library'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Theme.of(context).navigationBarTheme;
    return Scaffold(
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: _dests,
        backgroundColor: nav.backgroundColor,
        indicatorColor: nav.indicatorColor,
      ),
    );
  }
}
