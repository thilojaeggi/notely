class Exam {
  String? _id;
  String? _startDate;
  String? _endDate;
  String? _text;
  Null? _comment;
  Null? _roomToken;
  Null? _roomId;
  Null? _teachers;
  Null? _teacherIds;
  Null? _teacherTokens;
  String? _courseId;
  String? _courseToken;
  String? _courseName;
  Null? _status;
  Null? _color;
  String? _eventType;
  Null? _eventRoomStatus;
  Null? _timetableText;
  Null? _infoFacilityManagement;
  Null? _importset;
  Null? _lessons;
  Null? _publishToInfoSystem;
  Null? _studentNames;
  Null? _studentIds;

  Exam(
      {String? id,
      String? startDate,
      String? endDate,
      String? text,
      Null? comment,
      Null? roomToken,
      Null? roomId,
      Null? teachers,
      Null? teacherIds,
      Null? teacherTokens,
      String? courseId,
      String? courseToken,
      String? courseName,
      Null? status,
      Null? color,
      String? eventType,
      Null? eventRoomStatus,
      Null? timetableText,
      Null? infoFacilityManagement,
      Null? importset,
      Null? lessons,
      Null? publishToInfoSystem,
      Null? studentNames,
      Null? studentIds}) {
    if (id != null) {
      this._id = id;
    }
    if (startDate != null) {
      this._startDate = startDate;
    }
    if (endDate != null) {
      this._endDate = endDate;
    }
    if (text != null) {
      this._text = text;
    }
    if (comment != null) {
      this._comment = comment;
    }
    if (roomToken != null) {
      this._roomToken = roomToken;
    }
    if (roomId != null) {
      this._roomId = roomId;
    }
    if (teachers != null) {
      this._teachers = teachers;
    }
    if (teacherIds != null) {
      this._teacherIds = teacherIds;
    }
    if (teacherTokens != null) {
      this._teacherTokens = teacherTokens;
    }
    if (courseId != null) {
      this._courseId = courseId;
    }
    if (courseToken != null) {
      this._courseToken = courseToken;
    }
    if (courseName != null) {
      this._courseName = courseName;
    }
    if (status != null) {
      this._status = status;
    }
    if (color != null) {
      this._color = color;
    }
    if (eventType != null) {
      this._eventType = eventType;
    }
    if (eventRoomStatus != null) {
      this._eventRoomStatus = eventRoomStatus;
    }
    if (timetableText != null) {
      this._timetableText = timetableText;
    }
    if (infoFacilityManagement != null) {
      this._infoFacilityManagement = infoFacilityManagement;
    }
    if (importset != null) {
      this._importset = importset;
    }
    if (lessons != null) {
      this._lessons = lessons;
    }
    if (publishToInfoSystem != null) {
      this._publishToInfoSystem = publishToInfoSystem;
    }
    if (studentNames != null) {
      this._studentNames = studentNames;
    }
    if (studentIds != null) {
      this._studentIds = studentIds;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get startDate => _startDate;
  set startDate(String? startDate) => _startDate = startDate;
  String? get endDate => _endDate;
  set endDate(String? endDate) => _endDate = endDate;
  String? get text => _text;
  set text(String? text) => _text = text;
  Null? get comment => _comment;
  set comment(Null? comment) => _comment = comment;
  Null? get roomToken => _roomToken;
  set roomToken(Null? roomToken) => _roomToken = roomToken;
  Null? get roomId => _roomId;
  set roomId(Null? roomId) => _roomId = roomId;
  Null? get teachers => _teachers;
  set teachers(Null? teachers) => _teachers = teachers;
  Null? get teacherIds => _teacherIds;
  set teacherIds(Null? teacherIds) => _teacherIds = teacherIds;
  Null? get teacherTokens => _teacherTokens;
  set teacherTokens(Null? teacherTokens) => _teacherTokens = teacherTokens;
  String? get courseId => _courseId;
  set courseId(String? courseId) => _courseId = courseId;
  String? get courseToken => _courseToken;
  set courseToken(String? courseToken) => _courseToken = courseToken;
  String? get courseName => _courseName;
  set courseName(String? courseName) => _courseName = courseName;
  Null? get status => _status;
  set status(Null? status) => _status = status;
  Null? get color => _color;
  set color(Null? color) => _color = color;
  String? get eventType => _eventType;
  set eventType(String? eventType) => _eventType = eventType;
  Null? get eventRoomStatus => _eventRoomStatus;
  set eventRoomStatus(Null? eventRoomStatus) =>
      _eventRoomStatus = eventRoomStatus;
  Null? get timetableText => _timetableText;
  set timetableText(Null? timetableText) => _timetableText = timetableText;
  Null? get infoFacilityManagement => _infoFacilityManagement;
  set infoFacilityManagement(Null? infoFacilityManagement) =>
      _infoFacilityManagement = infoFacilityManagement;
  Null? get importset => _importset;
  set importset(Null? importset) => _importset = importset;
  Null? get lessons => _lessons;
  set lessons(Null? lessons) => _lessons = lessons;
  Null? get publishToInfoSystem => _publishToInfoSystem;
  set publishToInfoSystem(Null? publishToInfoSystem) =>
      _publishToInfoSystem = publishToInfoSystem;
  Null? get studentNames => _studentNames;
  set studentNames(Null? studentNames) => _studentNames = studentNames;
  Null? get studentIds => _studentIds;
  set studentIds(Null? studentIds) => _studentIds = studentIds;

  Exam.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _startDate = json['startDate'];
    _endDate = json['endDate'];
    _text = json['text'];
    _comment = json['comment'];
    _roomToken = json['roomToken'];
    _roomId = json['roomId'];
    _teachers = json['teachers'];
    _teacherIds = json['teacherIds'];
    _teacherTokens = json['teacherTokens'];
    _courseId = json['courseId'];
    _courseToken = json['courseToken'];
    _courseName = json['courseName'];
    _status = json['status'];
    _color = json['color'];
    _eventType = json['eventType'];
    _eventRoomStatus = json['eventRoomStatus'];
    _timetableText = json['timetableText'];
    _infoFacilityManagement = json['infoFacilityManagement'];
    _importset = json['importset'];
    _lessons = json['lessons'];
    _publishToInfoSystem = json['publishToInfoSystem'];
    _studentNames = json['studentNames'];
    _studentIds = json['studentIds'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this._id;
    data['startDate'] = this._startDate;
    data['endDate'] = this._endDate;
    data['text'] = this._text;
    data['comment'] = this._comment;
    data['roomToken'] = this._roomToken;
    data['roomId'] = this._roomId;
    data['teachers'] = this._teachers;
    data['teacherIds'] = this._teacherIds;
    data['teacherTokens'] = this._teacherTokens;
    data['courseId'] = this._courseId;
    data['courseToken'] = this._courseToken;
    data['courseName'] = this._courseName;
    data['status'] = this._status;
    data['color'] = this._color;
    data['eventType'] = this._eventType;
    data['eventRoomStatus'] = this._eventRoomStatus;
    data['timetableText'] = this._timetableText;
    data['infoFacilityManagement'] = this._infoFacilityManagement;
    data['importset'] = this._importset;
    data['lessons'] = this._lessons;
    data['publishToInfoSystem'] = this._publishToInfoSystem;
    data['studentNames'] = this._studentNames;
    data['studentIds'] = this._studentIds;
    return data;
  }
}
