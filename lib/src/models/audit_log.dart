import 'package:cloud_firestore/cloud_firestore.dart';

import 'audit_action.dart';

class AuditLog {
  final String id;            // docID
  final String userName;
  final String userID;
  final String? requestID;
  final AuditAction action;
  final String details;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userName,
    required this.userID,
    required this.action,
    required this.details,
    required this.timestamp,
    this.requestID,
  });

  factory AuditLog.fromJson(String id, Map<String, dynamic> json) =>
      AuditLog(
        id: id,
        userID: json['userID'],
        userName: json['userName']?? "",
        requestID: json['requestID'],
        action: AuditActionX.fromString(json['action']),
        details: json['details'],
        timestamp:  (json['timestamp'] as Timestamp?)?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  Map<String, dynamic> toJson() => {
    'userID': userID,
    'requestID': requestID,
    'action': action.value,
    'details': details,
    'timestamp': timestamp,
  };
}
