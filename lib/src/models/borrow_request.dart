import 'package:cloud_firestore/cloud_firestore.dart';

import 'borrow_status.dart';

class BorrowRequest {
  final String id;                      // docID
  final String userID;
  final DateTime borrowDate;
  final BorrowStatus status;
  final DateTime? returnDate;
  final DateTime? collectionDateTime;

  BorrowRequest({
    required this.id,
    required this.userID,
    required this.borrowDate,
    required this.status,
    this.returnDate,
    this.collectionDateTime,
  });

  factory BorrowRequest.fromJson(String id, Map<String, dynamic> json) =>
      BorrowRequest(
        id: id,
        userID: json['userID'],
        borrowDate: (json['borrowDate'] as Timestamp).toDate(),
        status: BorrowStatusX.fromString(json['status']),
        returnDate:
        json['returnDate'] != null ? (json['returnDate'] as Timestamp).toDate() : null,
        collectionDateTime: json['collectionDateTime'] != null
            ? (json['collectionDateTime'] as Timestamp).toDate()
            : null,
      );

  Map<String, dynamic> toJson() => {
    'userID': userID,
    'borrowDate': borrowDate,
    'status': status.value,
    'returnDate': returnDate,
    'collectionDateTime': collectionDateTime,
  };
}
