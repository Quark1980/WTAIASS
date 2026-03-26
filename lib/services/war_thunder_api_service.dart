import 'dart:convert';
import 'package:http/http.dart' as http;

class WarThunderApiService {
  final String host;
  final int port;

  WarThunderApiService({this.host = '192.168.1.100', this.port = 8111});

  Future<Map<String, dynamic>?> fetchGameState() async {
    final url = Uri.parse('http://$host:$port/state');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // Handle error or log
    }
    return null;
  }
}
