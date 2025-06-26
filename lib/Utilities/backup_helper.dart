import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../Data/Databasehelper.dart';

class BackupHelper {
  /// Call this for daily auto-backup (e.g., from home screen)
  static Future<void> backupDbIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final lastBackup = prefs.getString('last_backup_date');

    if (lastBackup == todayStr) return; // Already backed up today

    final backupFile = await _createBackupFile(todayStr);

    if (backupFile != null) {
      await prefs.setString('last_backup_date', todayStr);

      // Ask user to share
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Backup Complete'),
          content:
              const Text('Database backup created. Do you want to share it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Share.shareXFiles([XFile(backupFile.path)],
                    text: 'My DB Backup');
              },
              child: const Text('Share'),
            ),
          ],
        ),
      );
    }
  }

  /// Core backup logic, returns the backup file or null on error
  static Future<File?> _createBackupFile(String dateStr) async {
    try {
      final db = await DatabaseHelper.getDatabase();
      final dbPath = db.path;
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        print('Backup path: ${appDir.path}');
        final backupFile = File('${appDir.path}/backup_$dateStr.db');
        await dbFile.copy(backupFile.path);
        return backupFile;
      }
    } catch (e) {
      debugPrint('Error creating backup: $e');
    }
    return null;
  }

  /// Manual backup for UI (returns backup file or throws)
  static Future<File> manualBackup(BuildContext context) async {
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final backupFile = await _createBackupFile(todayDate);
    if (backupFile == null) {
      throw Exception("Backup failed");
    }
    return backupFile;
  }
}
