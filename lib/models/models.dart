import 'package:uuid/uuid.dart';
const _uuid = Uuid();

// ── Attachment ────────────────────────────────────────────────────
class NoteAttachment {
  final String id, name, type, localPath; // type: 'image' | 'pdf'
  NoteAttachment({String? id, required this.name, required this.type, required this.localPath})
      : id = id ?? _uuid.v4();
  factory NoteAttachment.fromJson(Map<String, dynamic> j) => NoteAttachment(
      id: j['id'] ?? _uuid.v4(), name: j['name'], type: j['type'], localPath: j['localPath']);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type, 'localPath': localPath};
}

// ── Course ────────────────────────────────────────────────────────
class Course {
  final String id, name;
  final double grade;
  final int credits;
  Course({String? id, required this.name, required this.grade, required this.credits}) : id = id ?? _uuid.v4();
  factory Course.fromJson(Map<String, dynamic> j) => Course(id: j['id'] ?? _uuid.v4(), name: j['name'], grade: (j['grade'] as num).toDouble(), credits: j['credits'] as int);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'grade': grade, 'credits': credits};
}

// ── Assignment ────────────────────────────────────────────────────
class Assignment {
  final String id, name, course;
  final String? details;
  final DateTime dueDate;
  final String priority;
  final bool completed;
  final DateTime? reminderTime;
  Assignment({String? id, required this.name, required this.course, this.details,
      required this.dueDate, required this.priority, this.completed = false, this.reminderTime})
      : id = id ?? _uuid.v4();
  Assignment copyWith({bool? completed, DateTime? reminderTime, String? details}) => Assignment(
      id: id, name: name, course: course, details: details ?? this.details,
      dueDate: dueDate, priority: priority,
      completed: completed ?? this.completed, reminderTime: reminderTime ?? this.reminderTime);
  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
      id: j['id'] ?? _uuid.v4(), name: j['name'], course: j['course'], details: j['details'],
      dueDate: DateTime.parse(j['due']), priority: j['priority'],
      completed: j['completed'] ?? false,
      reminderTime: j['reminderTime'] != null ? DateTime.tryParse(j['reminderTime']) : null);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'course': course, 'details': details,
      'due': dueDate.toIso8601String(), 'priority': priority, 'completed': completed,
      'reminderTime': reminderTime?.toIso8601String()};
}

// ── ScheduleItem ──────────────────────────────────────────────────
class ScheduleItem {
  final String id, name, day, time, location;
  ScheduleItem({String? id, required this.name, required this.day, required this.time, required this.location}) : id = id ?? _uuid.v4();
  ScheduleItem copyWith({String? name, String? day, String? time, String? location}) =>
      ScheduleItem(id: id, name: name ?? this.name, day: day ?? this.day, time: time ?? this.time, location: location ?? this.location);
  factory ScheduleItem.fromJson(Map<String, dynamic> j) => ScheduleItem(
      id: j['id']?.toString() ?? _uuid.v4(), name: j['name'], day: j['day'], time: j['time'], location: j['location'] ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'day': day, 'time': time, 'location': location};
}

// ── Note ──────────────────────────────────────────────────────────
class Note {
  final String id, title, content, branch;
  final DateTime date;
  final List<NoteAttachment> attachments;

  Note({String? id, required this.title, required this.content, required this.branch,
      DateTime? date, List<NoteAttachment>? attachments})
      : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now(),
        attachments = attachments ?? [];

  Note copyWith({String? title, String? content, String? branch, List<NoteAttachment>? attachments}) =>
      Note(id: id, title: title ?? this.title, content: content ?? this.content,
          branch: branch ?? this.branch, date: date, attachments: attachments ?? this.attachments);

  factory Note.fromJson(Map<String, dynamic> j) => Note(
      id: j['id']?.toString() ?? _uuid.v4(),
      title: j['title'], content: j['content'],
      branch: j['branch'] ?? 'general',
      date: j['date'] != null ? DateTime.tryParse(j['date']) ?? DateTime.now() : DateTime.now(),
      attachments: j['attachments'] != null
          ? (j['attachments'] as List).map((a) => NoteAttachment.fromJson(a)).toList()
          : []);

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'content': content, 'branch': branch,
    'date': date.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };
}

// ── Formula ───────────────────────────────────────────────────────
class Formula {
  final String id, name, formula, desc, category;
  final bool isCustom;
  Formula({String? id, required this.name, required this.formula, required this.desc, required this.category, this.isCustom = false})
      : id = id ?? _uuid.v4();
  Formula copyWith({String? name, String? formula, String? desc, String? category}) =>
      Formula(id: id, name: name ?? this.name, formula: formula ?? this.formula,
          desc: desc ?? this.desc, category: category ?? this.category, isCustom: isCustom);
  factory Formula.fromJson(Map<String, dynamic> j) => Formula(
      id: j['id']?.toString() ?? _uuid.v4(), name: j['name'], formula: j['formula'],
      desc: j['desc'] ?? '', category: j['category'], isCustom: j['isCustom'] ?? true);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'formula': formula, 'desc': desc, 'category': category, 'isCustom': isCustom};
}

// ── AppCategory ───────────────────────────────────────────────────
class AppCategory {
  final String id, name, emoji;
  AppCategory({String? id, required this.name, required this.emoji}) : id = id ?? _uuid.v4();
  factory AppCategory.fromJson(Map<String, dynamic> j) => AppCategory(id: j['id'] ?? _uuid.v4(), name: j['name'], emoji: j['emoji'] ?? '📁');
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};
}

// ── Notebook ──────────────────────────────────────────────────────
class Notebook {
  final String id, title, emoji, type;
  final DateTime createdAt;
  Notebook({String? id, required this.title, required this.emoji, this.type = 'notes', DateTime? createdAt})
      : id = id ?? _uuid.v4(), createdAt = createdAt ?? DateTime.now();
  factory Notebook.fromJson(Map<String, dynamic> j) => Notebook(
      id: j['id'] ?? _uuid.v4(), title: j['title'], emoji: j['emoji'] ?? '📓',
      type: j['type'] ?? 'notes',
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt']) ?? DateTime.now() : DateTime.now());
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'emoji': emoji, 'type': type, 'createdAt': createdAt.toIso8601String()};
}

// ── Static data ───────────────────────────────────────────────────
const Map<String, double> gradeValues = {
  'A (4.0)': 4.0, 'A- (3.7)': 3.7, 'B+ (3.3)': 3.3, 'B (3.0)': 3.0,
  'B- (2.7)': 2.7, 'C+ (2.3)': 2.3, 'C (2.0)': 2.0, 'C- (1.7)': 1.7,
  'D+ (1.3)': 1.3, 'D (1.0)': 1.0, 'F (0.0)': 0.0,
};
const List<String> weekDays = ['Saturday','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday'];

final List<AppCategory> defaultNoteCategories = [
  AppCategory(id: 'electricity', name: 'Electricity', emoji: '⚡'),
  AppCategory(id: 'motion', name: 'Motion', emoji: '🚀'),
  AppCategory(id: 'energy', name: 'Energy', emoji: '💡'),
  AppCategory(id: 'fluids', name: 'Fluids', emoji: '💧'),
  AppCategory(id: 'materials', name: 'Materials', emoji: '🔧'),
  AppCategory(id: 'thermo', name: 'Thermo', emoji: '🔥'),
  AppCategory(id: 'general', name: 'General', emoji: '📚'),
];
final List<AppCategory> defaultFormulaCategories = [
  AppCategory(id: 'electricity', name: 'Electricity', emoji: '⚡'),
  AppCategory(id: 'motion', name: 'Motion', emoji: '🚀'),
  AppCategory(id: 'energy', name: 'Energy', emoji: '💡'),
  AppCategory(id: 'fluids', name: 'Fluids', emoji: '💧'),
  AppCategory(id: 'materials', name: 'Materials', emoji: '🔧'),
  AppCategory(id: 'thermo', name: 'Thermo', emoji: '🔥'),
];
final List<AppCategory> defaultPriorities = [
  AppCategory(id: 'low', name: 'Low', emoji: '🟢'),
  AppCategory(id: 'medium', name: 'Medium', emoji: '🔵'),
  AppCategory(id: 'high', name: 'High', emoji: '🟠'),
  AppCategory(id: 'urgent', name: 'Urgent', emoji: '🔴'),
];
final List<Formula> defaultFormulas = [
  Formula(id:'f1', name:"Ohm's Law", formula:'V = IR', desc:'Voltage = Current × Resistance', category:'electricity', isCustom:false),
  Formula(id:'f2', name:'Power', formula:'P = VI = I²R = V²/R', desc:'Electrical power', category:'electricity', isCustom:false),
  Formula(id:'f3', name:'Capacitance', formula:'Q = CV', desc:'Charge = Capacitance × Voltage', category:'electricity', isCustom:false),
  Formula(id:'f4', name:'Electric Field', formula:'E = F/q = V/d', desc:'Electric field strength', category:'electricity', isCustom:false),
  Formula(id:'f5', name:'Resistors Series', formula:'R = R₁ + R₂ + R₃', desc:'Total resistance in series', category:'electricity', isCustom:false),
  Formula(id:'f6', name:'Resistors Parallel', formula:'1/R = 1/R₁ + 1/R₂', desc:'Total resistance in parallel', category:'electricity', isCustom:false),
  Formula(id:'f7', name:'Velocity', formula:'v = u + at', desc:'Final velocity with acceleration', category:'motion', isCustom:false),
  Formula(id:'f8', name:'Displacement', formula:'s = ut + ½at²', desc:'Distance traveled', category:'motion', isCustom:false),
  Formula(id:'f9', name:'Velocity²', formula:'v² = u² + 2as', desc:'Velocity-displacement relation', category:'motion', isCustom:false),
  Formula(id:'f10', name:"Newton's 2nd Law", formula:'F = ma', desc:'Force = mass × acceleration', category:'motion', isCustom:false),
  Formula(id:'f11', name:'Momentum', formula:'p = mv', desc:'Momentum = mass × velocity', category:'motion', isCustom:false),
  Formula(id:'f12', name:'Centripetal Force', formula:'F = mv²/r', desc:'Force toward center of circle', category:'motion', isCustom:false),
  Formula(id:'f13', name:'Kinetic Energy', formula:'KE = ½mv²', desc:'Energy of motion', category:'energy', isCustom:false),
  Formula(id:'f14', name:'Potential Energy', formula:'PE = mgh', desc:'Gravitational potential energy', category:'energy', isCustom:false),
  Formula(id:'f15', name:'Work', formula:'W = Fd·cosθ', desc:'Work done by a force', category:'energy', isCustom:false),
  Formula(id:'f16', name:'Power (mech)', formula:'P = W/t = Fv', desc:'Rate of doing work', category:'energy', isCustom:false),
  Formula(id:'f17', name:'Efficiency', formula:'η = (useful/total) × 100%', desc:'Energy efficiency', category:'energy', isCustom:false),
  Formula(id:'f18', name:'Pressure', formula:'P = F/A', desc:'Force per unit area', category:'fluids', isCustom:false),
  Formula(id:'f19', name:'Fluid Pressure', formula:'P = ρgh', desc:'Pressure at depth h', category:'fluids', isCustom:false),
  Formula(id:'f20', name:'Continuity', formula:'A₁v₁ = A₂v₂', desc:'Conservation of flow rate', category:'fluids', isCustom:false),
  Formula(id:'f21', name:"Bernoulli's", formula:'P + ½ρv² + ρgh = const', desc:"Bernoulli's principle", category:'fluids', isCustom:false),
  Formula(id:'f22', name:'Buoyancy', formula:'F_b = ρVg', desc:'Archimedes principle', category:'fluids', isCustom:false),
  Formula(id:'f23', name:"Young's Modulus", formula:'E = σ/ε', desc:'Elastic modulus', category:'materials', isCustom:false),
  Formula(id:'f24', name:'Stress', formula:'σ = F/A', desc:'Force per unit area', category:'materials', isCustom:false),
  Formula(id:'f25', name:'Strain', formula:'ε = ΔL/L', desc:'Fractional change in length', category:'materials', isCustom:false),
  Formula(id:'f26', name:'Thermal Expansion', formula:'ΔL = αL₀ΔT', desc:'Change in length due to heat', category:'materials', isCustom:false),
  Formula(id:'f27', name:'Heat Transfer', formula:'Q = mcΔT', desc:'Heat = mass × specific heat × ΔT', category:'thermo', isCustom:false),
  Formula(id:'f28', name:'Ideal Gas Law', formula:'PV = nRT', desc:'Pressure × Volume = nRT', category:'thermo', isCustom:false),
  Formula(id:'f29', name:'1st Law Thermo', formula:'ΔU = Q - W', desc:'Change in internal energy', category:'thermo', isCustom:false),
  Formula(id:'f30', name:'Carnot Efficiency', formula:'η = 1 - T_c/T_h', desc:'Maximum heat engine efficiency', category:'thermo', isCustom:false),
  Formula(id:'f31', name:'Conduction', formula:'Q/t = kA(ΔT/d)', desc:'Rate of heat conduction', category:'thermo', isCustom:false),
];
