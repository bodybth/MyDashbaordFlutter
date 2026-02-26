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
  List<Formula> formulas = [];
  List<AppCategory> noteCategories = [];
  List<AppCategory> formulaCategories = [];
  List<AppCategory> priorities = [];
  List<Collection> collections = [];

  static final DateTime expiryDate = DateTime(2026, 5, 22, 23, 59, 59);
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final c = _prefs.getString('courses');
    if (c != null) courses = (jsonDecode(c) as List).map((e) => Course.fromJson(e)).toList();

    final a = _prefs.getString('assignments');
    if (a != null) assignments = (jsonDecode(a) as List).map((e) => Assignment.fromJson(e)).toList();

    final s = _prefs.getString('schedule');
    if (s != null) { scheduleItems = (jsonDecode(s) as List).map((e) => ScheduleItem.fromJson(e)).toList(); _sortSchedule(); }

    final n = _prefs.getString('notes');
    if (n != null) notes = (jsonDecode(n) as List).map((e) => Note.fromJson(e)).toList();

    final f = _prefs.getString('formulas');
    if (f != null) {
      formulas = (jsonDecode(f) as List).map((e) => Formula.fromJson(e)).toList();
    } else {
      formulas = List.from(defaultFormulas);
    }

    final nc = _prefs.getString('noteCategories');
    if (nc != null) {
      noteCategories = (jsonDecode(nc) as List).map((e) => AppCategory.fromJson(e)).toList();
    } else {
      noteCategories = List.from(defaultNoteCategories);
    }

    final fc = _prefs.getString('formulaCategories');
    if (fc != null) {
      formulaCategories = (jsonDecode(fc) as List).map((e) => AppCategory.fromJson(e)).toList();
    } else {
      formulaCategories = List.from(defaultFormulaCategories);
    }

    final p = _prefs.getString('priorities');
    if (p != null) {
      priorities = (jsonDecode(p) as List).map((e) => AppCategory.fromJson(e)).toList();
    } else {
      priorities = List.from(defaultPriorities);
    }

    final col = _prefs.getString('collections');
    if (col != null) {
      collections = (jsonDecode(col) as List).map((e) => Collection.fromJson(e)).toList();
    } else {
      collections = [
        Collection(id: 'formulas', title: 'Formulas', emoji: '📐', type: 'formula'),
        Collection(id: 'notes', title: 'Notes', emoji: '📝', type: 'note'),
        Collection(id: 'emails', title: 'Email Addresses', emoji: '📧', type: 'email'),
      ];
    }
  }

  // ── Courses ───────────────────────────────────────────────────────
  void addCourse(Course c) { courses.add(c); _saveCourses(); notifyListeners(); }
  void deleteCourse(String id) { courses.removeWhere((c) => c.id == id); _saveCourses(); notifyListeners(); }
  void _saveCourses() => _prefs.setString('courses', jsonEncode(courses.map((c) => c.toJson()).toList()));

  double get gpa {
    if (courses.isEmpty) return 0;
    double tp = courses.fold(0, (s, c) => s + c.grade * c.credits);
    int tc = courses.fold(0, (s, c) => s + c.credits);
    return tc > 0 ? tp / tc : 0;
  }
  int get totalCredits => courses.fold(0, (s, c) => s + c.credits);

  // ── Assignments ───────────────────────────────────────────────────
  void addAssignment(Assignment a) {
    assignments.add(a);
    assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    _saveAssignments(); notifyListeners();
  }
  void deleteAssignment(String id) { assignments.removeWhere((a) => a.id == id); _saveAssignments(); notifyListeners(); }
  void toggleAssignment(String id) {
    final i = assignments.indexWhere((a) => a.id == id);
    if (i >= 0) { assignments[i] = assignments[i].copyWith(completed: !assignments[i].completed); _saveAssignments(); notifyListeners(); }
  }
  void updateAssignment(Assignment a) {
    final i = assignments.indexWhere((x) => x.id == a.id);
    if (i >= 0) { assignments[i] = a; assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate)); _saveAssignments(); notifyListeners(); }
  }
  void _saveAssignments() => _prefs.setString('assignments', jsonEncode(assignments.map((a) => a.toJson()).toList()));

  // ── Schedule ──────────────────────────────────────────────────────
  void addScheduleItem(ScheduleItem item) { scheduleItems.add(item); _sortSchedule(); _saveSchedule(); notifyListeners(); }
  void deleteScheduleItem(String id) { scheduleItems.removeWhere((s) => s.id == id); _saveSchedule(); notifyListeners(); }
  void updateScheduleItem(ScheduleItem item) {
    final i = scheduleItems.indexWhere((s) => s.id == item.id);
    if (i >= 0) { scheduleItems[i] = item; _sortSchedule(); _saveSchedule(); notifyListeners(); }
  }
  void _sortSchedule() {
    scheduleItems.sort((a, b) {
      final dayDiff = weekDays.indexOf(a.day) - weekDays.indexOf(b.day);
      return dayDiff != 0 ? dayDiff : a.time.compareTo(b.time);
    });
  }
  void _saveSchedule() => _prefs.setString('schedule', jsonEncode(scheduleItems.map((s) => s.toJson()).toList()));

  // ── Notes ─────────────────────────────────────────────────────────
  void addNote(Note n) { notes.insert(0, n); _saveNotes(); notifyListeners(); }
  void deleteNote(String id) { notes.removeWhere((n) => n.id == id); _saveNotes(); notifyListeners(); }
  void updateNote(Note n) {
    final i = notes.indexWhere((note) => note.id == n.id);
    if (i >= 0) { notes[i] = n; _saveNotes(); notifyListeners(); }
  }
  void _saveNotes() => _prefs.setString('notes', jsonEncode(notes.map((n) => n.toJson()).toList()));

  // ── Formulas ──────────────────────────────────────────────────────
  void addFormula(Formula f) { formulas.add(f); _saveFormulas(); notifyListeners(); }
  void deleteFormula(String id) { formulas.removeWhere((f) => f.id == id); _saveFormulas(); notifyListeners(); }
  void updateFormula(Formula f) {
    final i = formulas.indexWhere((x) => x.id == f.id);
    if (i >= 0) { formulas[i] = f; _saveFormulas(); notifyListeners(); }
  }
  void resetFormulas() { formulas = List.from(defaultFormulas); _saveFormulas(); notifyListeners(); }
  void _saveFormulas() => _prefs.setString('formulas', jsonEncode(formulas.map((f) => f.toJson()).toList()));

  // ── Collections ───────────────────────────────────────────────────
  void addCollection(Collection col) { collections.add(col); _saveCollections(); notifyListeners(); }
  void deleteCollection(String id) { collections.removeWhere((c) => c.id == id); _saveCollections(); notifyListeners(); }
  void updateCollection(Collection col) {
    final i = collections.indexWhere((c) => c.id == col.id);
    if (i >= 0) { collections[i] = col; _saveCollections(); notifyListeners(); }
  }
  void _saveCollections() => _prefs.setString('collections', jsonEncode(collections.map((c) => c.toJson()).toList()));

  // ── Categories ────────────────────────────────────────────────────
  void addNoteCategory(AppCategory cat) { noteCategories.add(cat); _saveNoteCategories(); notifyListeners(); }
  void deleteNoteCategory(String id) {
    noteCategories.removeWhere((c) => c.id == id);
    for (int i = 0; i < notes.length; i++) {
      if (notes[i].branch == id) notes[i] = Note(id: notes[i].id, title: notes[i].title, content: notes[i].content, branch: 'general', date: notes[i].date);
    }
    _saveNoteCategories(); _saveNotes(); notifyListeners();
  }
  void _saveNoteCategories() => _prefs.setString('noteCategories', jsonEncode(noteCategories.map((c) => c.toJson()).toList()));

  void addFormulaCategory(AppCategory cat) { formulaCategories.add(cat); _saveFormulaCategories(); notifyListeners(); }
  void deleteFormulaCategory(String id) {
    formulaCategories.removeWhere((c) => c.id == id);
    formulas.removeWhere((f) => f.category == id);
    _saveFormulaCategories(); _saveFormulas(); notifyListeners();
  }
  void _saveFormulaCategories() => _prefs.setString('formulaCategories', jsonEncode(formulaCategories.map((c) => c.toJson()).toList()));

  void addPriority(AppCategory cat) { priorities.add(cat); _savePriorities(); notifyListeners(); }
  void deletePriority(String id) {
    if (priorities.length <= 1) return;
    priorities.removeWhere((p) => p.id == id);
    _savePriorities(); notifyListeners();
  }
  void _savePriorities() => _prefs.setString('priorities', jsonEncode(priorities.map((p) => p.toJson()).toList()));

  // ── Export / Import ───────────────────────────────────────────────
  String exportData() {
    return jsonEncode({
      'courses': courses.map((c) => c.toJson()).toList(),
      'assignments': assignments.map((a) => a.toJson()).toList(),
      'schedule': scheduleItems.map((s) => s.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'formulas': formulas.map((f) => f.toJson()).toList(),
      'noteCategories': noteCategories.map((c) => c.toJson()).toList(),
      'formulaCategories': formulaCategories.map((c) => c.toJson()).toList(),
      'priorities': priorities.map((p) => p.toJson()).toList(),
      'collections': collections.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  String importData(String json) {
    try {
      final data = jsonDecode(json);
      if (data['courses'] != null) { courses = (data['courses'] as List).map((e) => Course.fromJson(e)).toList(); _saveCourses(); }
      if (data['assignments'] != null) { assignments = (data['assignments'] as List).map((e) => Assignment.fromJson(e)).toList(); _saveAssignments(); }
      if (data['schedule'] != null) { scheduleItems = (data['schedule'] as List).map((e) => ScheduleItem.fromJson(e)).toList(); _sortSchedule(); _saveSchedule(); }
      if (data['notes'] != null) { notes = (data['notes'] as List).map((e) => Note.fromJson(e)).toList(); _saveNotes(); }
      if (data['formulas'] != null) { formulas = (data['formulas'] as List).map((e) => Formula.fromJson(e)).toList(); _saveFormulas(); }
      if (data['noteCategories'] != null) { noteCategories = (data['noteCategories'] as List).map((e) => AppCategory.fromJson(e)).toList(); _saveNoteCategories(); }
      if (data['formulaCategories'] != null) { formulaCategories = (data['formulaCategories'] as List).map((e) => AppCategory.fromJson(e)).toList(); _saveFormulaCategories(); }
      if (data['priorities'] != null) { priorities = (data['priorities'] as List).map((e) => AppCategory.fromJson(e)).toList(); _savePriorities(); }
      if (data['collections'] != null) { collections = (data['collections'] as List).map((e) => Collection.fromJson(e)).toList(); _saveCollections(); }
      notifyListeners();
      return 'success';
    } catch (e) { return 'error: $e'; }
  }
}
