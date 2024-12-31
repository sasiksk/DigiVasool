// filepath: /J:/SASIKUMAR/skfinance/lib/Backuppage.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Data/Databasehelper.dart';

class DownloadDBScreen extends StatelessWidget {
  const DownloadDBScreen({super.key});

  Future<void> downloadDBFile(BuildContext context) async {
    try {
      final db = await DatabaseHelper.getDatabase();
      final dbPath = db.path;
      print(dbPath);
      final dbFile = File(dbPath);

      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        // Show alert dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Backup Reminder'),
              content: const Text(
                  'Kindly save the backup file in Google Drive. Thank you.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () async {
                    Navigator.of(context).pop(); // Dismiss the dialog

                    // Complete path
                    String savePath = '$dbPath';

                    // Copy the database file to the selected directory
                    //await dbFile.copy(savePath);

                    // Notify user

                    // Share the file
                    await Share.shareXFiles([XFile(savePath)],
                        text: 'Download DB file');
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error creating backup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating backup: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Database File')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => downloadDBFile(context),
          child: const Text('Download DB File'),
        ),
      ),
    );
  }
}
