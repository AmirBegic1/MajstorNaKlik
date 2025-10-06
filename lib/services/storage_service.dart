import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload slike za job i vraća listu URL-ova
  Future<List<String>> uploadJobImages(String jobId, List<File> images) async {
    final List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final String fileName =
            'job_${jobId}_image_${i + 1}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
        final String filePath = 'jobs/$jobId/images/$fileName';

        final Reference storageRef = _storage.ref().child(filePath);

        // Metadata za optimizaciju
        final SettableMetadata metadata = SettableMetadata(
          contentType: _getContentType(file.path),
          customMetadata: {
            'jobId': jobId,
            'uploadedBy': 'user',
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );

        final UploadTask uploadTask = storageRef.putFile(file, metadata);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      print('Greška pri upload-u slika: $e');
      // Obriši uspješno uploaded slike ako je došlo do greške
      await _cleanupPartialUpload(uploadedUrls);
      throw Exception('Greška pri upload-u slika: $e');
    }
  }

  /// Upload profilne slike korisnika
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final String filePath = 'users/$userId/profile/$fileName';

      final Reference storageRef = _storage.ref().child(filePath);

      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(imageFile.path),
        customMetadata: {
          'userId': userId,
          'type': 'profile',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Greška pri upload-u profilne slike: $e');
      throw Exception('Greška pri upload-u profilne slike: $e');
    }
  }

  /// Obriši sliku iz Storage-a
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Greška pri brisanju slike: $e');
      return false;
    }
  }

  /// Obriši sve slike job-a
  Future<void> deleteJobImages(String jobId) async {
    try {
      final Reference jobImagesRef = _storage.ref().child(
        'jobs/$jobId/images/',
      );
      final ListResult result = await jobImagesRef.listAll();

      for (final Reference ref in result.items) {
        await ref.delete();
      }
    } catch (e) {
      print('Greška pri brisanju slika job-a: $e');
    }
  }

  /// Priprema cleanup za neuspješan upload
  Future<void> _cleanupPartialUpload(List<String> uploadedUrls) async {
    for (final String url in uploadedUrls) {
      try {
        await deleteImage(url);
      } catch (e) {
        print('Greška pri cleanup-u: $e');
      }
    }
  }

  /// Odredi content type na osnovu ekstenzije datoteke
  String _getContentType(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Kompresuj sliku prije upload-a (optional, za bolju performansu)
  Future<File> compressImage(File imageFile, {int quality = 80}) async {
    // Ova funkcija zahtijeva image compression library
    // Za sada vraćamo originalnu sliku
    return imageFile;
  }

  /// Get progress stream za upload task
  Stream<double> getUploadProgress(UploadTask task) {
    return task.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}
