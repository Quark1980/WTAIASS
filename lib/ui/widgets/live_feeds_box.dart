import 'package:flutter/material.dart';
import '../../services/live_feed_provider.dart';
import 'package:provider/provider.dart';

class LiveFeedsBox extends StatelessWidget {
  const LiveFeedsBox({super.key});

  @override
  Widget build(BuildContext context) {
    final liveFeed = context.watch<LiveFeedProvider>();
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black87,
            child: liveFeed.hudMsg.isEmpty
                ? Center(
                    child: Text(
                      'Geen HUD berichten',
                      style: TextStyle(color: Colors.orange.withOpacity(0.5), fontSize: 13),
                    ),
                  )
                : ListView(
                    reverse: true,
                    children: liveFeed.hudMsg.reversed
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(
                                e['msg'] ?? '',
                                style: const TextStyle(color: Colors.orange, fontSize: 13),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),
        Divider(height: 1, color: Colors.white24),
        Expanded(
          child: Container(
            color: Colors.black54,
            child: liveFeed.gameChat.isEmpty
                ? Center(
                    child: Text(
                      'Geen chat berichten',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                    ),
                  )
                : ListView(
                    reverse: true,
                    children: liveFeed.gameChat.reversed
                        .map((e) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(
                                (e['sender'] != null && e['sender'] != '' ? '[${e['sender']}] ' : '') + (e['msg'] ?? ''),
                                style: TextStyle(
                                  color: e['enemy'] == true ? Colors.red : Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}
