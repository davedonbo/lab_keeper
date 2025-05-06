class BorrowedItem {
  final String id;                // item docID
  final String equipmentID;
  final int quantity;
  final String? description;
  final String? serialNumber;

  BorrowedItem({
    required this.id,
    required this.equipmentID,
    required this.quantity,
    this.description,
    this.serialNumber,
  });

  factory BorrowedItem.fromJson(String id, Map<String, dynamic> json) =>
      BorrowedItem(
        id: id,
        equipmentID : json['equipmentID']  ?? json['equipmentId'],
        quantity    : json['quantity']     ?? json['qty'] ?? 0,
        description: json['description'],
        serialNumber: json['serialNumber'],
      );

  Map<String, dynamic> toJson() => {
    'equipmentID': equipmentID,
    'quantity': quantity,
    'description': description,
    'serialNumber': serialNumber,
  };
}
