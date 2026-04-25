class Grade {
  final String? id;
  final String? course;
  final String? subject;
  final String? title;
  final DateTime? date;
  final num? mark;
  final num? weight;
  final bool isIgnored;

  const Grade(
      {this.id,
      this.course,
      this.subject,
      this.title,
      this.date,
      this.mark,
      this.weight,
      this.isIgnored = false});

  factory Grade.fromJson(Map<String, dynamic> json) {
    if (json['id'].runtimeType == int) {
      json['id'] = json['id'].toString();
    }
    return Grade(
        id: json['id'],
        course: json['course'],
        subject: json['subject'],
        title: json['title'],
        date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
        mark: json['mark'],
        weight: json['weight'],
        isIgnored: json['isIgnored'] ?? false);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['course'] = course;
    data['subject'] = subject;
    data['title'] = title;
    data['date'] = date?.toIso8601String(); // format date to iso8601
    data['mark'] = mark;
    data['weight'] = weight;
    data['isIgnored'] = isIgnored;
    return data;
  }
}
