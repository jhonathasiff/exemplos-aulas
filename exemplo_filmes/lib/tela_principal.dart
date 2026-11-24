import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final TextEditingController decadaCtrl = TextEditingController();
  List<Map<String, dynamic>> nomes = [];

  void obterNomes(String decada) async {
    final url = Uri.parse(
        "https://servicodados.ibge.gov.br/api/v2/censos/nomes/ranking/?decada=$decada");
    final response = await http.get(url);
    final jsonData = json.decode(response.body);

    List<Map<String, dynamic>> nomesRanking = [];

    if (jsonData.isNotEmpty && jsonData[0]["res"] != null) {
      for (var item in jsonData[0]["res"]) {
        nomesRanking.add({
          "nome": item["nome"],
          "frequencia": item["frequencia"],
          "ranking": item["ranking"],
        });
      }
    }

    setState(() {
      nomes = nomesRanking;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ranking de Nomes por Década"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: decadaCtrl,
                    decoration: const InputDecoration(
                      label: Text("Década"),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => obterNomes(decadaCtrl.text),
                  child: const Text("Buscar"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                  itemCount: nomes.length,
                  itemBuilder: (context, index) {
                    final item = nomes[index];
                    return ListTile(
                      leading: Text("#${item["ranking"]}"),
                      title: Text(item["nome"]),
                      subtitle: Text("Frequência: ${item["frequencia"]}"),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
