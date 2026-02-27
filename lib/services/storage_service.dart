import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService extends ChangeNotifier {
  late SharedPreferences _prefs;
  List<Course> courses = [];
  List<Assignment> assignments = [];
  List<ScheduleItem> scheduleItems = [];
  List<Note> notes = [];
  List<Formula> formulas = [];
  List<Notebook> notebooks = [];
  List<AppCategory> noteCategories = [];
  List<AppCategory> formulaCategories = [];
  List<AppCategory> priorities = [];

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
    formulas = f != null ? (jsonDecode(f) as List).map((e) => Formula.fromJson(e)).toList() : List.from(defaultFormulas);

    final nb = _prefs.getString('notebooks');
    if (nb != null) {
      notebooks = (jsonDecode(nb) as List).map((e) => Notebook.fromJson(e)).toList();
    } else {
      notebooks = [
        Notebook(id: 'nb_formulas', title: 'Formulas',       emoji: '📐', type: 'formulas'),
        Notebook(id: 'nb_notes',    title: 'Notes',           emoji: '📝', type: 'notes'),
        Notebook(id: 'nb_emails',   title: 'Email Addresses', emoji: '📧', type: 'notes'),
      ];
      _saveNotebooks();
    }

    final nc = _prefs.getString('noteCategories');
    noteCategories = nc != null ? (jsonDecode(nc) as List).map((e) => AppCategory.fromJson(e)).toList() : List.from(defaultNoteCategories);

    final fc = _prefs.getString('formulaCategories');
    formulaCategories = fc != null ? (jsonDecode(fc) as List).map((e) => AppCategory.fromJson(e)).toList() : List.from(defaultFormulaCategories);

    final p = _prefs.getString('priorities');
    priorities = p != null ? (jsonDecode(p) as List).map((e) => AppCategory.fromJson(e)).toList() : List.from(defaultPriorities);
  }

  // ── Attachment file management ────────────────────────────────────
  /// Copy a file into private app storage and return the new local path
  Future<String> copyAttachmentToPrivate(String sourcePath, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachDir = Directory('${dir.path}/note_attachments');
    if (!await attachDir.exists()) await attachDir.create(recursive: true);
    final dest = '${attachDir.path}/$filename';
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Delete an attachment file from private storage
  Future<void> deleteAttachmentFile(String localPath) async {
    try {
      final f = File(localPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ── Courses ───────────────────────────────────────────────────────
  void addCourse(Course c) { courses.add(c); _saveCourses(); notifyListeners(); }
  void deleteCourse(String id) { courses.removeWhere((c) => c.id == id); _saveCourses(); notifyListeners(); }
  void _saveCourses() => _prefs.setString('courses', jsonEncode(courses.map((c) => c.toJson()).toList()));
  double get gpa { if (courses.isEmpty) return 0; final tp = courses.fold<double>(0, (s, c) => s + c.grade * c.credits); final tc = courses.fold<int>(0, (s, c) => s + c.credits); return tc > 0 ? tp / tc : 0; }
  int get totalCredits => courses.fold<int>(0, (s, c) => s + c.credits);

  // ── Assignments ───────────────────────────────────────────────────
  void addAssignment(Assignment a) { assignments.add(a); assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate)); _saveAssignments(); notifyListeners(); }
  void deleteAssignment(String id) { assignments.removeWhere((a) => a.id == id); _saveAssignments(); notifyListeners(); }
  void toggleAssignment(String id) { final i = assignments.indexWhere((a) => a.id == id); if (i >= 0) { assignments[i] = assignments[i].copyWith(completed: !assignments[i].completed); _saveAssignments(); notifyListeners(); } }
  void updateAssignment(Assignment a) { final i = assignments.indexWhere((x) => x.id == a.id); if (i >= 0) { assignments[i] = a; assignments.sort((a, b) => a.dueDate.compareTo(b.dueDate)); _saveAssignments(); notifyListeners(); } }
  void _saveAssignments() => _prefs.setString('assignments', jsonEncode(assignments.map((a) => a.toJson()).toList()));

  // ── Schedule ──────────────────────────────────────────────────────
  void addScheduleItem(ScheduleItem item) { scheduleItems.add(item); _sortSchedule(); _saveSchedule(); notifyListeners(); }
  void deleteScheduleItem(String id) { scheduleItems.removeWhere((s) => s.id == id); _saveSchedule(); notifyListeners(); }
  void updateScheduleItem(ScheduleItem item) { final i = scheduleItems.indexWhere((s) => s.id == item.id); if (i >= 0) { scheduleItems[i] = item; _sortSchedule(); _saveSchedule(); notifyListeners(); } }
  void _sortSchedule() { scheduleItems.sort((a, b) { final d = weekDays.indexOf(a.day) - weekDays.indexOf(b.day); return d != 0 ? d : a.time.compareTo(b.time); }); }
  void _saveSchedule() => _prefs.setString('schedule', jsonEncode(scheduleItems.map((s) => s.toJson()).toList()));

  // ── Notes ─────────────────────────────────────────────────────────
  void addNote(Note n) { notes.insert(0, n); _saveNotes(); notifyListeners(); }
  void deleteNote(String id) async {
    final note = notes.firstWhere((n) => n.id == id, orElse: () => Note(title: '', content: '', branch: ''));
    for (final a in note.attachments) await deleteAttachmentFile(a.localPath);
    notes.removeWhere((n) => n.id == id);
    _saveNotes(); notifyListeners();
  }
  void updateNote(Note n) { final i = notes.indexWhere((x) => x.id == n.id); if (i >= 0) { notes[i] = n; _saveNotes(); notifyListeners(); } }
  List<Note> notesForNotebook(String nbId) => notes.where((n) => n.branch == nbId).toList();
  void _saveNotes() => _prefs.setString('notes', jsonEncode(notes.map((n) => n.toJson()).toList()));

  // ── Formulas ──────────────────────────────────────────────────────
  void addFormula(Formula f) { formulas.add(f); _saveFormulas(); notifyListeners(); }
  void deleteFormula(String id) { formulas.removeWhere((f) => f.id == id); _saveFormulas(); notifyListeners(); }
  void updateFormula(Formula f) { final i = formulas.indexWhere((x) => x.id == f.id); if (i >= 0) { formulas[i] = f; _saveFormulas(); notifyListeners(); } }
  void resetFormulas() { formulas = List.from(defaultFormulas); _saveFormulas(); notifyListeners(); }
  void _saveFormulas() => _prefs.setString('formulas', jsonEncode(formulas.map((f) => f.toJson()).toList()));

  // ── Notebooks ─────────────────────────────────────────────────────
  void addNotebook(Notebook nb) { notebooks.add(nb); _saveNotebooks(); notifyListeners(); }
  void deleteNotebook(String id) async {
    // delete attachment files from notes in this notebook
    for (final note in notes.where((n) => n.branch == id)) {
      for (final a in note.attachments) await deleteAttachmentFile(a.localPath);
    }
    notebooks.removeWhere((nb) => nb.id == id);
    notes.removeWhere((n) => n.branch == id);
    _saveNotebooks(); _saveNotes(); notifyListeners();
  }
  void updateNotebook(Notebook nb) { final i = notebooks.indexWhere((x) => x.id == nb.id); if (i >= 0) { notebooks[i] = nb; _saveNotebooks(); notifyListeners(); } }
  void _saveNotebooks() => _prefs.setString('notebooks', jsonEncode(notebooks.map((nb) => nb.toJson()).toList()));

  // ── Categories ────────────────────────────────────────────────────
  void addNoteCategory(AppCategory cat) { noteCategories.add(cat); _saveNoteCategories(); notifyListeners(); }
  void deleteNoteCategory(String id) { noteCategories.removeWhere((c) => c.id == id); for (int i = 0; i < notes.length; i++) { if (notes[i].branch == id) notes[i] = Note(id: notes[i].id, title: notes[i].title, content: notes[i].content, branch: 'general', date: notes[i].date); } _saveNoteCategories(); _saveNotes(); notifyListeners(); }
  void _saveNoteCategories() => _prefs.setString('noteCategories', jsonEncode(noteCategories.map((c) => c.toJson()).toList()));
  void addFormulaCategory(AppCategory cat) { formulaCategories.add(cat); _saveFormulaCategories(); notifyListeners(); }
  void deleteFormulaCategory(String id) { formulaCategories.removeWhere((c) => c.id == id); formulas.removeWhere((f) => f.category == id); _saveFormulaCategories(); _saveFormulas(); notifyListeners(); }
  void _saveFormulaCategories() => _prefs.setString('formulaCategories', jsonEncode(formulaCategories.map((c) => c.toJson()).toList()));
  void addPriority(AppCategory cat) { priorities.add(cat); _savePriorities(); notifyListeners(); }
  void deletePriority(String id) { if (priorities.length <= 1) return; priorities.removeWhere((p) => p.id == id); _savePriorities(); notifyListeners(); }
  void _savePriorities() => _prefs.setString('priorities', jsonEncode(priorities.map((p) => p.toJson()).toList()));

  // ── Selective Export ──────────────────────────────────────────────
  /// [sections] is a Set of section keys to include.
  /// Keys: 'gpa', 'assignments', 'schedule', 'library', 'formulas', 'priorities'
  String exportData({Set<String>? sections}) {
    final all = sections == null;
    final map = <String, dynamic>{};
    if (all || sections!.contains('gpa')) map['courses'] = courses.map((c) => c.toJson()).toList();
    if (all || sections!.contains('assignments')) map['assignments'] = assignments.map((a) => a.toJson()).toList();
    if (all || sections!.contains('schedule')) map['schedule'] = scheduleItems.map((s) => s.toJson()).toList();
    if (all || sections!.contains('library')) {
      map['notes']     = notes.map((n) => n.toJson()).toList();
      map['notebooks'] = notebooks.map((nb) => nb.toJson()).toList();
      map['noteCategories'] = noteCategories.map((c) => c.toJson()).toList();
    }
    if (all || sections!.contains('formulas')) {
      map['formulas']           = formulas.map((f) => f.toJson()).toList();
      map['formulaCategories']  = formulaCategories.map((c) => c.toJson()).toList();
    }
    if (all || sections!.contains('priorities')) map['priorities'] = priorities.map((p) => p.toJson()).toList();
    map['exportedAt'] = DateTime.now().toIso8601String();
    return jsonEncode(map);
  }

  // ── Selective Import ──────────────────────────────────────────────
  String importData(String json, {Set<String>? sections}) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final all = sections == null;
      if ((all || sections!.contains('gpa')) && data['courses'] != null) { courses = (data['courses'] as List).map((e) => Course.fromJson(e)).toList(); _saveCourses(); }
      if ((all || sections!.contains('assignments')) && data['assignments'] != null) { assignments = (data['assignments'] as List).map((e) => Assignment.fromJson(e)).toList(); _saveAssignments(); }
      if ((all || sections!.contains('schedule')) && data['schedule'] != null) { scheduleItems = (data['schedule'] as List).map((e) => ScheduleItem.fromJson(e)).toList(); _sortSchedule(); _saveSchedule(); }
      if (all || sections!.contains('library')) {
        if (data['notes'] != null) { notes = (data['notes'] as List).map((e) => Note.fromJson(e)).toList(); _saveNotes(); }
        if (data['notebooks'] != null) { notebooks = (data['notebooks'] as List).map((e) => Notebook.fromJson(e)).toList(); _saveNotebooks(); }
        if (data['noteCategories'] != null) { noteCategories = (data['noteCategories'] as List).map((e) => AppCategory.fromJson(e)).toList(); _saveNoteCategories(); }
      }
      if (all || sections!.contains('formulas')) {
        if (data['formulas'] != null) { formulas = (data['formulas'] as List).map((e) => Formula.fromJson(e)).toList(); _saveFormulas(); }
        if (data['formulaCategories'] != null) { formulaCategories = (data['formulaCategories'] as List).map((e) => AppCategory.fromJson(e)).toList(); _saveFormulaCategories(); }
      }
      if ((all || sections!.contains('priorities')) && data['priorities'] != null) { priorities = (data['priorities'] as List).map((e) => AppCategory.fromJson(e)).toList(); _savePriorities(); }
      notifyListeners(); return 'success';
    } catch (e) { return 'error: $e'; }
  }

  // ── Clear All ─────────────────────────────────────────────────────
  void clearAll() {
    courses.clear();
    assignments.clear();
    scheduleItems.clear();
    notes.clear();
    formulas = List.from(defaultFormulas);
    notebooks = [
      Notebook(id: 'nb_formulas', title: 'Formulas',       emoji: '📐', type: 'formulas'),
      Notebook(id: 'nb_notes',    title: 'Notes',           emoji: '📝', type: 'notes'),
      Notebook(id: 'nb_emails',   title: 'Email Addresses', emoji: '📧', type: 'notes'),
    ];
    noteCategories    = List.from(defaultNoteCategories);
    formulaCategories = List.from(defaultFormulaCategories);
    priorities        = List.from(defaultPriorities);
    _saveCourses(); _saveAssignments(); _saveSchedule(); _saveNotes();
    _saveFormulas(); _saveNotebooks(); _saveNoteCategories();
    _saveFormulaCategories(); _savePriorities();
    notifyListeners();
  }
}
