import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'Data/Databasehelper.dart';

class FirebaseBackupScreen extends StatelessWidget {
  const FirebaseBackupScreen({super.key});

  Future<void> uploadDBToFirebase(BuildContext context) async {
    try {
      // Get the database file path
      final db = await DatabaseHelper.getDatabase();
      final dbPath = db.path;
      final dbFile = File(dbPath);

      // Check if the database file exists
      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database file not found!')),
        );
        return;
      }

      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Firebase Storage reference
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('backups/${DateTime.now().toIso8601String()}_db.sqlite');

      // Upload the file
      final uploadTask = storageRef.putFile(dbFile);

      // Monitor the upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print(
            'Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      // Wait for the upload to complete
      await uploadTask;

      // Get the download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Close the loading dialog
      Navigator.of(context).pop();

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup uploaded successfully! URL: $downloadUrl'),
        ),
      );

      print('Download URL: $downloadUrl');
    } catch (e) {
      Navigator.of(context).pop(); // Close the loading dialog
      debugPrint('Error uploading to Firebase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading to Firebase: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup to Firebase')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Click "OK" to back up your database file to Firebase Storage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => uploadDBToFirebase(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
