import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Distritos extends StatefulWidget {
  const Distritos({super.key});

  @override
  State<Distritos> createState() => _DistritosState();
}

class _DistritosState extends State<Distritos> {
  List<String> distritos = [];

  Future<void> fetchDistricts() async {
    final url = Uri.parse(
      'https://servicodados.ibge.gov.br/api/v1/localidades/estados/RJ/distritos?orderBy=nome',
    );
    final response = await http.get(url);
    final jsonData = json.decode(response.body);

    List<String> nomesDistritos = [];
    for (var item in jsonData) {
      nomesDistritos.add(item['nome']);
    }

    setState(() {
      distritos = nomesDistritos;
    });
  }

  @override
  void initState() {
    fetchDistricts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Distritos')),
      body: ListView.builder(
        itemCount: distritos.length,
        itemBuilder: (context, index) {
          final nomeDistrito = distritos[index];
          return ListTile(title: Text(nomeDistrito));
        },
      ),
    );
  }
}
