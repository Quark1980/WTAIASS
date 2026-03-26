import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_data_service.dart';

class HudmsgBar extends StatelessWidget {
  const HudmsgBar({super.key});

  @override
  Widget build(BuildContext context) {
    final hudmsg = context.watch<GameDataService>().stateJson?['hudmsg'];
    if (hudmsg == null || hudmsg is! List || hudmsg.isEmpty) {
      return const SizedBox.shrink();
    }
    // Toon alleen de laatste 3 HUD-meldingen
    final List msgs = hudmsg.length > 3 ? hudmsg.sublist(hudmsg.length - 3) : hudmsg;
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: msgs.map<Widget>((m) => Text(
          m.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        )).toList(),
      ),
    );
  }
}
