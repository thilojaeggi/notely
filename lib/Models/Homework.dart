class Homework {
  final String id;
  final String lessonName;
  final String title;
  final String details;
  final DateTime dueDate;
  final bool isDone;

  Homework({
    required this.id,
    required this.lessonName,
    required this.title,
    required this.details,
    required this.dueDate,
    required this.isDone,
  });

  Homework copyWith({
    String? id,
    String? lessonName,
    String? title,
    String? details,
    DateTime? dueDate,
    bool? isDone,
  }) {
    return Homework(
      id: id ?? this.id,
      lessonName: lessonName ?? this.lessonName,
      title: title ?? this.title,
      details: details ?? this.details,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lesson_name': lessonName,
      'title': title,
      'details': details,
      'due_date': dueDate.toIso8601String(),
      'is_done': isDone ? 1 : 0,
    };
  }

  static Homework fromMap(Map<String, dynamic> map) {
    return Homework(
      id: map['id'] as String,
      lessonName: map['lesson_name'] as String,
      title: map['title'] as String,
      details: map['details'] as String,
      dueDate: DateTime.parse(
        map['due_date'] as String,
      ),
      isDone: (map['is_done'] as int) == 1,
    );
  }
}
