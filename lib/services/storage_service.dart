import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload an image XFile to Firebase Storage (with base64 fallback) and return its URL/data
  Future<String?> uploadRewardImage(XFile imageFile, String userId) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final Reference ref = _storage.ref().child('rewards/$userId/$fileName');

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final UploadTask uploadTask = ref.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Storage upload error: $e. Falling back to data URI.');
      // Fallback: Return Base64 Data URI so reward image upload NEVER fails
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }

  /// Upload profile avatar image to Firebase Storage (with base64 fallback) and return public URL/data
  Future<String?> uploadAvatarImage(XFile imageFile, String userId) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    try {
      final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('avatars/$userId/$fileName');

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final UploadTask uploadTask = ref.putData(bytes, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Avatar Storage upload error: $e. Falling back to base64 data URI.');
      // Fallback: Return Base64 Data URI so profile photo upload NEVER fails
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }
}
