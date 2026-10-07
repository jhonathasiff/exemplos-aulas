import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'login_page.dart';
import 'app_theme.dart';

class FuncionariaPage extends StatefulWidget {
  final String nome;

  const FuncionariaPage({
    super.key,
    required this.nome,
  });

  @override
  State<FuncionariaPage> createState() =>
      _FuncionariaPageState();
}

class _FuncionariaPageState extends State<FuncionariaPage> {
  final FirestoreService firestoreService =
      FirestoreService();

  final AuthService authService = AuthService();

  final TextEditingController pacienteController =
      TextEditingController();

  String? medicoId;
  String? medicoNome;
  String? tipoAgendamento;

  DateTime dataHora = DateTime.now();

  Future<void> escolherData() async {
    DateTime? data = await showDatePicker(
      context: context,
      initialDate: dataHora,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.verdeEscuro,
                      secondary: AppColors.dourado,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (data == null) return;
    if (!mounted) return;

    TimeOfDay? hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        dataHora,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.verdeEscuro,
                      secondary: AppColors.dourado,
                    ),
          ),
          child: child!,
        );
      },
    );

    if (hora == null) return;

    setState(() {
      dataHora = DateTime(
        data.year,
        data.month,
        data.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> criarAgendamento() async {
    if (pacienteController.text.trim().isEmpty ||
        medicoId == null ||
        tipoAgendamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos.',
          ),
        ),
      );

      return;
    }

    await firestoreService.criarAgendamento(
      medicoId: medicoId!,
      medicoNome: medicoNome!,
      paciente: pacienteController.text.trim(),
      tipo: tipoAgendamento!,
      dataHora: dataHora,
      funcionarioNome: widget.nome,
    );

    if (!mounted) return;

    pacienteController.clear();
    setState(() {
      tipoAgendamento = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.dourado,
            ),
            SizedBox(width: 10),
            Text('Agendamento criado!'),
          ],
        ),
      ),
    );
  }

  Future<void> sair() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  String formatarDataHora() {
    return '${dataHora.day.toString().padLeft(2, '0')}/'
        '${dataHora.month.toString().padLeft(2, '0')}/'
        '${dataHora.year} às '
        '${dataHora.hour.toString().padLeft(2, '0')}:'
        '${dataHora.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.medical_services_outlined,
              color: AppColors.dourado,
            ),
            const SizedBox(width: 10),
            Text('Clínica Fácil • ${widget.nome}'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: sair,
            icon: const Icon(
              Icons.logout_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.verdeClaro,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.verdeEscuro,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novo agendamento',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Preencha os dados da consulta',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller:
                              pacienteController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Nome do paciente',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: tipoAgendamento,
                          decoration: const InputDecoration(
                            labelText: 'Tipo',
                            prefixIcon: Icon(
                              Icons.medical_services_outlined,
                            ),
                          ),
                          items: FirestoreService.tiposAgendamento
                              .map(
                                (tipo) => DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Text(
                                    tipo[0].toUpperCase() +
                                        tipo.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (valor) {
                            setState(() {
                              tipoAgendamento = valor;
                            });
                          },
                        ),

                        const SizedBox(height: 18),

                        StreamBuilder<QuerySnapshot>(
                          stream: firestoreService
                              .buscarMedicos(),
                          builder:
                              (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding:
                                    EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(),
                              );
                            }

                            List<
                                    DropdownMenuItem<
                                        String>>
                                itens = [];

                            for (var doc
                                in snapshot
                                    .data!.docs) {
                              Map<String, dynamic>
                                  dados =
                                  doc.data()
                                      as Map<String,
                                          dynamic>;

                              final nomeExibido =
                                  dados['especialidade'] != null
                                      ? '${dados['nome']} • ${dados['especialidade']}'
                                      : '${dados['nome']}';

                              itens.add(
                                DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    nomeExibido,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }

                            return DropdownButtonFormField<
                                String>(
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Médico',
                                prefixIcon: Icon(
                                  Icons
                                      .medical_information_outlined,
                                ),
                              ),
                              items: itens,
                              initialValue: medicoId,
                              onChanged: (valor) {
                                setState(() {
                                  medicoId = valor;

                                  var doc = snapshot
                                      .data!.docs
                                      .firstWhere(
                                    (element) =>
                                        element.id ==
                                        valor,
                                  );

                                  medicoNome =
                                      doc['nome'];
                                });
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        InkWell(
                          borderRadius:
                              BorderRadius.circular(14),
                          onTap: escolherData,
                          child: Container(
                            padding:
                                const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.verdeClaro,
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFFD4E0DB,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const ContainerIcone(
                                  icon: Icons
                                      .event_available_outlined,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      const Text(
                                        'Data e horário',
                                        style: TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: 4),
                                      Text(
                                        formatarDataHora(),
                                        style:
                                            const TextStyle(
                                          color: AppColors
                                              .verdeMedio,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons
                                      .edit_calendar_outlined,
                                  color:
                                      AppColors.dourado,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                criarAgendamento,
                            icon: const Icon(
                              Icons
                                  .add_circle_outline_rounded,
                            ),
                            label: const Text(
                              'Criar agendamento',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContainerIcone extends StatelessWidget {
  final IconData icon;

  const ContainerIcone({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: AppColors.verdeEscuro,
      ),
    );
  }
}
