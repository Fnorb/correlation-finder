import 'package:flutter/material.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'new_entry_dialog.dart';

class TableApp extends StatefulWidget {
  const TableApp({super.key});

  @override
  State<TableApp> createState() => _TableAppState();
}

class _TableAppState extends State<TableApp> {
  static const double headerFontSize = 18;

  List<String> columns = [];
  List<List<String>> tableContent = [];

  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('columns', jsonEncode(columns));
    await prefs.setString('tableContent', jsonEncode(tableContent));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColumns = prefs.getString('columns');
    final savedContent = prefs.getString('tableContent');

    if (savedColumns != null && savedContent != null) {
      setState(() {
        columns = List<String>.from(jsonDecode(savedColumns));
        tableContent = List<List<String>>.from(
          jsonDecode(savedContent).map<List<String>>((e) => List<String>.from(e)),
        );
      });
    }
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('.');
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  String _mapSymbolToEmoji(String symbol) {
    switch (symbol) {
      case '+':
        return '✅';
      case 'x':
        return '❌';
      case '-':
      default:
        return '';
    }
  }

  void _editRow(List<String> row) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return NewEntryDialog(
          columns: columns,
          initialValues: List<String>.from(row),
          onSave: (List<String> updatedRow) {
            setState(() {
              final index = tableContent.indexOf(row);
              if (index != -1) {
                tableContent[index] = updatedRow;
              }
            });
            saveData();
          },
        );
      },
    );
  }

  void _confirmDeleteRow(List<String> row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eintrag vom ${row[0]} löschen?'),
        content: const Text('Dieser Eintrag wird dauerhaft entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                tableContent.remove(row);
              });
              Navigator.pop(context);
              saveData();
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _renameColumn(int index) {
    final controller = TextEditingController(text: columns[index]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spalte umbenennen'),
        content: TextField(
          controller: controller,
          maxLength: 10,
          decoration: const InputDecoration(hintText: 'Neuer Name', counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final newLabel = controller.text.trim();
              if (newLabel.isNotEmpty) {
                setState(() {
                  columns[index] = newLabel;
                });
                saveData();
              }
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteColumn(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Spalte "${columns[index]}" löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                columns.removeAt(index);
                for (var row in tableContent) {
                  row.removeAt(index + 1);
                }
              });
              Navigator.pop(context);
              saveData();
            },
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddColumnDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Spalte hinzufügen'),
        content: TextField(
          controller: controller,
          maxLength: 10,
          decoration: const InputDecoration(hintText: 'Name der Spalte', counterText: ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final newLabel = controller.text.trim();
              if (newLabel.isNotEmpty) {
                setState(() {
                  columns.add(newLabel);
                  for (var row in tableContent) {
                    row.add("-");
                  }
                });
                saveData();
              }
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv() async {
    List<List<String>> csvData = [['Datum', ...columns], ...tableContent];
    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/tabelle.csv';
    final file = File(path);
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(path)], text: 'Hier ist meine Tabelle als CSV');
  }

  void _showNewEntryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewEntryDialog(
        columns: columns,
        onSave: (List<String> newRow) {
          setState(() => tableContent.add(newRow));
          saveData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedContent = [...tableContent];
    sortedContent.sort((a, b) => _parseDate(b[0]).compareTo(_parseDate(a[0])));

    return Scaffold(
      appBar: AppBar(
        actions: [
          ElevatedButton(
            onPressed: _showNewEntryDialog,
            child: const Text('Neuer Eintrag'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _exportCsv,
            child: const Text('Teilen'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final minTableWidth = (columns.length + 2) * 80.0;
          final tableWidth = constraints.maxWidth > minTableWidth ? constraints.maxWidth : minTableWidth;

          return Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: tableWidth),
                child: SingleChildScrollView(
                  controller: _verticalController,
                  scrollDirection: Axis.vertical,
                  child: Table(
                    border: TableBorder.all(color: Colors.black),
                    columnWidths: {
                      for (int i = 0; i < columns.length + 1; i++) i: const FixedColumnWidth(80),
                      columns.length + 1: const FixedColumnWidth(100),
                    },
                    children: [
                      _buildTableHeader(context),
                      ..._buildTableRows(sortedContent),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  TableRow _buildTableHeader(BuildContext context) {
    return TableRow(
      children: [
        Container(
          height: 80,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: Text(
              'Datum',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
            ),
          ),
        ),
        ...columns.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          return Container(
            height: 80,
            color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Spalte bearbeiten',
                      onPressed: () => _renameColumn(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: 'Spalte löschen',
                      onPressed: () => _confirmDeleteColumn(index),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        Container(
          height: 80,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Spalte hinzufügen',
              onPressed: _showAddColumnDialog,
            ),
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildTableRows(List<List<String>> sortedContent) {
    return sortedContent.map((row) {
      final filledRow = [...row];
      while (filledRow.length < columns.length + 1) {
        filledRow.add("-");
      }

      return TableRow(
        children: [
          Container(
            height: 50,
            color: Theme.of(context).colorScheme.background,
            child: Center(child: Text(filledRow[0])),
          ),
          ...filledRow.sublist(1).map((value) => Container(
                height: 50,
                child: Center(child: Text(_mapSymbolToEmoji(value))),
              )),
          Container(
            height: 50,
            color: Theme.of(context).colorScheme.background,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Eintrag bearbeiten',
                    onPressed: () => _editRow(row),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    tooltip: 'Eintrag löschen',
                    onPressed: () => _confirmDeleteRow(row),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}
