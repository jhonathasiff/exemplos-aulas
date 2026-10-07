import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static const List<String> tiposAgendamento = [
    'exame',
    'consulta',
    'tratamento',
  ];

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> buscarUsuario(
    String uid,
  ) async {
    DocumentSnapshot doc =
        await _db.collection('usuarios').doc(uid).get();

    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }

    return null;
  }

  Stream<QuerySnapshot> buscarMedicos() {
    return _db
        .collection('usuarios')
        .where('tipo', isEqualTo: 'medico')
        .snapshots();
  }

  Future<void> criarAgendamento({
    required String medicoId,
    required String medicoNome,
    required String paciente,
    required String tipo,
    required DateTime dataHora,
    required String funcionarioNome,
  }) async {
    await _db
        .collection('usuarios')
        .doc(medicoId)
        .collection('agendamentos')
        .add({
      'paciente': paciente,
      'tipo': tipo,
      'medicoNome': medicoNome,
      'funcionarioNome': funcionarioNome,
      'dataHora': Timestamp.fromDate(dataHora),
      'status': 'agendado',
    });
  }

  Stream<QuerySnapshot> buscarAgendamentos(
    String medicoId,
    String status,
  ) {
    return _db
        .collection('usuarios')
        .doc(medicoId)
        .collection('agendamentos')
        .where(
          'status',
          isEqualTo: status,
        )
        .snapshots();
  }

  Future<void> mudarStatus({
    required String medicoId,
    required String agendamentoId,
    required String status,
  }) async {
    await _db
        .collection('usuarios')
        .doc(medicoId)
        .collection('agendamentos')
        .doc(agendamentoId)
        .update({
      'status': status,
    });
  }
}