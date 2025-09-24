import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Dialog wyboru daty
class CustomDatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CustomDatePickerDialog({
    super.key,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();

  /// Pokazuje dialog wyboru daty
  static Future<DateTime?> showCustom(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => CustomDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Wybierz datę',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
      content: SizedBox(
        width: 300,
        height: 300,
        child: CalendarDatePicker(
          initialDate: selectedDate,
          firstDate: widget.firstDate ?? DateTime(2020),
          lastDate: widget.lastDate ?? DateTime(2030),
          onDateChanged: (date) {
            setState(() {
              selectedDate = date;
            });
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppTheme.errorButton,
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(selectedDate),
          style: AppTheme.successButton,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
