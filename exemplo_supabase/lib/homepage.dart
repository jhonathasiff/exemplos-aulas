import 'package:flutter/material.dart';

import 'list_screen.dart';
import 'upload_screen.dart';

class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Storage')),
      body: Center(
        child: 
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadScreen()),
                );
            }, child: Text("Fazer Upload")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ListScreen()),
                );
            }, child: Text("Listar Arquivos")),
          ])
        ),
    );
  }
}