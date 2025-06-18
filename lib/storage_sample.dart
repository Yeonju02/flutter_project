import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StorageApp());
}

class StorageApp extends StatelessWidget {
  const StorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StorageSample(),
    );
  }
}

class StorageSample extends StatefulWidget {
  @override
  State<StorageSample> createState() => _StorageSampleState();
}

class _StorageSampleState extends State<StorageSample> {
  File? _imageFile;
  String? _downloadUrl;

  final ImagePicker _picker = ImagePicker();

  // 이미지 선택 + 업로드
  Future<void> _handleUploadImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File image = File(picked.path);
    setState(() => _imageFile = image);

    String url = await uploadImageToFirebase(image);
    setState(() => _downloadUrl = url);
  }

  // Firebase Storage 업로드 함수
  Future<String> uploadImageToFirebase(File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref('uploads/$fileName.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 다운로드 URL로 이미지 표시 함수
  Widget buildImageFromUrl(String url) {
    return Image.network(
      url,
      width: 200,
      height: 200,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Storage 업로드, 표시 예제")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _handleUploadImage,
              child: const Text("이미지 업로드"),
            ),
            const SizedBox(height: 20),
            if (_downloadUrl != null) buildImageFromUrl(_downloadUrl!),
            if (_downloadUrl != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(_downloadUrl!),
              ),
          ],
        ),
      ),
    );
  }
}
