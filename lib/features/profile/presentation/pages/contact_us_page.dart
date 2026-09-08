import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/app/constants/app_strings.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';
import 'package:psf_application/shared/widgets/common/app_sub_page_header.dart';
import 'package:psf_application/shared/widgets/states/app_state_view.dart';

import '../../domain/entities/contact_entity.dart';
import '../controllers/profile_controller.dart';

/// Founders / support contacts list — API-driven via
/// [ProfileController.fetchContacts]. Cards expand in place to reveal a
/// phone number when one is available.
class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final ProfileController _controller = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    if (_controller.contacts.isEmpty) {
      _controller.fetchContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppSubPageHeader(title: AppStrings.contactUs.tr),
      body: Obx(() {
        if (_controller.isContactsLoading.value && _controller.contacts.isEmpty) {
          return const AppStateView.loading();
        }

        if (_controller.hasContactsError.value && _controller.contacts.isEmpty) {
          return AppStateView.error(
            message: _controller.contactsErrorMessage.value.isEmpty
                ? AppStrings.somethingWentWrong.tr
                : _controller.contactsErrorMessage.value,
            onRetry: _controller.fetchContacts,
          );
        }

        if (_controller.contacts.isEmpty) {
          return AppStateView.empty(message: AppStrings.contactUsEmptyMessage.tr);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _controller.fetchContacts,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(18.px(context)),
            itemCount: _controller.contacts.length,
            separatorBuilder: (_, __) => SizedBox(height: 14.px(context)),
            itemBuilder: (context, index) => _ContactCard(contact: _controller.contacts[index]),
          ),
        );
      }),
    );
  }
}

class _ContactCard extends StatefulWidget {
  const _ContactCard({required this.contact});

  final ContactEntity contact;

  @override
  State<_ContactCard> createState() => _ContactCardState();
}

class _ContactCardState extends State<_ContactCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: EdgeInsets.all(14.px(context)),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(18.px(context)),
        border: Border.all(color: AppColors.primary.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: (contact.phone ?? '').isEmpty
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24.px(context),
                  backgroundColor: AppColors.primary.withOpacity(.15),
                  backgroundImage:
                      (contact.photoUrl ?? '').isNotEmpty ? NetworkImage(contact.photoUrl!) : null,
                  child: (contact.photoUrl ?? '').isEmpty
                      ? Icon(Icons.person_rounded, color: AppColors.primary, size: 24.px(context))
                      : null,
                ),
                SizedBox(width: 14.px(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5.px(context),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.px(context)),
                      Text(
                        [contact.role, if ((contact.year ?? '').isNotEmpty) contact.year]
                            .whereType<String>()
                            .join(' • '),
                        style: TextStyle(fontSize: 12.px(context), color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if ((contact.phone ?? '').isNotEmpty)
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
          if (_expanded && (contact.phone ?? '').isNotEmpty) ...[
            SizedBox(height: 10.px(context)),
            const Divider(height: 1, color: AppColors.border),
            SizedBox(height: 10.px(context)),
            Row(
              children: [
                Icon(Icons.call_outlined, size: 16.px(context), color: AppColors.primary),
                SizedBox(width: 8.px(context)),
                Text(
                  contact.phone!,
                  style: TextStyle(
                    fontSize: 13.px(context),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
