import 'contato.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  FirebaseFirestore db = FirebaseFirestore.instance;

  void inicializar() {
    db = FirebaseFirestore.instance;
  }

  Future incluir(Contato c) async {
    final contato = <String, dynamic>{
      "nome": c.nome,
      "email": c.email,
      "telefone": c.telefone,
    };
    await db.collection("contatos").add(contato);
  }

  Future editar(String id, Contato c) async {
    final contato = <String, dynamic>{
      "nome": c.nome,
      "email": c.email,
      "telefone": c.telefone,
    };
    await db.collection("contatos").doc(id).update(contato);
  }

  Future excluir(String id) async {
    await db.collection("contatos").doc(id).delete();
  }

  Future<List> listar() async {
    QuerySnapshot querySnapshot;
    List docs = [];
    querySnapshot = await db.collection('contatos').orderBy("nome").get();
    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs.toList()) {
        Map a = {
          "id": doc.id,
          "nome": doc['nome'],
          "email": doc["email"],
          "telefone": doc["telefone"],
        };
        docs.add(a);
      }
    }
    return docs;
  }
}
