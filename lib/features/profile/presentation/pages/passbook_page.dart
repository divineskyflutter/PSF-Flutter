import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/utils/simple_table_pdf_exporter.dart';
import 'package:psf_application/shared/utils/toast_util.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../../domain/entities/passbook_entry_entity.dart';
import '../controllers/profile_controller.dart';

/// The member's scheme ledger — paid / withdrawn / running balance per
/// entry, fetched via [ProfileController.fetchPassbook]. The header's
/// export icon saves the currently-loaded rows as a PDF.
class PassbookPage extends StatefulWidget {
  const PassbookPage({super.key});

  @override
  State<PassbookPage> createState() => _PassbookPageState();
}

class _PassbookPageState extends State<PassbookPage> {
  final ProfileController _controller = Get.find<ProfileController>();

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (_controller.passbook.isEmpty) {
      _controller.fetchPassbook();
    }
  }

  Future<void> _exportPdf() async {
    if (_isExporting || _controller.passbook.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final dateFormat = DateFormat('dd MMM yyyy');
      final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

      final bytes = await SimpleTablePdfExporter.build(
        title: AppStrings.passbook.tr,
        headers: [
          AppStrings.dueDate.tr,
          AppStrings.details.tr,
          AppStrings.paidAmount.tr,
          AppStrings.withdrawnAmount.tr,
          AppStrings.balanceAmount.tr,
        ],
        rows: _controller.passbook
            .map(
              (entry) => [
                entry.date != null ? dateFormat.format(entry.date!) : '-',
                entry.details,
                currency.format(entry.paidAmount),
                currency.format(entry.withdrawnAmount),
                currency.format(entry.balanceAmount),
              ],
            )
            .toList(),
      );

      final fileName = 'PSF_Passbook_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final savedPath = await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        dialogTitle: 'download_pdf'.tr,
      );

      if (!mounted) return;

      if (savedPath != null) {
        ToastUtil.success('pdf_saved_successfully'.tr);
      } else {
        ToastUtil.error('pdf_save_cancelled'.tr);
      }
    } catch (_) {
      if (mounted) ToastUtil.error('pdf_generation_failed'.tr);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(
        title: AppStrings.passbook.tr,
        actions: [
          Obx(
            () => AppHeaderIconButton(
              icon: _isExporting ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
              onTap: _controller.passbook.isEmpty ? () {} : _exportPdf,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isPassbookLoading.value && _controller.passbook.isEmpty) {
          return const AppStateView.loading();
        }

        if (_controller.hasPassbookError.value && _controller.passbook.isEmpty) {
          return AppStateView.error(
            message: _controller.passbookErrorMessage.value.isEmpty
                ? AppStrings.somethingWentWrong.tr
                : _controller.passbookErrorMessage.value,
            onRetry: _controller.fetchPassbook,
          );
        }

        if (_controller.passbook.isEmpty) {
          return AppStateView.empty(message: AppStrings.passbookEmptyMessage.tr);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _controller.fetchPassbook,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.px(context)),
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _PassbookTable(entries: _controller.passbook),
            ),
          ),
        );
      }),
    );
  }
}

class _PassbookTable extends StatelessWidget {
  const _PassbookTable({required this.entries});

  final List<PassbookEntryEntity> entries;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(AppColors.primary.withOpacity(.08)),
        dataRowMinHeight: 46,
        dataRowMaxHeight: 56,
        columnSpacing: 22,
        columns: [
          DataColumn(label: Text(AppStrings.dueDate.tr, style: _headerStyle)),
          DataColumn(label: Text(AppStrings.details.tr, style: _headerStyle)),
          DataColumn(label: Text(AppStrings.paidAmount.tr, style: _headerStyle)),
          DataColumn(label: Text(AppStrings.withdrawnAmount.tr, style: _headerStyle)),
          DataColumn(label: Text(AppStrings.balanceAmount.tr, style: _headerStyle)),
        ],
        rows: entries
            .map(
              (entry) => DataRow(
                cells: [
                  DataCell(Text(
                    entry.date != null ? dateFormat.format(entry.date!) : '-',
                    style: _cellStyle,
                  )),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(entry.details, style: _cellStyle, overflow: TextOverflow.ellipsis, maxLines: 2),
                    ),
                  ),
                  DataCell(Text(currency.format(entry.paidAmount), style: _cellStyle)),
                  DataCell(Text(currency.format(entry.withdrawnAmount), style: _cellStyle)),
                  DataCell(Text(
                    currency.format(entry.balanceAmount),
                    style: _cellStyle.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary),
                  )),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const _cellStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
}
