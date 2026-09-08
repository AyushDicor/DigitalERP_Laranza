import 'dart:convert';
import 'dart:io';

import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:digitalerp/utils/app_profile_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'employee_profile_fields.dart';
import 'profile_controller.dart';
import 'profile_theme.dart';

/// Employee Master profile — overview.
///
/// Shows the photo, a summary of who the employee is, and one tile per section
/// of the ERP Employee Master. Tapping a tile opens that section, where it can
/// be viewed and edited.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      builder: (controller) => Scaffold(
        backgroundColor: profileBgColor,
        body: RefreshIndicator(
          color: purpleColor,
          onRefresh: () => controller.loadProfile(showLoader: false),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                elevation: 0,

                /// A soft shadow once the content slides underneath, so the
                /// white cards separate from the header instead of butting
                /// straight against it.
                scrolledUnderElevation: 3,
                shadowColor: Colors.black26,
                backgroundColor: purpleColor,
                surfaceTintColor: Colors.transparent,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(9),
                  child: GestureDetector(
                    onTap: () => controller.backTap(),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 17),
                    ),
                  ),
                ),
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    /// 1 while fully expanded, 0 once collapsed. Used to fade
                    /// the avatar out on the way up — it used to shrink
                    /// straight through the title, which is what made the
                    /// scroll look chaotic.
                    final minHeight = kToolbarHeight +
                        MediaQuery.of(context).padding.top;
                    final range = (260 - minHeight).clamp(1.0, 260.0);
                    final expanded =
                        ((constraints.maxHeight - minHeight) / range)
                            .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      /// Starts clear of the back button. A hard `left: 20`
                      /// put the title underneath it when collapsed.
                      titlePadding: const EdgeInsetsDirectional.only(
                          start: 58, bottom: 15, end: 16),
                      title: const Text(
                        'My Profile',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      background: Opacity(
                        opacity: Curves.easeOut.transform(expanded),
                        child: _HeroBanner(controller: controller),
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityCard(controller: controller),
                      const SizedBox(height: 22),
                      const ProfileGroupTitle('Employee Details'),
                      const SizedBox(height: 6),
                      const Padding(
                        padding: EdgeInsets.only(left: 14, bottom: 12),
                        child: Text(
                          'Open a section to view or edit its information',
                          style: TextStyle(
                              fontSize: 12.5, color: profileSubtleColor),
                        ),
                      ),
                      if (controller.isBusy)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: purpleColor),
                          ),
                        )
                      else
                        /// One card with hairline dividers rather than nine
                        /// separate floating cards — the repeated rounded
                        /// rectangles were the other thing making the scroll
                        /// feel busy.
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < EmployeeProfileSpec.sections.length;
                                  i++) ...[
                                if (i > 0)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 62),
                                    child: Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFEEF1F6)),
                                  ),
                                _SectionTile(
                                  section: EmployeeProfileSpec.sections[i],
                                  status: controller.sectionStatus(
                                      EmployeeProfileSpec.sections[i]),
                                  onTap: () => controller.openSection(
                                      EmployeeProfileSpec.sections[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (!controller.detailApiAvailable && !controller.isBusy)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: _PendingApiNotice(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Hero banner: photo + camera button

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(decoration: const BoxDecoration(color: purpleColor)),
        Positioned(
          top: -30,
          right: -40,
          child: _blob(180),
        ),
        Positioned(
          bottom: 20,
          left: -30,
          child: _blob(120),
        ),
        Positioned(
          bottom: 36,
          left: 0,
          right: 0,
          child: Center(child: _ProfileAvatar(controller: controller)),
        ),
      ],
    );
  }

  Widget _blob(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
      );
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF5B8EFF), Color(0xFFABC4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: purpleColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: controller.selectedImage.isEmpty
                ? ProfileImageView(size: 96, imageUrl: controller.photoUrl)
                : ProfileImageView(
                    size: 96,
                    fileImage: controller.selectedImage.value,
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showImageDialog(context, controller),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B8EFF), Color(0xFF1C2B6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: purpleColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, ProfileController value) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE1F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Update Profile Photo',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: profileValueColor,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a source to update your photo',
              style: TextStyle(fontSize: 13, color: profileSubtleColor),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceTile(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    color: const Color(0xFF5B8EFF),
                    onTap: () => _getImage(ImageSource.gallery, value),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SourceTile(
                    icon: Icons.camera_enhance_outlined,
                    label: 'Camera',
                    color: purpleColor,
                    onTap: () => _getImage(ImageSource.camera, value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _getImage(ImageSource source, ProfileController value) async {
    Get.back();
    var pickedFile =
        await value.picker.pickImage(source: source, imageQuality: 65);
    if (pickedFile != null) {
      var file = File(pickedFile.path);
      value.selectedImageBase64.value = base64.encode(file.readAsBytesSync());
      value.selectedImageFileName.value = file.path.split('/').last;
      value.setSelectedImage(file.path);
      await value.saveProfilePhoto();
    }
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Summary card

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final name = controller.displayName;
    final role = controller.roleLine;
    final empId = controller.employeeIdLine;
    final joined = controller.profile.str('dateofjoining');

    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isEmpty ? '—' : name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: profileValueColor,
              letterSpacing: 0.2,
            ),
          ),
          if (role.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              role,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: purpleColor,
              ),
            ),
          ],
          if (empId.isNotEmpty || joined.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: profileBorderColor),
            const SizedBox(height: 14),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                if (empId.isNotEmpty)
                  _MetaChip(icon: Icons.tag_rounded, text: empId),
                if (joined.isNotEmpty)
                  _MetaChip(
                    icon: Icons.event_available_outlined,
                    text: 'Joined  $joined',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: profileSubtleColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: profileSubtleColor,
          ),
        ),
      ],
    );
  }
}

// Section tile

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.status,
    required this.onTap,
  });

  final ErpSection section;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /// Draws no card of its own — the surrounding group provides the single
    /// white surface and the dividers between rows.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: purpleColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(section.icon, size: 20, color: purpleColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: profileValueColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: profileSubtleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 22, color: profileHintColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown while the Employee Master endpoints are still being built, so the
/// blank sections read as "not wired yet" instead of "your data is missing".
class _PendingApiNotice extends StatelessWidget {
  const _PendingApiNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: newOrangeLightColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: newOrangeColor),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Employee details are not connected to the server yet. '
              'Sections will fill in once the profile API is live.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFF8A6100),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
