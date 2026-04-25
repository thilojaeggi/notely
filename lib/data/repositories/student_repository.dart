import 'package:notely/data/api_client.dart';
import 'package:notely/models/student.dart';

class StudentRepository {
  final APIClient _apiClient = APIClient();

  Future<Student?> getStudent({void Function(Student?)? onUpdate}) async {
    final cached = await _apiClient.getStudent(true);

    if (onUpdate != null) {
      _apiClient.getStudent(false).then((fresh) {
        onUpdate(fresh);
      }).catchError((_) {
        // Ignore
      });
    }

    return cached;
  }
}
