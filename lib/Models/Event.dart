class Event {
  String? _id;
  String? _startDate;
  String? _endDate;
  String? _text;
  String? _comment;
  String? _roomToken;
  String? _roomId;
  List<String>? _teachers;
  List<String>? _teacherIds;
  List<String>? _teacherTokens;
  String? _courseId;
  String? _courseToken;
  String? _courseName;
  String? _status;
  String? _color;
  String? _eventType;
  Null? _eventRoomStatus;
  Null? _timetableText;
  Null? _infoFacilityManagement;
  Null? _importset;
  Null? _lessons;
  Null? _publishToInfoSystem;
  Null? _studentNames;
  Null? _studentIds;

  Event(
      {String? id,
      String? startDate,
      String? endDate,
      String? text,
      String? comment,
      String? roomToken,
      String? roomId,
      List<String>? teachers,
      List<String>? teacherIds,
      List<String>? teacherTokens,
      String? courseId,
      String? courseToken,
      String? courseName,
      String? status,
      String? color,
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
  String? get comment => _comment;
  set comment(String? comment) => _comment = comment;
  String? get roomToken => _roomToken;
  set roomToken(String? roomToken) => _roomToken = roomToken;
  String? get roomId => _roomId;
  set roomId(String? roomId) => _roomId = roomId;
  List<String>? get teachers => _teachers;
  set teachers(List<String>? teachers) => _teachers = teachers;
  List<String>? get teacherIds => _teacherIds;
  set teacherIds(List<String>? teacherIds) => _teacherIds = teacherIds;
  List<String>? get teacherTokens => _teacherTokens;
  set teacherTokens(List<String>? teacherTokens) =>
      _teacherTokens = teacherTokens;
  String? get courseId => _courseId;
  set courseId(String? courseId) => _courseId = courseId;
  String? get courseToken => _courseToken;
  set courseToken(String? courseToken) => _courseToken = courseToken;
  String? get courseName => _courseName;
  set courseName(String? courseName) => _courseName = courseName;
  String? get status => _status;
  set status(String? status) => _status = status;
  String? get color => _color;
  set color(String? color) => _color = color;
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

  Event.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _startDate = json['startDate'];
    _endDate = json['endDate'];
    _text = json['text'];
    _comment = json['comment'];
    _roomToken = json['roomToken'];
    _roomId = json['roomId'];
    _teachers = json['teachers'].cast<String>();
    _teacherIds = json['teacherIds'].cast<String>();
    _teacherTokens = json['teacherTokens'].cast<String>();
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
