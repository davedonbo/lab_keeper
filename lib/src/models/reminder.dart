import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String id;            // docID
  final String requestID;
  final DateTime reminderDate;
  final bool sent;

  Reminder({
    required this.id,
    required this.requestID,
    required this.reminderDate,
    required this.sent,
  });

  factory Reminder.fromJson(String id, Map<String, dynamic> json) =>
      Reminder(
        id: id,
        requestID: json['requestID'],
        reminderDate: (json['reminderDate'] as Timestamp).toDate(),
        sent: json['sent'] as bool,
      );

  Map<String, dynamic> toJson() => {
    'requestID': requestID,
    'reminderDate': reminderDate,
    'sent': sent,
  };
}
