class Absence {
  String? _id;
  String? _studentId;
  String? _date;
  String? _hourFrom;
  String? _hourTo;
  String? _status;
  String? _comment;
  bool? _isExamLesson;
  String? _profile;
  String? _course;
  String? _absenceId;

  Absence(
      {String? id,
      String? studentId,
      String? date,
      String? hourFrom,
      String? hourTo,
      String? status,
      String? comment,
      bool? isExamLesson,
      String? profile,
      String? course,
      String? absenceId}) {
    if (id != null) {
      _id = id;
    }
    if (studentId != null) {
      _studentId = studentId;
    }
    if (date != null) {
      _date = date;
    }
    if (hourFrom != null) {
      _hourFrom = hourFrom;
    }
    if (hourTo != null) {
      _hourTo = hourTo;
    }
    if (status != null) {
      _status = status;
    }
    if (comment != null) {
      _comment = comment;
    }
    if (isExamLesson != null) {
      _isExamLesson = isExamLesson;
    }
    if (profile != null) {
      _profile = profile;
    }
    if (course != null) {
      _course = course;
    }
    if (absenceId != null) {
      _absenceId = absenceId;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get studentId => _studentId;
  set studentId(String? studentId) => _studentId = studentId;
  String? get date => _date;
  set date(String? date) => _date = date;
  String? get hourFrom => _hourFrom;
  set hourFrom(String? hourFrom) => _hourFrom = hourFrom;
  String? get hourTo => _hourTo;
  set hourTo(String? hourTo) => _hourTo = hourTo;
  String? get status => _status;
  set status(String? status) => _status = status;
  String? get comment => _comment;
  set comment(String? comment) => _comment = comment;
  bool? get isExamLesson => _isExamLesson;
  set isExamLesson(bool? isExamLesson) => _isExamLesson = isExamLesson;
  String? get profile => _profile;
  set profile(String? profile) => _profile = profile;
  String? get course => _course;
  set course(String? course) => _course = course;
  String? get absenceId => _absenceId;
  set absenceId(String? absenceId) => _absenceId = absenceId;

  Absence.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _studentId = json['studentId'];
    _date = json['date'];
    _hourFrom = json['hourFrom'];
    _hourTo = json['hourTo'];
    _status = json['status'];
    _comment = json['comment'];
    _isExamLesson = json['isExamLesson'];
    _profile = json['profile'];
    _course = json['course'];
    _absenceId = json['absenceId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = _id;
    data['studentId'] = _studentId;
    data['date'] = _date;
    data['hourFrom'] = _hourFrom;
    data['hourTo'] = _hourTo;
    data['status'] = _status;
    data['comment'] = _comment;
    data['isExamLesson'] = _isExamLesson;
    data['profile'] = _profile;
    data['course'] = _course;
    data['absenceId'] = _absenceId;
    return data;
  }
}
