import 'package:notely/data/api_client.dart';
import 'package:notely/models/grade.dart';

class GradeRepository {
  final APIClient _apiClient = APIClient();

  /// Retrieves grades. First from cache, then triggers a background refresh
  /// that calls [onUpdate] if the fresh data differs or arrives later.
  Future<List<Grade>> getGrades(
      {void Function(List<Grade>)? onUpdate}) async {
    final cached = await _apiClient.getGrades(true);

    if (onUpdate != null) {
      _apiClient.getGrades(false).then((fresh) {
        onUpdate(fresh);
      }).catchError((_) {
        // Ignore errors on background refresh
      });
    }

    return cached;
  }
}
