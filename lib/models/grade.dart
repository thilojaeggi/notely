class Grade {
  String? id;
  String? course;
  String? courseType;
  String? subject;
  String? subjectToken;
  String? title;
  DateTime? date;
  num? mark;
  num? weight;
  bool? isConfirmed;

  Grade(
      {this.id,
      this.course,
      this.courseType,
      this.subject,
      this.subjectToken,
      this.title,
      this.date,
      this.mark,
      this.weight,
      this.isConfirmed});

  Grade.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    course = json['course'];
    courseType = json['courseType'];
    subject = json['subject'];
    subjectToken = json['subjectToken'];
    title = json['title'];
    date = json['date'] != null ? DateTime.tryParse(json['date']) : null;
    mark = json['mark'];
    weight = json['weight'];
    isConfirmed = json['isConfirmed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['course'] = course;
    data['courseType'] = courseType;
    data['subject'] = subject;
    data['subjectToken'] = subjectToken;
    data['title'] = title;
    data['date'] =
        date?.toIso8601String(); // format: yyyy-MM-ddTHH:mm:ss.mmmuuu
    // if the API expects just date, this might include time, but usually fine for ISO parsers.
    // If stricly needed YYYY-MM-DD we can adjust.
    // Given the user request "store as datetime", keeping precision is usually safe unless sending back to strict API.
    // The toJson is often used for caching here (shared_preferences).
    data['mark'] = mark;
    data['weight'] = weight;
    data['isConfirmed'] = isConfirmed;
    return data;
  }
}
