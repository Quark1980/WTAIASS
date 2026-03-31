import 'game_data_service.dart';

// Add stub for updateFromWTApiService for compatibility
extension GameDataServiceCompat on GameDataService {
  void updateFromWTApiService({required List<dynamic> mapObjects, Map<String, dynamic>? mapInfo}) {}
}
