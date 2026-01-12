import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthFilterBar extends StatefulWidget {
  final Function(String monthName) onMonthSelected;

  const MonthFilterBar({
    required this.onMonthSelected,
    super.key,
  });

  @override
  State<MonthFilterBar> createState() =>
      _MonthFilterBarState();
}

class _MonthFilterBarState extends State<MonthFilterBar> {
  late int selectedIndex;
  bool _hasTriggeredInitial = false;

  final List<String> months = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
  );

  @override
  void initState() {
    super.initState();
    selectedIndex = DateTime.now().month - 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasTriggeredInitial) {
        _hasTriggeredInitial = true;
        widget.onMonthSelected(months[selectedIndex]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: ChoiceChip(
              label: Text(months[index]),
              selected: isSelected,
              onSelected: (_) {
                setState(() => selectedIndex = index);
                widget.onMonthSelected(months[index]);
              },
              selectedColor: Colors.blue.shade300,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}
