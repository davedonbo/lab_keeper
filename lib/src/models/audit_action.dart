enum AuditAction { create, update, delete, borrow, returnItem, notify, approve }

extension AuditActionX on AuditAction {
  String get value => switch (this) {
    AuditAction.create     => 'Create',
    AuditAction.update     => 'Update',
    AuditAction.delete     => 'Delete',
    AuditAction.borrow     => 'Borrow',
    AuditAction.returnItem => 'Return',
    AuditAction.notify     => 'Notify',
    AuditAction.approve    => 'Approve',
  };

  static AuditAction fromString(String s) =>
      AuditAction.values.firstWhere((e) => e.value == s,
          orElse: () => AuditAction.create);
}
