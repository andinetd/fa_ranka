// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _transactionHashMeta = const VerificationMeta(
    'transactionHash',
  );
  @override
  late final GeneratedColumn<String> transactionHash = GeneratedColumn<String>(
    'transaction_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionDirection, String>
  direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TransactionDirection>($TransactionsTable.$converterdirection);
  static const VerificationMeta _counterpartyNameMeta = const VerificationMeta(
    'counterpartyName',
  );
  @override
  late final GeneratedColumn<String> counterpartyName = GeneratedColumn<String>(
    'counterparty_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyNumberMeta =
      const VerificationMeta('counterpartyNumber');
  @override
  late final GeneratedColumn<String> counterpartyNumber =
      GeneratedColumn<String>(
        'counterparty_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankTransactionIdMeta = const VerificationMeta(
    'bankTransactionId',
  );
  @override
  late final GeneratedColumn<String> bankTransactionId =
      GeneratedColumn<String>(
        'bank_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _referenceNumberMeta = const VerificationMeta(
    'referenceNumber',
  );
  @override
  late final GeneratedColumn<String> referenceNumber = GeneratedColumn<String>(
    'reference_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceAfterMeta = const VerificationMeta(
    'balanceAfter',
  );
  @override
  late final GeneratedColumn<double> balanceAfter = GeneratedColumn<double>(
    'balance_after',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptUrlMeta = const VerificationMeta(
    'receiptUrl',
  );
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
    'receipt_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localReceiptPathMeta = const VerificationMeta(
    'localReceiptPath',
  );
  @override
  late final GeneratedColumn<String> localReceiptPath = GeneratedColumn<String>(
    'local_receipt_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonRawTextMeta = const VerificationMeta(
    'reasonRawText',
  );
  @override
  late final GeneratedColumn<String> reasonRawText = GeneratedColumn<String>(
    'reason_raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedReasonMeta = const VerificationMeta(
    'normalizedReason',
  );
  @override
  late final GeneratedColumn<String> normalizedReason = GeneratedColumn<String>(
    'normalized_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parsedCategoryMeta = const VerificationMeta(
    'parsedCategory',
  );
  @override
  late final GeneratedColumn<String> parsedCategory = GeneratedColumn<String>(
    'parsed_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Uncategorized'),
  );
  static const VerificationMeta _commissionMeta = const VerificationMeta(
    'commission',
  );
  @override
  late final GeneratedColumn<double> commission = GeneratedColumn<double>(
    'commission',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _vatMeta = const VerificationMeta('vat');
  @override
  late final GeneratedColumn<double> vat = GeneratedColumn<double>(
    'vat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _branchNameMeta = const VerificationMeta(
    'branchName',
  );
  @override
  late final GeneratedColumn<String> branchName = GeneratedColumn<String>(
    'branch_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _smsIdMeta = const VerificationMeta('smsId');
  @override
  late final GeneratedColumn<String> smsId = GeneratedColumn<String>(
    'sms_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderAddressMeta = const VerificationMeta(
    'senderAddress',
  );
  @override
  late final GeneratedColumn<String> senderAddress = GeneratedColumn<String>(
    'sender_address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawSmsBodyMeta = const VerificationMeta(
    'rawSmsBody',
  );
  @override
  late final GeneratedColumn<String> rawSmsBody = GeneratedColumn<String>(
    'raw_sms_body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsTimestampMeta = const VerificationMeta(
    'smsTimestamp',
  );
  @override
  late final GeneratedColumn<int> smsTimestamp = GeneratedColumn<int>(
    'sms_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<int> importedAt = GeneratedColumn<int>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _smsReadMeta = const VerificationMeta(
    'smsRead',
  );
  @override
  late final GeneratedColumn<bool> smsRead = GeneratedColumn<bool>(
    'sms_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sms_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _parserVersionMeta = const VerificationMeta(
    'parserVersion',
  );
  @override
  late final GeneratedColumn<int> parserVersion = GeneratedColumn<int>(
    'parser_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRecurringMeta = const VerificationMeta(
    'isRecurring',
  );
  @override
  late final GeneratedColumn<bool> isRecurring = GeneratedColumn<bool>(
    'is_recurring',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_recurring" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurringPatternMeta = const VerificationMeta(
    'recurringPattern',
  );
  @override
  late final GeneratedColumn<String> recurringPattern = GeneratedColumn<String>(
    'recurring_pattern',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptExtractionStatusMeta =
      const VerificationMeta('receiptExtractionStatus');
  @override
  late final GeneratedColumn<String> receiptExtractionStatus =
      GeneratedColumn<String>(
        'receipt_extraction_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('pending'),
      );
  static const VerificationMeta _receiptExtractionErrorMeta =
      const VerificationMeta('receiptExtractionError');
  @override
  late final GeneratedColumn<String> receiptExtractionError =
      GeneratedColumn<String>(
        'receipt_extraction_error',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _receiptExtractionAttemptedAtMeta =
      const VerificationMeta('receiptExtractionAttemptedAt');
  @override
  late final GeneratedColumn<int> receiptExtractionAttemptedAt =
      GeneratedColumn<int>(
        'receipt_extraction_attempted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _extractionRetryAttemptsMeta =
      const VerificationMeta('extractionRetryAttempts');
  @override
  late final GeneratedColumn<int> extractionRetryAttempts =
      GeneratedColumn<int>(
        'extraction_retry_attempts',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _extractionNextRetryAtMeta =
      const VerificationMeta('extractionNextRetryAt');
  @override
  late final GeneratedColumn<int> extractionNextRetryAt = GeneratedColumn<int>(
    'extraction_next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    transactionHash,
    amount,
    currency,
    direction,
    counterpartyName,
    counterpartyNumber,
    bankName,
    bankTransactionId,
    referenceNumber,
    channel,
    location,
    balanceAfter,
    receiptUrl,
    localReceiptPath,
    reasonRawText,
    normalizedReason,
    parsedCategory,
    commission,
    vat,
    branchName,
    smsId,
    threadId,
    senderAddress,
    rawSmsBody,
    smsTimestamp,
    importedAt,
    smsRead,
    parserVersion,
    isRecurring,
    recurringPattern,
    receiptExtractionStatus,
    receiptExtractionError,
    receiptExtractionAttemptedAt,
    extractionRetryAttempts,
    extractionNextRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('transaction_hash')) {
      context.handle(
        _transactionHashMeta,
        transactionHash.isAcceptableOrUnknown(
          data['transaction_hash']!,
          _transactionHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionHashMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('counterparty_name')) {
      context.handle(
        _counterpartyNameMeta,
        counterpartyName.isAcceptableOrUnknown(
          data['counterparty_name']!,
          _counterpartyNameMeta,
        ),
      );
    }
    if (data.containsKey('counterparty_number')) {
      context.handle(
        _counterpartyNumberMeta,
        counterpartyNumber.isAcceptableOrUnknown(
          data['counterparty_number']!,
          _counterpartyNumberMeta,
        ),
      );
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('bank_transaction_id')) {
      context.handle(
        _bankTransactionIdMeta,
        bankTransactionId.isAcceptableOrUnknown(
          data['bank_transaction_id']!,
          _bankTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('reference_number')) {
      context.handle(
        _referenceNumberMeta,
        referenceNumber.isAcceptableOrUnknown(
          data['reference_number']!,
          _referenceNumberMeta,
        ),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('balance_after')) {
      context.handle(
        _balanceAfterMeta,
        balanceAfter.isAcceptableOrUnknown(
          data['balance_after']!,
          _balanceAfterMeta,
        ),
      );
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
        _receiptUrlMeta,
        receiptUrl.isAcceptableOrUnknown(data['receipt_url']!, _receiptUrlMeta),
      );
    }
    if (data.containsKey('local_receipt_path')) {
      context.handle(
        _localReceiptPathMeta,
        localReceiptPath.isAcceptableOrUnknown(
          data['local_receipt_path']!,
          _localReceiptPathMeta,
        ),
      );
    }
    if (data.containsKey('reason_raw_text')) {
      context.handle(
        _reasonRawTextMeta,
        reasonRawText.isAcceptableOrUnknown(
          data['reason_raw_text']!,
          _reasonRawTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reasonRawTextMeta);
    }
    if (data.containsKey('normalized_reason')) {
      context.handle(
        _normalizedReasonMeta,
        normalizedReason.isAcceptableOrUnknown(
          data['normalized_reason']!,
          _normalizedReasonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedReasonMeta);
    }
    if (data.containsKey('parsed_category')) {
      context.handle(
        _parsedCategoryMeta,
        parsedCategory.isAcceptableOrUnknown(
          data['parsed_category']!,
          _parsedCategoryMeta,
        ),
      );
    }
    if (data.containsKey('commission')) {
      context.handle(
        _commissionMeta,
        commission.isAcceptableOrUnknown(data['commission']!, _commissionMeta),
      );
    }
    if (data.containsKey('vat')) {
      context.handle(
        _vatMeta,
        vat.isAcceptableOrUnknown(data['vat']!, _vatMeta),
      );
    }
    if (data.containsKey('branch_name')) {
      context.handle(
        _branchNameMeta,
        branchName.isAcceptableOrUnknown(data['branch_name']!, _branchNameMeta),
      );
    }
    if (data.containsKey('sms_id')) {
      context.handle(
        _smsIdMeta,
        smsId.isAcceptableOrUnknown(data['sms_id']!, _smsIdMeta),
      );
    } else if (isInserting) {
      context.missing(_smsIdMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('sender_address')) {
      context.handle(
        _senderAddressMeta,
        senderAddress.isAcceptableOrUnknown(
          data['sender_address']!,
          _senderAddressMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderAddressMeta);
    }
    if (data.containsKey('raw_sms_body')) {
      context.handle(
        _rawSmsBodyMeta,
        rawSmsBody.isAcceptableOrUnknown(
          data['raw_sms_body']!,
          _rawSmsBodyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawSmsBodyMeta);
    }
    if (data.containsKey('sms_timestamp')) {
      context.handle(
        _smsTimestampMeta,
        smsTimestamp.isAcceptableOrUnknown(
          data['sms_timestamp']!,
          _smsTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_smsTimestampMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('sms_read')) {
      context.handle(
        _smsReadMeta,
        smsRead.isAcceptableOrUnknown(data['sms_read']!, _smsReadMeta),
      );
    }
    if (data.containsKey('parser_version')) {
      context.handle(
        _parserVersionMeta,
        parserVersion.isAcceptableOrUnknown(
          data['parser_version']!,
          _parserVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parserVersionMeta);
    }
    if (data.containsKey('is_recurring')) {
      context.handle(
        _isRecurringMeta,
        isRecurring.isAcceptableOrUnknown(
          data['is_recurring']!,
          _isRecurringMeta,
        ),
      );
    }
    if (data.containsKey('recurring_pattern')) {
      context.handle(
        _recurringPatternMeta,
        recurringPattern.isAcceptableOrUnknown(
          data['recurring_pattern']!,
          _recurringPatternMeta,
        ),
      );
    }
    if (data.containsKey('receipt_extraction_status')) {
      context.handle(
        _receiptExtractionStatusMeta,
        receiptExtractionStatus.isAcceptableOrUnknown(
          data['receipt_extraction_status']!,
          _receiptExtractionStatusMeta,
        ),
      );
    }
    if (data.containsKey('receipt_extraction_error')) {
      context.handle(
        _receiptExtractionErrorMeta,
        receiptExtractionError.isAcceptableOrUnknown(
          data['receipt_extraction_error']!,
          _receiptExtractionErrorMeta,
        ),
      );
    }
    if (data.containsKey('receipt_extraction_attempted_at')) {
      context.handle(
        _receiptExtractionAttemptedAtMeta,
        receiptExtractionAttemptedAt.isAcceptableOrUnknown(
          data['receipt_extraction_attempted_at']!,
          _receiptExtractionAttemptedAtMeta,
        ),
      );
    }
    if (data.containsKey('extraction_retry_attempts')) {
      context.handle(
        _extractionRetryAttemptsMeta,
        extractionRetryAttempts.isAcceptableOrUnknown(
          data['extraction_retry_attempts']!,
          _extractionRetryAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('extraction_next_retry_at')) {
      context.handle(
        _extractionNextRetryAtMeta,
        extractionNextRetryAt.isAcceptableOrUnknown(
          data['extraction_next_retry_at']!,
          _extractionNextRetryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      transactionHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_hash'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      direction: $TransactionsTable.$converterdirection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}direction'],
        )!,
      ),
      counterpartyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty_name'],
      ),
      counterpartyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty_number'],
      ),
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      bankTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_transaction_id'],
      ),
      referenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_number'],
      ),
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      balanceAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance_after'],
      ),
      receiptUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_url'],
      ),
      localReceiptPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_receipt_path'],
      ),
      reasonRawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_raw_text'],
      )!,
      normalizedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_reason'],
      )!,
      parsedCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_category'],
      )!,
      commission: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}commission'],
      )!,
      vat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat'],
      )!,
      branchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_name'],
      ),
      smsId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sms_id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      senderAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_address'],
      )!,
      rawSmsBody: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_sms_body'],
      )!,
      smsTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sms_timestamp'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}imported_at'],
      )!,
      smsRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sms_read'],
      )!,
      parserVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parser_version'],
      )!,
      isRecurring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_recurring'],
      )!,
      recurringPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_pattern'],
      ),
      receiptExtractionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_extraction_status'],
      )!,
      receiptExtractionError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_extraction_error'],
      ),
      receiptExtractionAttemptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_extraction_attempted_at'],
      ),
      extractionRetryAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extraction_retry_attempts'],
      )!,
      extractionNextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extraction_next_retry_at'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionDirection, String, String>
  $converterdirection = const EnumNameConverter<TransactionDirection>(
    TransactionDirection.values,
  );
}

class TransactionData extends DataClass implements Insertable<TransactionData> {
  final int id;
  final String transactionHash;
  final double amount;
  final String currency;
  final TransactionDirection direction;
  final String? counterpartyName;
  final String? counterpartyNumber;
  final String? bankName;
  final String? bankTransactionId;
  final String? referenceNumber;
  final String? channel;
  final String? location;
  final double? balanceAfter;
  final String? receiptUrl;
  final String? localReceiptPath;
  final String reasonRawText;
  final String normalizedReason;
  final String parsedCategory;
  final double commission;
  final double vat;
  final String? branchName;
  final String smsId;
  final String threadId;
  final String senderAddress;
  final String rawSmsBody;
  final int smsTimestamp;
  final int importedAt;
  final bool smsRead;
  final int parserVersion;
  final bool isRecurring;
  final String? recurringPattern;
  final String receiptExtractionStatus;
  final String? receiptExtractionError;
  final int? receiptExtractionAttemptedAt;
  final int extractionRetryAttempts;
  final int? extractionNextRetryAt;
  const TransactionData({
    required this.id,
    required this.transactionHash,
    required this.amount,
    required this.currency,
    required this.direction,
    this.counterpartyName,
    this.counterpartyNumber,
    this.bankName,
    this.bankTransactionId,
    this.referenceNumber,
    this.channel,
    this.location,
    this.balanceAfter,
    this.receiptUrl,
    this.localReceiptPath,
    required this.reasonRawText,
    required this.normalizedReason,
    required this.parsedCategory,
    required this.commission,
    required this.vat,
    this.branchName,
    required this.smsId,
    required this.threadId,
    required this.senderAddress,
    required this.rawSmsBody,
    required this.smsTimestamp,
    required this.importedAt,
    required this.smsRead,
    required this.parserVersion,
    required this.isRecurring,
    this.recurringPattern,
    required this.receiptExtractionStatus,
    this.receiptExtractionError,
    this.receiptExtractionAttemptedAt,
    required this.extractionRetryAttempts,
    this.extractionNextRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['transaction_hash'] = Variable<String>(transactionHash);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    {
      map['direction'] = Variable<String>(
        $TransactionsTable.$converterdirection.toSql(direction),
      );
    }
    if (!nullToAbsent || counterpartyName != null) {
      map['counterparty_name'] = Variable<String>(counterpartyName);
    }
    if (!nullToAbsent || counterpartyNumber != null) {
      map['counterparty_number'] = Variable<String>(counterpartyNumber);
    }
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || bankTransactionId != null) {
      map['bank_transaction_id'] = Variable<String>(bankTransactionId);
    }
    if (!nullToAbsent || referenceNumber != null) {
      map['reference_number'] = Variable<String>(referenceNumber);
    }
    if (!nullToAbsent || channel != null) {
      map['channel'] = Variable<String>(channel);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || balanceAfter != null) {
      map['balance_after'] = Variable<double>(balanceAfter);
    }
    if (!nullToAbsent || receiptUrl != null) {
      map['receipt_url'] = Variable<String>(receiptUrl);
    }
    if (!nullToAbsent || localReceiptPath != null) {
      map['local_receipt_path'] = Variable<String>(localReceiptPath);
    }
    map['reason_raw_text'] = Variable<String>(reasonRawText);
    map['normalized_reason'] = Variable<String>(normalizedReason);
    map['parsed_category'] = Variable<String>(parsedCategory);
    map['commission'] = Variable<double>(commission);
    map['vat'] = Variable<double>(vat);
    if (!nullToAbsent || branchName != null) {
      map['branch_name'] = Variable<String>(branchName);
    }
    map['sms_id'] = Variable<String>(smsId);
    map['thread_id'] = Variable<String>(threadId);
    map['sender_address'] = Variable<String>(senderAddress);
    map['raw_sms_body'] = Variable<String>(rawSmsBody);
    map['sms_timestamp'] = Variable<int>(smsTimestamp);
    map['imported_at'] = Variable<int>(importedAt);
    map['sms_read'] = Variable<bool>(smsRead);
    map['parser_version'] = Variable<int>(parserVersion);
    map['is_recurring'] = Variable<bool>(isRecurring);
    if (!nullToAbsent || recurringPattern != null) {
      map['recurring_pattern'] = Variable<String>(recurringPattern);
    }
    map['receipt_extraction_status'] = Variable<String>(
      receiptExtractionStatus,
    );
    if (!nullToAbsent || receiptExtractionError != null) {
      map['receipt_extraction_error'] = Variable<String>(
        receiptExtractionError,
      );
    }
    if (!nullToAbsent || receiptExtractionAttemptedAt != null) {
      map['receipt_extraction_attempted_at'] = Variable<int>(
        receiptExtractionAttemptedAt,
      );
    }
    map['extraction_retry_attempts'] = Variable<int>(extractionRetryAttempts);
    if (!nullToAbsent || extractionNextRetryAt != null) {
      map['extraction_next_retry_at'] = Variable<int>(extractionNextRetryAt);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      transactionHash: Value(transactionHash),
      amount: Value(amount),
      currency: Value(currency),
      direction: Value(direction),
      counterpartyName: counterpartyName == null && nullToAbsent
          ? const Value.absent()
          : Value(counterpartyName),
      counterpartyNumber: counterpartyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(counterpartyNumber),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      bankTransactionId: bankTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(bankTransactionId),
      referenceNumber: referenceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceNumber),
      channel: channel == null && nullToAbsent
          ? const Value.absent()
          : Value(channel),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      balanceAfter: balanceAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(balanceAfter),
      receiptUrl: receiptUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptUrl),
      localReceiptPath: localReceiptPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localReceiptPath),
      reasonRawText: Value(reasonRawText),
      normalizedReason: Value(normalizedReason),
      parsedCategory: Value(parsedCategory),
      commission: Value(commission),
      vat: Value(vat),
      branchName: branchName == null && nullToAbsent
          ? const Value.absent()
          : Value(branchName),
      smsId: Value(smsId),
      threadId: Value(threadId),
      senderAddress: Value(senderAddress),
      rawSmsBody: Value(rawSmsBody),
      smsTimestamp: Value(smsTimestamp),
      importedAt: Value(importedAt),
      smsRead: Value(smsRead),
      parserVersion: Value(parserVersion),
      isRecurring: Value(isRecurring),
      recurringPattern: recurringPattern == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringPattern),
      receiptExtractionStatus: Value(receiptExtractionStatus),
      receiptExtractionError: receiptExtractionError == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptExtractionError),
      receiptExtractionAttemptedAt:
          receiptExtractionAttemptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptExtractionAttemptedAt),
      extractionRetryAttempts: Value(extractionRetryAttempts),
      extractionNextRetryAt: extractionNextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionNextRetryAt),
    );
  }

  factory TransactionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionData(
      id: serializer.fromJson<int>(json['id']),
      transactionHash: serializer.fromJson<String>(json['transactionHash']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      direction: $TransactionsTable.$converterdirection.fromJson(
        serializer.fromJson<String>(json['direction']),
      ),
      counterpartyName: serializer.fromJson<String?>(json['counterpartyName']),
      counterpartyNumber: serializer.fromJson<String?>(
        json['counterpartyNumber'],
      ),
      bankName: serializer.fromJson<String?>(json['bankName']),
      bankTransactionId: serializer.fromJson<String?>(
        json['bankTransactionId'],
      ),
      referenceNumber: serializer.fromJson<String?>(json['referenceNumber']),
      channel: serializer.fromJson<String?>(json['channel']),
      location: serializer.fromJson<String?>(json['location']),
      balanceAfter: serializer.fromJson<double?>(json['balanceAfter']),
      receiptUrl: serializer.fromJson<String?>(json['receiptUrl']),
      localReceiptPath: serializer.fromJson<String?>(json['localReceiptPath']),
      reasonRawText: serializer.fromJson<String>(json['reasonRawText']),
      normalizedReason: serializer.fromJson<String>(json['normalizedReason']),
      parsedCategory: serializer.fromJson<String>(json['parsedCategory']),
      commission: serializer.fromJson<double>(json['commission']),
      vat: serializer.fromJson<double>(json['vat']),
      branchName: serializer.fromJson<String?>(json['branchName']),
      smsId: serializer.fromJson<String>(json['smsId']),
      threadId: serializer.fromJson<String>(json['threadId']),
      senderAddress: serializer.fromJson<String>(json['senderAddress']),
      rawSmsBody: serializer.fromJson<String>(json['rawSmsBody']),
      smsTimestamp: serializer.fromJson<int>(json['smsTimestamp']),
      importedAt: serializer.fromJson<int>(json['importedAt']),
      smsRead: serializer.fromJson<bool>(json['smsRead']),
      parserVersion: serializer.fromJson<int>(json['parserVersion']),
      isRecurring: serializer.fromJson<bool>(json['isRecurring']),
      recurringPattern: serializer.fromJson<String?>(json['recurringPattern']),
      receiptExtractionStatus: serializer.fromJson<String>(
        json['receiptExtractionStatus'],
      ),
      receiptExtractionError: serializer.fromJson<String?>(
        json['receiptExtractionError'],
      ),
      receiptExtractionAttemptedAt: serializer.fromJson<int?>(
        json['receiptExtractionAttemptedAt'],
      ),
      extractionRetryAttempts: serializer.fromJson<int>(
        json['extractionRetryAttempts'],
      ),
      extractionNextRetryAt: serializer.fromJson<int?>(
        json['extractionNextRetryAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'transactionHash': serializer.toJson<String>(transactionHash),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'direction': serializer.toJson<String>(
        $TransactionsTable.$converterdirection.toJson(direction),
      ),
      'counterpartyName': serializer.toJson<String?>(counterpartyName),
      'counterpartyNumber': serializer.toJson<String?>(counterpartyNumber),
      'bankName': serializer.toJson<String?>(bankName),
      'bankTransactionId': serializer.toJson<String?>(bankTransactionId),
      'referenceNumber': serializer.toJson<String?>(referenceNumber),
      'channel': serializer.toJson<String?>(channel),
      'location': serializer.toJson<String?>(location),
      'balanceAfter': serializer.toJson<double?>(balanceAfter),
      'receiptUrl': serializer.toJson<String?>(receiptUrl),
      'localReceiptPath': serializer.toJson<String?>(localReceiptPath),
      'reasonRawText': serializer.toJson<String>(reasonRawText),
      'normalizedReason': serializer.toJson<String>(normalizedReason),
      'parsedCategory': serializer.toJson<String>(parsedCategory),
      'commission': serializer.toJson<double>(commission),
      'vat': serializer.toJson<double>(vat),
      'branchName': serializer.toJson<String?>(branchName),
      'smsId': serializer.toJson<String>(smsId),
      'threadId': serializer.toJson<String>(threadId),
      'senderAddress': serializer.toJson<String>(senderAddress),
      'rawSmsBody': serializer.toJson<String>(rawSmsBody),
      'smsTimestamp': serializer.toJson<int>(smsTimestamp),
      'importedAt': serializer.toJson<int>(importedAt),
      'smsRead': serializer.toJson<bool>(smsRead),
      'parserVersion': serializer.toJson<int>(parserVersion),
      'isRecurring': serializer.toJson<bool>(isRecurring),
      'recurringPattern': serializer.toJson<String?>(recurringPattern),
      'receiptExtractionStatus': serializer.toJson<String>(
        receiptExtractionStatus,
      ),
      'receiptExtractionError': serializer.toJson<String?>(
        receiptExtractionError,
      ),
      'receiptExtractionAttemptedAt': serializer.toJson<int?>(
        receiptExtractionAttemptedAt,
      ),
      'extractionRetryAttempts': serializer.toJson<int>(
        extractionRetryAttempts,
      ),
      'extractionNextRetryAt': serializer.toJson<int?>(extractionNextRetryAt),
    };
  }

  TransactionData copyWith({
    int? id,
    String? transactionHash,
    double? amount,
    String? currency,
    TransactionDirection? direction,
    Value<String?> counterpartyName = const Value.absent(),
    Value<String?> counterpartyNumber = const Value.absent(),
    Value<String?> bankName = const Value.absent(),
    Value<String?> bankTransactionId = const Value.absent(),
    Value<String?> referenceNumber = const Value.absent(),
    Value<String?> channel = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<double?> balanceAfter = const Value.absent(),
    Value<String?> receiptUrl = const Value.absent(),
    Value<String?> localReceiptPath = const Value.absent(),
    String? reasonRawText,
    String? normalizedReason,
    String? parsedCategory,
    double? commission,
    double? vat,
    Value<String?> branchName = const Value.absent(),
    String? smsId,
    String? threadId,
    String? senderAddress,
    String? rawSmsBody,
    int? smsTimestamp,
    int? importedAt,
    bool? smsRead,
    int? parserVersion,
    bool? isRecurring,
    Value<String?> recurringPattern = const Value.absent(),
    String? receiptExtractionStatus,
    Value<String?> receiptExtractionError = const Value.absent(),
    Value<int?> receiptExtractionAttemptedAt = const Value.absent(),
    int? extractionRetryAttempts,
    Value<int?> extractionNextRetryAt = const Value.absent(),
  }) => TransactionData(
    id: id ?? this.id,
    transactionHash: transactionHash ?? this.transactionHash,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    direction: direction ?? this.direction,
    counterpartyName: counterpartyName.present
        ? counterpartyName.value
        : this.counterpartyName,
    counterpartyNumber: counterpartyNumber.present
        ? counterpartyNumber.value
        : this.counterpartyNumber,
    bankName: bankName.present ? bankName.value : this.bankName,
    bankTransactionId: bankTransactionId.present
        ? bankTransactionId.value
        : this.bankTransactionId,
    referenceNumber: referenceNumber.present
        ? referenceNumber.value
        : this.referenceNumber,
    channel: channel.present ? channel.value : this.channel,
    location: location.present ? location.value : this.location,
    balanceAfter: balanceAfter.present ? balanceAfter.value : this.balanceAfter,
    receiptUrl: receiptUrl.present ? receiptUrl.value : this.receiptUrl,
    localReceiptPath: localReceiptPath.present
        ? localReceiptPath.value
        : this.localReceiptPath,
    reasonRawText: reasonRawText ?? this.reasonRawText,
    normalizedReason: normalizedReason ?? this.normalizedReason,
    parsedCategory: parsedCategory ?? this.parsedCategory,
    commission: commission ?? this.commission,
    vat: vat ?? this.vat,
    branchName: branchName.present ? branchName.value : this.branchName,
    smsId: smsId ?? this.smsId,
    threadId: threadId ?? this.threadId,
    senderAddress: senderAddress ?? this.senderAddress,
    rawSmsBody: rawSmsBody ?? this.rawSmsBody,
    smsTimestamp: smsTimestamp ?? this.smsTimestamp,
    importedAt: importedAt ?? this.importedAt,
    smsRead: smsRead ?? this.smsRead,
    parserVersion: parserVersion ?? this.parserVersion,
    isRecurring: isRecurring ?? this.isRecurring,
    recurringPattern: recurringPattern.present
        ? recurringPattern.value
        : this.recurringPattern,
    receiptExtractionStatus:
        receiptExtractionStatus ?? this.receiptExtractionStatus,
    receiptExtractionError: receiptExtractionError.present
        ? receiptExtractionError.value
        : this.receiptExtractionError,
    receiptExtractionAttemptedAt: receiptExtractionAttemptedAt.present
        ? receiptExtractionAttemptedAt.value
        : this.receiptExtractionAttemptedAt,
    extractionRetryAttempts:
        extractionRetryAttempts ?? this.extractionRetryAttempts,
    extractionNextRetryAt: extractionNextRetryAt.present
        ? extractionNextRetryAt.value
        : this.extractionNextRetryAt,
  );
  TransactionData copyWithCompanion(TransactionsCompanion data) {
    return TransactionData(
      id: data.id.present ? data.id.value : this.id,
      transactionHash: data.transactionHash.present
          ? data.transactionHash.value
          : this.transactionHash,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      direction: data.direction.present ? data.direction.value : this.direction,
      counterpartyName: data.counterpartyName.present
          ? data.counterpartyName.value
          : this.counterpartyName,
      counterpartyNumber: data.counterpartyNumber.present
          ? data.counterpartyNumber.value
          : this.counterpartyNumber,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankTransactionId: data.bankTransactionId.present
          ? data.bankTransactionId.value
          : this.bankTransactionId,
      referenceNumber: data.referenceNumber.present
          ? data.referenceNumber.value
          : this.referenceNumber,
      channel: data.channel.present ? data.channel.value : this.channel,
      location: data.location.present ? data.location.value : this.location,
      balanceAfter: data.balanceAfter.present
          ? data.balanceAfter.value
          : this.balanceAfter,
      receiptUrl: data.receiptUrl.present
          ? data.receiptUrl.value
          : this.receiptUrl,
      localReceiptPath: data.localReceiptPath.present
          ? data.localReceiptPath.value
          : this.localReceiptPath,
      reasonRawText: data.reasonRawText.present
          ? data.reasonRawText.value
          : this.reasonRawText,
      normalizedReason: data.normalizedReason.present
          ? data.normalizedReason.value
          : this.normalizedReason,
      parsedCategory: data.parsedCategory.present
          ? data.parsedCategory.value
          : this.parsedCategory,
      commission: data.commission.present
          ? data.commission.value
          : this.commission,
      vat: data.vat.present ? data.vat.value : this.vat,
      branchName: data.branchName.present
          ? data.branchName.value
          : this.branchName,
      smsId: data.smsId.present ? data.smsId.value : this.smsId,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      senderAddress: data.senderAddress.present
          ? data.senderAddress.value
          : this.senderAddress,
      rawSmsBody: data.rawSmsBody.present
          ? data.rawSmsBody.value
          : this.rawSmsBody,
      smsTimestamp: data.smsTimestamp.present
          ? data.smsTimestamp.value
          : this.smsTimestamp,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      smsRead: data.smsRead.present ? data.smsRead.value : this.smsRead,
      parserVersion: data.parserVersion.present
          ? data.parserVersion.value
          : this.parserVersion,
      isRecurring: data.isRecurring.present
          ? data.isRecurring.value
          : this.isRecurring,
      recurringPattern: data.recurringPattern.present
          ? data.recurringPattern.value
          : this.recurringPattern,
      receiptExtractionStatus: data.receiptExtractionStatus.present
          ? data.receiptExtractionStatus.value
          : this.receiptExtractionStatus,
      receiptExtractionError: data.receiptExtractionError.present
          ? data.receiptExtractionError.value
          : this.receiptExtractionError,
      receiptExtractionAttemptedAt: data.receiptExtractionAttemptedAt.present
          ? data.receiptExtractionAttemptedAt.value
          : this.receiptExtractionAttemptedAt,
      extractionRetryAttempts: data.extractionRetryAttempts.present
          ? data.extractionRetryAttempts.value
          : this.extractionRetryAttempts,
      extractionNextRetryAt: data.extractionNextRetryAt.present
          ? data.extractionNextRetryAt.value
          : this.extractionNextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionData(')
          ..write('id: $id, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('direction: $direction, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('counterpartyNumber: $counterpartyNumber, ')
          ..write('bankName: $bankName, ')
          ..write('bankTransactionId: $bankTransactionId, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('channel: $channel, ')
          ..write('location: $location, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('localReceiptPath: $localReceiptPath, ')
          ..write('reasonRawText: $reasonRawText, ')
          ..write('normalizedReason: $normalizedReason, ')
          ..write('parsedCategory: $parsedCategory, ')
          ..write('commission: $commission, ')
          ..write('vat: $vat, ')
          ..write('branchName: $branchName, ')
          ..write('smsId: $smsId, ')
          ..write('threadId: $threadId, ')
          ..write('senderAddress: $senderAddress, ')
          ..write('rawSmsBody: $rawSmsBody, ')
          ..write('smsTimestamp: $smsTimestamp, ')
          ..write('importedAt: $importedAt, ')
          ..write('smsRead: $smsRead, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringPattern: $recurringPattern, ')
          ..write('receiptExtractionStatus: $receiptExtractionStatus, ')
          ..write('receiptExtractionError: $receiptExtractionError, ')
          ..write(
            'receiptExtractionAttemptedAt: $receiptExtractionAttemptedAt, ',
          )
          ..write('extractionRetryAttempts: $extractionRetryAttempts, ')
          ..write('extractionNextRetryAt: $extractionNextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    transactionHash,
    amount,
    currency,
    direction,
    counterpartyName,
    counterpartyNumber,
    bankName,
    bankTransactionId,
    referenceNumber,
    channel,
    location,
    balanceAfter,
    receiptUrl,
    localReceiptPath,
    reasonRawText,
    normalizedReason,
    parsedCategory,
    commission,
    vat,
    branchName,
    smsId,
    threadId,
    senderAddress,
    rawSmsBody,
    smsTimestamp,
    importedAt,
    smsRead,
    parserVersion,
    isRecurring,
    recurringPattern,
    receiptExtractionStatus,
    receiptExtractionError,
    receiptExtractionAttemptedAt,
    extractionRetryAttempts,
    extractionNextRetryAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionData &&
          other.id == this.id &&
          other.transactionHash == this.transactionHash &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.direction == this.direction &&
          other.counterpartyName == this.counterpartyName &&
          other.counterpartyNumber == this.counterpartyNumber &&
          other.bankName == this.bankName &&
          other.bankTransactionId == this.bankTransactionId &&
          other.referenceNumber == this.referenceNumber &&
          other.channel == this.channel &&
          other.location == this.location &&
          other.balanceAfter == this.balanceAfter &&
          other.receiptUrl == this.receiptUrl &&
          other.localReceiptPath == this.localReceiptPath &&
          other.reasonRawText == this.reasonRawText &&
          other.normalizedReason == this.normalizedReason &&
          other.parsedCategory == this.parsedCategory &&
          other.commission == this.commission &&
          other.vat == this.vat &&
          other.branchName == this.branchName &&
          other.smsId == this.smsId &&
          other.threadId == this.threadId &&
          other.senderAddress == this.senderAddress &&
          other.rawSmsBody == this.rawSmsBody &&
          other.smsTimestamp == this.smsTimestamp &&
          other.importedAt == this.importedAt &&
          other.smsRead == this.smsRead &&
          other.parserVersion == this.parserVersion &&
          other.isRecurring == this.isRecurring &&
          other.recurringPattern == this.recurringPattern &&
          other.receiptExtractionStatus == this.receiptExtractionStatus &&
          other.receiptExtractionError == this.receiptExtractionError &&
          other.receiptExtractionAttemptedAt ==
              this.receiptExtractionAttemptedAt &&
          other.extractionRetryAttempts == this.extractionRetryAttempts &&
          other.extractionNextRetryAt == this.extractionNextRetryAt);
}

class TransactionsCompanion extends UpdateCompanion<TransactionData> {
  final Value<int> id;
  final Value<String> transactionHash;
  final Value<double> amount;
  final Value<String> currency;
  final Value<TransactionDirection> direction;
  final Value<String?> counterpartyName;
  final Value<String?> counterpartyNumber;
  final Value<String?> bankName;
  final Value<String?> bankTransactionId;
  final Value<String?> referenceNumber;
  final Value<String?> channel;
  final Value<String?> location;
  final Value<double?> balanceAfter;
  final Value<String?> receiptUrl;
  final Value<String?> localReceiptPath;
  final Value<String> reasonRawText;
  final Value<String> normalizedReason;
  final Value<String> parsedCategory;
  final Value<double> commission;
  final Value<double> vat;
  final Value<String?> branchName;
  final Value<String> smsId;
  final Value<String> threadId;
  final Value<String> senderAddress;
  final Value<String> rawSmsBody;
  final Value<int> smsTimestamp;
  final Value<int> importedAt;
  final Value<bool> smsRead;
  final Value<int> parserVersion;
  final Value<bool> isRecurring;
  final Value<String?> recurringPattern;
  final Value<String> receiptExtractionStatus;
  final Value<String?> receiptExtractionError;
  final Value<int?> receiptExtractionAttemptedAt;
  final Value<int> extractionRetryAttempts;
  final Value<int?> extractionNextRetryAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.transactionHash = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.direction = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.counterpartyNumber = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankTransactionId = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.channel = const Value.absent(),
    this.location = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.localReceiptPath = const Value.absent(),
    this.reasonRawText = const Value.absent(),
    this.normalizedReason = const Value.absent(),
    this.parsedCategory = const Value.absent(),
    this.commission = const Value.absent(),
    this.vat = const Value.absent(),
    this.branchName = const Value.absent(),
    this.smsId = const Value.absent(),
    this.threadId = const Value.absent(),
    this.senderAddress = const Value.absent(),
    this.rawSmsBody = const Value.absent(),
    this.smsTimestamp = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.smsRead = const Value.absent(),
    this.parserVersion = const Value.absent(),
    this.isRecurring = const Value.absent(),
    this.recurringPattern = const Value.absent(),
    this.receiptExtractionStatus = const Value.absent(),
    this.receiptExtractionError = const Value.absent(),
    this.receiptExtractionAttemptedAt = const Value.absent(),
    this.extractionRetryAttempts = const Value.absent(),
    this.extractionNextRetryAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String transactionHash,
    required double amount,
    this.currency = const Value.absent(),
    required TransactionDirection direction,
    this.counterpartyName = const Value.absent(),
    this.counterpartyNumber = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankTransactionId = const Value.absent(),
    this.referenceNumber = const Value.absent(),
    this.channel = const Value.absent(),
    this.location = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.localReceiptPath = const Value.absent(),
    required String reasonRawText,
    required String normalizedReason,
    this.parsedCategory = const Value.absent(),
    this.commission = const Value.absent(),
    this.vat = const Value.absent(),
    this.branchName = const Value.absent(),
    required String smsId,
    required String threadId,
    required String senderAddress,
    required String rawSmsBody,
    required int smsTimestamp,
    required int importedAt,
    this.smsRead = const Value.absent(),
    required int parserVersion,
    this.isRecurring = const Value.absent(),
    this.recurringPattern = const Value.absent(),
    this.receiptExtractionStatus = const Value.absent(),
    this.receiptExtractionError = const Value.absent(),
    this.receiptExtractionAttemptedAt = const Value.absent(),
    this.extractionRetryAttempts = const Value.absent(),
    this.extractionNextRetryAt = const Value.absent(),
  }) : transactionHash = Value(transactionHash),
       amount = Value(amount),
       direction = Value(direction),
       reasonRawText = Value(reasonRawText),
       normalizedReason = Value(normalizedReason),
       smsId = Value(smsId),
       threadId = Value(threadId),
       senderAddress = Value(senderAddress),
       rawSmsBody = Value(rawSmsBody),
       smsTimestamp = Value(smsTimestamp),
       importedAt = Value(importedAt),
       parserVersion = Value(parserVersion);
  static Insertable<TransactionData> custom({
    Expression<int>? id,
    Expression<String>? transactionHash,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<String>? direction,
    Expression<String>? counterpartyName,
    Expression<String>? counterpartyNumber,
    Expression<String>? bankName,
    Expression<String>? bankTransactionId,
    Expression<String>? referenceNumber,
    Expression<String>? channel,
    Expression<String>? location,
    Expression<double>? balanceAfter,
    Expression<String>? receiptUrl,
    Expression<String>? localReceiptPath,
    Expression<String>? reasonRawText,
    Expression<String>? normalizedReason,
    Expression<String>? parsedCategory,
    Expression<double>? commission,
    Expression<double>? vat,
    Expression<String>? branchName,
    Expression<String>? smsId,
    Expression<String>? threadId,
    Expression<String>? senderAddress,
    Expression<String>? rawSmsBody,
    Expression<int>? smsTimestamp,
    Expression<int>? importedAt,
    Expression<bool>? smsRead,
    Expression<int>? parserVersion,
    Expression<bool>? isRecurring,
    Expression<String>? recurringPattern,
    Expression<String>? receiptExtractionStatus,
    Expression<String>? receiptExtractionError,
    Expression<int>? receiptExtractionAttemptedAt,
    Expression<int>? extractionRetryAttempts,
    Expression<int>? extractionNextRetryAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionHash != null) 'transaction_hash': transactionHash,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (direction != null) 'direction': direction,
      if (counterpartyName != null) 'counterparty_name': counterpartyName,
      if (counterpartyNumber != null) 'counterparty_number': counterpartyNumber,
      if (bankName != null) 'bank_name': bankName,
      if (bankTransactionId != null) 'bank_transaction_id': bankTransactionId,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (channel != null) 'channel': channel,
      if (location != null) 'location': location,
      if (balanceAfter != null) 'balance_after': balanceAfter,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (localReceiptPath != null) 'local_receipt_path': localReceiptPath,
      if (reasonRawText != null) 'reason_raw_text': reasonRawText,
      if (normalizedReason != null) 'normalized_reason': normalizedReason,
      if (parsedCategory != null) 'parsed_category': parsedCategory,
      if (commission != null) 'commission': commission,
      if (vat != null) 'vat': vat,
      if (branchName != null) 'branch_name': branchName,
      if (smsId != null) 'sms_id': smsId,
      if (threadId != null) 'thread_id': threadId,
      if (senderAddress != null) 'sender_address': senderAddress,
      if (rawSmsBody != null) 'raw_sms_body': rawSmsBody,
      if (smsTimestamp != null) 'sms_timestamp': smsTimestamp,
      if (importedAt != null) 'imported_at': importedAt,
      if (smsRead != null) 'sms_read': smsRead,
      if (parserVersion != null) 'parser_version': parserVersion,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurringPattern != null) 'recurring_pattern': recurringPattern,
      if (receiptExtractionStatus != null)
        'receipt_extraction_status': receiptExtractionStatus,
      if (receiptExtractionError != null)
        'receipt_extraction_error': receiptExtractionError,
      if (receiptExtractionAttemptedAt != null)
        'receipt_extraction_attempted_at': receiptExtractionAttemptedAt,
      if (extractionRetryAttempts != null)
        'extraction_retry_attempts': extractionRetryAttempts,
      if (extractionNextRetryAt != null)
        'extraction_next_retry_at': extractionNextRetryAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<String>? transactionHash,
    Value<double>? amount,
    Value<String>? currency,
    Value<TransactionDirection>? direction,
    Value<String?>? counterpartyName,
    Value<String?>? counterpartyNumber,
    Value<String?>? bankName,
    Value<String?>? bankTransactionId,
    Value<String?>? referenceNumber,
    Value<String?>? channel,
    Value<String?>? location,
    Value<double?>? balanceAfter,
    Value<String?>? receiptUrl,
    Value<String?>? localReceiptPath,
    Value<String>? reasonRawText,
    Value<String>? normalizedReason,
    Value<String>? parsedCategory,
    Value<double>? commission,
    Value<double>? vat,
    Value<String?>? branchName,
    Value<String>? smsId,
    Value<String>? threadId,
    Value<String>? senderAddress,
    Value<String>? rawSmsBody,
    Value<int>? smsTimestamp,
    Value<int>? importedAt,
    Value<bool>? smsRead,
    Value<int>? parserVersion,
    Value<bool>? isRecurring,
    Value<String?>? recurringPattern,
    Value<String>? receiptExtractionStatus,
    Value<String?>? receiptExtractionError,
    Value<int?>? receiptExtractionAttemptedAt,
    Value<int>? extractionRetryAttempts,
    Value<int?>? extractionNextRetryAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      transactionHash: transactionHash ?? this.transactionHash,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      direction: direction ?? this.direction,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      counterpartyNumber: counterpartyNumber ?? this.counterpartyNumber,
      bankName: bankName ?? this.bankName,
      bankTransactionId: bankTransactionId ?? this.bankTransactionId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      channel: channel ?? this.channel,
      location: location ?? this.location,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      localReceiptPath: localReceiptPath ?? this.localReceiptPath,
      reasonRawText: reasonRawText ?? this.reasonRawText,
      normalizedReason: normalizedReason ?? this.normalizedReason,
      parsedCategory: parsedCategory ?? this.parsedCategory,
      commission: commission ?? this.commission,
      vat: vat ?? this.vat,
      branchName: branchName ?? this.branchName,
      smsId: smsId ?? this.smsId,
      threadId: threadId ?? this.threadId,
      senderAddress: senderAddress ?? this.senderAddress,
      rawSmsBody: rawSmsBody ?? this.rawSmsBody,
      smsTimestamp: smsTimestamp ?? this.smsTimestamp,
      importedAt: importedAt ?? this.importedAt,
      smsRead: smsRead ?? this.smsRead,
      parserVersion: parserVersion ?? this.parserVersion,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      receiptExtractionStatus:
          receiptExtractionStatus ?? this.receiptExtractionStatus,
      receiptExtractionError:
          receiptExtractionError ?? this.receiptExtractionError,
      receiptExtractionAttemptedAt:
          receiptExtractionAttemptedAt ?? this.receiptExtractionAttemptedAt,
      extractionRetryAttempts:
          extractionRetryAttempts ?? this.extractionRetryAttempts,
      extractionNextRetryAt:
          extractionNextRetryAt ?? this.extractionNextRetryAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (transactionHash.present) {
      map['transaction_hash'] = Variable<String>(transactionHash.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(
        $TransactionsTable.$converterdirection.toSql(direction.value),
      );
    }
    if (counterpartyName.present) {
      map['counterparty_name'] = Variable<String>(counterpartyName.value);
    }
    if (counterpartyNumber.present) {
      map['counterparty_number'] = Variable<String>(counterpartyNumber.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankTransactionId.present) {
      map['bank_transaction_id'] = Variable<String>(bankTransactionId.value);
    }
    if (referenceNumber.present) {
      map['reference_number'] = Variable<String>(referenceNumber.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (balanceAfter.present) {
      map['balance_after'] = Variable<double>(balanceAfter.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (localReceiptPath.present) {
      map['local_receipt_path'] = Variable<String>(localReceiptPath.value);
    }
    if (reasonRawText.present) {
      map['reason_raw_text'] = Variable<String>(reasonRawText.value);
    }
    if (normalizedReason.present) {
      map['normalized_reason'] = Variable<String>(normalizedReason.value);
    }
    if (parsedCategory.present) {
      map['parsed_category'] = Variable<String>(parsedCategory.value);
    }
    if (commission.present) {
      map['commission'] = Variable<double>(commission.value);
    }
    if (vat.present) {
      map['vat'] = Variable<double>(vat.value);
    }
    if (branchName.present) {
      map['branch_name'] = Variable<String>(branchName.value);
    }
    if (smsId.present) {
      map['sms_id'] = Variable<String>(smsId.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (senderAddress.present) {
      map['sender_address'] = Variable<String>(senderAddress.value);
    }
    if (rawSmsBody.present) {
      map['raw_sms_body'] = Variable<String>(rawSmsBody.value);
    }
    if (smsTimestamp.present) {
      map['sms_timestamp'] = Variable<int>(smsTimestamp.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<int>(importedAt.value);
    }
    if (smsRead.present) {
      map['sms_read'] = Variable<bool>(smsRead.value);
    }
    if (parserVersion.present) {
      map['parser_version'] = Variable<int>(parserVersion.value);
    }
    if (isRecurring.present) {
      map['is_recurring'] = Variable<bool>(isRecurring.value);
    }
    if (recurringPattern.present) {
      map['recurring_pattern'] = Variable<String>(recurringPattern.value);
    }
    if (receiptExtractionStatus.present) {
      map['receipt_extraction_status'] = Variable<String>(
        receiptExtractionStatus.value,
      );
    }
    if (receiptExtractionError.present) {
      map['receipt_extraction_error'] = Variable<String>(
        receiptExtractionError.value,
      );
    }
    if (receiptExtractionAttemptedAt.present) {
      map['receipt_extraction_attempted_at'] = Variable<int>(
        receiptExtractionAttemptedAt.value,
      );
    }
    if (extractionRetryAttempts.present) {
      map['extraction_retry_attempts'] = Variable<int>(
        extractionRetryAttempts.value,
      );
    }
    if (extractionNextRetryAt.present) {
      map['extraction_next_retry_at'] = Variable<int>(
        extractionNextRetryAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('transactionHash: $transactionHash, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('direction: $direction, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('counterpartyNumber: $counterpartyNumber, ')
          ..write('bankName: $bankName, ')
          ..write('bankTransactionId: $bankTransactionId, ')
          ..write('referenceNumber: $referenceNumber, ')
          ..write('channel: $channel, ')
          ..write('location: $location, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('localReceiptPath: $localReceiptPath, ')
          ..write('reasonRawText: $reasonRawText, ')
          ..write('normalizedReason: $normalizedReason, ')
          ..write('parsedCategory: $parsedCategory, ')
          ..write('commission: $commission, ')
          ..write('vat: $vat, ')
          ..write('branchName: $branchName, ')
          ..write('smsId: $smsId, ')
          ..write('threadId: $threadId, ')
          ..write('senderAddress: $senderAddress, ')
          ..write('rawSmsBody: $rawSmsBody, ')
          ..write('smsTimestamp: $smsTimestamp, ')
          ..write('importedAt: $importedAt, ')
          ..write('smsRead: $smsRead, ')
          ..write('parserVersion: $parserVersion, ')
          ..write('isRecurring: $isRecurring, ')
          ..write('recurringPattern: $recurringPattern, ')
          ..write('receiptExtractionStatus: $receiptExtractionStatus, ')
          ..write('receiptExtractionError: $receiptExtractionError, ')
          ..write(
            'receiptExtractionAttemptedAt: $receiptExtractionAttemptedAt, ',
          )
          ..write('extractionRetryAttempts: $extractionRetryAttempts, ')
          ..write('extractionNextRetryAt: $extractionNextRetryAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, normalizedName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String name;
  final String normalizedName;
  const Category({
    required this.id,
    required this.name,
    required this.normalizedName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      normalizedName: Value(normalizedName),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
    };
  }

  Category copyWith({int? id, String? name, String? normalizedName}) =>
      Category(
        id: id ?? this.id,
        name: name ?? this.name,
        normalizedName: normalizedName ?? this.normalizedName,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, normalizedName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> normalizedName;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String normalizedName,
  }) : name = Value(name),
       normalizedName = Value(normalizedName);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? normalizedName,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? normalizedName,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName')
          ..write(')'))
        .toString();
  }
}

class $SmsInboxTable extends SmsInbox
    with TableInfo<$SmsInboxTable, SmsInboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsInboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isProcessedMeta = const VerificationMeta(
    'isProcessed',
  );
  @override
  late final GeneratedColumn<bool> isProcessed = GeneratedColumn<bool>(
    'is_processed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_processed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _processingAttemptsMeta =
      const VerificationMeta('processingAttempts');
  @override
  late final GeneratedColumn<int> processingAttempts = GeneratedColumn<int>(
    'processing_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastTriedAtMeta = const VerificationMeta(
    'lastTriedAt',
  );
  @override
  late final GeneratedColumn<int> lastTriedAt = GeneratedColumn<int>(
    'last_tried_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<int> processedAt = GeneratedColumn<int>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parsedDateMeta = const VerificationMeta(
    'parsedDate',
  );
  @override
  late final GeneratedColumn<String> parsedDate = GeneratedColumn<String>(
    'parsed_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parsedTimeMeta = const VerificationMeta(
    'parsedTime',
  );
  @override
  late final GeneratedColumn<String> parsedTime = GeneratedColumn<String>(
    'parsed_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _commissionMeta = const VerificationMeta(
    'commission',
  );
  @override
  late final GeneratedColumn<double> commission = GeneratedColumn<double>(
    'commission',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vatMeta = const VerificationMeta('vat');
  @override
  late final GeneratedColumn<double> vat = GeneratedColumn<double>(
    'vat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromAccountMeta = const VerificationMeta(
    'fromAccount',
  );
  @override
  late final GeneratedColumn<String> fromAccount = GeneratedColumn<String>(
    'from_account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAccountMeta = const VerificationMeta(
    'toAccount',
  );
  @override
  late final GeneratedColumn<String> toAccount = GeneratedColumn<String>(
    'to_account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _beneficiaryAccountMeta =
      const VerificationMeta('beneficiaryAccount');
  @override
  late final GeneratedColumn<String> beneficiaryAccount =
      GeneratedColumn<String>(
        'beneficiary_account',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _beneficiaryBankMeta = const VerificationMeta(
    'beneficiaryBank',
  );
  @override
  late final GeneratedColumn<String> beneficiaryBank = GeneratedColumn<String>(
    'beneficiary_bank',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tillNumberMeta = const VerificationMeta(
    'tillNumber',
  );
  @override
  late final GeneratedColumn<String> tillNumber = GeneratedColumn<String>(
    'till_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tinMeta = const VerificationMeta('tin');
  @override
  late final GeneratedColumn<String> tin = GeneratedColumn<String>(
    'tin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vatRegMeta = const VerificationMeta('vatReg');
  @override
  late final GeneratedColumn<String> vatReg = GeneratedColumn<String>(
    'vat_reg',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parseSourceMeta = const VerificationMeta(
    'parseSource',
  );
  @override
  late final GeneratedColumn<String> parseSource = GeneratedColumn<String>(
    'parse_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    threadId,
    address,
    body,
    date,
    isProcessed,
    processingAttempts,
    lastTriedAt,
    processedAt,
    lastError,
    transactionId,
    parsedDate,
    parsedTime,
    amount,
    commission,
    vat,
    total,
    fromAccount,
    toAccount,
    beneficiaryAccount,
    beneficiaryBank,
    transactionType,
    reason,
    tillNumber,
    tin,
    vatReg,
    parseSource,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_inbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsInboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_processed')) {
      context.handle(
        _isProcessedMeta,
        isProcessed.isAcceptableOrUnknown(
          data['is_processed']!,
          _isProcessedMeta,
        ),
      );
    }
    if (data.containsKey('processing_attempts')) {
      context.handle(
        _processingAttemptsMeta,
        processingAttempts.isAcceptableOrUnknown(
          data['processing_attempts']!,
          _processingAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('last_tried_at')) {
      context.handle(
        _lastTriedAtMeta,
        lastTriedAt.isAcceptableOrUnknown(
          data['last_tried_at']!,
          _lastTriedAtMeta,
        ),
      );
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    if (data.containsKey('parsed_date')) {
      context.handle(
        _parsedDateMeta,
        parsedDate.isAcceptableOrUnknown(data['parsed_date']!, _parsedDateMeta),
      );
    }
    if (data.containsKey('parsed_time')) {
      context.handle(
        _parsedTimeMeta,
        parsedTime.isAcceptableOrUnknown(data['parsed_time']!, _parsedTimeMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('commission')) {
      context.handle(
        _commissionMeta,
        commission.isAcceptableOrUnknown(data['commission']!, _commissionMeta),
      );
    }
    if (data.containsKey('vat')) {
      context.handle(
        _vatMeta,
        vat.isAcceptableOrUnknown(data['vat']!, _vatMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('from_account')) {
      context.handle(
        _fromAccountMeta,
        fromAccount.isAcceptableOrUnknown(
          data['from_account']!,
          _fromAccountMeta,
        ),
      );
    }
    if (data.containsKey('to_account')) {
      context.handle(
        _toAccountMeta,
        toAccount.isAcceptableOrUnknown(data['to_account']!, _toAccountMeta),
      );
    }
    if (data.containsKey('beneficiary_account')) {
      context.handle(
        _beneficiaryAccountMeta,
        beneficiaryAccount.isAcceptableOrUnknown(
          data['beneficiary_account']!,
          _beneficiaryAccountMeta,
        ),
      );
    }
    if (data.containsKey('beneficiary_bank')) {
      context.handle(
        _beneficiaryBankMeta,
        beneficiaryBank.isAcceptableOrUnknown(
          data['beneficiary_bank']!,
          _beneficiaryBankMeta,
        ),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('till_number')) {
      context.handle(
        _tillNumberMeta,
        tillNumber.isAcceptableOrUnknown(data['till_number']!, _tillNumberMeta),
      );
    }
    if (data.containsKey('tin')) {
      context.handle(
        _tinMeta,
        tin.isAcceptableOrUnknown(data['tin']!, _tinMeta),
      );
    }
    if (data.containsKey('vat_reg')) {
      context.handle(
        _vatRegMeta,
        vatReg.isAcceptableOrUnknown(data['vat_reg']!, _vatRegMeta),
      );
    }
    if (data.containsKey('parse_source')) {
      context.handle(
        _parseSourceMeta,
        parseSource.isAcceptableOrUnknown(
          data['parse_source']!,
          _parseSourceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsInboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsInboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isProcessed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_processed'],
      )!,
      processingAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processing_attempts'],
      )!,
      lastTriedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_tried_at'],
      ),
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_id'],
      ),
      parsedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_date'],
      ),
      parsedTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parsed_time'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      commission: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}commission'],
      ),
      vat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat'],
      ),
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total'],
      ),
      fromAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_account'],
      ),
      toAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account'],
      ),
      beneficiaryAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary_account'],
      ),
      beneficiaryBank: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}beneficiary_bank'],
      ),
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      tillNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}till_number'],
      ),
      tin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tin'],
      ),
      vatReg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vat_reg'],
      ),
      parseSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parse_source'],
      ),
    );
  }

  @override
  $SmsInboxTable createAlias(String alias) {
    return $SmsInboxTable(attachedDatabase, alias);
  }
}

class SmsInboxData extends DataClass implements Insertable<SmsInboxData> {
  final String id;
  final String? threadId;
  final String address;
  final String body;
  final DateTime date;
  final bool isProcessed;
  final int processingAttempts;
  final int? lastTriedAt;
  final int? processedAt;
  final String? lastError;
  final String? transactionId;
  final String? parsedDate;
  final String? parsedTime;
  final double? amount;
  final double? commission;
  final double? vat;
  final double? total;
  final String? fromAccount;
  final String? toAccount;
  final String? beneficiaryAccount;
  final String? beneficiaryBank;
  final String? transactionType;
  final String? reason;
  final String? tillNumber;
  final String? tin;
  final String? vatReg;
  final String? parseSource;
  const SmsInboxData({
    required this.id,
    this.threadId,
    required this.address,
    required this.body,
    required this.date,
    required this.isProcessed,
    required this.processingAttempts,
    this.lastTriedAt,
    this.processedAt,
    this.lastError,
    this.transactionId,
    this.parsedDate,
    this.parsedTime,
    this.amount,
    this.commission,
    this.vat,
    this.total,
    this.fromAccount,
    this.toAccount,
    this.beneficiaryAccount,
    this.beneficiaryBank,
    this.transactionType,
    this.reason,
    this.tillNumber,
    this.tin,
    this.vatReg,
    this.parseSource,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || threadId != null) {
      map['thread_id'] = Variable<String>(threadId);
    }
    map['address'] = Variable<String>(address);
    map['body'] = Variable<String>(body);
    map['date'] = Variable<DateTime>(date);
    map['is_processed'] = Variable<bool>(isProcessed);
    map['processing_attempts'] = Variable<int>(processingAttempts);
    if (!nullToAbsent || lastTriedAt != null) {
      map['last_tried_at'] = Variable<int>(lastTriedAt);
    }
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<int>(processedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<String>(transactionId);
    }
    if (!nullToAbsent || parsedDate != null) {
      map['parsed_date'] = Variable<String>(parsedDate);
    }
    if (!nullToAbsent || parsedTime != null) {
      map['parsed_time'] = Variable<String>(parsedTime);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || commission != null) {
      map['commission'] = Variable<double>(commission);
    }
    if (!nullToAbsent || vat != null) {
      map['vat'] = Variable<double>(vat);
    }
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<double>(total);
    }
    if (!nullToAbsent || fromAccount != null) {
      map['from_account'] = Variable<String>(fromAccount);
    }
    if (!nullToAbsent || toAccount != null) {
      map['to_account'] = Variable<String>(toAccount);
    }
    if (!nullToAbsent || beneficiaryAccount != null) {
      map['beneficiary_account'] = Variable<String>(beneficiaryAccount);
    }
    if (!nullToAbsent || beneficiaryBank != null) {
      map['beneficiary_bank'] = Variable<String>(beneficiaryBank);
    }
    if (!nullToAbsent || transactionType != null) {
      map['transaction_type'] = Variable<String>(transactionType);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || tillNumber != null) {
      map['till_number'] = Variable<String>(tillNumber);
    }
    if (!nullToAbsent || tin != null) {
      map['tin'] = Variable<String>(tin);
    }
    if (!nullToAbsent || vatReg != null) {
      map['vat_reg'] = Variable<String>(vatReg);
    }
    if (!nullToAbsent || parseSource != null) {
      map['parse_source'] = Variable<String>(parseSource);
    }
    return map;
  }

  SmsInboxCompanion toCompanion(bool nullToAbsent) {
    return SmsInboxCompanion(
      id: Value(id),
      threadId: threadId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadId),
      address: Value(address),
      body: Value(body),
      date: Value(date),
      isProcessed: Value(isProcessed),
      processingAttempts: Value(processingAttempts),
      lastTriedAt: lastTriedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTriedAt),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
      parsedDate: parsedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedDate),
      parsedTime: parsedTime == null && nullToAbsent
          ? const Value.absent()
          : Value(parsedTime),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      commission: commission == null && nullToAbsent
          ? const Value.absent()
          : Value(commission),
      vat: vat == null && nullToAbsent ? const Value.absent() : Value(vat),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
      fromAccount: fromAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccount),
      toAccount: toAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccount),
      beneficiaryAccount: beneficiaryAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiaryAccount),
      beneficiaryBank: beneficiaryBank == null && nullToAbsent
          ? const Value.absent()
          : Value(beneficiaryBank),
      transactionType: transactionType == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionType),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      tillNumber: tillNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tillNumber),
      tin: tin == null && nullToAbsent ? const Value.absent() : Value(tin),
      vatReg: vatReg == null && nullToAbsent
          ? const Value.absent()
          : Value(vatReg),
      parseSource: parseSource == null && nullToAbsent
          ? const Value.absent()
          : Value(parseSource),
    );
  }

  factory SmsInboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsInboxData(
      id: serializer.fromJson<String>(json['id']),
      threadId: serializer.fromJson<String?>(json['threadId']),
      address: serializer.fromJson<String>(json['address']),
      body: serializer.fromJson<String>(json['body']),
      date: serializer.fromJson<DateTime>(json['date']),
      isProcessed: serializer.fromJson<bool>(json['isProcessed']),
      processingAttempts: serializer.fromJson<int>(json['processingAttempts']),
      lastTriedAt: serializer.fromJson<int?>(json['lastTriedAt']),
      processedAt: serializer.fromJson<int?>(json['processedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      transactionId: serializer.fromJson<String?>(json['transactionId']),
      parsedDate: serializer.fromJson<String?>(json['parsedDate']),
      parsedTime: serializer.fromJson<String?>(json['parsedTime']),
      amount: serializer.fromJson<double?>(json['amount']),
      commission: serializer.fromJson<double?>(json['commission']),
      vat: serializer.fromJson<double?>(json['vat']),
      total: serializer.fromJson<double?>(json['total']),
      fromAccount: serializer.fromJson<String?>(json['fromAccount']),
      toAccount: serializer.fromJson<String?>(json['toAccount']),
      beneficiaryAccount: serializer.fromJson<String?>(
        json['beneficiaryAccount'],
      ),
      beneficiaryBank: serializer.fromJson<String?>(json['beneficiaryBank']),
      transactionType: serializer.fromJson<String?>(json['transactionType']),
      reason: serializer.fromJson<String?>(json['reason']),
      tillNumber: serializer.fromJson<String?>(json['tillNumber']),
      tin: serializer.fromJson<String?>(json['tin']),
      vatReg: serializer.fromJson<String?>(json['vatReg']),
      parseSource: serializer.fromJson<String?>(json['parseSource']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'threadId': serializer.toJson<String?>(threadId),
      'address': serializer.toJson<String>(address),
      'body': serializer.toJson<String>(body),
      'date': serializer.toJson<DateTime>(date),
      'isProcessed': serializer.toJson<bool>(isProcessed),
      'processingAttempts': serializer.toJson<int>(processingAttempts),
      'lastTriedAt': serializer.toJson<int?>(lastTriedAt),
      'processedAt': serializer.toJson<int?>(processedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'transactionId': serializer.toJson<String?>(transactionId),
      'parsedDate': serializer.toJson<String?>(parsedDate),
      'parsedTime': serializer.toJson<String?>(parsedTime),
      'amount': serializer.toJson<double?>(amount),
      'commission': serializer.toJson<double?>(commission),
      'vat': serializer.toJson<double?>(vat),
      'total': serializer.toJson<double?>(total),
      'fromAccount': serializer.toJson<String?>(fromAccount),
      'toAccount': serializer.toJson<String?>(toAccount),
      'beneficiaryAccount': serializer.toJson<String?>(beneficiaryAccount),
      'beneficiaryBank': serializer.toJson<String?>(beneficiaryBank),
      'transactionType': serializer.toJson<String?>(transactionType),
      'reason': serializer.toJson<String?>(reason),
      'tillNumber': serializer.toJson<String?>(tillNumber),
      'tin': serializer.toJson<String?>(tin),
      'vatReg': serializer.toJson<String?>(vatReg),
      'parseSource': serializer.toJson<String?>(parseSource),
    };
  }

  SmsInboxData copyWith({
    String? id,
    Value<String?> threadId = const Value.absent(),
    String? address,
    String? body,
    DateTime? date,
    bool? isProcessed,
    int? processingAttempts,
    Value<int?> lastTriedAt = const Value.absent(),
    Value<int?> processedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> transactionId = const Value.absent(),
    Value<String?> parsedDate = const Value.absent(),
    Value<String?> parsedTime = const Value.absent(),
    Value<double?> amount = const Value.absent(),
    Value<double?> commission = const Value.absent(),
    Value<double?> vat = const Value.absent(),
    Value<double?> total = const Value.absent(),
    Value<String?> fromAccount = const Value.absent(),
    Value<String?> toAccount = const Value.absent(),
    Value<String?> beneficiaryAccount = const Value.absent(),
    Value<String?> beneficiaryBank = const Value.absent(),
    Value<String?> transactionType = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<String?> tillNumber = const Value.absent(),
    Value<String?> tin = const Value.absent(),
    Value<String?> vatReg = const Value.absent(),
    Value<String?> parseSource = const Value.absent(),
  }) => SmsInboxData(
    id: id ?? this.id,
    threadId: threadId.present ? threadId.value : this.threadId,
    address: address ?? this.address,
    body: body ?? this.body,
    date: date ?? this.date,
    isProcessed: isProcessed ?? this.isProcessed,
    processingAttempts: processingAttempts ?? this.processingAttempts,
    lastTriedAt: lastTriedAt.present ? lastTriedAt.value : this.lastTriedAt,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
    parsedDate: parsedDate.present ? parsedDate.value : this.parsedDate,
    parsedTime: parsedTime.present ? parsedTime.value : this.parsedTime,
    amount: amount.present ? amount.value : this.amount,
    commission: commission.present ? commission.value : this.commission,
    vat: vat.present ? vat.value : this.vat,
    total: total.present ? total.value : this.total,
    fromAccount: fromAccount.present ? fromAccount.value : this.fromAccount,
    toAccount: toAccount.present ? toAccount.value : this.toAccount,
    beneficiaryAccount: beneficiaryAccount.present
        ? beneficiaryAccount.value
        : this.beneficiaryAccount,
    beneficiaryBank: beneficiaryBank.present
        ? beneficiaryBank.value
        : this.beneficiaryBank,
    transactionType: transactionType.present
        ? transactionType.value
        : this.transactionType,
    reason: reason.present ? reason.value : this.reason,
    tillNumber: tillNumber.present ? tillNumber.value : this.tillNumber,
    tin: tin.present ? tin.value : this.tin,
    vatReg: vatReg.present ? vatReg.value : this.vatReg,
    parseSource: parseSource.present ? parseSource.value : this.parseSource,
  );
  SmsInboxData copyWithCompanion(SmsInboxCompanion data) {
    return SmsInboxData(
      id: data.id.present ? data.id.value : this.id,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      address: data.address.present ? data.address.value : this.address,
      body: data.body.present ? data.body.value : this.body,
      date: data.date.present ? data.date.value : this.date,
      isProcessed: data.isProcessed.present
          ? data.isProcessed.value
          : this.isProcessed,
      processingAttempts: data.processingAttempts.present
          ? data.processingAttempts.value
          : this.processingAttempts,
      lastTriedAt: data.lastTriedAt.present
          ? data.lastTriedAt.value
          : this.lastTriedAt,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      parsedDate: data.parsedDate.present
          ? data.parsedDate.value
          : this.parsedDate,
      parsedTime: data.parsedTime.present
          ? data.parsedTime.value
          : this.parsedTime,
      amount: data.amount.present ? data.amount.value : this.amount,
      commission: data.commission.present
          ? data.commission.value
          : this.commission,
      vat: data.vat.present ? data.vat.value : this.vat,
      total: data.total.present ? data.total.value : this.total,
      fromAccount: data.fromAccount.present
          ? data.fromAccount.value
          : this.fromAccount,
      toAccount: data.toAccount.present ? data.toAccount.value : this.toAccount,
      beneficiaryAccount: data.beneficiaryAccount.present
          ? data.beneficiaryAccount.value
          : this.beneficiaryAccount,
      beneficiaryBank: data.beneficiaryBank.present
          ? data.beneficiaryBank.value
          : this.beneficiaryBank,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      reason: data.reason.present ? data.reason.value : this.reason,
      tillNumber: data.tillNumber.present
          ? data.tillNumber.value
          : this.tillNumber,
      tin: data.tin.present ? data.tin.value : this.tin,
      vatReg: data.vatReg.present ? data.vatReg.value : this.vatReg,
      parseSource: data.parseSource.present
          ? data.parseSource.value
          : this.parseSource,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsInboxData(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('address: $address, ')
          ..write('body: $body, ')
          ..write('date: $date, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('processingAttempts: $processingAttempts, ')
          ..write('lastTriedAt: $lastTriedAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('lastError: $lastError, ')
          ..write('transactionId: $transactionId, ')
          ..write('parsedDate: $parsedDate, ')
          ..write('parsedTime: $parsedTime, ')
          ..write('amount: $amount, ')
          ..write('commission: $commission, ')
          ..write('vat: $vat, ')
          ..write('total: $total, ')
          ..write('fromAccount: $fromAccount, ')
          ..write('toAccount: $toAccount, ')
          ..write('beneficiaryAccount: $beneficiaryAccount, ')
          ..write('beneficiaryBank: $beneficiaryBank, ')
          ..write('transactionType: $transactionType, ')
          ..write('reason: $reason, ')
          ..write('tillNumber: $tillNumber, ')
          ..write('tin: $tin, ')
          ..write('vatReg: $vatReg, ')
          ..write('parseSource: $parseSource')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    threadId,
    address,
    body,
    date,
    isProcessed,
    processingAttempts,
    lastTriedAt,
    processedAt,
    lastError,
    transactionId,
    parsedDate,
    parsedTime,
    amount,
    commission,
    vat,
    total,
    fromAccount,
    toAccount,
    beneficiaryAccount,
    beneficiaryBank,
    transactionType,
    reason,
    tillNumber,
    tin,
    vatReg,
    parseSource,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsInboxData &&
          other.id == this.id &&
          other.threadId == this.threadId &&
          other.address == this.address &&
          other.body == this.body &&
          other.date == this.date &&
          other.isProcessed == this.isProcessed &&
          other.processingAttempts == this.processingAttempts &&
          other.lastTriedAt == this.lastTriedAt &&
          other.processedAt == this.processedAt &&
          other.lastError == this.lastError &&
          other.transactionId == this.transactionId &&
          other.parsedDate == this.parsedDate &&
          other.parsedTime == this.parsedTime &&
          other.amount == this.amount &&
          other.commission == this.commission &&
          other.vat == this.vat &&
          other.total == this.total &&
          other.fromAccount == this.fromAccount &&
          other.toAccount == this.toAccount &&
          other.beneficiaryAccount == this.beneficiaryAccount &&
          other.beneficiaryBank == this.beneficiaryBank &&
          other.transactionType == this.transactionType &&
          other.reason == this.reason &&
          other.tillNumber == this.tillNumber &&
          other.tin == this.tin &&
          other.vatReg == this.vatReg &&
          other.parseSource == this.parseSource);
}

class SmsInboxCompanion extends UpdateCompanion<SmsInboxData> {
  final Value<String> id;
  final Value<String?> threadId;
  final Value<String> address;
  final Value<String> body;
  final Value<DateTime> date;
  final Value<bool> isProcessed;
  final Value<int> processingAttempts;
  final Value<int?> lastTriedAt;
  final Value<int?> processedAt;
  final Value<String?> lastError;
  final Value<String?> transactionId;
  final Value<String?> parsedDate;
  final Value<String?> parsedTime;
  final Value<double?> amount;
  final Value<double?> commission;
  final Value<double?> vat;
  final Value<double?> total;
  final Value<String?> fromAccount;
  final Value<String?> toAccount;
  final Value<String?> beneficiaryAccount;
  final Value<String?> beneficiaryBank;
  final Value<String?> transactionType;
  final Value<String?> reason;
  final Value<String?> tillNumber;
  final Value<String?> tin;
  final Value<String?> vatReg;
  final Value<String?> parseSource;
  final Value<int> rowid;
  const SmsInboxCompanion({
    this.id = const Value.absent(),
    this.threadId = const Value.absent(),
    this.address = const Value.absent(),
    this.body = const Value.absent(),
    this.date = const Value.absent(),
    this.isProcessed = const Value.absent(),
    this.processingAttempts = const Value.absent(),
    this.lastTriedAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.parsedDate = const Value.absent(),
    this.parsedTime = const Value.absent(),
    this.amount = const Value.absent(),
    this.commission = const Value.absent(),
    this.vat = const Value.absent(),
    this.total = const Value.absent(),
    this.fromAccount = const Value.absent(),
    this.toAccount = const Value.absent(),
    this.beneficiaryAccount = const Value.absent(),
    this.beneficiaryBank = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.reason = const Value.absent(),
    this.tillNumber = const Value.absent(),
    this.tin = const Value.absent(),
    this.vatReg = const Value.absent(),
    this.parseSource = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsInboxCompanion.insert({
    required String id,
    this.threadId = const Value.absent(),
    required String address,
    required String body,
    required DateTime date,
    this.isProcessed = const Value.absent(),
    this.processingAttempts = const Value.absent(),
    this.lastTriedAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.parsedDate = const Value.absent(),
    this.parsedTime = const Value.absent(),
    this.amount = const Value.absent(),
    this.commission = const Value.absent(),
    this.vat = const Value.absent(),
    this.total = const Value.absent(),
    this.fromAccount = const Value.absent(),
    this.toAccount = const Value.absent(),
    this.beneficiaryAccount = const Value.absent(),
    this.beneficiaryBank = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.reason = const Value.absent(),
    this.tillNumber = const Value.absent(),
    this.tin = const Value.absent(),
    this.vatReg = const Value.absent(),
    this.parseSource = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       address = Value(address),
       body = Value(body),
       date = Value(date);
  static Insertable<SmsInboxData> custom({
    Expression<String>? id,
    Expression<String>? threadId,
    Expression<String>? address,
    Expression<String>? body,
    Expression<DateTime>? date,
    Expression<bool>? isProcessed,
    Expression<int>? processingAttempts,
    Expression<int>? lastTriedAt,
    Expression<int>? processedAt,
    Expression<String>? lastError,
    Expression<String>? transactionId,
    Expression<String>? parsedDate,
    Expression<String>? parsedTime,
    Expression<double>? amount,
    Expression<double>? commission,
    Expression<double>? vat,
    Expression<double>? total,
    Expression<String>? fromAccount,
    Expression<String>? toAccount,
    Expression<String>? beneficiaryAccount,
    Expression<String>? beneficiaryBank,
    Expression<String>? transactionType,
    Expression<String>? reason,
    Expression<String>? tillNumber,
    Expression<String>? tin,
    Expression<String>? vatReg,
    Expression<String>? parseSource,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (threadId != null) 'thread_id': threadId,
      if (address != null) 'address': address,
      if (body != null) 'body': body,
      if (date != null) 'date': date,
      if (isProcessed != null) 'is_processed': isProcessed,
      if (processingAttempts != null) 'processing_attempts': processingAttempts,
      if (lastTriedAt != null) 'last_tried_at': lastTriedAt,
      if (processedAt != null) 'processed_at': processedAt,
      if (lastError != null) 'last_error': lastError,
      if (transactionId != null) 'transaction_id': transactionId,
      if (parsedDate != null) 'parsed_date': parsedDate,
      if (parsedTime != null) 'parsed_time': parsedTime,
      if (amount != null) 'amount': amount,
      if (commission != null) 'commission': commission,
      if (vat != null) 'vat': vat,
      if (total != null) 'total': total,
      if (fromAccount != null) 'from_account': fromAccount,
      if (toAccount != null) 'to_account': toAccount,
      if (beneficiaryAccount != null) 'beneficiary_account': beneficiaryAccount,
      if (beneficiaryBank != null) 'beneficiary_bank': beneficiaryBank,
      if (transactionType != null) 'transaction_type': transactionType,
      if (reason != null) 'reason': reason,
      if (tillNumber != null) 'till_number': tillNumber,
      if (tin != null) 'tin': tin,
      if (vatReg != null) 'vat_reg': vatReg,
      if (parseSource != null) 'parse_source': parseSource,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsInboxCompanion copyWith({
    Value<String>? id,
    Value<String?>? threadId,
    Value<String>? address,
    Value<String>? body,
    Value<DateTime>? date,
    Value<bool>? isProcessed,
    Value<int>? processingAttempts,
    Value<int?>? lastTriedAt,
    Value<int?>? processedAt,
    Value<String?>? lastError,
    Value<String?>? transactionId,
    Value<String?>? parsedDate,
    Value<String?>? parsedTime,
    Value<double?>? amount,
    Value<double?>? commission,
    Value<double?>? vat,
    Value<double?>? total,
    Value<String?>? fromAccount,
    Value<String?>? toAccount,
    Value<String?>? beneficiaryAccount,
    Value<String?>? beneficiaryBank,
    Value<String?>? transactionType,
    Value<String?>? reason,
    Value<String?>? tillNumber,
    Value<String?>? tin,
    Value<String?>? vatReg,
    Value<String?>? parseSource,
    Value<int>? rowid,
  }) {
    return SmsInboxCompanion(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      address: address ?? this.address,
      body: body ?? this.body,
      date: date ?? this.date,
      isProcessed: isProcessed ?? this.isProcessed,
      processingAttempts: processingAttempts ?? this.processingAttempts,
      lastTriedAt: lastTriedAt ?? this.lastTriedAt,
      processedAt: processedAt ?? this.processedAt,
      lastError: lastError ?? this.lastError,
      transactionId: transactionId ?? this.transactionId,
      parsedDate: parsedDate ?? this.parsedDate,
      parsedTime: parsedTime ?? this.parsedTime,
      amount: amount ?? this.amount,
      commission: commission ?? this.commission,
      vat: vat ?? this.vat,
      total: total ?? this.total,
      fromAccount: fromAccount ?? this.fromAccount,
      toAccount: toAccount ?? this.toAccount,
      beneficiaryAccount: beneficiaryAccount ?? this.beneficiaryAccount,
      beneficiaryBank: beneficiaryBank ?? this.beneficiaryBank,
      transactionType: transactionType ?? this.transactionType,
      reason: reason ?? this.reason,
      tillNumber: tillNumber ?? this.tillNumber,
      tin: tin ?? this.tin,
      vatReg: vatReg ?? this.vatReg,
      parseSource: parseSource ?? this.parseSource,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isProcessed.present) {
      map['is_processed'] = Variable<bool>(isProcessed.value);
    }
    if (processingAttempts.present) {
      map['processing_attempts'] = Variable<int>(processingAttempts.value);
    }
    if (lastTriedAt.present) {
      map['last_tried_at'] = Variable<int>(lastTriedAt.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<int>(processedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (parsedDate.present) {
      map['parsed_date'] = Variable<String>(parsedDate.value);
    }
    if (parsedTime.present) {
      map['parsed_time'] = Variable<String>(parsedTime.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (commission.present) {
      map['commission'] = Variable<double>(commission.value);
    }
    if (vat.present) {
      map['vat'] = Variable<double>(vat.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    if (fromAccount.present) {
      map['from_account'] = Variable<String>(fromAccount.value);
    }
    if (toAccount.present) {
      map['to_account'] = Variable<String>(toAccount.value);
    }
    if (beneficiaryAccount.present) {
      map['beneficiary_account'] = Variable<String>(beneficiaryAccount.value);
    }
    if (beneficiaryBank.present) {
      map['beneficiary_bank'] = Variable<String>(beneficiaryBank.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (tillNumber.present) {
      map['till_number'] = Variable<String>(tillNumber.value);
    }
    if (tin.present) {
      map['tin'] = Variable<String>(tin.value);
    }
    if (vatReg.present) {
      map['vat_reg'] = Variable<String>(vatReg.value);
    }
    if (parseSource.present) {
      map['parse_source'] = Variable<String>(parseSource.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsInboxCompanion(')
          ..write('id: $id, ')
          ..write('threadId: $threadId, ')
          ..write('address: $address, ')
          ..write('body: $body, ')
          ..write('date: $date, ')
          ..write('isProcessed: $isProcessed, ')
          ..write('processingAttempts: $processingAttempts, ')
          ..write('lastTriedAt: $lastTriedAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('lastError: $lastError, ')
          ..write('transactionId: $transactionId, ')
          ..write('parsedDate: $parsedDate, ')
          ..write('parsedTime: $parsedTime, ')
          ..write('amount: $amount, ')
          ..write('commission: $commission, ')
          ..write('vat: $vat, ')
          ..write('total: $total, ')
          ..write('fromAccount: $fromAccount, ')
          ..write('toAccount: $toAccount, ')
          ..write('beneficiaryAccount: $beneficiaryAccount, ')
          ..write('beneficiaryBank: $beneficiaryBank, ')
          ..write('transactionType: $transactionType, ')
          ..write('reason: $reason, ')
          ..write('tillNumber: $tillNumber, ')
          ..write('tin: $tin, ')
          ..write('vatReg: $vatReg, ')
          ..write('parseSource: $parseSource, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SmsInboxTable smsInbox = $SmsInboxTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactions,
    categories,
    smsInbox,
  ];
}

typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required String transactionHash,
      required double amount,
      Value<String> currency,
      required TransactionDirection direction,
      Value<String?> counterpartyName,
      Value<String?> counterpartyNumber,
      Value<String?> bankName,
      Value<String?> bankTransactionId,
      Value<String?> referenceNumber,
      Value<String?> channel,
      Value<String?> location,
      Value<double?> balanceAfter,
      Value<String?> receiptUrl,
      Value<String?> localReceiptPath,
      required String reasonRawText,
      required String normalizedReason,
      Value<String> parsedCategory,
      Value<double> commission,
      Value<double> vat,
      Value<String?> branchName,
      required String smsId,
      required String threadId,
      required String senderAddress,
      required String rawSmsBody,
      required int smsTimestamp,
      required int importedAt,
      Value<bool> smsRead,
      required int parserVersion,
      Value<bool> isRecurring,
      Value<String?> recurringPattern,
      Value<String> receiptExtractionStatus,
      Value<String?> receiptExtractionError,
      Value<int?> receiptExtractionAttemptedAt,
      Value<int> extractionRetryAttempts,
      Value<int?> extractionNextRetryAt,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<String> transactionHash,
      Value<double> amount,
      Value<String> currency,
      Value<TransactionDirection> direction,
      Value<String?> counterpartyName,
      Value<String?> counterpartyNumber,
      Value<String?> bankName,
      Value<String?> bankTransactionId,
      Value<String?> referenceNumber,
      Value<String?> channel,
      Value<String?> location,
      Value<double?> balanceAfter,
      Value<String?> receiptUrl,
      Value<String?> localReceiptPath,
      Value<String> reasonRawText,
      Value<String> normalizedReason,
      Value<String> parsedCategory,
      Value<double> commission,
      Value<double> vat,
      Value<String?> branchName,
      Value<String> smsId,
      Value<String> threadId,
      Value<String> senderAddress,
      Value<String> rawSmsBody,
      Value<int> smsTimestamp,
      Value<int> importedAt,
      Value<bool> smsRead,
      Value<int> parserVersion,
      Value<bool> isRecurring,
      Value<String?> recurringPattern,
      Value<String> receiptExtractionStatus,
      Value<String?> receiptExtractionError,
      Value<int?> receiptExtractionAttemptedAt,
      Value<int> extractionRetryAttempts,
      Value<int?> extractionNextRetryAt,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionHash => $composableBuilder(
    column: $table.transactionHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    TransactionDirection,
    TransactionDirection,
    String
  >
  get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterpartyNumber => $composableBuilder(
    column: $table.counterpartyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankTransactionId => $composableBuilder(
    column: $table.bankTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceNumber => $composableBuilder(
    column: $table.referenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localReceiptPath => $composableBuilder(
    column: $table.localReceiptPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonRawText => $composableBuilder(
    column: $table.reasonRawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedReason => $composableBuilder(
    column: $table.normalizedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedCategory => $composableBuilder(
    column: $table.parsedCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get commission => $composableBuilder(
    column: $table.commission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vat => $composableBuilder(
    column: $table.vat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get smsId => $composableBuilder(
    column: $table.smsId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderAddress => $composableBuilder(
    column: $table.senderAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get smsTimestamp => $composableBuilder(
    column: $table.smsTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get smsRead => $composableBuilder(
    column: $table.smsRead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurringPattern => $composableBuilder(
    column: $table.recurringPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptExtractionStatus => $composableBuilder(
    column: $table.receiptExtractionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptExtractionError => $composableBuilder(
    column: $table.receiptExtractionError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptExtractionAttemptedAt => $composableBuilder(
    column: $table.receiptExtractionAttemptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extractionRetryAttempts => $composableBuilder(
    column: $table.extractionRetryAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extractionNextRetryAt => $composableBuilder(
    column: $table.extractionNextRetryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionHash => $composableBuilder(
    column: $table.transactionHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterpartyNumber => $composableBuilder(
    column: $table.counterpartyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankTransactionId => $composableBuilder(
    column: $table.bankTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceNumber => $composableBuilder(
    column: $table.referenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localReceiptPath => $composableBuilder(
    column: $table.localReceiptPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonRawText => $composableBuilder(
    column: $table.reasonRawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedReason => $composableBuilder(
    column: $table.normalizedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedCategory => $composableBuilder(
    column: $table.parsedCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get commission => $composableBuilder(
    column: $table.commission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vat => $composableBuilder(
    column: $table.vat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get smsId => $composableBuilder(
    column: $table.smsId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderAddress => $composableBuilder(
    column: $table.senderAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get smsTimestamp => $composableBuilder(
    column: $table.smsTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get smsRead => $composableBuilder(
    column: $table.smsRead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurringPattern => $composableBuilder(
    column: $table.recurringPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptExtractionStatus => $composableBuilder(
    column: $table.receiptExtractionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptExtractionError => $composableBuilder(
    column: $table.receiptExtractionError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptExtractionAttemptedAt => $composableBuilder(
    column: $table.receiptExtractionAttemptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extractionRetryAttempts => $composableBuilder(
    column: $table.extractionRetryAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extractionNextRetryAt => $composableBuilder(
    column: $table.extractionNextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionHash => $composableBuilder(
    column: $table.transactionHash,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionDirection, String>
  get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterpartyNumber => $composableBuilder(
    column: $table.counterpartyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankTransactionId => $composableBuilder(
    column: $table.bankTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceNumber => $composableBuilder(
    column: $table.referenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
    column: $table.receiptUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localReceiptPath => $composableBuilder(
    column: $table.localReceiptPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reasonRawText => $composableBuilder(
    column: $table.reasonRawText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedReason => $composableBuilder(
    column: $table.normalizedReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parsedCategory => $composableBuilder(
    column: $table.parsedCategory,
    builder: (column) => column,
  );

  GeneratedColumn<double> get commission => $composableBuilder(
    column: $table.commission,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vat =>
      $composableBuilder(column: $table.vat, builder: (column) => column);

  GeneratedColumn<String> get branchName => $composableBuilder(
    column: $table.branchName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get smsId =>
      $composableBuilder(column: $table.smsId, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get senderAddress => $composableBuilder(
    column: $table.senderAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawSmsBody => $composableBuilder(
    column: $table.rawSmsBody,
    builder: (column) => column,
  );

  GeneratedColumn<int> get smsTimestamp => $composableBuilder(
    column: $table.smsTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get smsRead =>
      $composableBuilder(column: $table.smsRead, builder: (column) => column);

  GeneratedColumn<int> get parserVersion => $composableBuilder(
    column: $table.parserVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRecurring => $composableBuilder(
    column: $table.isRecurring,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurringPattern => $composableBuilder(
    column: $table.recurringPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptExtractionStatus => $composableBuilder(
    column: $table.receiptExtractionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptExtractionError => $composableBuilder(
    column: $table.receiptExtractionError,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receiptExtractionAttemptedAt => $composableBuilder(
    column: $table.receiptExtractionAttemptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extractionRetryAttempts => $composableBuilder(
    column: $table.extractionRetryAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extractionNextRetryAt => $composableBuilder(
    column: $table.extractionNextRetryAt,
    builder: (column) => column,
  );
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionData,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionData,
            BaseReferences<_$AppDatabase, $TransactionsTable, TransactionData>,
          ),
          TransactionData,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> transactionHash = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<TransactionDirection> direction = const Value.absent(),
                Value<String?> counterpartyName = const Value.absent(),
                Value<String?> counterpartyNumber = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankTransactionId = const Value.absent(),
                Value<String?> referenceNumber = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> balanceAfter = const Value.absent(),
                Value<String?> receiptUrl = const Value.absent(),
                Value<String?> localReceiptPath = const Value.absent(),
                Value<String> reasonRawText = const Value.absent(),
                Value<String> normalizedReason = const Value.absent(),
                Value<String> parsedCategory = const Value.absent(),
                Value<double> commission = const Value.absent(),
                Value<double> vat = const Value.absent(),
                Value<String?> branchName = const Value.absent(),
                Value<String> smsId = const Value.absent(),
                Value<String> threadId = const Value.absent(),
                Value<String> senderAddress = const Value.absent(),
                Value<String> rawSmsBody = const Value.absent(),
                Value<int> smsTimestamp = const Value.absent(),
                Value<int> importedAt = const Value.absent(),
                Value<bool> smsRead = const Value.absent(),
                Value<int> parserVersion = const Value.absent(),
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringPattern = const Value.absent(),
                Value<String> receiptExtractionStatus = const Value.absent(),
                Value<String?> receiptExtractionError = const Value.absent(),
                Value<int?> receiptExtractionAttemptedAt = const Value.absent(),
                Value<int> extractionRetryAttempts = const Value.absent(),
                Value<int?> extractionNextRetryAt = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                transactionHash: transactionHash,
                amount: amount,
                currency: currency,
                direction: direction,
                counterpartyName: counterpartyName,
                counterpartyNumber: counterpartyNumber,
                bankName: bankName,
                bankTransactionId: bankTransactionId,
                referenceNumber: referenceNumber,
                channel: channel,
                location: location,
                balanceAfter: balanceAfter,
                receiptUrl: receiptUrl,
                localReceiptPath: localReceiptPath,
                reasonRawText: reasonRawText,
                normalizedReason: normalizedReason,
                parsedCategory: parsedCategory,
                commission: commission,
                vat: vat,
                branchName: branchName,
                smsId: smsId,
                threadId: threadId,
                senderAddress: senderAddress,
                rawSmsBody: rawSmsBody,
                smsTimestamp: smsTimestamp,
                importedAt: importedAt,
                smsRead: smsRead,
                parserVersion: parserVersion,
                isRecurring: isRecurring,
                recurringPattern: recurringPattern,
                receiptExtractionStatus: receiptExtractionStatus,
                receiptExtractionError: receiptExtractionError,
                receiptExtractionAttemptedAt: receiptExtractionAttemptedAt,
                extractionRetryAttempts: extractionRetryAttempts,
                extractionNextRetryAt: extractionNextRetryAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String transactionHash,
                required double amount,
                Value<String> currency = const Value.absent(),
                required TransactionDirection direction,
                Value<String?> counterpartyName = const Value.absent(),
                Value<String?> counterpartyNumber = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankTransactionId = const Value.absent(),
                Value<String?> referenceNumber = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> balanceAfter = const Value.absent(),
                Value<String?> receiptUrl = const Value.absent(),
                Value<String?> localReceiptPath = const Value.absent(),
                required String reasonRawText,
                required String normalizedReason,
                Value<String> parsedCategory = const Value.absent(),
                Value<double> commission = const Value.absent(),
                Value<double> vat = const Value.absent(),
                Value<String?> branchName = const Value.absent(),
                required String smsId,
                required String threadId,
                required String senderAddress,
                required String rawSmsBody,
                required int smsTimestamp,
                required int importedAt,
                Value<bool> smsRead = const Value.absent(),
                required int parserVersion,
                Value<bool> isRecurring = const Value.absent(),
                Value<String?> recurringPattern = const Value.absent(),
                Value<String> receiptExtractionStatus = const Value.absent(),
                Value<String?> receiptExtractionError = const Value.absent(),
                Value<int?> receiptExtractionAttemptedAt = const Value.absent(),
                Value<int> extractionRetryAttempts = const Value.absent(),
                Value<int?> extractionNextRetryAt = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                transactionHash: transactionHash,
                amount: amount,
                currency: currency,
                direction: direction,
                counterpartyName: counterpartyName,
                counterpartyNumber: counterpartyNumber,
                bankName: bankName,
                bankTransactionId: bankTransactionId,
                referenceNumber: referenceNumber,
                channel: channel,
                location: location,
                balanceAfter: balanceAfter,
                receiptUrl: receiptUrl,
                localReceiptPath: localReceiptPath,
                reasonRawText: reasonRawText,
                normalizedReason: normalizedReason,
                parsedCategory: parsedCategory,
                commission: commission,
                vat: vat,
                branchName: branchName,
                smsId: smsId,
                threadId: threadId,
                senderAddress: senderAddress,
                rawSmsBody: rawSmsBody,
                smsTimestamp: smsTimestamp,
                importedAt: importedAt,
                smsRead: smsRead,
                parserVersion: parserVersion,
                isRecurring: isRecurring,
                recurringPattern: recurringPattern,
                receiptExtractionStatus: receiptExtractionStatus,
                receiptExtractionError: receiptExtractionError,
                receiptExtractionAttemptedAt: receiptExtractionAttemptedAt,
                extractionRetryAttempts: extractionRetryAttempts,
                extractionNextRetryAt: extractionNextRetryAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionData,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionData,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionData>,
      ),
      TransactionData,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      required String normalizedName,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> normalizedName,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
          Category,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                normalizedName: normalizedName,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String normalizedName,
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                normalizedName: normalizedName,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, BaseReferences<_$AppDatabase, $CategoriesTable, Category>),
      Category,
      PrefetchHooks Function()
    >;
typedef $$SmsInboxTableCreateCompanionBuilder =
    SmsInboxCompanion Function({
      required String id,
      Value<String?> threadId,
      required String address,
      required String body,
      required DateTime date,
      Value<bool> isProcessed,
      Value<int> processingAttempts,
      Value<int?> lastTriedAt,
      Value<int?> processedAt,
      Value<String?> lastError,
      Value<String?> transactionId,
      Value<String?> parsedDate,
      Value<String?> parsedTime,
      Value<double?> amount,
      Value<double?> commission,
      Value<double?> vat,
      Value<double?> total,
      Value<String?> fromAccount,
      Value<String?> toAccount,
      Value<String?> beneficiaryAccount,
      Value<String?> beneficiaryBank,
      Value<String?> transactionType,
      Value<String?> reason,
      Value<String?> tillNumber,
      Value<String?> tin,
      Value<String?> vatReg,
      Value<String?> parseSource,
      Value<int> rowid,
    });
typedef $$SmsInboxTableUpdateCompanionBuilder =
    SmsInboxCompanion Function({
      Value<String> id,
      Value<String?> threadId,
      Value<String> address,
      Value<String> body,
      Value<DateTime> date,
      Value<bool> isProcessed,
      Value<int> processingAttempts,
      Value<int?> lastTriedAt,
      Value<int?> processedAt,
      Value<String?> lastError,
      Value<String?> transactionId,
      Value<String?> parsedDate,
      Value<String?> parsedTime,
      Value<double?> amount,
      Value<double?> commission,
      Value<double?> vat,
      Value<double?> total,
      Value<String?> fromAccount,
      Value<String?> toAccount,
      Value<String?> beneficiaryAccount,
      Value<String?> beneficiaryBank,
      Value<String?> transactionType,
      Value<String?> reason,
      Value<String?> tillNumber,
      Value<String?> tin,
      Value<String?> vatReg,
      Value<String?> parseSource,
      Value<int> rowid,
    });

class $$SmsInboxTableFilterComposer
    extends Composer<_$AppDatabase, $SmsInboxTable> {
  $$SmsInboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processingAttempts => $composableBuilder(
    column: $table.processingAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedDate => $composableBuilder(
    column: $table.parsedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parsedTime => $composableBuilder(
    column: $table.parsedTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get commission => $composableBuilder(
    column: $table.commission,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vat => $composableBuilder(
    column: $table.vat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromAccount => $composableBuilder(
    column: $table.fromAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccount => $composableBuilder(
    column: $table.toAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiaryAccount => $composableBuilder(
    column: $table.beneficiaryAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beneficiaryBank => $composableBuilder(
    column: $table.beneficiaryBank,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tillNumber => $composableBuilder(
    column: $table.tillNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tin => $composableBuilder(
    column: $table.tin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vatReg => $composableBuilder(
    column: $table.vatReg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parseSource => $composableBuilder(
    column: $table.parseSource,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsInboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsInboxTable> {
  $$SmsInboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processingAttempts => $composableBuilder(
    column: $table.processingAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedDate => $composableBuilder(
    column: $table.parsedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parsedTime => $composableBuilder(
    column: $table.parsedTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get commission => $composableBuilder(
    column: $table.commission,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vat => $composableBuilder(
    column: $table.vat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromAccount => $composableBuilder(
    column: $table.fromAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccount => $composableBuilder(
    column: $table.toAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiaryAccount => $composableBuilder(
    column: $table.beneficiaryAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beneficiaryBank => $composableBuilder(
    column: $table.beneficiaryBank,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tillNumber => $composableBuilder(
    column: $table.tillNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tin => $composableBuilder(
    column: $table.tin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vatReg => $composableBuilder(
    column: $table.vatReg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parseSource => $composableBuilder(
    column: $table.parseSource,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsInboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsInboxTable> {
  $$SmsInboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isProcessed => $composableBuilder(
    column: $table.isProcessed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get processingAttempts => $composableBuilder(
    column: $table.processingAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get transactionId => $composableBuilder(
    column: $table.transactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parsedDate => $composableBuilder(
    column: $table.parsedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parsedTime => $composableBuilder(
    column: $table.parsedTime,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get commission => $composableBuilder(
    column: $table.commission,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vat =>
      $composableBuilder(column: $table.vat, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<String> get fromAccount => $composableBuilder(
    column: $table.fromAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toAccount =>
      $composableBuilder(column: $table.toAccount, builder: (column) => column);

  GeneratedColumn<String> get beneficiaryAccount => $composableBuilder(
    column: $table.beneficiaryAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get beneficiaryBank => $composableBuilder(
    column: $table.beneficiaryBank,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get tillNumber => $composableBuilder(
    column: $table.tillNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tin =>
      $composableBuilder(column: $table.tin, builder: (column) => column);

  GeneratedColumn<String> get vatReg =>
      $composableBuilder(column: $table.vatReg, builder: (column) => column);

  GeneratedColumn<String> get parseSource => $composableBuilder(
    column: $table.parseSource,
    builder: (column) => column,
  );
}

class $$SmsInboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsInboxTable,
          SmsInboxData,
          $$SmsInboxTableFilterComposer,
          $$SmsInboxTableOrderingComposer,
          $$SmsInboxTableAnnotationComposer,
          $$SmsInboxTableCreateCompanionBuilder,
          $$SmsInboxTableUpdateCompanionBuilder,
          (
            SmsInboxData,
            BaseReferences<_$AppDatabase, $SmsInboxTable, SmsInboxData>,
          ),
          SmsInboxData,
          PrefetchHooks Function()
        > {
  $$SmsInboxTableTableManager(_$AppDatabase db, $SmsInboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsInboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsInboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsInboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> threadId = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isProcessed = const Value.absent(),
                Value<int> processingAttempts = const Value.absent(),
                Value<int?> lastTriedAt = const Value.absent(),
                Value<int?> processedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> parsedDate = const Value.absent(),
                Value<String?> parsedTime = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<double?> commission = const Value.absent(),
                Value<double?> vat = const Value.absent(),
                Value<double?> total = const Value.absent(),
                Value<String?> fromAccount = const Value.absent(),
                Value<String?> toAccount = const Value.absent(),
                Value<String?> beneficiaryAccount = const Value.absent(),
                Value<String?> beneficiaryBank = const Value.absent(),
                Value<String?> transactionType = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> tillNumber = const Value.absent(),
                Value<String?> tin = const Value.absent(),
                Value<String?> vatReg = const Value.absent(),
                Value<String?> parseSource = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsInboxCompanion(
                id: id,
                threadId: threadId,
                address: address,
                body: body,
                date: date,
                isProcessed: isProcessed,
                processingAttempts: processingAttempts,
                lastTriedAt: lastTriedAt,
                processedAt: processedAt,
                lastError: lastError,
                transactionId: transactionId,
                parsedDate: parsedDate,
                parsedTime: parsedTime,
                amount: amount,
                commission: commission,
                vat: vat,
                total: total,
                fromAccount: fromAccount,
                toAccount: toAccount,
                beneficiaryAccount: beneficiaryAccount,
                beneficiaryBank: beneficiaryBank,
                transactionType: transactionType,
                reason: reason,
                tillNumber: tillNumber,
                tin: tin,
                vatReg: vatReg,
                parseSource: parseSource,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> threadId = const Value.absent(),
                required String address,
                required String body,
                required DateTime date,
                Value<bool> isProcessed = const Value.absent(),
                Value<int> processingAttempts = const Value.absent(),
                Value<int?> lastTriedAt = const Value.absent(),
                Value<int?> processedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> transactionId = const Value.absent(),
                Value<String?> parsedDate = const Value.absent(),
                Value<String?> parsedTime = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<double?> commission = const Value.absent(),
                Value<double?> vat = const Value.absent(),
                Value<double?> total = const Value.absent(),
                Value<String?> fromAccount = const Value.absent(),
                Value<String?> toAccount = const Value.absent(),
                Value<String?> beneficiaryAccount = const Value.absent(),
                Value<String?> beneficiaryBank = const Value.absent(),
                Value<String?> transactionType = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> tillNumber = const Value.absent(),
                Value<String?> tin = const Value.absent(),
                Value<String?> vatReg = const Value.absent(),
                Value<String?> parseSource = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsInboxCompanion.insert(
                id: id,
                threadId: threadId,
                address: address,
                body: body,
                date: date,
                isProcessed: isProcessed,
                processingAttempts: processingAttempts,
                lastTriedAt: lastTriedAt,
                processedAt: processedAt,
                lastError: lastError,
                transactionId: transactionId,
                parsedDate: parsedDate,
                parsedTime: parsedTime,
                amount: amount,
                commission: commission,
                vat: vat,
                total: total,
                fromAccount: fromAccount,
                toAccount: toAccount,
                beneficiaryAccount: beneficiaryAccount,
                beneficiaryBank: beneficiaryBank,
                transactionType: transactionType,
                reason: reason,
                tillNumber: tillNumber,
                tin: tin,
                vatReg: vatReg,
                parseSource: parseSource,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsInboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsInboxTable,
      SmsInboxData,
      $$SmsInboxTableFilterComposer,
      $$SmsInboxTableOrderingComposer,
      $$SmsInboxTableAnnotationComposer,
      $$SmsInboxTableCreateCompanionBuilder,
      $$SmsInboxTableUpdateCompanionBuilder,
      (
        SmsInboxData,
        BaseReferences<_$AppDatabase, $SmsInboxTable, SmsInboxData>,
      ),
      SmsInboxData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SmsInboxTableTableManager get smsInbox =>
      $$SmsInboxTableTableManager(_db, _db.smsInbox);
}
