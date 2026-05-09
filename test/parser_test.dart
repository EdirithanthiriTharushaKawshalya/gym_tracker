import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/services/workout_parser.dart';

void main() {
  test('Workout Parser should handle complex AI Markdown format', () {
    const text = """
Here is your professionalized workout schedule.

## **8-Week Max Weight Training Plan**

---

### **Day 1**

**[CHEST]**

* Pec Flys 12(3)
* Dumbbell Press 10(3) 8

**[TRICEPS]**

* Rope Press Down 12 10 8(2)

---

### **Day 2**

**[BACK]**

* Mag Grip Lat Pulldown 12 10(2) 8

> **Coach's Note:** Good luck.
""";

    final schedule = WorkoutParser.parse(text, 'Test Schedule');

    expect(schedule.templates.length, 2);
    expect(schedule.templates[0].name, 'Day 1');
    expect(schedule.templates[0].exercises.length, 3);
    expect(schedule.templates[0].exercises[0].name, 'Pec Flys');
    expect(schedule.templates[0].exercises[0].category, 'Chest'); // Normalized to Title Case
    
    expect(schedule.templates[1].name, 'Day 2');
    expect(schedule.templates[1].exercises[0].name, 'Mag Grip Lat Pulldown');
    expect(schedule.templates[1].exercises[0].category, 'Back'); // Normalized to Title Case
  });
}
