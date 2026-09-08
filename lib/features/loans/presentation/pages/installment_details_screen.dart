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

import '../../domain/entities/installment_entity.dart';
import '../controllers/loans_controller.dart';

class InstallmentDetailsScreen extends StatefulWidget {
  const InstallmentDetailsScreen({super.key});

  @override
  State<InstallmentDetailsScreen> createState() => _InstallmentDetailsScreenState();
}

class _InstallmentDetailsScreenState extends State<InstallmentDetailsScreen> {
  final LoansController _controller = Get.find<LoansController>();

  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (_controller.installments.isEmpty) {
      _controller.fetchInstallments();
    }
  }

  Future<void> _exportPdf() async {
    if (_isExporting || _controller.installments.isEmpty) return;

    setState(() => _isExporting = true);

    try {
      final dateFormat = DateFormat('dd MMM yyyy');
      final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

      final bytes = await SimpleTablePdfExporter.build(
        title: AppStrings.installmentDetails.tr,
        headers: [
          AppStrings.installmentNo.tr,
          AppStrings.dueDate.tr,
          AppStrings.paidAmount.tr,
          AppStrings.pending.tr,
        ],
        rows: _controller.installments
            .map(
              (installment) => [
                '${installment.installmentNo}',
                installment.dueDate != null ? dateFormat.format(installment.dueDate!) : '-',
                currency.format(installment.amount),
                _statusLabel(installment.status),
              ],
            )
            .toList(),
      );

      final fileName = 'PSF_Instalments_${DateTime.now().millisecondsSinceEpoch}.pdf';

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

  String _statusLabel(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.paid:
        return AppStrings.paid.tr;
      case InstallmentStatus.overdue:
        return AppStrings.overdue.tr;
      case InstallmentStatus.pending:
        return AppStrings.pending.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(
        title: AppStrings.installmentDetails.tr,
        actions: [
          Obx(
            () => AppHeaderIconButton(
              icon: _isExporting ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
              onTap: _controller.installments.isEmpty ? () {} : _exportPdf,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isInstallmentsLoading.value && _controller.installments.isEmpty) {
          return const AppStateView.loading();
        }

        if (_controller.hasInstallmentsError.value && _controller.installments.isEmpty) {
          return AppStateView.error(
            message: _controller.installmentsErrorMessage.value.isEmpty
                ? AppStrings.somethingWentWrong.tr
                : _controller.installmentsErrorMessage.value,
            onRetry: _controller.fetchInstallments,
          );
        }

        if (_controller.installments.isEmpty) {
          return AppStateView.empty(message: AppStrings.noDataFound.tr);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _controller.fetchInstallments,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(18.px(context)),
            itemCount: _controller.installments.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.px(context)),
            itemBuilder: (context, index) =>
                _InstallmentTile(installment: _controller.installments[index]),
          ),
        );
      }),
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.installment});

  final InstallmentEntity installment;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final statusStyle = _statusStyle(installment.status);

    return Container(
      padding: EdgeInsets.all(14.px(context)),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.px(context)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.px(context),
            height: 40.px(context),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(12.px(context)),
            ),
            alignment: Alignment.center,
            child: Text(
              '${installment.installmentNo}',
              style: TextStyle(
                fontSize: 14.px(context),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 14.px(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.installmentNo.tr} ${installment.installmentNo}',
                  style: TextStyle(
                    fontSize: 13.5.px(context),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.px(context)),
                Text(
                  installment.dueDate != null
                      ? DateFormat('dd MMM yyyy').format(installment.dueDate!)
                      : '-',
                  style: TextStyle(fontSize: 11.5.px(context), color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currency.format(installment.amount),
                style: TextStyle(
                  fontSize: 13.5.px(context),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 5.px(context)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.px(context), vertical: 3.px(context)),
                decoration: BoxDecoration(
                  color: statusStyle.$1.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusStyle.$2,
                  style: TextStyle(
                    fontSize: 10.px(context),
                    fontWeight: FontWeight.w700,
                    color: statusStyle.$1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, String) _statusStyle(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.paid:
        return (AppColors.success, AppStrings.paid.tr);
      case InstallmentStatus.overdue:
        return (AppColors.danger, AppStrings.overdue.tr);
      case InstallmentStatus.pending:
        return (AppColors.warning, AppStrings.pending.tr);
    }
  }
}
