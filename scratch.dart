void main() {
  final text = """Day 1 - Chest Arms
[CORE]
Decline Crunch 15 15 15(3)

Day 2: Back
[BACK]
Pull Ups 6 6 6(3)

### Day 3 - Shoulders Arms
[SHOULDERS]
Shoulder Press 6 6 6(3)
""";

  // Allow any characters after the day number until the end of the line
  final dayRegex = RegExp(r'((?:^|\n)(?:#+\s*)?(?:\*\*|__)?(?:day\s+\d+|\d+(?:st|nd|rd|th|d)?\s+day)(?:\*\*|__)?[^\n]*(?:\n|$))', caseSensitive: false);
  
  final matches = dayRegex.allMatches(text).toList();
  print("Matches found: \${matches.length}");
  for (var m in matches) {
    print("Match: '\${m.group(1)}'");
  }
}
