import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker_app/services/workout_parser.dart';

void main() {
  test('Workout Parser should correctly parse the user schedule', () {
    const text = """
3 days workout plan new

1st day

B/b flat bench press 10(2) 8(2)
D/b hammer rotation press 10(3) 8
Incline cabel flys 12(3)

2nd day

Narro Mac grip lat pull 12 10(2) 8
Wide grip cabel row 10(2) 8(2)
""";

    final schedule = WorkoutParser.parse(text, 'Test Schedule');

    expect(schedule.templates.length, 2);
    final workouts = schedule.templates;
    expect(workouts[0].name, contains('1st day'));
    expect(workouts[0].targetMuscleGroups, containsAll(['Chest', 'Shoulders']));
    expect(workouts[0].exercises.length, 3);
    
    // B/b flat bench press 10(2) 8(2) -> 4 sets
    expect(workouts[0].exercises[0].name, 'B/b flat bench press');
    expect(workouts[0].exercises[0].targetReps.length, 4);
    expect(workouts[0].exercises[0].targetReps, [10, 10, 8, 8]);

    // D/b hammer rotation press 10(3) 8 -> 4 sets
    expect(workouts[0].exercises[1].name, 'D/b hammer rotation press');
    expect(workouts[0].exercises[1].targetReps, [10, 10, 10, 8]);

    // Incline cabel flys 12(3)
    expect(workouts[0].exercises[2].name, 'Incline cabel flys');
    expect(workouts[0].exercises[2].targetReps, [12, 12, 12]);

    // 2nd day
    expect(workouts[1].name, contains('2nd day'));
    expect(workouts[1].targetMuscleGroups, containsAll(['Back']));
    // Narro Mac grip lat pull 12 10(2) 8 -> 12, 10, 10, 8
    expect(workouts[1].exercises[0].name, 'Narro Mac grip lat pull');
    expect(workouts[1].exercises[0].targetReps, [12, 10, 10, 8]);
  });

  test('Workout Parser should correctly parse and clean asterisks from AI formatting', () {
    const text = """
3 days workout plan new

*1st day*

**B/b flat bench press** 10(2) 8(2)
*D/b hammer rotation press* 10(3) 8
*Incline cabel flys* 12(3)

**2nd day**

*Narro Mac grip lat pull* 12 10(2) 8
*Wide grip cabel row* 10(2) 8(2)
""";

    final schedule = WorkoutParser.parse(text, 'Test Schedule');

    expect(schedule.templates.length, 2);
    final workouts = schedule.templates;
    expect(workouts[0].name, '1st day');
    expect(workouts[0].exercises[0].name, 'B/b flat bench press');
    
    expect(workouts[1].name, '2nd day');
    expect(workouts[1].exercises[0].name, 'Narro Mac grip lat pull');
  });
}
