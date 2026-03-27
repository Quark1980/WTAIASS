import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LiveFeedProvider extends ChangeNotifier {
  final String baseUrl;
  List<Map<String, dynamic>> gameChat = [];
  List<Map<String, dynamic>> hudMsg = [];
  int lastChatId = 0;
  int lastDmgId = 0;
  Timer? _timer;

  LiveFeedProvider({this.baseUrl = 'http://localhost:8111'}) {
    _start();
  }

  void _start() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await fetchGameChat();
      await fetchHudMsg();
    });
  }

  Future<void> fetchGameChat() async {
    try {
      final url = Uri.parse('$baseUrl/gamechat?lastId=$lastChatId');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(resp.body);
        if (data.isNotEmpty) {
          gameChat.addAll(data.cast<Map<String, dynamic>>());
          lastChatId = gameChat.last['id'] ?? lastChatId;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> fetchHudMsg() async {
    try {
      final url = Uri.parse('$baseUrl/hudmsg?lastEvt=0&lastDmg=$lastDmgId');
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final List<dynamic> dmg = data['damage'] ?? [];
        if (dmg.isNotEmpty) {
          hudMsg.addAll(dmg.cast<Map<String, dynamic>>());
          lastDmgId = hudMsg.last['id'] ?? lastDmgId;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
