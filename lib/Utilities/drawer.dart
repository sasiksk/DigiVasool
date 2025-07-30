import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vasool_diary/Screens/Main/BulkInsert/CollectionEntryScreen.dart';

import 'package:vasool_diary/Screens/Main/BulkInsert/bulk_insert_screen.dart';
import 'package:vasool_diary/Screens/TableDetailsScreen.dart';

import 'package:vasool_diary/Screens/UtilScreens/Backuppage.dart';
import 'package:vasool_diary/ContactUs.dart';
import 'package:vasool_diary/Data/Databasehelper.dart';
import 'package:vasool_diary/Screens/UtilScreens/Restore.dart';
import 'package:vasool_diary/Utilities/Reports/CustomerReportScreen.dart';
import 'package:vasool_diary/Screens/Main/home_screen.dart';

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        // Gradient Header with user info
        Container(
          padding: const EdgeInsets.only(top: 40, bottom: 20),
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF42A5F5), Color(0xFF81D4FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Vasool Diary',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        // Drawer Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              _buildDrawerItem(
                context,
                icon: Icons.home,
                title: 'Home',
                onTap: () => _navigateTo(context, const HomeScreen()),
              ),
              /*_buildDrawerItem(
                context,
                icon: Icons.insert_drive_file,
                title: 'Bulk Insert',
                onTap: () => _navigateTo(context, const TableDetailsScreen()),
              ),*/
              _buildDrawerItem(
                context,
                icon: Icons.monetization_on,
                title: 'Collection Entry',
                onTap: () =>
                    _navigateTo(context, const CollectionEntryScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.backup,
                title: 'Back Up',
                onTap: () => _navigateTo(context, const DownloadDBScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.restore,
                title: 'Restore',
                onTap: () => _navigateTo(context, RestorePage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.picture_as_pdf,
                title: 'View Reports',
                onTap: () => _navigateTo(context, const ViewReportsPage()),
              ),
              const Divider(thickness: 1),
              _buildDrawerItem(
                context,
                icon: Icons.restore_from_trash,
                title: 'Reset All',
                onTap: () => _showResetConfirmationDialog(context),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.contact_phone,
                title: 'Contact Us',
                onTap: () => _navigateTo(context, const ContactPage()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.exit_to_app,
                title: 'Exit',
                onTap: () => SystemNavigator.pop(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade700),
          const SizedBox(width: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

// Reusable Drawer Item Widget

// Navigation Helper Function

// Reset Confirmation Dialog
void _showResetConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Are you sure you want to reset all data?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              DatabaseHelper.dropDatabase();
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Success'),
                    content:
                        const Text('All data has been reset successfully.'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      );
    },
  );
}

void _navigateTo(BuildContext context, Widget screen) {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}
