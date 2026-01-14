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
    date = json['date'];
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
    data['date'] = date;
    data['mark'] = mark;
    data['weight'] = weight;
    data['isConfirmed'] = isConfirmed;
    return data;
  }
}
