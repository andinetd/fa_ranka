class AwashTransaction {
  final String direction;
  final String? smsAmount;
  final String? smsTxnId;
  final String? counterparty;
  final String? date;
  final String? time;
  final String? url;

  double? amount;
  double? commission;
  double? vat;
  double? total;
  String? parsedTxnId;
  String? receiptDate;
  String? receiptTime;
  String? fromAccount;
  String? toAccount;
  String? txnType;
  String? reason;
  String? beneficiaryAccount;
  String? beneficiaryBank;
  String? tillNumber;
  String? tin;
  String? vatReg;
  String? parseSource;

  AwashTransaction({
    required this.direction,
    this.smsAmount,
    this.smsTxnId,
    this.counterparty,
    this.date,
    this.time,
    this.url,
  });
}
