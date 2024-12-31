import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:DigiVasool/Data/Databasehelper.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

class RestorePage extends StatefulWidget {
  @override
  _RestorePageState createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  bool _isLoading = false;

  Future<void> restoreDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request storage permissions
      if (await Permission.storage.request().isGranted ||
          await Permission.manageExternalStorage.request().isGranted) {
        // Open file picker to select the database file
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any, // Allow all file types
        );

        if (result != null && result.files.single.path != null) {
          // Get the selected file
          File selectedFile = File(result.files.single.path!);

          // Validate the file extension
          if (selectedFile.path.endsWith('.db')) {
            // Proceed with restoring the database
            // Define the target database path

            //String dbPath = await DatabaseHelper.getDatabasePath();
            final dbPath = await sql.getDatabasesPath();
            final dbFullPath = path.join(dbPath, 'finance3.db');
            //dbPath = '${dbPath}finance3.db';

// Delete the existing file if it exists
            File dbFile = File(dbFullPath);
            if (await dbFile.exists()) {
              await dbFile.delete();
            }

// Copy the selected file to the app's database directory, overwriting the existing file
            await selectedFile.copy(dbFullPath);

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Success'),
                  content: const Text(
                      'Database restored successfully! Please restart the application.'),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Restart'),
                      onPressed: () {
                        exit(0); // Exit the application
                      },
                    ),
                  ],
                );
              },
            );
          } else {
            // Notify the user about the invalid file type
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Invalid file type. Please select a .db file.')),
            );
          }
        } else {
          // User canceled the picker
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected.')),
          );
        }
      } else {
        // Permissions not granted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permissions not granted.')),
        );
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring database: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Database'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'Hello User! Please choose the correct file and Restore .Kindly restart the application after restore. Thank you!\n\nFor any queries, contact sasiksr4@gmail.com',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        )),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: restoreDatabase,
                    child: const Text('Restore Database'),
                  ),
                ],
              ),
      ),
    );
  }
}
