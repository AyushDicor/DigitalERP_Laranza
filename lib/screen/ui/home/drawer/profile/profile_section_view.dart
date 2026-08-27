import 'package:digitalerp/response/employee_profile_response.dart';
import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'employee_profile_fields.dart';
import 'profile_section_controller.dart';
import 'profile_theme.dart';

/// One section of the Employee Master profile (General, Family, Bank, ...).
/// Opens read-only; Edit turns every writable row into an input.
class ProfileSectionView extends StatelessWidget {
  const ProfileSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    // Tagged per section so a half-disposed controller from the previously
    // opened section can never be reused for this one.
    return GetBuilder<ProfileSectionController>(
      init: ProfileSectionController(),
      tag: Get.arguments?.toString() ?? '',
      builder: (c) => PopScope(
        canPop: !c.editing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmDiscard(context, c);
        },
        child: Scaffold(
          backgroundColor: profileBgColor,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: _SectionAppBar(controller: c),
          ),
          body: c.isBusy
              ? const Center(child: CircularProgressIndicator(color: purpleColor))
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    _SectionIntro(section: c.section),
                    const SizedBox(height: 16),
                    for (final group in c.section.groups)
                      if (group.fields.isNotEmpty) ...[
                        _GroupCard(group: group, controller: c),
                        const SizedBox(height: 16),
                      ],
                    if (c.section.repeatable != null && c.repeatableVisible)
                      _RepeatableGroup(controller: c),
                  ],
                ),
        ),
      ),
    );
  }

  void _confirmDiscard(BuildContext context, ProfileSectionController c) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Discard changes?'),
        content: const Text('Your edits to this section have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              c.cancelEdit();
              Get.back();
            },
            child: const Text('Discard', style: TextStyle(color: newRedColor)),
          ),
        ],
      ),
    );
  }
}

// App bar with the Edit / Save+Cancel actions

class _SectionAppBar extends StatelessWidget {
  const _SectionAppBar({required this.controller});

  final ProfileSectionController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 20, color: newTextPrimary),
            ),
            Expanded(
              child: Text(
                controller.section.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: newTextPrimary,
                ),
              ),
            ),
            if (!controller.editing)
              _ActionChip(
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: controller.startEdit,
              )
            else ...[
              _ActionChip(
                label: 'Cancel',
                onTap: controller.cancelEdit,
                subdued: true,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.check_rounded,
                label: 'Save',
                onTap: controller.save,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.subdued = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final color = subdued ? profileSubtleColor : purpleColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.section});

  final ErpSection section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: purpleColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(section.icon, color: purpleColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            section.subtitle,
            style: const TextStyle(
              fontSize: 13,
              height: 1.35,
              color: profileSubtleColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Cards

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.controller});

  final ErpGroup group;
  final ProfileSectionController controller;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.title != null) ...[
            ProfileGroupTitle(group.title!),
            const SizedBox(height: 18),
          ],
          for (int i = 0; i < group.fields.length; i++) ...[
            _FieldRow(field: group.fields[i], controller: controller),
            if (i != group.fields.length - 1) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _RepeatableGroup extends StatelessWidget {
  const _RepeatableGroup({required this.controller});

  final ProfileSectionController controller;

  @override
  Widget build(BuildContext context) {
    final rep = controller.section.repeatable!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileGroupTitle('${rep.itemLabel} List'),
        const SizedBox(height: 12),
        if (controller.items.isEmpty)
          ProfileCard(
            child: Row(
              children: [
                const Icon(Icons.inbox_outlined,
                    size: 20, color: profileSubtleColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No ${rep.itemLabel.toLowerCase()} added yet',
                    style: const TextStyle(
                        fontSize: 13, color: profileSubtleColor),
                  ),
                ),
              ],
            ),
          ),
        for (int i = 0; i < controller.items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          ProfileCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        controller.itemTitle(controller.items[i], i),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: profileValueColor,
                        ),
                      ),
                    ),
                    if (controller.editing)
                      InkWell(
                        onTap: () => controller.removeItem(controller.items[i]),
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 20, color: newRedColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                for (int f = 0; f < rep.fields.length; f++) ...[
                  _FieldRow(
                    field: rep.fields[f],
                    controller: controller,
                    item: controller.items[i],
                  ),
                  if (f != rep.fields.length - 1) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ],
        if (controller.editing) ...[
          const SizedBox(height: 14),
          InkWell(
            onTap: controller.addItem,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: purpleColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: purpleColor.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded, size: 18, color: purpleColor),
                  const SizedBox(width: 8),
                  Text(
                    'Add ${rep.itemLabel}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: purpleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// One label + value / input

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.controller,
    this.item,
  });

  final ErpField field;
  final ProfileSectionController controller;

  /// Set when this row belongs to a repeatable card.
  final Map<String, dynamic>? item;

  String get _value => item == null
      ? controller.valueOf(field)
      : controller.itemValue(item!, field);

  bool get _editable => controller.editing && !field.readOnly;

  @override
  Widget build(BuildContext context) {
    if (field.type == ErpFieldType.toggle) {
      return _buildToggle();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileFieldLabel(
          label: field.label,
          showReadOnlyBadge: controller.editing && field.readOnly,
        ),
        const SizedBox(height: 8),
        _editable ? _buildInput(context) : _buildValue(context),
      ],
    );
  }

  Widget _buildToggle() {
    final on = item == null
        ? controller.toggleOf(field)
        : _truthy(controller.itemValue(item!, field));

    if (!controller.editing || field.readOnly) {
      return Row(
        children: [
          Icon(
            on ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: on ? newGreenColor : profileHintColor,
          ),
          const SizedBox(width: 10),
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: profileValueColor,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => controller.setToggle(field, !on),
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Checkbox(
            value: on,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: purpleColor,
            onChanged: (v) => controller.setToggle(field, v ?? false),
          ),
          const SizedBox(width: 6),
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: profileValueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValue(BuildContext context) {
    if (field.type == ErpFieldType.file) {
      return _FileValue(value: _value);
    }

    final display =
        field.type == ErpFieldType.date ? controller.formatDate(_value) : _value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: profileReadOnlyFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: profileBorderColor),
      ),
      child: Text(
        display.isEmpty ? '—' : display,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: display.isEmpty ? profileHintColor : profileValueColor,
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (field.type) {
      case ErpFieldType.file:
        return _FileInput(field: field, controller: controller, item: item);

      case ErpFieldType.date:
        return _TapField(
          text: controller.formatDate(_value),
          hint: 'Select date',
          icon: Icons.calendar_today_rounded,
          onTap: () => controller.pickDate(field, item: item),
        );

      case ErpFieldType.dropdown:
        final options = controller.optionsFor(field);
        // No lookup available yet — fall back to free text rather than
        // blocking the field behind an empty dropdown.
        if (options.isEmpty) return _textInput();
        return _TapField(
          text: _value,
          hint: 'Select ${field.label.toLowerCase()}',
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: () => _showOptionPicker(context, options),
        );

      default:
        return _textInput();
    }
  }

  Widget _textInput() {
    final id = item == null
        ? controller.fieldControllerId(field)
        : controller.itemControllerId(item!, field);

    return TextFormField(
      controller: controller.textController(id, _value),
      keyboardType: _keyboardType,
      inputFormatters: field.type == ErpFieldType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      maxLines: field.type == ErpFieldType.multiline ? 3 : 1,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: profileValueColor,
      ),
      decoration: profileInputDecoration(
        hint: field.hint ?? 'Enter ${field.label.toLowerCase()}',
      ),
    );
  }

  TextInputType get _keyboardType {
    switch (field.type) {
      case ErpFieldType.email:
        return TextInputType.emailAddress;
      case ErpFieldType.phone:
        return TextInputType.phone;
      case ErpFieldType.number:
        return TextInputType.number;
      case ErpFieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  void _showOptionPicker(BuildContext context, List<LookupItem> options) {
    final search = TextEditingController();
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          final query = search.text.trim().toLowerCase();
          final visible = query.isEmpty
              ? options
              : options
                  .where((o) => o.name.toLowerCase().contains(query))
                  .toList();

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    color: profileBorderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: profileValueColor,
                  ),
                ),
                const SizedBox(height: 14),
                if (options.length > 8)
                  TextField(
                    controller: search,
                    onChanged: (_) => setSheetState(() {}),
                    decoration: profileInputDecoration(
                      hint: 'Search',
                      prefix: const Icon(Icons.search_rounded,
                          size: 20, color: profileHintColor),
                    ),
                  ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: profileBorderColor),
                    itemBuilder: (_, i) {
                      final option = visible[i];
                      final selected = option.name == _value;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                selected ? purpleColor : profileValueColor,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: purpleColor)
                            : null,
                        onTap: () {
                          Get.back();
                          if (item == null) {
                            controller.selectOption(field, option);
                          } else {
                            controller.selectItemOption(item!, field, option);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  static bool _truthy(String v) =>
      const {'1', 'true', 'yes', 'y', 'on'}.contains(v.toLowerCase());
}

/// Read-only row that behaves like a button (date / dropdown in edit mode).
class _TapField extends StatelessWidget {
  const _TapField({
    required this.text,
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final empty = text.isEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: profileInputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: profileBorderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                empty ? hint : text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: empty ? profileHintColor : profileValueColor,
                ),
              ),
            ),
            Icon(icon, size: 18, color: profileSubtleColor),
          ],
        ),
      ),
    );
  }
}

// File rows

class _FileValue extends StatelessWidget {
  const _FileValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final isLink = value.startsWith('http');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: profileReadOnlyFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: profileBorderColor),
      ),
      child: Row(
        children: [
          Icon(
            value.isEmpty
                ? Icons.insert_drive_file_outlined
                : Icons.description_rounded,
            size: 18,
            color: value.isEmpty ? profileHintColor : purpleColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not uploaded' : _fileLabel(value),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: value.isEmpty ? profileHintColor : profileValueColor,
              ),
            ),
          ),
          if (isLink)
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse(value),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('View',
                  style: TextStyle(fontSize: 13, color: purpleColor)),
            ),
        ],
      ),
    );
  }

  static String _fileLabel(String value) =>
      value.startsWith('http') ? value.split('/').last : value;
}

class _FileInput extends StatelessWidget {
  const _FileInput({
    required this.field,
    required this.controller,
    this.item,
  });

  final ErpField field;
  final ProfileSectionController controller;
  final Map<String, dynamic>? item;

  @override
  Widget build(BuildContext context) {
    final value = item == null
        ? controller.valueOf(field)
        : controller.itemValue(item!, field);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: profileInputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: profileBorderColor, width: 1.5),
            ),
            child: Text(
              value.isEmpty ? 'No file chosen' : _FileValue._fileLabel(value),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: value.isEmpty ? profileHintColor : profileValueColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ActionChip(
          icon: Icons.upload_rounded,
          label: value.isEmpty ? 'Upload' : 'Change',
          onTap: () => controller.pickFile(field, item: item),
        ),
        if (value.isNotEmpty)
          IconButton(
            tooltip: 'Remove',
            onPressed: () => controller.clearFile(field, item: item),
            icon: const Icon(Icons.close_rounded,
                size: 18, color: profileSubtleColor),
          ),
      ],
    );
  }
}
