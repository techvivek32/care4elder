import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import '../constants/api_constants.dart';

class FileDownloadService {
  static final Dio _dio = Dio();

  static Future<void> downloadAndOpenFile(BuildContext context, String url) async {
    final fullUrl = ApiConstants.resolveImageUrl(url);
    final fileName = fullUrl.split('/').last;
    
    try {
      // 1. Request Storage Permission
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Fallback for older Android versions
          await Permission.storage.request();
        }
      }

      // 2. Get Directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) throw Exception('Could not find directory');

      final savePath = '${directory.path}/$fileName';

      // 3. Show Loading Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text('Downloading $fileName...')),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // 4. Download File
      await _dio.download(
        fullUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Can update progress here if needed
          }
        },
      );

      // 5. Open File
      final result = await OpenFilex.open(savePath);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.type == ResultType.done 
                ? 'Downloaded to ${directory.path}' 
                : 'Download complete. Error opening: ${result.message}'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => OpenFilex.open(savePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download Error: $e')),
        );
      }
    }
  }
}
