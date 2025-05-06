import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lab_keeper/src/models/audit_action.dart';
import '../../services/audit_service.dart';
import '../../models/audit_log.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: StreamBuilder<QuerySnapshot>(
        stream: AuditService.instance.streamAll(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Center(child: Text('Nothing yet'));
          final logs = snap.data!.docs
              .map((d) => AuditLog.fromJson(d.id, d.data()! as Map<String, dynamic>))
              .toList();
          return ListView.separated(
            itemCount: logs.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final log = logs[i];
              return ListTile(
                title: Text('${log.userName} • ${log.action.value}'),
                subtitle: Text(log.details),
                trailing: Text(
                  '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
