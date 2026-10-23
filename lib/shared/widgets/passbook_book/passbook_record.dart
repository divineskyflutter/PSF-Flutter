/// One row of a passbook-style ledger (fee payments today; loan and deposit
/// entries later). Everything is optional except [no]; a missing value is
/// drawn as "-".
class PassbookRecord {
  const PassbookRecord({
    required this.no,
    this.date,
    this.amount,
    this.type,
    this.status,
    this.receiptId,
  });

  /// Serial number shown in the first column.
  final int no;
  final DateTime? date;
  final double? amount;

  /// Type of payment (online, installment, ...).
  final String? type;
  final String? status;

  /// Id the receipt download needs; null while there is no receipt.
  final String? receiptId;
}

/// What one page of entries looks like once loaded.
class PassbookPageData {
  const PassbookPageData({required this.records, required this.totalPages});

  final List<PassbookRecord> records;

  /// How many pages the whole ledger has (at least 1).
  final int totalPages;
}

/// Where a ledger's entries come from. The book asks for one page at a time
/// (1-based) and only for the pages the member actually reaches, so a real
/// API with pagination can be plugged in by implementing [loadPage] — the
/// widgets need no change.
abstract class PassbookPageSource {
  /// Entries per page (also how many ruled rows a page shows).
  int get pageSize;

  Future<PassbookPageData> loadPage(int page);
}

/// A source over an in-memory list (a finished list, or an empty one for a
/// ledger that has no entries yet). The book always has at least [minPages]
/// pages — the ones past the last entry are blank ruled pages — so even an
/// empty ledger feels like a real book to turn through.
class ListPassbookPageSource implements PassbookPageSource {
  const ListPassbookPageSource(
    this.records, {
    this.pageSize = 10,
    this.minPages = 5,
  });

  final List<PassbookRecord> records;
  final int minPages;

  @override
  final int pageSize;

  @override
  Future<PassbookPageData> loadPage(int page) async {
    final total = (records.length / pageSize).ceil().clamp(minPages, 100000);
    final start = (page - 1) * pageSize;
    final slice = start >= records.length
        ? const <PassbookRecord>[]
        : records.sublist(start, (start + pageSize).clamp(0, records.length));
    return PassbookPageData(records: slice, totalPages: total);
  }
}
