class HeaderDetector {

  static final RegExp _followDatePattern = RegExp(
    r'^(\d{1,2}[-/\s](\d{1,2}|[A-Za-z]{3})[-/\s]\d{2,4}|\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})$',
    caseSensitive: false,
  );

  int dateColumn = -1;

  int descriptionColumn = -1;

  int debitColumn = -1;

  int creditColumn = -1;

  int amountColumn = -1;

  int balanceColumn = -1;

  int descriptionSpan = 1;

  bool invertedDrCrSemantics = false;



  void detect(List<dynamic> headerRow) {

    dateColumn = -1;

    descriptionColumn = -1;

    debitColumn = -1;

    creditColumn = -1;

    amountColumn = -1;

    balanceColumn = -1;

    descriptionSpan = 1;

    invertedDrCrSemantics = false;



    int transactionDateColumn = -1;

    int valueDateColumn = -1;

    int genericDateColumn = -1;



    bool hasShortDr = false;

    bool hasShortCr = false;

    bool hasStandardWithdrawal = false;



    for (int i = 0; i < headerRow.length; i++) {

      final raw = headerRow[i].toString();

      final header = raw
          .toLowerCase()
          .replaceAll(RegExp(r'[\r\n]+'), ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();



      if (header.contains('transaction date') ||

          header == 'txn date' ||

          header == 'tran date' ||

          header.contains('post date')) {

        transactionDateColumn = i;

      } else if (header.contains('value date') || header.contains('value dt')) {

        valueDateColumn = i;

      } else if (genericDateColumn == -1 &&

          (header.contains('date') || header == 'dt') &&

          !header.contains('statement') &&

          !header.contains('start') &&

          !header.contains('end')) {

        genericDateColumn = i;

      }



      if (header.contains('transaction reference') ||

          header.contains('txn reference') ||

          header.contains('tran reference') ||

          header.contains('particular') ||

          header.contains('narration') ||

          header.contains('description') ||

          header.contains('remarks') ||

          header.contains('details') ||

          (header.contains('transaction') &&

              !header.contains('date') &&

              !header.contains('reference')) ||

          header == 'transaction') {

        descriptionColumn = i;

      }



      if (header == 'dr' ||

          header.contains('withdrawal') ||

          header.contains('withdrawn') ||

          header.contains('withdraw amt') ||

          header.contains('withdrawal amt') ||

          header.contains('dr amount') ||

          header.contains('dr amt')) {

        debitColumn = i;

        if (header == 'dr') hasShortDr = true;

        if (header.contains('withdraw')) hasStandardWithdrawal = true;

      } else if (header.contains('debit')) {

        debitColumn = i;

      }



      if (header == 'cr' ||

          header.contains('deposit') ||

          header.contains('cr amount') ||

          header.contains('cr amt')) {

        creditColumn = i;

        if (header == 'cr') hasShortCr = true;

        if (header.contains('deposit')) hasStandardWithdrawal = true;

      } else if (header.contains('credit')) {

        creditColumn = i;

      }



      if (header.contains('amount') &&

          !header.contains('balance') &&

          !header.contains('inr')) {

        amountColumn = i;

      }



      if (header.contains('withdrawal amount') ||

          header.contains('deposit amount') ||

          header.contains('withdrawal(dr)') ||

          header.contains('deposit(cr)')) {

        hasStandardWithdrawal = true;

      }



      if (header == 'bal' ||

          header.contains('balance') ||

          header.contains('closing balance')) {

        balanceColumn = i;

      }

    }



    if (transactionDateColumn != -1) {

      dateColumn = transactionDateColumn;

    } else if (genericDateColumn != -1) {

      dateColumn = genericDateColumn;

    } else if (valueDateColumn != -1) {

      dateColumn = valueDateColumn;

    }



    if (descriptionColumn != -1 &&

        descriptionColumn + 1 < headerRow.length) {

      final descHeader =

          headerRow[descriptionColumn].toString().toLowerCase().trim();

      final nextHeader =

          headerRow[descriptionColumn + 1].toString().toLowerCase().trim();

      if (!descHeader.contains('reference') && nextHeader == 'reference') {

        descriptionSpan = 2;

      }

    }



    invertedDrCrSemantics = _resolveSemantics(

      hasShortDr: hasShortDr,

      hasShortCr: hasShortCr,

      hasStandardWithdrawal: hasStandardWithdrawal,

    );

  }



  /// Axis/IndusInd CSV and Excel use short [DR]/[CR] where DR = money in, CR = money out.

  /// PDF exports use Withdrawal/Deposit with normal semantics.

  static bool _resolveSemantics({

    required bool hasShortDr,

    required bool hasShortCr,

    required bool hasStandardWithdrawal,

  }) {

    if (hasStandardWithdrawal) {

      return false;

    }



    return hasShortDr && hasShortCr;

  }



  bool isValid() {

    return dateColumn != -1 &&

        descriptionColumn != -1 &&

        (debitColumn != -1 || creditColumn != -1 || amountColumn != -1);

  }



  static int? findHeaderRowIndex(List<List<dynamic>> rows) {
    int? bestIndex;
    var bestScore = -1.0;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final detector = HeaderDetector()..detect(row);
      if (!detector.isValid()) continue;

      var score = 0.0;
      if (detector.balanceColumn != -1) score += 2;
      if (detector.debitColumn != -1 && detector.creditColumn != -1) score += 3;
      if (detector.descriptionColumn != -1) score += 1;

      var validFollowing = 0;
      for (var j = i + 1; j < rows.length && j < i + 8; j++) {
        final follow = rows[j];
        if (follow.isEmpty || follow.length <= detector.dateColumn) continue;
        final dateText = follow[detector.dateColumn].toString().trim();
        if (_followDatePattern.hasMatch(dateText)) {
          validFollowing++;
        }
      }
      score += validFollowing * 2;

      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

}

