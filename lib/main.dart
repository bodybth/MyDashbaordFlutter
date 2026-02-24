import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'screens/gpa_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/formulas_screen.dart';
import 'screens/notes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  final storage = StorageService();
  await storage.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>(create: (_) => storage),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );
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
        colorScheme: ColorScheme.fromSeed(seedColor: _kPrimary, primary: _kPrimary,
            secondary: _kSecondary, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
        cardColor: Colors.white,
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _kPrimary.withOpacity(0.15),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _kPrimary, primary: _kPrimary,
            secondary: _kSecondary, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF1C2333),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF161B27),
          indicatorColor: _kPrimary.withOpacity(0.25),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF1A237E), Color(0xFF0D1F3C)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(opacity: _fadeAnim,
            child: ScaleTransition(scale: _scaleAnim,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: 180, height: 180,
                    child: Image.asset('assets/icon.png', fit: BoxFit.contain)),
                const SizedBox(height: 28),
                const Text('My Dashboard', style: TextStyle(color: Colors.white,
                    fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                const Text('Engineering Student',
                    style: TextStyle(color: Colors.white54, fontSize: 15, letterSpacing: 1.0)),
                const SizedBox(height: 48),
                SizedBox(width: 40, child: LinearProgressIndicator(
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
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    GpaScreen(), AssignmentsScreen(), TimerScreen(),
    ScheduleScreen(), FormulasScreen(), NotesScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'GPA'),
    NavigationDestination(icon: Icon(Icons.assignment), label: 'Tasks'),
    NavigationDestination(icon: Icon(Icons.timer), label: 'Timer'),
    NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Schedule'),
    NavigationDestination(icon: Icon(Icons.calculate), label: 'Formulas'),
    NavigationDestination(icon: Icon(Icons.notes), label: 'Notes'),
  ];

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).navigationBarTheme;
    return Scaffold(
      // No appBar here — each screen has its own GradientAppBar with toggle built in
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _destinations,
        backgroundColor: navTheme.backgroundColor,
        indicatorColor: navTheme.indicatorColor,
      ),
    );
  }
}
