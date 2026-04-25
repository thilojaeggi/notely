import 'package:notely/data/api_client.dart';
import 'package:notely/models/event.dart';

class EventRepository {
  final APIClient _apiClient = APIClient();

  /// Retrieves events for a specific date. First from cache, then triggers a 
  /// background refresh that calls [onUpdate].
  Future<List<Event>> getEvents(DateTime date,
      {void Function(List<Event>)? onUpdate}) async {
    final cached = await _apiClient.getEvents(date, true);

    if (onUpdate != null) {
      _apiClient.getEvents(date, false).then((fresh) {
        onUpdate(fresh);
      }).catchError((_) {
        // Ignore errors on background refresh
      });
    }

    return cached;
  }
}
