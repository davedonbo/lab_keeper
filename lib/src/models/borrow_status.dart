enum BorrowStatus { pending, approved, returned, overdue }

extension BorrowStatusX on BorrowStatus {
  String get value => switch (this) {
    BorrowStatus.pending  => 'Pending',
    BorrowStatus.approved => 'Approved',
    BorrowStatus.returned => 'Returned',
    BorrowStatus.overdue  => 'Overdue',
  };

  static BorrowStatus fromString(String s) =>
      BorrowStatus.values.firstWhere((e) => e.value == s,
          orElse: () => BorrowStatus.pending);
}
