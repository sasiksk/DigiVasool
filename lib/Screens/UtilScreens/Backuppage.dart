import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart'; // For app-specific directories
import 'package:lottie/lottie.dart'; // For animations
import 'package:intl/intl.dart'; // For date formatting

import '../../Data/Databasehelper.dart';

class DownloadDBScreen extends StatelessWidget {
  const DownloadDBScreen({super.key});

  Future<void> downloadDBFile(BuildContext context) async {
    try {
      // Get the database file
      final db = await DatabaseHelper.getDatabase();
      final dbPath = db.path;
      final dbFile = File(dbPath);

      // Generate a file name based on today's date and time
      final now = DateTime.now();
      final String todayDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
      final appDir = await getApplicationDocumentsDirectory();
      final backupFile = File('${appDir.path}/backup_$todayDate.db');

      // Copy the database file to the new location with the new name
      await dbFile.copy(backupFile.path);

      // Also copy to Android/media/com.DigiThinkers.DigiVasool
      final mediaDir = Directory(
          '/storage/emulated/0/Android/media/com.DigiThinkers.VasoolDiary');
      if (!(await mediaDir.exists())) {
        await mediaDir.create(recursive: true);
      }
      final mediaBackupFile = File('${mediaDir.path}/backup_$todayDate.db');
      await dbFile.copy(mediaBackupFile.path);

      // Show a loading animation while preparing the backup
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animations/backup_icon.json',
                      width: 150,
                      height: 150,
                      repeat: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Preparing your database backup...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Simulate a delay for the backup process
      await Future.delayed(const Duration(seconds: 2));

      // Dismiss the loading animation
      Navigator.of(context).pop();

      // After backup, check for old backup files and prompt for deletion
      await checkAndPromptDeleteOldBackups(context, mediaDir);

      // Show alert dialog for backup completion
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Share Backup'),
            content: const Text(
                'Your database backup is ready. You can share it or save it to a secure location.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Share Backup'),
                onPressed: () async {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  await Share.shareXFiles([XFile(backupFile.path)],
                      text: 'Here is the backup of your database file.');
                },
              ),
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss the dialog
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error creating backup: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating backup: $e")),
      );
    }
  }

  Future<void> checkAndPromptDeleteOldBackups(
      BuildContext context, Directory mediaDir) async {
    try {
      // List all files in the mediaDir
      final List<FileSystemEntity> mediaFiles = mediaDir.listSync();

      // Filter out the backup files (assuming they start with 'backup_')
      final List<FileSystemEntity> mediaBackupFiles = mediaFiles.where((file) {
        return file is File && file.path.contains('/backup_');
      }).toList();

      // Also check the app sandbox directory
      final appDir = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> appFiles = Directory(appDir.path).listSync();
      final List<FileSystemEntity> appBackupFiles = appFiles.where((file) {
        return file is File && file.path.contains('/backup_');
      }).toList();

      // If there are more than 10 backup files, prompt the user to delete old ones
      if (mediaBackupFiles.length > 10) {
        // Sort by file path (which includes date/time, so latest will be last)
        mediaBackupFiles.sort((a, b) => b.path.compareTo(a.path));
        appBackupFiles.sort((a, b) => b.path.compareTo(a.path));

        // Show a dialog to the user
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Old Backups'),
              content: const Text(
                  'You have more than 10 backup files. Do you want to delete the oldest backups and keep only the latest 10? This will delete from both backup locations.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () async {
                    Navigator.of(context).pop(); // Dismiss the dialog

                    // Delete old backup files, keeping only the latest 10
                    for (int i = 10; i < mediaBackupFiles.length; i++) {
                      try {
                        if (mediaBackupFiles[i] is File) {
                          await (mediaBackupFiles[i] as File).delete();
                        }
                      } catch (e) {
                        debugPrint(
                            'Error deleting media file: ${mediaBackupFiles[i]}');
                      }
                    }
                    for (int i = 10; i < appBackupFiles.length; i++) {
                      try {
                        if (appBackupFiles[i] is File) {
                          await (appBackupFiles[i] as File).delete();
                        }
                      } catch (e) {
                        debugPrint(
                            'Error deleting sandbox file: ${appBackupFiles[i]}');
                      }
                    }

                    // Show a snackbar or dialog to inform the user
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Old backup files deleted from both locations.')),
                    );
                  },
                ),
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error checking or deleting old backups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Database')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/backup_icon.json', // Add a Lottie animation for the backup screen
              width: 200,
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Backup Your Database',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Ensure your data is safe by creating a backup of your database. You can share the backup file or save it to a secure location.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => downloadDBFile(context),
              icon: const Icon(Icons.backup),
              label: const Text('Start Backup'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
