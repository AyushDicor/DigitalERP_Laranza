import 'package:digitalerp/utils/app_constant_new.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Searchable bottom-sheet picker shared by the Quick Order screen's Company
/// and Brand fields.
///
/// The party list runs to ~180 entries on live data, which a plain
/// [DropdownButton] cannot present usably, so both fields open this sheet
/// instead — keeping the two selectors visually identical.
///
/// Returns the picked item, or `null` if the sheet was dismissed.
Future<T?> showPickerSheet<T>({
  required String title,
  required List<T> items,
  required String Function(T item) labelOf,
  String Function(T item)? subtitleOf,
  bool Function(T item)? isSelected,
  String searchHint = 'Search',
  String emptyText = 'Nothing to show',
}) {
  return Get.bottomSheet<T>(
    _PickerSheet<T>(
      title: title,
      items: items,
      labelOf: labelOf,
      subtitleOf: subtitleOf,
      isSelected: isSelected,
      searchHint: searchHint,
      emptyText: emptyText,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    ignoreSafeArea: false,
  );
}

class _PickerSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T item) labelOf;
  final String Function(T item)? subtitleOf;
  final bool Function(T item)? isSelected;
  final String searchHint;
  final String emptyText;

  const _PickerSheet({
    super.key,
    required this.title,
    required this.items,
    required this.labelOf,
    this.subtitleOf,
    this.isSelected,
    required this.searchHint,
    required this.emptyText,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _searchController = TextEditingController();
  late List<T> _filtered = widget.items;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items
              .where((e) => widget.labelOf(e).toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: newBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: newTextPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back<T>(),
                  icon: const Icon(Icons.close_rounded,
                      size: 22, color: newTextSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: const TextStyle(fontSize: 14, color: newTextPrimary),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: const TextStyle(color: newTextHint, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: newTextSecondary, size: 20),
                filled: true,
                fillColor: newSurfaceColor,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: newBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: newBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: newBlueColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: _filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      widget.emptyText,
                      style: const TextStyle(
                          color: newTextSecondary, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, thickness: 1, color: newBorderColor),
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final selected = widget.isSelected?.call(item) ?? false;
                      final subtitle = widget.subtitleOf?.call(item);
                      return ListTile(
                        dense: true,
                        onTap: () => Get.back<T>(result: item),
                        title: Text(
                          widget.labelOf(item),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? newBlueColor : newTextPrimary,
                          ),
                        ),
                        subtitle: (subtitle == null || subtitle.isEmpty)
                            ? null
                            : Text(
                                subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: newTextSecondary),
                              ),
                        trailing: selected
                            ? const Icon(Icons.check_circle_rounded,
                                size: 20, color: newBlueColor)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
