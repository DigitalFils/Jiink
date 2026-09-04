import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a captured photo and returns its public download URL. Stored
  /// under the seller's own uid so Storage rules can allow only them to
  /// write there.
  Future<String> uploadListingPhoto({
    required String uid,
    required File file,
  }) async {
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref('listingPhotos/$uid/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
