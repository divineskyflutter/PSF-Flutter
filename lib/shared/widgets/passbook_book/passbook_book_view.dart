import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:page_flip/page_flip.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import 'passbook_record.dart';
import 'tearable_page.dart';

typedef PassbookRecordAction = void Function(PassbookRecord record);

/// A passbook shown as a paper BOOK, one tall page per screen of entries —
/// shared by every ledger in the app (fee entries, deposit account, loan
/// account, ...): give it a [PassbookPageSource] and it does the rest.
///
///  * Pages are ruled, with the column headings on top and a page number
///    underneath. An empty ledger is one blank ruled page.
///  * Swipe sideways to turn the page (a real page-turn animation, like the
///    registration preview). Only the page in view and the next one are built,
///    so a paginated API is asked for pages as the member reaches them.
///  * Drag up or down on a page and it tears (see [TearablePage]).
///  * Pinch to zoom the page; drag to move around while zoomed.
///
/// Set [active] to false while the book is off screen (for example another
/// tab is selected): it is torn down, so coming back gives fresh whole pages.
class PassbookBookView extends StatefulWidget {
  const PassbookBookView({
    super.key,
    required this.source,
    this.onDownload,
    this.active = true,
  });

  final PassbookPageSource source;

  /// Receipt download for one entry. Without it a "not available yet" note is
  /// shown.
  final PassbookRecordAction? onDownload;

  final bool active;

  @override
  State<PassbookBookView> createState() => _PassbookBookViewState();
}

class _PassbookBookViewState extends State<PassbookBookView> {
  late Future<PassbookPageData> _first = widget.source.loadPage(1);
  final Map<int, Future<PassbookPageData>> _pages = {};
  final PageFlipController _flip = PageFlipController();

  Future<PassbookPageData> _load(int index) =>
      index == 0 ? _first : _pages.putIfAbsent(index, () => widget.source.loadPage(index + 1));

  void _download(PassbookRecord record) {
    final handler = widget.onDownload;
    if (handler != null) {
      handler(record);
    } else {
      ToastUtil.info(AppStrings.receiptNotAvailable.tr);
    }
  }

  /// The page-turn animation uses a picture of each page taken a moment after
  /// it appears; after a tear that picture is stale, so drop it and let the
  /// book take a new one.
  void _refreshSnapshot(int index) {
    imageData.remove(index);
    final shown = currentPage.value;
    if (shown < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentPage.value = -1;
      currentPage.value = shown;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return FutureBuilder<PassbookPageData>(
      future: _first,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppStateView.error(
            message: AppStrings.somethingWentWrong.tr,
            onRetry: () => setState(() {
              _pages.clear();
              _first = widget.source.loadPage(1);
            }),
          );
        }
        if (!snapshot.hasData) return const AppStateView.loading();

        final total = snapshot.data!.totalPages.clamp(1, 100000);

        Widget pageAt(int i) => TearablePage(
              onSettled: total > 1 ? () => _refreshSnapshot(i) : null,
              child: _LedgerPage(
                load: _load(i),
                pageSize: widget.source.pageSize,
                number: i + 1,
                total: total,
                onDownload: _download,
              ),
            );

        final book = total == 1
            ? pageAt(0)
            : PageFlipWidget(
                controller: _flip,
                backgroundColor: AppColors.background,
                children: [for (var i = 0; i < total; i++) pageAt(i)],
              );

        // The page fills the whole area; its number is printed at its foot.
        return _ZoomBox(child: book);
      },
    );
  }
}

/// Pinch to zoom; once zoomed, the page can be dragged around and the page
/// underneath ignores touches (so zooming never turns or tears it).
class _ZoomBox extends StatefulWidget {
  const _ZoomBox({required this.child});

  final Widget child;

  @override
  State<_ZoomBox> createState() => _ZoomBoxState();
}

class _ZoomBoxState extends State<_ZoomBox> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(() {
      final zoomed = _transform.value.getMaxScaleOnAxis() > 1.02;
      if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 4,
      panEnabled: _zoomed,
      child: AbsorbPointer(absorbing: _zoomed, child: widget.child),
    );
  }
}

/// One ruled page: heading row, then [pageSize] rows (blank where there is no
/// entry).
class _LedgerPage extends StatelessWidget {
  const _LedgerPage({
    required this.load,
    required this.pageSize,
    required this.number,
    required this.total,
    required this.onDownload,
  });

  final Future<PassbookPageData> load;
  final int pageSize;

  /// This page's number (1-based) and how many pages there are.
  final int number;
  final int total;
  final PassbookRecordAction onDownload;

  static const _flex = [2, 4, 4, 5, 4, 3];

  @override
  Widget build(BuildContext context) {
    final headings = [
      AppStrings.colNo.tr,
      AppStrings.colDate.tr,
      AppStrings.colAmount.tr,
      AppStrings.colPaymentType.tr,
      AppStrings.colStatus.tr,
      AppStrings.colReceipt.tr,
    ];

    return Container(
      margin: EdgeInsets.all(2.px(context)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(14.px(context)),
        border: Border.all(color: AppColors.primary.withOpacity(.22)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<PassbookPageData>(
        future: load,
        builder: (context, snapshot) {
          final records = snapshot.data?.records ?? const <PassbookRecord>[];

          return Column(
            children: [
              Container(
                color: AppColors.primary.withOpacity(.14),
                padding: EdgeInsets.symmetric(vertical: 12.px(context), horizontal: 4.px(context)),
                child: Row(
                  children: [
                    for (var i = 0; i < headings.length; i++)
                      Expanded(
                        flex: _flex[i],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.px(context)),
                          child: _Cell(headings[i], header: true),
                        ),
                      ),
                  ],
                ),
              ),
              for (var r = 0; r < pageSize; r++)
                Expanded(
                  child: _Row(
                    record: r < records.length ? records[r] : null,
                    onDownload: onDownload,
                  ),
                ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 9.px(context)),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.08),
                ),
                child: Text(
                  AppStrings.pageOfTotal.trParams({
                    'page': '$number',
                    'total': '$total',
                  }),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.px(context),
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.record, required this.onDownload});

  final PassbookRecord? record;
  final PassbookRecordAction onDownload;

  static final _money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final r = record;
    String dash(String? v) => (v == null || v.trim().isEmpty) ? '-' : v.trim();

    final cells = r == null
        ? const <String>[]
        : [
            '${r.no}',
            r.date != null ? AppDateFormat.medium(r.date!) : '-',
            r.amount != null ? _money.format(r.amount) : '-',
            dash(r.type),
            dash(r.status),
          ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.px(context)),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(.14)),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Expanded(
              flex: _LedgerPage._flex[i],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.px(context)),
                child: r == null ? const SizedBox.shrink() : _Cell(cells[i]),
              ),
            ),
          Expanded(
            flex: _LedgerPage._flex[5],
            child: r == null
                ? const SizedBox.shrink()
                : Center(
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onDownload(r),
                      child: Padding(
                        padding: EdgeInsets.all(6.px(context)),
                        child: Icon(
                          Icons.download_rounded,
                          size: 20.px(context),
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: header ? 2 : 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: header ? 12.px(context) : 12.5.px(context),
            fontWeight: header ? FontWeight.w800 : FontWeight.w600,
            color: header ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
