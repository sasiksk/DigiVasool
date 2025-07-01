import 'package:flutter/material.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';

class TableDetailsScreen extends StatefulWidget {
  const TableDetailsScreen({super.key});

  @override
  _TableDetailsScreenState createState() => _TableDetailsScreenState();
}

class _TableDetailsScreenState extends State<TableDetailsScreen> {
  List<String> _tableNames = ['Lending', 'Collection', 'Line'];
  String? _selectedTableName;
  List<Map<String, dynamic>> _tableDetails = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Details'),
        backgroundColor: Colors.teal.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Table Details Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Choose Table Name',
                border: OutlineInputBorder(),
              ),
              value: _selectedTableName,
              items: _tableNames.map((tableName) {
                return DropdownMenuItem<String>(
                  value: tableName,
                  child: Text(tableName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTableName = value;
                  _loadTableDetails(value!);
                });
              },
              selectedItemBuilder: (BuildContext context) {
                return _tableNames.map<Widget>((String tableName) {
                  return Text(
                    _selectedTableName ?? 'Choose Table Name',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  );
                }).toList();
              },
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: _tableDetails.isNotEmpty
                      ? DataTable(
                          columns: _getColumns(),
                          rows: _getRows(),
                        )
                      : const Center(child: Text('No data available')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTableDetails(String tableName) async {
    List<Map<String, dynamic>> details = [];
    final db = await DatabaseHelper.getDatabase();

    switch (tableName) {
      case 'Lending':
        details = await db.query('Lending');
        break;
      case 'Collection':
        details = await db.query('Collection');
        break;
      case 'Line':
        details = await db.query('Line');
        break;
    }

    setState(() {
      _tableDetails = details;
    });
  }

  List<DataColumn> _getColumns() {
    if (_tableDetails.isEmpty) return [];

    return _tableDetails.first.keys.map((key) {
      return DataColumn(label: Text(key, style: TextStyle(fontSize: 12)));
    }).toList();
  }

  List<DataRow> _getRows() {
    return _tableDetails.map((detail) {
      return DataRow(
        cells: detail.values.map((value) {
          return DataCell(
              Text(value.toString(), style: TextStyle(fontSize: 12)));
        }).toList(),
      );
    }).toList();
  }
}
