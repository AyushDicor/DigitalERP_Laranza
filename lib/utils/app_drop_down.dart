import 'package:digitalerp/utils/app_constant_new.dart';
//    show newTextPrimary, newTextSecondary, newTextHint, newBorderColor, newBlueColor, newRedColor;
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final void Function(T?)? onChanged;
  final bool isRequired;
  final String Function(T) displayText;
  final String? Function(T?)? validator;
  final AutovalidateMode autovalidateMode;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.displayText,
    this.isRequired = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: newTextPrimary),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: newRedColor, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: newBorderColor),
                  color: Colors.white,
                ),
                child: Text(
                  "No $label available",
                  style: TextStyle(fontSize: 14, color: newTextSecondary),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: newBorderColor),
                  color: Colors.white,
                ),
                child: DropdownButtonFormField<T>(
                  isExpanded: true,
                  value: value,
                  onChanged: onChanged,
                  validator: validator,
                  autovalidateMode: autovalidateMode,
                  style: TextStyle(fontSize: 14, color: newTextPrimary),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: newBlueColor, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: newRedColor, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: newRedColor, width: 1.5),
                    ),
                  ),
                  hint: Text(
                    hint,
                    style: TextStyle(fontSize: 14, color: newTextHint),
                  ),
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: newTextSecondary, size: 24),
                  items: items.map((T item) {
                    return DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        displayText(item),
                        style: TextStyle(fontSize: 14, color: newTextPrimary),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final InputDecoration? inputDecoration;
  final bool isRequired;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final AutovalidateMode autovalidateMode;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.isRequired = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.inputDecoration,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: newTextPrimary),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: newRedColor, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: newBorderColor),
            color: Colors.white,
          ),
          child: TextFormField(
            autovalidateMode: autovalidateMode,
            controller: controller ?? TextEditingController(),
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(fontSize: 14, color: newTextPrimary),
            decoration: inputDecoration ??
                InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 14, color: newTextHint),
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: newBlueColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: newRedColor, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: newRedColor, width: 1.5),
                  ),
                ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
