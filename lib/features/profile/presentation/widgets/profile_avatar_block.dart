import 'package:flutter/material.dart';

import 'package:psf_application/app/constants/app_colors.dart';
import 'package:psf_application/shared/extensions/new_responsive_extensions.dart';

/// The member photo + name + mobile block shown at the top of every dark
/// profile card. The Profile tab's summary card ([ProfileScreen]) and the
/// full My Profile page reuse this exact same block so both genuinely
/// read as "the same card" — just a taller one on My Profile, with the
/// rest of the member's details below it.
///
/// Lives in `profile/presentation/widgets/` (not `shared/`) — same
/// "feature owns its own widgets" convention as Home's
/// `MemberSummaryCard` / `PaymentReminderCard`.
class ProfileAvatarBlock extends StatelessWidget {
  const ProfileAvatarBlock({
    super.key,
    required this.name,
    required this.mobile,
    this.photoUrl,
  });

  final String name;

  final String mobile;

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 60.px(context),
          height: 60.px(context),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: (photoUrl?.isNotEmpty ?? false)
              ? Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackIcon(context),
                )
              : _fallbackIcon(context),
        ),
        SizedBox(width: 16.px(context)),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.px(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5.px(context)),
              Row(
                children: [
                  Icon(
                    Icons.call_outlined,
                    color: Colors.white.withOpacity(.8),
                    size: 14.px(context),
                  ),
                  SizedBox(width: 6.px(context)),
                  Flexible(
                    child: Text(
                      mobile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(.85),
                        fontSize: 13.px(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      color: AppColors.primaryDark,
      size: 32.px(context),
    );
  }
}
