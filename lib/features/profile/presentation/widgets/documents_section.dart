import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/windows/common_image_preview.dart';

import 'document_thumbnail.dart';
import 'profile_card_style.dart';

/// One labelled document photo (Aadhaar front, PAN, nominee cheque, ...).
class DocumentItem {
  const DocumentItem({required this.label, required this.url});

  final String label;

  final String? url;
}

/// A "Documents" row that opens and closes on tap. Closed it is just the
/// label (with how many documents were uploaded); open it reveals the
/// document photos — each one tappable to the zoomable popup preview (same
/// blurred-backdrop dialog style as the legal/rules screens' image
/// preview), swipeable between the member's other documents.
///
/// Used under the member details (Personal tab) and under each nominee, so
/// the images no longer take up the top of the screen.
class DocumentsSection extends StatefulWidget {
  const DocumentsSection({
    super.key,
    required this.documents,
    this.framed = true,
  });

  final List<DocumentItem> documents;

  /// `true` draws its own card around the row (Personal tab); `false` is
  /// for use inside an existing card (Nominee card).
  final bool framed;

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  void _openPreview(String url) {
    final available = widget.documents
        .where((document) => document.url?.isNotEmpty ?? false)
        .map((document) => PreviewImageItem(imagePath: document.url!))
        .toList();

    final index = available.indexWhere((image) => image.imagePath == url);

    CommonImagePreview.show(
      context: context,
      images: available,
      initialIndex: index < 0 ? 0 : index,
      mode: ImagePreviewMode.dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploaded =
        widget.documents.where((document) => document.url?.isNotEmpty ?? false).length;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16.px(context)),
          onTap: _toggle,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.framed ? 16.px(context) : 0,
              vertical: 14.px(context),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.px(context)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12.px(context)),
                  ),
                  child: Icon(Icons.folder_open_rounded, size: 20.px(context), color: AppColors.primary),
                ),
                SizedBox(width: 12.px(context)),
                Expanded(
                  child: Text(
                    'documents'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.px(context),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.px(context), vertical: 3.px(context)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(20.px(context)),
                  ),
                  child: Text(
                    '$uploaded/${widget.documents.length}',
                    style: TextStyle(
                      fontSize: 11.5.px(context),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 6.px(context)),
                RotationTransition(
                  turns: Tween<double>(begin: 0, end: .5).animate(_curve),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 26.px(context)),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _curve,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _curve,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                widget.framed ? 16.px(context) : 0,
                2.px(context),
                widget.framed ? 16.px(context) : 0,
                16.px(context),
              ),
              child: Wrap(
                spacing: 8.px(context),
                runSpacing: 14.px(context),
                children: [
                  for (final document in widget.documents)
                    DocumentThumbnail(
                      label: document.label,
                      imageUrl: document.url,
                      onTap: () => _openPreview(document.url!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (!widget.framed) return content;

    return Container(
      decoration: profileCardDecoration(context),
      child: content,
    );
  }
}
