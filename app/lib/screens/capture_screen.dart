import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
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
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
