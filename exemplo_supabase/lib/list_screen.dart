import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final supabase = Supabase.instance.client;
  late final bucket = supabase.storage.from('arquivos');
  List<FileObject> arquivos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    listarArquivos();
  }

  Future<void> listarArquivos() async {
    final result = await bucket.list(path: 'arquivos');
    setState(() {
      arquivos = result;
      loading = false;
    });
  }

  Future<void> excluirArquivo(String nome) async {
    await bucket.remove(['arquivos/$nome']);
    listarArquivos();
  }

  bool ehImagem(String nome) {
    final ext = nome.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Arquivos no Bucket')),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: arquivos.length,
                itemBuilder: (context, index) {
                  final arquivo = arquivos[index];
                  final url = bucket.getPublicUrl('arquivos/${arquivo.name}');

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(arquivo.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ehImagem(arquivo.name))
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.network(url,
                                  height: 150, fit: BoxFit.cover),
                            )
                          else
                            Text('URL: $url'),
                          TextButton.icon(
                            onPressed: () => excluirArquivo(arquivo.name),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Excluir',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      );
}