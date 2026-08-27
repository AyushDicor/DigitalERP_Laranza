import 'dart:convert';
import 'dart:io';

import 'package:digitalerp/response/employee_profile_response.dart';
import 'package:digitalerp/screen/base/base_controller.dart';
import 'package:digitalerp/services/api_service/request_keys.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:digitalerp/utils/shared_pre.dart';
import 'package:digitalerp/utils/show_message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'employee_profile_fields.dart';
import 'profile_controller.dart';

/// Drives one section page of the Employee Master profile.
///
/// The page opens in view mode; Edit swaps every writable row for an input and
/// Save posts just this section. Edits happen on a copy so Cancel is free.
class ProfileSectionController extends AppBaseController {
  late final ErpSection section;
  late final ProfileController parent;

  /// Working copy — only merged into [parent] once the save succeeds.
  EmployeeProfile working = EmployeeProfile();

  /// Draft rows for a repeatable section. Each carries a `_uid` so its text
  /// controllers survive an add/remove of its siblings.
  List<Map<String, dynamic>> items = [];

  bool editing = false;

  final Map<String, TextEditingController> _text = {};
  int _uidSeed = 0;

  /// ERP renders these as checkbox pairs where ticking one clears the other.
  static const Map<String, List<String>> _exclusive = {
    'experienced': ['freshers'],
    'freshers': ['experienced'],
    'createbyorganization': ['havealready'],
    'havealready': ['createbyorganization'],
  };

  static const String _dateStoreFormat = 'yyyy-MM-dd';
  static const String _dateShowFormat = 'dd-MM-yyyy';

  @override
  void onInit() {
    section = EmployeeProfileSpec.byKey(Get.arguments?.toString() ?? '');
    parent = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    _resetFromParent();
    super.onInit();
  }

  @override
  void onClose() {
    for (final c in _text.values) {
      c.dispose();
    }
    _text.clear();
    super.onClose();
  }

  // Edit lifecycle

  void startEdit() {
    _recycleControllers();
    editing = true;
    update();
  }

  void cancelEdit() {
    _resetFromParent();
    editing = false;
    update();
  }

  void _resetFromParent() {
    _recycleControllers();
    working = parent.profile.copy();
    final rep = section.repeatable;
    items = rep == null
        ? []
        : working.list(rep.listKey).map((e) {
            final copy = Map<String, dynamic>.from(e);
            copy['_uid'] = '${_uidSeed++}';
            return copy;
          }).toList();
  }

  /// Drops the current text controllers, disposing them only after the frame
  /// that still has their TextFields mounted has finished.
  void _recycleControllers() {
    if (_text.isEmpty) return;
    final retired = _text.values.toList();
    _text.clear();
    _disposeAfterFrame(retired);
  }

  void _disposeAfterFrame(List<TextEditingController> retired) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in retired) {
        c.dispose();
      }
    });
  }

  // Field access

  ErpField? _fieldByKey(String key) {
    for (final f in section.allFields) {
      if (f.key == key) return f;
    }
    return null;
  }

  String valueOf(ErpField field) => working.str(field.key);

  bool toggleOf(ErpField field) => working.flag(field.key);

  /// Case-insensitive read from a repeatable row.
  String itemValue(Map<String, dynamic> item, ErpField field) {
    for (final entry in item.entries) {
      if (entry.key.toLowerCase() == field.key.toLowerCase()) {
        final v = entry.value;
        if (v == null) return '';
        final s = v.toString().trim();
        return s == 'null' ? '' : s;
      }
    }
    return '';
  }

  void setItemValue(Map<String, dynamic> item, ErpField field, String value) {
    for (final key in item.keys.toList()) {
      if (key.toLowerCase() == field.key.toLowerCase()) {
        item[key] = value;
        return;
      }
    }
    item[field.key] = value;
  }

  TextEditingController textController(String id, String initial) =>
      _text.putIfAbsent(id, () => TextEditingController(text: initial));

  String fieldControllerId(ErpField field) => 'f.${field.key}';

  String itemControllerId(Map<String, dynamic> item, ErpField field) =>
      'i.${item['_uid']}.${field.key}';

  // Toggles

  void setToggle(ErpField field, bool value) {
    working.set(field.key, value ? '1' : '0');
    if (value) {
      for (final other in _exclusive[field.key] ?? const <String>[]) {
        working.set(other, '0');
      }
    }
    update();
  }

  // Dropdowns

  /// Options for [field]: the API lookup when present, otherwise the static
  /// fallback list. An empty result makes the row fall back to free text so a
  /// missing lookup never blocks editing.
  List<LookupItem> optionsFor(ErpField field) {
    var list = field.lookup == null
        ? const <LookupItem>[]
        : (parent.lookups[field.lookup!.toLowerCase()] ?? const <LookupItem>[]);

    if (list.isEmpty && (field.options?.isNotEmpty ?? false)) {
      list = field.options!.map((e) => LookupItem(id: e, name: e)).toList();
    }

    final dependsOn = field.dependsOn;
    if (dependsOn != null && list.isNotEmpty) {
      final parentField = _fieldByKey(dependsOn);
      final parentId = parentField?.idKey == null
          ? ''
          : working.str(parentField!.idKey!);
      if (parentId.isNotEmpty && list.any((e) => e.parentId != null)) {
        list = list
            .where((e) => e.parentId == null || e.parentId == parentId)
            .toList();
      }
    }
    return list;
  }

  void selectOption(ErpField field, LookupItem option) {
    working.set(field.key, option.name);
    if (field.idKey != null) {
      working.set(field.idKey!, option.id);
    }
    // A new state invalidates the chosen city.
    for (final f in section.allFields) {
      if (f.dependsOn == field.key) {
        working.set(f.key, '');
        if (f.idKey != null) working.set(f.idKey!, '');
      }
    }
    update();
  }

  void selectItemOption(
      Map<String, dynamic> item, ErpField field, LookupItem option) {
    setItemValue(item, field, option.name);
    if (field.idKey != null) {
      item[field.idKey!] = option.id;
    }
    update();
  }

  // Dates

  DateTime? _parseDate(String raw) {
    if (raw.isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;
    for (final f in [_dateShowFormat, 'dd/MM/yyyy', 'MM/dd/yyyy']) {
      try {
        return DateFormat(f).parseStrict(raw);
      } catch (_) {
        // try the next pattern
      }
    }
    return null;
  }

  String formatDate(String raw) {
    final d = _parseDate(raw);
    return d == null ? raw : DateFormat(_dateShowFormat).format(d);
  }

  Future<void> pickDate(ErpField field, {Map<String, dynamic>? item}) async {
    final current = item == null ? valueOf(field) : itemValue(item, field);
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: _parseDate(current) ?? DateTime.now(),
      firstDate: AppConst.calenderFirstDate,
      lastDate: AppConst.calenderLastDate,
    );
    if (picked == null) return;
    final stored = DateFormat(_dateStoreFormat).format(picked);
    if (item == null) {
      working.set(field.key, stored);
    } else {
      setItemValue(item, field, stored);
    }
    update();
  }

  // Files

  Future<void> pickFile(ErpField field, {Map<String, dynamic>? item}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      final picked = result?.files.single;
      if (picked?.path == null) return;

      final bytes = await File(picked!.path!).readAsBytes();
      final encoded = base64.encode(bytes);
      if (item == null) {
        working.set(field.key, picked.name);
        working.set(field.base64Key, encoded);
        working.set(field.fileNameKey, picked.name);
      } else {
        setItemValue(item, field, picked.name);
        item[field.base64Key] = encoded;
        item[field.fileNameKey] = picked.name;
      }
      update();
    } catch (e) {
      ShowMessage.showSnackBar('File', 'Could not pick file: $e');
    }
  }

  void clearFile(ErpField field, {Map<String, dynamic>? item}) {
    if (item == null) {
      working.set(field.key, '');
      working.set(field.base64Key, '');
      working.set(field.fileNameKey, '');
    } else {
      setItemValue(item, field, '');
      item[field.base64Key] = '';
      item[field.fileNameKey] = '';
    }
    update();
  }

  // Repeatable rows

  bool get repeatableVisible {
    final rep = section.repeatable;
    if (rep == null) return false;
    final gate = rep.visibleWhenFlag;
    return gate == null || working.flag(gate);
  }

  void addItem() {
    items.add({'_uid': '${_uidSeed++}'});
    update();
  }

  void removeItem(Map<String, dynamic> item) {
    final uid = item['_uid'];
    items.remove(item);
    final retired = <TextEditingController>[];
    _text.removeWhere((key, controller) {
      if (key.startsWith('i.$uid.')) {
        retired.add(controller);
        return true;
      }
      return false;
    });
    _disposeAfterFrame(retired);
    update();
  }

  String itemTitle(Map<String, dynamic> item, int index) {
    final rep = section.repeatable!;
    for (final entry in item.entries) {
      if (entry.key.toLowerCase() == rep.titleKey.toLowerCase()) {
        final v = entry.value?.toString().trim() ?? '';
        if (v.isNotEmpty) return v;
      }
    }
    return '${rep.itemLabel} ${index + 1}';
  }

  // Save

  /// Pulls every on-screen text input back onto the working copy.
  void _harvest() {
    for (final field in section.allFields) {
      final c = _text[fieldControllerId(field)];
      if (c != null) working.set(field.key, c.text.trim());
    }
    final rep = section.repeatable;
    if (rep == null) return;
    for (final item in items) {
      for (final field in rep.fields) {
        final c = _text[itemControllerId(item, field)];
        if (c != null) setItemValue(item, field, c.text.trim());
      }
    }
  }

  /// Only this section's keys travel — not the whole 150-field record.
  Map<String, dynamic> _sectionPayload() {
    final data = <String, dynamic>{
      'id': working.str('id'),
      'employeeid': working.str('employeeid'),
    };

    void addField(ErpField field) {
      data[field.key] = working.str(field.key);
      if (field.idKey != null) data[field.idKey!] = working.str(field.idKey!);
      if (field.type == ErpFieldType.file) {
        data[field.base64Key] = working.str(field.base64Key);
        data[field.fileNameKey] = working.str(field.fileNameKey);
      }
    }

    section.allFields.forEach(addField);

    final rep = section.repeatable;
    if (rep != null) {
      data[rep.listKey] = items.map((item) {
        final row = Map<String, dynamic>.from(item)..remove('_uid');
        return row;
      }).toList();
    }
    return data;
  }

  Future<void> save() async {
    _harvest();
    setBusy(true);
    try {
      final user = parent.homeController.currentUserData;
      final body = {
        RequestKeys.userId: user?.userid?.toString() ?? '',
        RequestKeys.compId: user?.compId?.toString() ?? '',
        'section': section.key,
        'data': _sectionPayload(),
      };

      final res = await api.saveEmployeeProfileSection(json.encode(body));
      if (res.status == 200) {
        if (res.data != null && !res.data!.isEmpty) {
          working = res.data!;
        }
        _commit();
        ShowMessage.showSnackBar(
            section.title, res.message?.toString() ?? 'Saved');
        return;
      }

      // Employee Master endpoint not live yet — save what the existing
      // UserProfile endpoint already supports, so General still works today.
      if (section.key == 'general' && await _saveViaLegacyEndpoint()) {
        _commit();
        ShowMessage.showSnackBar('Profile',
            'Name, email and address saved. Remaining fields need the new employee profile API.');
        return;
      }

      ShowMessage.showSnackBar(
        section.title,
        res.message?.toString().isNotEmpty ?? false
            ? res.message.toString()
            : 'Employee profile API is not available yet.',
      );
    } catch (e) {
      ShowMessage.showSnackBar(AppString.somethingTxt, '$e');
    } finally {
      setBusy(false);
    }
  }

  void _commit() {
    final rep = section.repeatable;
    if (rep != null) {
      working.set(
        rep.listKey,
        items.map((item) => Map<String, dynamic>.from(item)..remove('_uid')).toList(),
      );
    }
    parent.profile = working.copy();
    parent.update();
    editing = false;
    _recycleControllers();
    update();
  }

  Future<bool> _saveViaLegacyEndpoint() async {
    final user = parent.homeController.currentUserData;
    final fullName =
        '${working.str('firstname')} ${working.str('lastname')}'.trim();
    final email = working.str('companyemailid').isNotEmpty
        ? working.str('companyemailid')
        : working.str('personalemailid');

    final body = <String, String>{
      RequestKeys.userId: user?.userid?.toString() ?? '',
      RequestKeys.compId: user?.compId?.toString() ?? '',
      RequestKeys.name: fullName,
      RequestKeys.email: email,
      RequestKeys.address: parent.addressController.text.trim(),
      RequestKeys.photo: '',
      RequestKeys.filename: '',
    };
    final res = await api.updateProfileJson(json.encode(body));
    if (res.status != 200) return false;

    SharedPre.setValue(SharedPre.userData, res.data?.toJson());
    parent.homeController.currentUserData =
        await userDataController.getUserData;
    parent.nameController.text = fullName;
    parent.emailController.text = email;
    return true;
  }
}
