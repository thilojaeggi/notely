// To parse this JSON data, do
//
//     final Student = StudentFromJson(jsonString);

class Student {
  Student({
    required this.id,
    required this.idNr,
    this.externalKey,
    this.registerNr,
    required this.lastName,
    required this.firstName,
    this.fullFirstName,
    this.letterSalutation,
    required this.loginActive,
    required this.loginAd,
    this.username,
    this.initialPassword,
    required this.gender,
    required this.birthday,
    required this.street,
    this.addressLine2,
    this.postOfficeBox,
    this.canton,
    this.country,
    required this.zip,
    required this.city,
    this.schoolMunicipality,
    this.residencePermit,
    this.studentCategory,
    required this.nationality,
    this.nationality2,
    required this.hometown,
    this.hometown2,
    this.nativeLanguage,
    this.nativeLanguage2,
    this.residence,
    this.socialSecurityNumber,
    required this.phone,
    required this.mobile,
    this.phoneOffice,
    required this.email,
    required this.emailPrivate,
    this.confession,
    this.remark,
    required this.profil1,
    this.profil2,
    required this.entryDate,
    this.exitDate,
    this.entryDecision,
    this.exitReason,
    this.otherSchools,
    this.promotionStatus,
    this.classDivisionBilingual,
    this.classDivisionSubject,
    this.classDivisionAttribute1,
    this.classDivisionAttribute2,
    this.previousSchool,
    this.previousSchoolClass,
    this.previousSchoolZip,
    this.previousSchoolCity,
    this.previousSchoolType,
    this.inGermanSpeakingRegionSince,
    this.status,
    this.statusClass,
    required this.regularClasses,
    required this.additionalClasses,
    this.parentId,
    this.keyNumber,
    this.endOfSchool,
    this.internalExternal,
    this.graduationYear,
    this.customFields,
    this.invoiceCompany,
    this.invoiceSalutation,
    this.invoiceLastName,
    this.invoiceFirstName,
    this.invoiceStreet,
    this.invoiceAddressLine2,
    this.invoicePostOfficeBox,
    this.invoiceZip,
    this.invoiceCity,
    this.invoiceCountry,
    this.invoicePhone,
    this.invoicePhoneOffice,
    this.invoiceTelefax,
    this.invoiceMail,
  });

  String? id;
  String? idNr;
  dynamic externalKey;
  dynamic registerNr;
  String? lastName;
  String? firstName;
  dynamic fullFirstName;
  dynamic letterSalutation;
  bool loginActive;
  bool loginAd;
  dynamic username;
  dynamic initialPassword;
  String? gender;
  DateTime birthday;
  String? street;
  dynamic addressLine2;
  dynamic postOfficeBox;
  dynamic canton;
  dynamic country;
  String? zip;
  String? city;
  dynamic schoolMunicipality;
  dynamic residencePermit;
  dynamic studentCategory;
  String? nationality;
  dynamic nationality2;
  String? hometown;
  dynamic hometown2;
  dynamic nativeLanguage;
  dynamic nativeLanguage2;
  dynamic residence;
  dynamic socialSecurityNumber;
  String? phone;
  String? mobile;
  dynamic phoneOffice;
  String? email;
  String? emailPrivate;
  dynamic confession;
  dynamic remark;
  String? profil1;
  dynamic profil2;
  DateTime entryDate;
  dynamic exitDate;
  dynamic entryDecision;
  dynamic exitReason;
  dynamic otherSchools;
  dynamic promotionStatus;
  dynamic classDivisionBilingual;
  dynamic classDivisionSubject;
  dynamic classDivisionAttribute1;
  dynamic classDivisionAttribute2;
  dynamic previousSchool;
  dynamic previousSchoolClass;
  dynamic previousSchoolZip;
  dynamic previousSchoolCity;
  dynamic previousSchoolType;
  dynamic inGermanSpeakingRegionSince;
  dynamic status;
  dynamic statusClass;
  List<RegularClass> regularClasses;
  List<dynamic> additionalClasses;
  dynamic parentId;
  dynamic keyNumber;
  dynamic endOfSchool;
  dynamic internalExternal;
  dynamic graduationYear;
  dynamic customFields;
  dynamic invoiceCompany;
  dynamic invoiceSalutation;
  dynamic invoiceLastName;
  dynamic invoiceFirstName;
  dynamic invoiceStreet;
  dynamic invoiceAddressLine2;
  dynamic invoicePostOfficeBox;
  dynamic invoiceZip;
  dynamic invoiceCity;
  dynamic invoiceCountry;
  dynamic invoicePhone;
  dynamic invoicePhoneOffice;
  dynamic invoiceTelefax;
  dynamic invoiceMail;

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json["id"],
        idNr: json["idNr"],
        externalKey: json["externalKey"],
        registerNr: json["registerNr"],
        lastName: json["lastName"],
        firstName: json["firstName"],
        fullFirstName: json["fullFirstName"],
        letterSalutation: json["letterSalutation"],
        loginActive: json["loginActive"],
        loginAd: json["loginAD"],
        username: json["username"],
        initialPassword: json["initialPassword"],
        gender: json["gender"],
        birthday: DateTime.parse(json["birthday"]),
        street: json["street"],
        addressLine2: json["addressLine2"],
        postOfficeBox: json["postOfficeBox"],
        canton: json["canton"],
        country: json["country"],
        zip: json["zip"],
        city: json["city"],
        schoolMunicipality: json["schoolMunicipality"],
        residencePermit: json["residencePermit"],
        studentCategory: json["studentCategory"],
        nationality: json["nationality"],
        nationality2: json["nationality2"],
        hometown: json["hometown"],
        hometown2: json["hometown2"],
        nativeLanguage: json["nativeLanguage"],
        nativeLanguage2: json["nativeLanguage2"],
        residence: json["residence"],
        socialSecurityNumber: json["socialSecurityNumber"],
        phone: json["phone"],
        mobile: json["mobile"],
        phoneOffice: json["phoneOffice"],
        email: json["email"],
        emailPrivate: json["emailPrivate"],
        confession: json["confession"],
        remark: json["remark"],
        profil1: json["profil1"],
        profil2: json["profil2"],
        entryDate: DateTime.parse(json["entryDate"]),
        exitDate: json["exitDate"],
        entryDecision: json["entryDecision"],
        exitReason: json["exitReason"],
        otherSchools: json["otherSchools"],
        promotionStatus: json["promotionStatus"],
        classDivisionBilingual: json["classDivisionBilingual"],
        classDivisionSubject: json["classDivisionSubject"],
        classDivisionAttribute1: json["classDivisionAttribute1"],
        classDivisionAttribute2: json["classDivisionAttribute2"],
        previousSchool: json["previousSchool"],
        previousSchoolClass: json["previousSchoolClass"],
        previousSchoolZip: json["previousSchoolZip"],
        previousSchoolCity: json["previousSchoolCity"],
        previousSchoolType: json["previousSchoolType"],
        inGermanSpeakingRegionSince: json["inGermanSpeakingRegionSince"],
        status: json["status"],
        statusClass: json["statusClass"],
        regularClasses: List<RegularClass>.from(
            json["regularClasses"].map((x) => RegularClass.fromJson(x))),
        additionalClasses:
            List<dynamic>.from(json["additionalClasses"].map((x) => x)),
        parentId: json["parentId"],
        keyNumber: json["keyNumber"],
        endOfSchool: json["endOfSchool"],
        internalExternal: json["internalExternal"],
        graduationYear: json["graduationYear"],
        customFields: json["customFields"],
        invoiceCompany: json["invoiceCompany"],
        invoiceSalutation: json["invoiceSalutation"],
        invoiceLastName: json["invoiceLastName"],
        invoiceFirstName: json["invoiceFirstName"],
        invoiceStreet: json["invoiceStreet"],
        invoiceAddressLine2: json["invoiceAddressLine2"],
        invoicePostOfficeBox: json["invoicePostOfficeBox"],
        invoiceZip: json["invoiceZip"],
        invoiceCity: json["invoiceCity"],
        invoiceCountry: json["invoiceCountry"],
        invoicePhone: json["invoicePhone"],
        invoicePhoneOffice: json["invoicePhoneOffice"],
        invoiceTelefax: json["invoiceTelefax"],
        invoiceMail: json["invoiceMail"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "idNr": idNr,
        "externalKey": externalKey,
        "registerNr": registerNr,
        "lastName": lastName,
        "firstName": firstName,
        "fullFirstName": fullFirstName,
        "letterSalutation": letterSalutation,
        "loginActive": loginActive,
        "loginAD": loginAd,
        "username": username,
        "initialPassword": initialPassword,
        "gender": gender,
        "birthday":
            "${birthday.year.toString().padLeft(4, '0')}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}",
        "street": street,
        "addressLine2": addressLine2,
        "postOfficeBox": postOfficeBox,
        "canton": canton,
        "country": country,
        "zip": zip,
        "city": city,
        "schoolMunicipality": schoolMunicipality,
        "residencePermit": residencePermit,
        "studentCategory": studentCategory,
        "nationality": nationality,
        "nationality2": nationality2,
        "hometown": hometown,
        "hometown2": hometown2,
        "nativeLanguage": nativeLanguage,
        "nativeLanguage2": nativeLanguage2,
        "residence": residence,
        "socialSecurityNumber": socialSecurityNumber,
        "phone": phone,
        "mobile": mobile,
        "phoneOffice": phoneOffice,
        "email": email,
        "emailPrivate": emailPrivate,
        "confession": confession,
        "remark": remark,
        "profil1": profil1,
        "profil2": profil2,
        "entryDate":
            "${entryDate.year.toString().padLeft(4, '0')}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}",
        "exitDate": exitDate,
        "entryDecision": entryDecision,
        "exitReason": exitReason,
        "otherSchools": otherSchools,
        "promotionStatus": promotionStatus,
        "classDivisionBilingual": classDivisionBilingual,
        "classDivisionSubject": classDivisionSubject,
        "classDivisionAttribute1": classDivisionAttribute1,
        "classDivisionAttribute2": classDivisionAttribute2,
        "previousSchool": previousSchool,
        "previousSchoolClass": previousSchoolClass,
        "previousSchoolZip": previousSchoolZip,
        "previousSchoolCity": previousSchoolCity,
        "previousSchoolType": previousSchoolType,
        "inGermanSpeakingRegionSince": inGermanSpeakingRegionSince,
        "status": status,
        "statusClass": statusClass,
        "regularClasses":
            List<dynamic>.from(regularClasses.map((x) => x.toJson())),
        "additionalClasses":
            List<dynamic>.from(additionalClasses.map((x) => x)),
        "parentId": parentId,
        "keyNumber": keyNumber,
        "endOfSchool": endOfSchool,
        "internalExternal": internalExternal,
        "graduationYear": graduationYear,
        "customFields": customFields,
        "invoiceCompany": invoiceCompany,
        "invoiceSalutation": invoiceSalutation,
        "invoiceLastName": invoiceLastName,
        "invoiceFirstName": invoiceFirstName,
        "invoiceStreet": invoiceStreet,
        "invoiceAddressLine2": invoiceAddressLine2,
        "invoicePostOfficeBox": invoicePostOfficeBox,
        "invoiceZip": invoiceZip,
        "invoiceCity": invoiceCity,
        "invoiceCountry": invoiceCountry,
        "invoicePhone": invoicePhone,
        "invoicePhoneOffice": invoicePhoneOffice,
        "invoiceTelefax": invoiceTelefax,
        "invoiceMail": invoiceMail,
      };
}

class RegularClass {
  RegularClass({
    required this.id,
    required this.token,
    required this.semester,
  });

  String? id;
  String? token;
  String? semester;

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
