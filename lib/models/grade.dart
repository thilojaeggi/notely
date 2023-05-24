class Grade {
  String? id;
  String? course;
  String? courseType;
  String? subject;
  String? subjectToken;
  String? title;
  String? date;
  num? mark;
  num? weight;
  bool? isConfirmed;

  Grade(
      {String? id,
      String? course,
      String? courseType,
      String? subject,
      String? subjectToken,
      String? title,
      String? date,
      num? mark,
      num? weight,
      bool? isConfirmed}) {
    if (id != null) {
      id = id;
    }
    if (course != null) {
      course = course;
    }
    if (courseType != null) {
      courseType = courseType;
    }
    if (subject != null) {
      subject = subject;
    }
    if (subjectToken != null) {
      subjectToken = subjectToken;
    }
    if (title != null) {
      title = title;
    }
    if (date != null) {
      date = date;
    }
    if (mark != null) {
      mark = mark;
    }
    if (weight != null) {
      weight = weight;
    }
    if (isConfirmed != null) {
      isConfirmed = isConfirmed;
    }
  }

  Grade.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    course = json['course'];
    courseType = json['courseType'];
    subject = json['subject'];
    subjectToken = json['subjectToken'];
    title = json['title'];
    date = json['date'];
    mark = json['mark'];
    weight = json['weight'];
    isConfirmed = json['isConfirmed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['course'] = course;
    data['courseType'] = courseType;
    data['subject'] = subject;
    data['subjectToken'] = subjectToken;
    data['title'] = title;
    data['date'] = date;
    data['mark'] = mark;
    data['weight'] = weight;
    data['isConfirmed'] = isConfirmed;
    return data;
  }
}
