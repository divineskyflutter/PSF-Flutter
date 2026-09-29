import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import 'package:psf_application/core/localization/language_controller.dart';
import 'package:psf_application/core/storage/app_secure_storage.dart';
import 'package:psf_application/features/enum_bundle/data/models/enum_bundle_model.dart';
import 'package:psf_application/features/profile/presentation/controllers/profile_controller.dart';
import 'package:psf_application/shared/enums/app_language.dart';
import 'package:psf_application/shared/utils/app_date_format.dart';
import 'package:psf_application/shared/utils/localized_field.dart';
import 'package:psf_application/shared/utils/toast_util.dart';

import '../card_image_builder.dart';
import '../member_card_layout.dart';
import '../printed_card_pdf.dart';
import '../../data/member_card_data.dart';
import '../../data/member_card_repository.dart';
import '../../data/member_qr_image.dart';

/// Which file format the member picked in the download sheet.
enum CardDownloadFormat { pdf, image }

/// Drives the wallet-style Card tab: loads the member's QR code, builds the
/// display-ready [MemberCardData] from the cached login profile, and
/// downloads the card as a PDF.
class MemberCardController extends GetxController {
  MemberCardController(this._repository, this._profile);

  final MemberCardRepository _repository;

  final ProfileController _profile;

  final Rx<MemberQrImage?> qr = Rx<MemberQrImage?>(null);

  final RxBool isQrLoading = false.obs;

  final RxBool hasQrError = false.obs;

  final RxBool isDownloading = false.obs;

  /// Which card shape the member is looking at — and downloads.
  final Rx<MemberCardLayout> layout = MemberCardLayout.horizontal.obs;

  bool _resumeOpen = false;

  /// True while the wallet cover is actively sliding open or closed — the
  /// ambient backdrop behind it pauses its own animations for this window,
  /// so the wallet's own transition isn't competing for frame time.
  final RxBool isWalletBusy = false.obs;

  /// Switches the card shape from inside the open wallet; the new panel
  /// picks up where the old one was (see [takeResumeOpen]).
  void setLayout(MemberCardLayout value) {
    if (layout.value == value) return;
    _resumeOpen = true;
    layout.value = value;
  }

  /// `true` once after a [setLayout] — the panel it creates starts with the
  /// wallet already open instead of replaying the intro.
  bool takeResumeOpen() {
    final resume = _resumeOpen;
    _resumeOpen = false;
    return resume;
  }

  @override
  void onInit() {
    super.onInit();
    loadQr();
  }

  Future<void> loadQr() async {
    if (isQrLoading.value) return;

    isQrLoading.value = true;
    hasQrError.value = false;

    try {
      final memberId = _profile.memberDetails.value?.memberId ??
          await AppSecureStorage.getMemberId();

      if (memberId == null || memberId == 0) {
        hasQrError.value = true;
        return;
      }

      final result = await _repository.getMemberQr(memberId);

      qr.value = result;
      hasQrError.value = result == null;
    } catch (_) {
      hasQrError.value = true;
    } finally {
      isQrLoading.value = false;
    }
  }

  /// Builds the card's field values. [localized] `true` uses the member's
  /// selected app language (Hindi/Gujarati variants where the API sent
  /// them) for the on-screen card; `false` always uses the plain English
  /// values, which is what the PDF's standard fonts can render.
  MemberCardData buildData({required bool localized}) {
    final member = _profile.memberDetails.value;
    final profile = _profile.profile.value;

    final language = localized
        ? Get.find<LanguageController>().currentAppLanguage
        : AppLanguage.english;

    String pick(String? plain, String? hindi, String? gujarati) =>
        localizedField(language, plain: plain, hindi: hindi, gujarati: gujarati);

    String formatIso(String? iso) {
      final parsed = DateTime.tryParse(iso ?? '');
      return parsed == null ? '' : AppDateFormat.medium(parsed, localized: localized);
    }

    final bundle = _profile.enumBundle.value;

    String enumName(List<EnumItem>? items, int? id) {
      if (id == null || items == null) return '';
      return EnumBundleModel.nameFor(items, id, fallback: '', localized: localized);
    }

    final name = member != null
        ? member.localizedFullName(language)
        : (profile?.fullName ?? '');

    // Card shows the address line alone — village/taluka/district/state
    // used to be appended here too, but that made this one field far
    // longer than the card's layout was designed for.
    final address = member == null
        ? ''
        : pick(member.address, member.hAddress, member.gAddress);

    return MemberCardData(
      name: name,
      // Real member number only — the database id is NOT a member number,
      // so it shows as '-' until one is assigned.
      memberNo: member?.memberNo ?? '',
      mobile: member?.mobile ?? profile?.mobile ?? '',
      dateOfBirth: formatIso(member?.dateOfBirth),
      dateOfBirthNumeric: () {
        final parsed = DateTime.tryParse(member?.dateOfBirth ?? '');
        return parsed == null ? '' : AppDateFormat.numeric(parsed);
      }(),
      gender: enumName(bundle?.gender, int.tryParse(member?.gender ?? '')),
      maritalStatus:
          enumName(bundle?.maritalStatus, int.tryParse(member?.maritalStatus ?? '')),
      status: enumName(bundle?.memberStatus, member?.status),
      fatherName: member == null
          ? ''
          : pick(member.fatherName, member.hFatherName, member.gFatherName),
      address: address,
      occupation: member == null
          ? ''
          : pick(member.occupation, member.hOccupation, member.gOccupation),
      nomineeCount: _profile.nominees.length,
      joiningDate: profile?.joiningDate != null
          ? AppDateFormat.medium(profile!.joiningDate!, localized: localized)
          : '',
      photoUrl: member?.imageUrl ?? profile?.photoUrl,
    );
  }

  /// Downloads the card the member is looking at (their picked shape, their
  /// selected language) as either a PDF or a PNG image — same card faces,
  /// same QR, either way.
  Future<void> downloadCardAs(CardDownloadFormat format) async {
    if (isDownloading.value) return;

    isDownloading.value = true;

    try {
      // The QR is normally already loaded by the time the member reaches
      // Download (it's shown on the wallet cover from the moment this
      // controller starts), but make sure — a download shouldn't go out
      // with a blank hole where the QR belongs just because that first
      // fetch is still in flight or was never retried after failing.
      if (qr.value == null && !hasQrError.value) {
        await loadQr();
      }

      final data = buildData(localized: true);
      final safeNo = data.memberNo.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      final baseName = 'PSF_Member_Card_${safeNo.isEmpty ? 'card' : safeNo}';

      final Uint8List bytes;
      final String extension;
      switch (format) {
        case CardDownloadFormat.pdf:
          bytes = await PrintedCardPdf.build(
            data,
            layout.value,
            qr: qr.value,
            hasQrError: hasQrError.value,
          );
          extension = 'pdf';
        case CardDownloadFormat.image:
          bytes = await CardImageBuilder.build(
            data,
            layout.value,
            qr: qr.value,
            hasQrError: hasQrError.value,
          );
          extension = 'png';
      }

      final savedPath = await FilePicker.platform.saveFile(
        fileName: '$baseName.$extension',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [extension],
        dialogTitle: 'download_card'.tr,
      );

      final isPdf = format == CardDownloadFormat.pdf;
      if (savedPath != null) {
        ToastUtil.success(
          isPdf ? 'pdf_saved_successfully'.tr : 'image_saved_successfully'.tr,
        );
      } else {
        ToastUtil.error(
          isPdf ? 'pdf_save_cancelled'.tr : 'image_save_cancelled'.tr,
        );
      }
    } catch (_) {
      ToastUtil.error(
        format == CardDownloadFormat.pdf
            ? 'pdf_generation_failed'.tr
            : 'image_generation_failed'.tr,
      );
    } finally {
      isDownloading.value = false;
    }
  }
}
