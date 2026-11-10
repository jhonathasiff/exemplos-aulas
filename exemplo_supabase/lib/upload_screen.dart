import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final supabase = Supabase.instance.client;
  String? uploadedUrl;

  Future<void> uploadFile() async {
    final result = await FilePicker.pickFiles();

    final file = result.first;
    final bucket = supabase.storage.from('arquivos');

    final path =
        'arquivos/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final bytes = await file.readAsBytes();
    await bucket.uploadBinary(path, bytes);

    final url = bucket.getPublicUrl(path);
    setState(() => uploadedUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload de Arquivo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: uploadFile,
              child: const Text('Selecionar e Enviar Arquivo'),
            ),
            const SizedBox(height: 20),
            if (uploadedUrl != null)
              uploadedUrl!.endsWith('.jpg') ||
              uploadedUrl!.endsWith('.jpeg') ||
              uploadedUrl!.endsWith('.png')
                    ? Image.network(uploadedUrl!, height: 200)
                    : Text('Arquivo enviado: $uploadedUrl'),
          ],
        ),
      ),
    );
  }
}