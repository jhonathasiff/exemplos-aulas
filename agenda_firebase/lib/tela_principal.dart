import 'package:flutter/material.dart';
import 'database.dart';
import 'formulario.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  late Database db;
  List docs = [];

  void atualizarLista() {
    db = Database();
    db.inicializar();
    db.listar().then(
      (value) => {
        setState(() {
          docs = value;
        }),
      },
    );
  }

  @override
  void initState() {
    super.initState();
    atualizarLista();
  }

  void _abrirFormulario(Map contatoSelec) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Formulario(contatoSelecionado: contatoSelec),
      ),
    ).then((_) {
      setState(() {
        atualizarLista();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Agenda Firebase Flutter")),
      body: ListView.builder(
        itemCount: docs.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              contentPadding: const EdgeInsets.only(right: 30, left: 36),
              title: Text(docs[index]['nome']),
              trailing: Text(docs[index]['email']),
              subtitle: Text(docs[index]['telefone']),
              onTap: () {
                Map<String, String> contato() => {
                  "id": docs[index]['id'],
                  "nome": docs[index]['nome'],
                  "email": docs[index]['email'],
                  "telefone": docs[index]['telefone'],
                };
                _abrirFormulario(contato());
              },
              onLongPress: () {
                db.excluir(docs[index]['id']);
                setState(() {
                  atualizarLista();
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Map<String, String> mapNulo() => {
            "nome": "",
            "email": "",
            "telefone": "",
          };
          _abrirFormulario(mapNulo());
        },
        tooltip: 'Novo Contato',
        child: const Icon(Icons.add),
      ),
    );
  }
}
