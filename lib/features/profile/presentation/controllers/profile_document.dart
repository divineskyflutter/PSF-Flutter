import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/app/constants/app_strings.dart';

/// One downloadable document on the Profile "download" sheet.
///
/// [endpoint] is the API that returns the file itself (same "POST {id: memberId}
/// -> file bytes" style as `GeneratePdf`). It is `null` while the backend has
/// no endpoint for that document — tapping it then just says it isn't
/// available yet. Fill in the endpoint here when the API exists; nothing else
/// needs to change.
class ProfileDocument {
  const ProfileDocument({
    required this.labelKey,
    required this.icon,
    required this.fileName,
    this.endpoint,
  });

  final String labelKey;
  final IconData icon;
  final String fileName;
  final String? endpoint;

  static ProfileDocument get applicationForm => ProfileDocument(
        labelKey: AppStrings.docApplicationForm,
        icon: Icons.description_rounded,
        fileName: 'PSF_Application.pdf',
        endpoint: ApiEndPoints.generatePdf,
      );

  /// Order shown on the sheet.
  static List<ProfileDocument> get all => [
        applicationForm,
        const ProfileDocument(
          labelKey: AppStrings.docIdCard,
          icon: Icons.badge_rounded,
          fileName: 'PSF_ID_Card.pdf',
          // endpoint: ApiEndPoints.<idCard>  <- add when the API exists
        ),
        const ProfileDocument(
          labelKey: AppStrings.docReceipt,
          icon: Icons.receipt_long_rounded,
          fileName: 'PSF_Receipt.pdf',
        ),
        const ProfileDocument(
          labelKey: AppStrings.docCertificate,
          icon: Icons.workspace_premium_rounded,
          fileName: 'PSF_Certificate.pdf',
        ),
        const ProfileDocument(
          labelKey: AppStrings.docAgreement,
          icon: Icons.handshake_rounded,
          fileName: 'PSF_Agreement.pdf',
        ),
      ];
}
