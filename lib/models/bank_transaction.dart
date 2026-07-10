class BankTransaction {

  final DateTime date;

  final String description;

  final double amount;

  bool isDebit;



  String category;

  String item;

  bool duplicate;

  bool selected;

  int? accountId;

  /// Indicative account label shown during import (e.g. member's bank account).
  String? accountName;



  BankTransaction({

    required this.date,

    required this.description,

    required this.amount,

    required this.isDebit,

    this.category = "Other",

    this.item = "",

    this.duplicate = false,

    this.selected = true,

    this.accountId,

    this.accountName,

  });

}

