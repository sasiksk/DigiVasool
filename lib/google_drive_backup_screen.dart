import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';

class GoogleDriveBackupScreen extends StatelessWidget {
  GoogleDriveBackupScreen({super.key});

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );

  final secureStorage = const FlutterSecureStorage();

  Future<GoogleSignInAccount?> _signIn(BuildContext context) async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during sign-in: $e')),
      );
      return null;
    }
  }

  Future<String?> _createFolder(
      String folderName, Map<String, String> headers) async {
    final response = await http.post(
      Uri.parse('https://www.googleapis.com/drive/v3/files'),
      headers: headers,
      body: jsonEncode({
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return responseBody['id'] as String?;
    } else {
      return null;
    }
  }

  Future<void> _backupDatabase(BuildContext context) async {
    try {
      final account = await _signIn(context);
      if (account == null) return;

      final headers = await account.authHeaders;
      headers['Content-Type'] = 'application/json';

      // Create a folder in Google Drive
      final folderId = await _createFolder('DigiVasool_Backups', headers);
      if (folderId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create folder')),
        );
        return;
      }

      // Get the database file path
      final directory = await getApplicationDocumentsDirectory();
      final dbPath =
          '${directory.path}/your_database_file.db'; // Replace with your actual database file name
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database file not found!')),
        );
        return;
      }

      // Zip the database file
      final zipFilePath = '${dbFile.parent.path}/database.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      encoder.addFile(dbFile);
      encoder.close();

      final zipFile = File(zipFilePath);

      // Upload the zip file to Google Drive
      final uploadRequest = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        ),
      );

      uploadRequest.headers.addAll(headers);
      uploadRequest.fields['name'] = zipFile.uri.pathSegments.last;
      uploadRequest.fields['parents'] = jsonEncode([folderId]);

      uploadRequest.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await zipFile.readAsBytes(),
          filename: zipFile.uri.pathSegments.last,
        ),
      );

      final response = await uploadRequest.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup uploaded successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload backup')),
        );
      }

      // Delete the temporary zip file
      await zipFile.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during backup: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Drive Backup')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _backupDatabase(context),
          child: const Text('Backup Database to Google Drive'),
        ),
      ),
    );
  }
}
