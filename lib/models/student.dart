DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String? _formatDate(DateTime? value) {
  if (value == null) return null;
  return value.toIso8601String().split('T').first;
}

List<RegularClass> _parseClasses(dynamic data) {
  if (data is List) {
    return data
        .whereType<Map<String, dynamic>>()
        .map(RegularClass.fromJson)
        .toList();
  }
  return <RegularClass>[];
}

class Student {
  const Student({
    required this.id,
    required this.userType,
    required this.idNr,
    required this.lastName,
    required this.firstName,
    required this.loginActive,
    this.gender,
    this.birthday,
    this.street,
    this.addressLine2,
    this.postOfficeBox,
    this.zip,
    this.city,
    this.nationality,
    this.hometown,
    this.phone,
    this.mobile,
    this.email,
    this.emailPrivate,
    this.profil1,
    this.profil2,
    this.entryDate,
    this.exitDate,
    required this.regularClasses,
    required this.additionalClasses,
  });

  final String id;
  final String userType;
  final String idNr;
  final String lastName;
  final String firstName;
  final bool loginActive;
  final String? gender;
  final DateTime? birthday;
  final String? street;
  final String? addressLine2;
  final String? postOfficeBox;
  final String? zip;
  final String? city;
  final String? nationality;
  final String? hometown;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? emailPrivate;
  final String? profil1;
  final String? profil2;
  final DateTime? entryDate;
  final DateTime? exitDate;
  final List<RegularClass> regularClasses;
  final List<RegularClass> additionalClasses;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json["id"] ?? '',
        userType: json["userType"] ?? '',
        idNr: json["idNr"] ?? '',
        lastName: json["lastName"] ?? '',
        firstName: json["firstName"] ?? '',
        loginActive: json["loginActive"] ?? false,
        gender: json["gender"],
        birthday: _tryParseDate(json["birthday"]),
        street: json["street"],
        addressLine2: json["addressLine2"],
        postOfficeBox: json["postOfficeBox"],
        zip: json["zip"],
        city: json["city"],
        nationality: json["nationality"],
        hometown: json["hometown"],
        phone: json["phone"],
        mobile: json["mobile"],
        email: json["email"],
        emailPrivate: json["emailPrivate"],
        profil1: json["profil1"],
        profil2: json["profil2"],
        entryDate: _tryParseDate(json["entryDate"]),
        exitDate: _tryParseDate(json["exitDate"]),
        regularClasses: _parseClasses(json["regularClasses"]),
        additionalClasses: _parseClasses(json["additionalClasses"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "userType": userType,
        "idNr": idNr,
        "lastName": lastName,
        "firstName": firstName,
        "loginActive": loginActive,
        "gender": gender,
        "birthday": _formatDate(birthday),
        "street": street,
        "addressLine2": addressLine2,
        "postOfficeBox": postOfficeBox,
        "zip": zip,
        "city": city,
        "nationality": nationality,
        "hometown": hometown,
        "phone": phone,
        "mobile": mobile,
        "email": email,
        "emailPrivate": emailPrivate,
        "profil1": profil1,
        "profil2": profil2,
        "entryDate": _formatDate(entryDate),
        "exitDate": _formatDate(exitDate),
        "regularClasses":
            regularClasses.map((regularClass) => regularClass.toJson()).toList(),
        "additionalClasses": additionalClasses
            .map((regularClass) => regularClass.toJson())
            .toList(),
      };
}

class RegularClass {
  const RegularClass({
    this.id,
    this.token,
    this.semester,
  });

  final String? id;
  final String? token;
  final String? semester;

  factory RegularClass.fromJson(Map<String, dynamic> json) => RegularClass(
        id: json["id"],
        token: json["token"],
        semester: json["semester"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "token": token,
        "semester": semester,
      };
}
