import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class LogFeedBox extends StatelessWidget {
  const LogFeedBox({super.key});

  /// Parses [color=#RRGGBB]text[/color] tags and returns a list of TextSpans.
  List<InlineSpan> _parseColorTags(String text, {TextStyle? baseStyle}) {
    final List<InlineSpan> spans = [];
    final RegExp exp = RegExp(r'\[color=(#[0-9A-Fa-f]{6})\](.*?)\[/color\]', dotAll: true);
    int lastEnd = 0;
    final matches = exp.allMatches(text);
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      final colorHex = match.group(1)!;
      final innerText = match.group(2)!;
      Color color = Colors.white;
      try {
        color = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
      } catch (_) {}
      spans.add(TextSpan(text: innerText, style: baseStyle?.copyWith(color: color) ?? TextStyle(color: color)));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return AnimatedBuilder(
      animation: DatabaseHelper(),
      builder: (context, _) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper().getLastMatchLogs(limit: 30),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            // Auto-scroll to top (latest message) after logs update
            if (scrollController.hasClients) {
              scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
            return Container(
              color: Colors.black87,
              child: ListView.builder(
                controller: scrollController,
                reverse: true,
                itemCount: logs.length,
                itemBuilder: (context, idx) {
                  final log = logs[idx];
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
                  final isChat = log['type'] == 'CHAT';
                  final sender = isChat && log['sender'] != null && log['sender'] != '' ? '[${log['sender']}] ' : '';
                  final message = log['message'] ?? '';
                  final style = TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: isChat && (message.contains('[color='))
                        ? RichText(
                            text: TextSpan(
                              children: [
                                if (sender.isNotEmpty) TextSpan(text: sender, style: style),
                                ..._parseColorTags(message, baseStyle: style),
                              ],
                            ),
                          )
                        : Text(
                            sender + message,
                            style: style,
                          ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}