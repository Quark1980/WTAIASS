import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_data_service.dart';

class DebugDataPage extends StatelessWidget {
  const DebugDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raw Data Inspector')),
      body: Consumer<GameDataService>(
        builder: (context, service, _) {
          final mapObj = service.mapObjects;
          final state = null; // Geen state property meer
          final mapInfo = service.mapInfo;
          return ListView(
            children: [
              _JsonExpansionTile(title: '/map_obj.json', jsonData: mapObj),
              _JsonExpansionTile(title: '/state', jsonData: state),
              _JsonExpansionTile(title: '/map_info.json', jsonData: mapInfo),
            ],
          );
        },
      ),
    );
  }
}

class _JsonExpansionTile extends StatelessWidget {
  final String title;
  final dynamic jsonData;
  const _JsonExpansionTile({required this.title, required this.jsonData});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildJsonView(jsonData),
        ),
      ],
    );
  }

  Widget _buildJsonView(dynamic data) {
    if (data == null) return const Text('No data');
    if (data is Map<String, dynamic>) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((e) => _JsonExpansionTile(title: e.key, jsonData: e.value)).toList(),
      );
    }
    if (data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.asMap().entries.map((e) => _JsonExpansionTile(title: '[${e.key}]', jsonData: e.value)).toList(),
      );
    }
    return Text(data.toString());
  }
}
