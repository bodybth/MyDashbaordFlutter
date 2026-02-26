import 'package:flutter_test/flutter_test.dart';
import 'package:my_dashboard/models/models.dart';

void main() {
  group('Assignment model', () {
    test('creates with defaults', () {
      final a = Assignment(
        name: 'Test', course: 'Physics',
        dueDate: DateTime(2026, 3, 1), priority: 'High',
      );
      expect(a.completed, false);
      expect(a.inProgress, false);
      expect(a.details, '');
    });

    test('serializes and deserializes correctly', () {
      final a = Assignment(
        id: 'abc',
        name: 'Lab Report', course: 'EE101',
        dueDate: DateTime(2026, 4, 15), priority: 'Urgent',
        inProgress: true, details: 'Write 5 pages',
      );
      final json = a.toJson();
      final restored = Assignment.fromJson(json);
      expect(restored.id, 'abc');
      expect(restored.name, 'Lab Report');
      expect(restored.inProgress, true);
      expect(restored.details, 'Write 5 pages');
    });

    test('copyWith preserves fields', () {
      final a = Assignment(
        name: 'HW1', course: 'Math', dueDate: DateTime(2026, 3, 10), priority: 'Low',
      );
      final b = a.copyWith(completed: true);
      expect(b.completed, true);
      expect(b.name, 'HW1');
    });
  });

  group('Collection model', () {
    test('creates and serializes', () {
      final col = Collection(id: 'c1', title: 'My Formulas', emoji: '📐', type: 'formula');
      final json = col.toJson();
      final restored = Collection.fromJson(json);
      expect(restored.title, 'My Formulas');
      expect(restored.type, 'formula');
    });
  });

  group('Formula model', () {
    test('default formulas are loaded', () {
      expect(defaultFormulas.isNotEmpty, true);
      expect(defaultFormulas.first.isCustom, false);
    });
  });

  group('ScheduleItem model', () {
    test('time parsing', () {
      final item = ScheduleItem(name: 'Math', day: 'Monday', time: '09:30', location: 'Room 101');
      final json = item.toJson();
      final r = ScheduleItem.fromJson(json);
      expect(r.time, '09:30');
      expect(r.day, 'Monday');
    });
  });
}
