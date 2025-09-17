import 'package:flutter/material.dart';
import 'package:vasool_diary/Screens/Main/BulkInsert/EnhancedBulkInsertScreen.dart';

import 'package:vasool_diary/Screens/Main/BulkInsert/bulk_insert_screen.dart';

class CollectionEntryScreen extends StatefulWidget {
  const CollectionEntryScreen({super.key});

  @override
  _CollectionEntryScreenState createState() => _CollectionEntryScreenState();
}

class _CollectionEntryScreenState extends State<CollectionEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Entry'),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.table_rows),
              text: 'Individual',
            ),
            Tab(
              icon: Icon(Icons.credit_card),
              text: 'Bulk Insert',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EnhancedBulkInsertScreen(),
          BulkInsertScreen(),
        ],
      ),
    );
  }
}
