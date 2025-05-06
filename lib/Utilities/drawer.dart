import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:DigiVasool/Screens/TableDetailsScreen.dart';
import 'package:DigiVasool/Screens/UtilScreens/bulk_insert_screen.dart';
import 'package:DigiVasool/firebase_backup_screen.dart';
import 'package:DigiVasool/google_drive_backup_screen.dart';
import 'package:DigiVasool/Screens/UtilScreens/Backuppage.dart';
import 'package:DigiVasool/ContactUs.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/Screens/UtilScreens/Restore.dart';
import 'package:DigiVasool/Utilities/Reports/CustomerReportScreen.dart';
import 'package:DigiVasool/Screens/Main/home_screen.dart';

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: Column(
      children: [
        // Gradient Header
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF42A5F5), Color(0xFF81D4FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Drawer Items
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerItem(
                context,
                icon: Icons.home,
                title: 'Home',
                onTap: () => _navigateTo(context, const HomeScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.insert_drive_file,
                title: 'Table Details',
                onTap: () => _navigateTo(context, const TableDetailsScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.insert_drive_file,
                title: 'Bulk Insert',
                onTap: () => _navigateTo(context, const BulkInsertScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.backup,
                title: 'Back Up',
                onTap: () => _navigateTo(context, const DownloadDBScreen()),
              ),
              /*_buildDrawerItem(
                context,
                icon: Icons.cloud_upload,
                title: 'Back Up - Firebase',
                onTap: () => _navigateTo(context, const FirebaseBackupScreen()),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.drive_folder_upload,
                title: 'Back Up - Google Drive',
                onTap: () => _navigateTo(context, GoogleDriveBackupScreen()),
              ),*/
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
                onTap: () => _navigateTo(context, ViewReportsPage()),
              ),
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

// Reusable Drawer Item Widget
Widget _buildDrawerItem(
  BuildContext context, {
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.teal.shade900),
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    onTap: onTap,
  );
}

// Navigation Helper Function
void _navigateTo(BuildContext context, Widget screen) {
  Navigator.pop(context);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

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
