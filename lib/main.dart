import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'screens/gpa_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/formulas_screen.dart';
import 'screens/notes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();
  runApp(
    ChangeNotifierProvider(create: (_) => storage, child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667EEA),
          primary: const Color(0xFF667EEA),
          secondary: const Color(0xFF764BA2),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
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
    GpaScreen(),
    AssignmentsScreen(),
    TimerScreen(),
    ScheduleScreen(),
    FormulasScreen(),
    NotesScreen(),
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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _destinations,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF667EEA).withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
