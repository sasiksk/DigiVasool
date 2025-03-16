import 'package:DigiVasool/Screens/TableDetailsScreen.dart';
import 'package:DigiVasool/Screens/bulk_insert_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/authorizedbuyersmarketplace/v1.dart';

import 'package:DigiVasool/Backuppage.dart';
import 'package:DigiVasool/ContactUs.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:DigiVasool/Restore.dart';
import 'package:DigiVasool/Utilities/Reports/CustomerReportScreen.dart';
import 'package:DigiVasool/Screens/Main/home_screen.dart';
/*import 'package:DigiVasool/CollectionScreen.dart';

import 'package:DigiVasool/LendingScreen.dart';
import 'package:DigiVasool/LineScreen.dart';
import 'package:DigiVasool/ReportScreen.dart';

import 'package:DigiVasool/Utilities/PartyScreen.dart';
import 'package:DigiVasool/Utilities/Reports/Custrans/ReportScreen1.dart';


import 'package:DigiVasool/linedetailScreen.dart';*/

Widget buildDrawer(BuildContext context) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.teal.shade900,
          ),
          child: const Text(
            'Menu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () {
            //navigate to home screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: const Text('Table Details'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TableDetailsScreen()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: const Text('Bulk Insert'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BulkInsertScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('Back Up'),
          onTap: () {
            //navigate to home screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DownloadDBScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('Restore'),
          onTap: () {
            //navigate to home screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RestorePage()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text(' View Reports'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ViewReportsPage()),
            );
          },
        ),

        ListTile(
          leading: const Icon(Icons.restore_from_trash_sharp),
          title: const Text('Reset All '),
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirm'),
                  content:
                      const Text('Are you sure you want to reset all data?'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () {
                        DatabaseHelper.dropDatabase();
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Success'),
                              content: const Text(
                                  'All data has been reset successfully.'),
                              actions: <Widget>[
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
          },
        ),
        ListTile(
          leading: const Icon(Icons.contact_phone),
          title: const Text(' Contact Us'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ContactPage()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.exit_to_app_rounded),
          title: const Text(' Exit'),
          onTap: () {
            SystemNavigator.pop();
          },
        ),
        /* ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Reports'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportScreen()),
            );
          },
        ),
        
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Create db'),
          onTap: () {
            DatabaseHelper.getDatabase();
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Line Add'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LineScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Party Add'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PartyScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('LineDetail Screen'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LineDetailScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Lending Screen'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => LendingCombinedDetailsScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Collection Screen'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CollectionScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.report),
          title: const Text('Collection Screen'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportScreen1()),
            );
          },
        ),*/

        // Add more items here as needed
      ],
    ),
  );
}
