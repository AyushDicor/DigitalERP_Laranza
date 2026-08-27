// Employee Profile (ERP Employee Master) response models.
//
// The ERP Employee Master carries ~150 fields across 9 sections and the backend
// API for it is still being written. So instead of ~150 nullable properties the
// profile is kept as a case-insensitive map: the UI addresses fields by the same
// keys the ERP model uses (firstname, desgination, permanentpincode, ...), and a
// column arriving as `PermanentPincode` or `permanentpincode` both resolve.

import 'dart:convert';

EmployeeProfileResponse employeeProfileResponseFromJson(String str) =>
    EmployeeProfileResponse.fromJson(json.decode(str));

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

class EmployeeProfileResponse {
  EmployeeProfileResponse({
    this.success,
    this.data,
    this.message,
    this.status,
  });

  bool? success;
  EmployeeProfile? data;
  String? message;
  int? status;

  factory EmployeeProfileResponse.fromJson(Map<String, dynamic> json) {
    // `data` may arrive as an object or as a single-row list — accept both.
    dynamic d = json['data'];
    if (d is List) {
      d = d.isNotEmpty ? d.first : null;
    }
    return EmployeeProfileResponse(
      success: json['success'] is bool ? json['success'] : null,
      data: d is Map
          ? EmployeeProfile.fromJson(Map<String, dynamic>.from(d))
          : null,
      message: json['message']?.toString(),
      status: _toInt(json['status']),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'data': data?.toJson(),
        'message': message,
        'status': status,
      };
}

/// Case-insensitive bag of employee-master fields.
class EmployeeProfile {
  final Map<String, dynamic> _raw = {};

  /// lower-cased key -> the key actually stored in [_raw]
  final Map<String, String> _index = {};

  EmployeeProfile([Map<String, dynamic>? source]) {
    source?.forEach(set);
  }

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) =>
      EmployeeProfile(json);

  Map<String, dynamic> get raw => _raw;

  bool get isEmpty => _raw.isEmpty;

  dynamic operator [](String key) => _raw[_index[key.toLowerCase()] ?? key];

  void set(String key, dynamic value) {
    final lower = key.toLowerCase();
    final existing = _index[lower];
    if (existing != null) {
      _raw[existing] = value;
    } else {
      _index[lower] = key;
      _raw[key] = value;
    }
  }

  /// Fills [key] only when it has no value yet — used to seed the profile from
  /// the login payload while the detail endpoint is still missing.
  void setIfEmpty(String key, dynamic value) {
    if (str(key).isEmpty && value != null && value.toString().isNotEmpty) {
      set(key, value);
    }
  }

  String str(String key) {
    final v = this[key];
    if (v == null) return '';
    final s = v.toString().trim();
    return (s == 'null') ? '' : s;
  }

  /// ERP stores its checkboxes as 1/0, "true"/"false" or "Y"/"N".
  bool flag(String key) {
    const truthy = {'1', 'true', 'yes', 'y', 'on', 'checked'};
    return truthy.contains(str(key).toLowerCase());
  }

  List<Map<String, dynamic>> list(String key) {
    final v = this[key];
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_raw);

  EmployeeProfile copy() => EmployeeProfile(toJson());
}

// Dropdown lookups (Department, Designation, State, City, Grade, ...)

class LookupItem {
  const LookupItem({required this.id, required this.name, this.parentId});

  final String id;
  final String name;

  /// Set for dependent lists — e.g. a city's state id.
  final String? parentId;

  factory LookupItem.fromJson(dynamic json) {
    if (json is String || json is num) {
      return LookupItem(id: json.toString(), name: json.toString());
    }
    final map = Map<String, dynamic>.from(json as Map);
    String pick(List<String> keys) {
      for (final k in map.keys) {
        if (keys.contains(k.toLowerCase())) {
          final v = map[k];
          if (v != null && v.toString().trim().isNotEmpty) {
            return v.toString().trim();
          }
        }
      }
      return '';
    }

    final name = pick(['name', 'text', 'label', 'value', 'title']);
    final id = pick(['id', 'code', 'key']);
    final parent = pick(['parentid', 'stateid', 'parent']);
    return LookupItem(
      id: id.isEmpty ? name : id,
      name: name.isEmpty ? id : name,
      parentId: parent.isEmpty ? null : parent,
    );
  }
}

ProfileLookupsResponse profileLookupsResponseFromJson(String str) =>
    ProfileLookupsResponse.fromJson(json.decode(str));

class ProfileLookupsResponse {
  ProfileLookupsResponse({
    this.success,
    Map<String, List<LookupItem>>? data,
    this.message,
    this.status,
  }) : data = data ?? {};

  bool? success;
  Map<String, List<LookupItem>> data;
  String? message;
  int? status;

  factory ProfileLookupsResponse.fromJson(Map<String, dynamic> json) {
    final parsed = <String, List<LookupItem>>{};
    final d = json['data'];
    if (d is Map) {
      d.forEach((key, value) {
        if (value is List) {
          parsed[key.toString().toLowerCase()] =
              value.map(LookupItem.fromJson).toList();
        }
      });
    }
    return ProfileLookupsResponse(
      success: json['success'] is bool ? json['success'] : null,
      data: parsed,
      message: json['message']?.toString(),
      status: _toInt(json['status']),
    );
  }
}
