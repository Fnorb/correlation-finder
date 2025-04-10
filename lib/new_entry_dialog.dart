import 'package:flutter/material.dart';

class NewEntryDialog extends StatefulWidget {
  final List<String> columns;
  final void Function(List<String> newRow) onSave;
  final List<String>? initialValues;

  const NewEntryDialog({
    super.key,
    required this.columns,
    required this.onSave,
    this.initialValues,
  });

  @override
  State<NewEntryDialog> createState() => _NewEntryDialogState();
}

class _NewEntryDialogState extends State<NewEntryDialog> {
  int stepIndex = 0;
  List<String> values = [];

  @override
  void initState() {
    super.initState();
    values = widget.initialValues != null
        ? List<String>.from(widget.initialValues!)
        : [_formattedToday()];
  }

  String _formattedToday() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.'
           '${now.month.toString().padLeft(2, '0')}.'
           '${now.year}';
  }

  void _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      final formatted = '${selected.day.toString().padLeft(2, '0')}.'
                        '${selected.month.toString().padLeft(2, '0')}.'
                        '${selected.year}';
      setState(() {
        values[0] = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.columns.length + 1;
    final currentStep = stepIndex + 1;
    final currentLabel = stepIndex == 0
        ? 'Datum ($currentStep/$totalSteps)'
        : '${widget.columns[stepIndex - 1]} ($currentStep/$totalSteps)';

    return AlertDialog(
      title: Text(currentLabel),
      content: SizedBox(
        height: 80,
        child: Center(
          child: stepIndex == 0
              ? TextButton(
                  onPressed: _pickDate,
                  child: Text(
                    values[0],
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: ['+', 'x', '-'].map((symbol) {
                    final isSelected = values.length > stepIndex &&
                        values[stepIndex] == symbol;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected ? Colors.blue[100] : null,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            if (values.length <= stepIndex) {
                              values.add(symbol);
                            } else {
                              values[stepIndex] = symbol;
                            }
                          });

                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (stepIndex < widget.columns.length) {
                              setState(() {
                                stepIndex++;
                              });
                            } else {
                              widget.onSave(values);
                              Navigator.pop(context);
                            }
                          });
                        },
                        child: Text(
                          symbol == '+'
                              ? '✅'
                              : symbol == 'x'
                                  ? '❌'
                                  : '➖',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ),
      actions: stepIndex == 0
          ? [
              TextButton(
                onPressed: () {
                  if (values.length <= stepIndex) {
                    values.add('-');
                  }
                  setState(() {
                    stepIndex++;
                  });
                },
                child: const Text('Weiter'),
              ),
            ]
          : [],
    );
  }
}
