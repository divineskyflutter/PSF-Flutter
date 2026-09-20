import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:psf_application/app/constants/api_end_points.dart';
import 'package:psf_application/core/network/network_caller.dart';

import 'member_qr_image.dart';

class MemberCardRepository {
  MemberCardRepository(this._networkCaller);

  final NetworkCaller _networkCaller;

  /// `POST /api/Api/GetMemberQrCode?Id={memberId}` — `null` when the
  /// response held nothing usable as an image.
  Future<MemberQrImage?> getMemberQr(int memberId) async {
    final raw = await _networkCaller.postRequestBytes(
      ApiEndPoints.getMemberQrCode,
      queryParams: {'Id': memberId},
    );

    return MemberQrImage.parse(raw);
  }

  /// Plain image download (member photo / signature / QR url) for
  /// embedding in the downloadable card PDF. Uses a bare [Dio] — these are
  /// public file URLs, so no auth header or global error toast applies —
  /// and returns `null` on any failure so a missing picture never blocks
  /// the PDF itself.
  Future<Uint8List?> downloadImage(String? url) async {
    if (url == null || url.isEmpty) return null;

    try {
      final response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) return null;

      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }
}
