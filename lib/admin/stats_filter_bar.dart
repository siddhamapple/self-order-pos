import 'package:flutter/material.dart';

enum StatsRangeType {
  today,
  week,
  month,
  quarter,
  custom,
}

class StatsRange {
  final DateTime start;
  final DateTime end;
  final StatsRangeType type;

  StatsRange({
    required this.start,
    required this.end,
    required this.type,
  });
}

class StatsFilterBar extends StatefulWidget {
  final Function(StatsRange range) onRangeChanged;

  const StatsFilterBar({super.key, required this.onRangeChanged});

  @override
  State<StatsFilterBar> createState() => _StatsFilterBarState();
}

class _StatsFilterBarState extends State<StatsFilterBar> {
  StatsRangeType _selected = StatsRangeType.today;
  DateTime _customStart = DateTime.now();
  DateTime _customEnd = DateTime.now();

  @override
  void initState() {
    super.initState();
    _emitRange();
  }

  void _emitRange() {
    final now = DateTime.now();
    late DateTime start;
    late DateTime end;

    switch (_selected) {
      case StatsRangeType.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;

      case StatsRangeType.week:
        start = now.subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;

      case StatsRangeType.month:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;

      case StatsRangeType.quarter:
        final q = ((now.month - 1) ~/ 3) + 1;
        start = DateTime(now.year, (q - 1) * 3 + 1, 1);
        end = DateTime(now.year, (q - 1) * 3 + 4, 1);
        break;

      case StatsRangeType.custom:
        start = _customStart;
        end = _customEnd.add(const Duration(days: 1));
        break;
    }

    widget.onRangeChanged(
      StatsRange(start: start, end: end, type: _selected),
    );
  }

  Future<void> _pickCustomDates() async {
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (start == null) return;

    final end = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: DateTime.now(),
    );

    if (end == null) return;

    setState(() {
      _customStart = start;
      _customEnd = end;
      _selected = StatsRangeType.custom;
    });

    _emitRange();
  }

  Widget _chip(String label, StatsRangeType type) {
    final isSelected = _selected == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selected = type);
        _emitRange();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip("Today", StatsRangeType.today),
        _chip("Week", StatsRangeType.week),
        _chip("Month", StatsRangeType.month),
        _chip("Quarter", StatsRangeType.quarter),
        ActionChip(
          label: const Text("Custom"),
          onPressed: _pickCustomDates,
        ),
      ],
    );
  }
}
