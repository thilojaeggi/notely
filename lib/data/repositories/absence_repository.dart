import 'package:notely/data/api_client.dart';
import 'package:notely/models/absence.dart';

class AbsenceRepository {
  final APIClient _apiClient = APIClient();

  Future<List<Absence>> getAbsences(
      {void Function(List<Absence>)? onUpdate}) async {
    final cached = await _apiClient.getAbsences(true);

    if (onUpdate != null) {
      _apiClient.getAbsences(false).then((fresh) {
        onUpdate(fresh);
      }).catchError((_) {
        // Ignore errors
      });
    }

    return cached;
  }
}
