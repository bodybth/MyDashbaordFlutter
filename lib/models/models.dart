import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ── Course ────────────────────────────────────────────────────────
class Course {
  final String id;
  final String name;
  final double grade;
  final int credits;

  Course({String? id, required this.name, required this.grade, required this.credits})
      : id = id ?? _uuid.v4();

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'] ?? _uuid.v4(),
        name: j['name'],
        grade: (j['grade'] as num).toDouble(),
        credits: j['credits'] as int,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'grade': grade, 'credits': credits};
}

// ── Assignment ────────────────────────────────────────────────────
class Assignment {
  final String id;
  final String name;
  final String course;
  final DateTime dueDate;
  final String priority;
  final bool completed;

  Assignment({
    String? id,
    required this.name,
    required this.course,
    required this.dueDate,
    required this.priority,
    this.completed = false,
  }) : id = id ?? _uuid.v4();

  Assignment copyWith({bool? completed}) => Assignment(
        id: id,
        name: name,
        course: course,
        dueDate: dueDate,
        priority: priority,
        completed: completed ?? this.completed,
      );

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
        id: j['id'] ?? _uuid.v4(),
        name: j['name'],
        course: j['course'],
        dueDate: DateTime.parse(j['due']),
        priority: j['priority'],
        completed: j['completed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'course': course,
        'due': dueDate.toIso8601String(),
        'priority': priority,
        'completed': completed,
      };
}

// ── ScheduleItem ──────────────────────────────────────────────────
class ScheduleItem {
  final String id;
  final String name;
  final String day;
  final String time;
  final String location;

  ScheduleItem({
    String? id,
    required this.name,
    required this.day,
    required this.time,
    required this.location,
  }) : id = id ?? _uuid.v4();

  ScheduleItem copyWith({String? name, String? day, String? time, String? location}) =>
      ScheduleItem(
        id: id,
        name: name ?? this.name,
        day: day ?? this.day,
        time: time ?? this.time,
        location: location ?? this.location,
      );

  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
        id: j['id']?.toString() ?? _uuid.v4(),
        name: j['name'],
        day: j['day'],
        time: j['time'],
        location: j['location'] ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'day': day, 'time': time, 'location': location};
}

// ── Note ──────────────────────────────────────────────────────────
class Note {
  final String id;
  final String title;
  final String content;
  final String branch;
  final DateTime date;

  Note({
    String? id,
    required this.title,
    required this.content,
    required this.branch,
    DateTime? date,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id']?.toString() ?? _uuid.v4(),
        title: j['title'],
        content: j['content'],
        branch: j['branch'] ?? 'general',
        date: j['date'] != null ? DateTime.tryParse(j['date']) ?? DateTime.now() : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'branch': branch,
        'date': date.toIso8601String(),
      };
}

// ── Grade mappings ────────────────────────────────────────────────
const Map<String, double> gradeValues = {
  'A (4.0)': 4.0,
  'A- (3.7)': 3.7,
  'B+ (3.3)': 3.3,
  'B (3.0)': 3.0,
  'B- (2.7)': 2.7,
  'C+ (2.3)': 2.3,
  'C (2.0)': 2.0,
  'C- (1.7)': 1.7,
  'D+ (1.3)': 1.3,
  'D (1.0)': 1.0,
  'F (0.0)': 0.0,
};

const List<String> weekDays = [
  'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
];

const List<String> noteBranches = [
  'electricity', 'motion', 'energy', 'fluids', 'materials', 'thermo', 'general'
];

const Map<String, String> branchLabels = {
  'electricity': '⚡ Electricity',
  'motion': '🚀 Motion',
  'energy': '💡 Energy',
  'fluids': '💧 Fluids',
  'materials': '🔧 Materials',
  'thermo': '🔥 Thermo',
  'general': '📚 General',
};
