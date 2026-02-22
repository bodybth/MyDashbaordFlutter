import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService extends ChangeNotifier {
  late SharedPreferences _prefs;

  List<Course> courses = [];
  List<Assignment> assignments = [];
  List<ScheduleItem> scheduleItems = [];
  List<Note> notes = [];

  // Expiry date - change this to disable the app
  static final DateTime expiryDate = DateTime(2026, 5, 22, 23, 59, 59);

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    // Courses
    final c = _prefs.getString('courses');
    if (c != null) courses = (jsonDecode(c) as List).map((e) => Course.fromJson(e)).toList();

    // Assignments
    final a = _prefs.getString('assignments');
    if (a != null) assignments = (jsonDecode(a) as List).map((e) => Assignment.fromJson(e)).toList();

    // Schedule
    final s = _prefs.getString('schedule');
    if (s != null) {
      scheduleItems = (jsonDecode(s) as List).map((e) => ScheduleItem.fromJson(e)).toList();
      _sortSchedule();
    }

    // Notes
    final n = _prefs.getString('notes');
    if (n != null) notes = (jsonDecode(n) as List).map((e) => Note.fromJson(e)).toList();
  }

  // ── Courses ──────────────────────────────────────────────────────
  void addCourse(Course c) {
    courses.add(c);
    _saveCourses();
    notifyListeners();
  }

  void deleteCourse(String id) {
    courses.removeWhere((c) => c.id == id);
    _saveCourses();
    notifyListeners();
  }

  void _saveCourses() => _prefs.setString('courses', jsonEncode(courses.map((c) => c.toJson()).toList()));

  double get gpa {
    if (courses.isEmpty) return 0;
    double totalPoints = courses.fold(0, (s, c) => s + c.grade * c.credits);
    int totalCredits = courses.fold(0, (s, c) => s + c.credits);
    return totalCredits > 0 ? totalPoints / totalCredits : 0;
  }

  int get totalCredits => courses.fold(0, (s, c) => s + c.credits);

  // ── Assignments ───────────────────────────────────────────────────
  void addAssignment(Assignment a) {
    assignments.add(a);
    assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _saveAssignments();
    notifyListeners();
  }

  void deleteAssignment(String id) {
    assignments.removeWhere((a) => a.id == id);
    _saveAssignments();
    notifyListeners();
  }

  void toggleAssignment(String id) {
    final i = assignments.indexWhere((a) => a.id == id);
    if (i >= 0) {
      assignments[i] = assignments[i].copyWith(completed: !assignments[i].completed);
      _saveAssignments();
      notifyListeners();
    }
  }

  void _saveAssignments() => _prefs.setString('assignments', jsonEncode(assignments.map((a) => a.toJson()).toList()));

  // ── Schedule ──────────────────────────────────────────────────────
  void addScheduleItem(ScheduleItem item) {
    scheduleItems.add(item);
    _sortSchedule();
    _saveSchedule();
    notifyListeners();
  }

  void deleteScheduleItem(String id) {
    scheduleItems.removeWhere((s) => s.id == id);
    _saveSchedule();
    notifyListeners();
  }

  void updateScheduleItem(ScheduleItem item) {
    final i = scheduleItems.indexWhere((s) => s.id == item.id);
    if (i >= 0) {
      scheduleItems[i] = item;
      _sortSchedule();
      _saveSchedule();
      notifyListeners();
    }
  }

  void _sortSchedule() {
    const dayOrder = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    scheduleItems.sort((a, b) {
      final dayDiff = dayOrder.indexOf(a.day) - dayOrder.indexOf(b.day);
      if (dayDiff != 0) return dayDiff;
      return a.time.compareTo(b.time);
    });
  }

  void _saveSchedule() => _prefs.setString('schedule', jsonEncode(scheduleItems.map((s) => s.toJson()).toList()));

  // ── Notes ─────────────────────────────────────────────────────────
  void addNote(Note n) {
    notes.insert(0, n);
    _saveNotes();
    notifyListeners();
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
    _saveNotes();
    notifyListeners();
  }

  void updateNote(Note n) {
    final i = notes.indexWhere((note) => note.id == n.id);
    if (i >= 0) {
      notes[i] = n;
      _saveNotes();
      notifyListeners();
    }
  }

  void _saveNotes() => _prefs.setString('notes', jsonEncode(notes.map((n) => n.toJson()).toList()));

  // ── Export / Import ───────────────────────────────────────────────
  String exportData() {
    return jsonEncode({
      'courses': courses.map((c) => c.toJson()).toList(),
      'assignments': assignments.map((a) => a.toJson()).toList(),
      'schedule': scheduleItems.map((s) => s.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  String importData(String json) {
    try {
      final data = jsonDecode(json);
      if (data['courses'] != null) {
        courses = (data['courses'] as List).map((e) => Course.fromJson(e)).toList();
        _saveCourses();
      }
      if (data['assignments'] != null) {
        assignments = (data['assignments'] as List).map((e) => Assignment.fromJson(e)).toList();
        _saveAssignments();
      }
      if (data['schedule'] != null) {
        scheduleItems = (data['schedule'] as List).map((e) => ScheduleItem.fromJson(e)).toList();
        _sortSchedule();
        _saveSchedule();
      }
      if (data['notes'] != null) {
        notes = (data['notes'] as List).map((e) => Note.fromJson(e)).toList();
        _saveNotes();
      }
      notifyListeners();
      return 'success';
    } catch (e) {
      return 'error: $e';
    }
  }
}
