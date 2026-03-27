import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class LogFeedBox extends StatefulWidget {
  const LogFeedBox({super.key});

  @override
  State<LogFeedBox> createState() => _LogFeedBoxState();
}

class _LogFeedBoxState extends State<LogFeedBox> {
  List<Map<String, dynamic>> _logs = [];
  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await DatabaseHelper().getLastMatchLogs(limit: 5);
    setState(() {
      _logs = logs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: ListView.builder(
        reverse: true,
        itemCount: _logs.length,
        itemBuilder: (context, idx) {
          final log = _logs[idx];
          Color color;
          switch (log['type']) {
            case 'HUD':
              color = Colors.amberAccent;
              break;
            case 'CHAT':
              color = Colors.white;
              break;
            case 'SYSTEM':
              color = Colors.blueGrey;
              break;
            default:
              color = Colors.white70;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              (log['type'] == 'CHAT' && log['sender'] != null && log['sender'] != ''
                  ? '[${log['sender']}] '
                  : '') + (log['message'] ?? ''),
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          );
        },
      ),
    );
  }
}