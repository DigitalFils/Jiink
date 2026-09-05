import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';
import 'publish_screen.dart';

/// Entry point for the core "snap it" loop: opens the camera immediately,
/// then hands the photo straight to the publish screen. No gallery picker,
/// no multi-step wizard — that friction is what S8LL is built to avoid.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    final picker = ImagePicker();
    XFile? photo;
    try {
      // maxWidth resizes the image itself — imageQuality alone only
      // re-compresses it at full camera resolution (often 3000px+ wide,
      // several MB), which is what was making publishing slow: the upload
      // had to move that whole file before Storage would return a URL.
      photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      photo = null;
    }

    if (!mounted) return;

    if (photo == null) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PublishScreen(photoPath: photo!.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: S8llColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: S8llColors.lime),
            SizedBox(height: 16),
            Text('Opening camera…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
