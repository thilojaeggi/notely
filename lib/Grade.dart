class Grade {
  String? _id;
  String? _course;
  String? _courseType;
  String? _subject;
  String? _subjectToken;
  String? _title;
  String? _date;
  num? _mark;
  num? _weight;
  bool? _isConfirmed;

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
      this._id = id;
    }
    if (course != null) {
      this._course = course;
    }
    if (courseType != null) {
      this._courseType = courseType;
    }
    if (subject != null) {
      this._subject = subject;
    }
    if (subjectToken != null) {
      this._subjectToken = subjectToken;
    }
    if (title != null) {
      this._title = title;
    }
    if (date != null) {
      this._date = date;
    }
    if (mark != null) {
      this._mark = mark;
    }
    if (weight != null) {
      this._weight = weight;
    }
    if (isConfirmed != null) {
      this._isConfirmed = isConfirmed;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get course => _course;
  set course(String? course) => _course = course;
  String? get courseType => _courseType;
  set courseType(String? courseType) => _courseType = courseType;
  String? get subject => _subject;
  set subject(String? subject) => _subject = subject;
  String? get subjectToken => _subjectToken;
  set subjectToken(String? subjectToken) => _subjectToken = subjectToken;
  String? get title => _title;
  set title(String? title) => _title = title;
  String? get date => _date;
  set date(String? date) => _date = date;
  num? get mark => _mark;
  set mark(num? mark) => _mark = mark;
  num? get weight => _weight;
  set weight(num? weight) => _weight = weight;
  bool? get isConfirmed => _isConfirmed;
  set isConfirmed(bool? isConfirmed) => _isConfirmed = isConfirmed;

  Grade.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _course = json['course'];
    _courseType = json['courseType'];
    _subject = json['subject'];
    _subjectToken = json['subjectToken'];
    _title = json['title'];
    _date = json['date'];
    _mark = json['mark'];
    _weight = json['weight'];
    _isConfirmed = json['isConfirmed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this._id;
    data['course'] = this._course;
    data['courseType'] = this._courseType;
    data['subject'] = this._subject;
    data['subjectToken'] = this._subjectToken;
    data['title'] = this._title;
    data['date'] = this._date;
    data['mark'] = this._mark;
    data['weight'] = this._weight;
    data['isConfirmed'] = this._isConfirmed;
    return data;
  }
}
