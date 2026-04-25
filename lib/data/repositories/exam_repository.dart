import 'package:notely/data/api_client.dart';
import 'package:notely/models/exam.dart';

class ExamRepository {
  final APIClient _apiClient = APIClient();

  Future<List<Exam>> getExams({void Function(List<Exam>)? onUpdate}) async {
    final cached = await _apiClient.getExams(true);

    if (onUpdate != null) {
      _apiClient.getExams(false).then((fresh) {
        onUpdate(fresh);
      }).catchError((_) {
        // Ignore errors
      });
    }

    return cached;
  }
}
