import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'login_page.dart';
import 'app_theme.dart';

class MedicoPage extends StatefulWidget {
  final String uid;
  final String nome;
  final String especialidade;

  const MedicoPage({
    super.key,
    required this.uid,
    required this.nome,
    this.especialidade = 'Especialidade não informada',
  });

  @override
  State<MedicoPage> createState() => _MedicoPageState();
}

class _MedicoPageState extends State<MedicoPage> {
  final FirestoreService firestoreService = FirestoreService();

  final AuthService authService = AuthService();

  String statusSelecionado = 'agendado';
  String tipoSelecionado = 'todos';
  bool modoCalendario = false;

  DateTime mesExibido = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime diaSelecionado = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  Future<void> sair() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  bool mesmoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool diaTemConsulta(DateTime dia, List<QueryDocumentSnapshot> documentos) {
    for (final doc in documentos) {
      final dados = doc.data() as Map<String, dynamic>;

      final timestamp = dados['dataHora'] as Timestamp;

      final data = timestamp.toDate();

      if (mesmoDia(data, dia)) {
        return true;
      }
    }

    return false;
  }

  List<QueryDocumentSnapshot> consultasDoDia(
    DateTime dia,
    List<QueryDocumentSnapshot> documentos,
  ) {
    final consultas = documentos.where((doc) {
      final dados = doc.data() as Map<String, dynamic>;

      final timestamp = dados['dataHora'] as Timestamp;

      final data = timestamp.toDate();

      return mesmoDia(data, dia);
    }).toList();

    consultas.sort((a, b) {
      final dadosA = a.data() as Map<String, dynamic>;

      final dadosB = b.data() as Map<String, dynamic>;

      final dataA = (dadosA['dataHora'] as Timestamp).toDate();

      final dataB = (dadosB['dataHora'] as Timestamp).toDate();

      return dataA.compareTo(dataB);
    });

    return consultas;
  }

  String tituloStatus() {
    switch (statusSelecionado) {
      case 'concluido':
        return 'Agendamentos concluídos';
      case 'cancelado':
        return 'Agendamentos cancelados';
      default:
        return 'Próximos agendamentos';
    }
  }

  IconData iconeStatus() {
    switch (statusSelecionado) {
      case 'concluido':
        return Icons.check_circle_outline_rounded;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule_rounded;
    }
  }

  Widget cardAgendamento(QueryDocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;

    final timestamp = dados['dataHora'] as Timestamp;

    final data = timestamp.toDate();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.verdeClaro,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.verdeEscuro,
              ),
            ),
            title: Text(
              dados['paciente'] ?? 'Paciente',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${data.day.toString().padLeft(2, '0')}/'
                '${data.month.toString().padLeft(2, '0')}/'
                '${data.year} • '
                '${data.hour.toString().padLeft(2, '0')}:'
                '${data.minute.toString().padLeft(2, '0')}\n'
                'Tipo: ${dados['tipo'] ?? 'Não informado'} • '
                'Agendado por: ${dados['funcionarioNome'] ?? '-'}',
              ),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              tooltip: 'Opções',
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'concluido',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded),
                      SizedBox(width: 10),
                      Text('Concluir'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'cancelado',
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined),
                      SizedBox(width: 10),
                      Text('Cancelar'),
                    ],
                  ),
                ),
              ],
              onSelected: (valor) {
                firestoreService.mudarStatus(
                  medicoId: widget.uid,
                  agendamentoId: doc.id,
                  status: valor,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget construirLista(List<QueryDocumentSnapshot> documentos) {
    if (documentos.isEmpty) {
      return const _EstadoVazio(
        icon: Icons.event_busy_outlined,
        titulo: 'Nenhum agendamento',
        subtitulo: 'Não existem agendamentos neste filtro.',
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: documentos.length,
          itemBuilder: (context, index) {
            return cardAgendamento(documentos[index]);
          },
        ),
      ),
    );
  }

  Widget construirCalendario(List<QueryDocumentSnapshot> documentos) {
    final primeiroDiaDoMes = DateTime(mesExibido.year, mesExibido.month, 1);

    final quantidadeDias = DateTime(
      mesExibido.year,
      mesExibido.month + 1,
      0,
    ).day;

    final espacosAntes = primeiroDiaDoMes.weekday % 7;

    final totalCelulas = ((espacosAntes + quantidadeDias + 6) ~/ 7) * 7;

    final consultasSelecionadas = consultasDoDia(diaSelecionado, documentos);

    const nomesMeses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calendário mais compacto.
        double larguraCalendario = constraints.maxWidth * 0.62;

        if (larguraCalendario > 590) {
          larguraCalendario = 590;
        }

        if (larguraCalendario < 300) {
          larguraCalendario = constraints.maxWidth - 24;
        }

        /*
         * IMPORTANTE:
         * O calendário e as consultas agora ficam dentro do MESMO
         * SingleChildScrollView.
         *
         * Isso elimina:
         * - overflow na parte inferior;
         * - lista de consultas espremida;
         * - consultas cortadas quando existem 2, 3, 4 ou mais.
         */
        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: larguraCalendario,
                        ),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Mês anterior',
                                      onPressed: () {
                                        setState(() {
                                          mesExibido = DateTime(
                                            mesExibido.year,
                                            mesExibido.month - 1,
                                          );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            nomesMeses[mesExibido.month - 1],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          Text(
                                            '${mesExibido.year}',
                                            style: const TextStyle(
                                              color: AppColors.dourado,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Próximo mês',
                                      onPressed: () {
                                        setState(() {
                                          mesExibido = DateTime(
                                            mesExibido.year,
                                            mesExibido.month + 1,
                                          );
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                const Row(
                                  children: [
                                    _CabecalhoDia('D'),
                                    _CabecalhoDia('S'),
                                    _CabecalhoDia('T'),
                                    _CabecalhoDia('Q'),
                                    _CabecalhoDia('Q'),
                                    _CabecalhoDia('S'),
                                    _CabecalhoDia('S'),
                                  ],
                                ),

                                const SizedBox(height: 5),

                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 5,
                                        crossAxisSpacing: 5,

                                        // Maior = células menos altas.
                                        childAspectRatio: 1.28,
                                      ),
                                  itemCount: totalCelulas,
                                  itemBuilder: (context, index) {
                                    final numeroDia = index - espacosAntes + 1;

                                    if (numeroDia < 1 ||
                                        numeroDia > quantidadeDias) {
                                      return const SizedBox.shrink();
                                    }

                                    final dia = DateTime(
                                      mesExibido.year,
                                      mesExibido.month,
                                      numeroDia,
                                    );

                                    final temConsulta = diaTemConsulta(
                                      dia,
                                      documentos,
                                    );

                                    final selecionado = mesmoDia(
                                      dia,
                                      diaSelecionado,
                                    );

                                    final hoje = mesmoDia(dia, DateTime.now());

                                    Color fundoDia = Colors.transparent;

                                    Color textoDia = AppColors.texto;

                                    if (temConsulta) {
                                      fundoDia = AppColors.douradoClaro;
                                    }

                                    if (selecionado) {
                                      fundoDia = AppColors.verdeEscuro;

                                      textoDia = AppColors.branco;
                                    }

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        setState(() {
                                          diaSelecionado = dia;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: fundoDia,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: hoje
                                                ? AppColors.dourado
                                                : const Color(0xFFE5ECE9),
                                            width: hoje ? 2 : 1,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Text(
                                                '$numeroDia',
                                                style: TextStyle(
                                                  color: textoDia,
                                                  fontWeight:
                                                      selecionado || temConsulta
                                                      ? FontWeight.w800
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            if (temConsulta && !selecionado)
                                              const Positioned(
                                                bottom: 4,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                  child: CircleAvatar(
                                                    radius: 2.5,
                                                    backgroundColor:
                                                        AppColors.verdeEscuro,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.verdeClaro,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            color: AppColors.verdeEscuro,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Consultas de '
                            '${diaSelecionado.day.toString().padLeft(2, '0')}/'
                            '${diaSelecionado.month.toString().padLeft(2, '0')}/'
                            '${diaSelecionado.year}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (consultasSelecionadas.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.douradoClaro,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${consultasSelecionadas.length}',
                              style: const TextStyle(
                                color: AppColors.verdeEscuro,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (consultasSelecionadas.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: _EstadoVazio(
                          icon: Icons.event_available_outlined,
                          titulo: 'Dia disponível',
                          subtitulo: 'Nenhuma consulta marcada para esta data.',
                        ),
                      )
                    else
                      ...consultasSelecionadas.map(
                        (doc) => cardAgendamento(doc),
                      ),

                    /*
                     * Espaço extra para impedir que o último card
                     * fique encostado ou cortado no fim da tela.
                     */
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              color: AppColors.dourado,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.nome, overflow: TextOverflow.ellipsis),
                  Text(
                    widget.especialidade,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.dourado,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: sair,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.branco,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.verdeClaro,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            iconeStatus(),
                            color: AppColors.verdeEscuro,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tituloStatus(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: statusSelecionado,
                            decoration: const InputDecoration(
                              labelText: 'Filtrar por status',
                              prefixIcon: Icon(Icons.filter_alt_outlined),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'agendado',
                                child: Text('Agendados'),
                              ),
                              DropdownMenuItem(
                                value: 'concluido',
                                child: Text('Concluídos'),
                              ),
                              DropdownMenuItem(
                                value: 'cancelado',
                                child: Text('Cancelados'),
                              ),
                            ],
                            onChanged: (valor) {
                              if (valor == null) {
                                return;
                              }

                              setState(() {
                                statusSelecionado = valor;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por tipo',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: 'todos',
                          child: Text('Todos os tipos'),
                        ),
                        ...FirestoreService.tiposAgendamento.map(
                          (tipo) => DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(
                              tipo[0].toUpperCase() + tipo.substring(1),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor == null) return;
                        setState(() {
                          tipoSelecionado = valor;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: !modoCalendario
                                  ? ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          modoCalendario = false;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.view_list_outlined,
                                      ),
                                      label: const Text('Lista'),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          modoCalendario = false;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.view_list_outlined,
                                      ),
                                      label: const Text('Lista'),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: modoCalendario
                                  ? ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          modoCalendario = true;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.calendar_month_outlined,
                                      ),
                                      label: const Text('Calendário'),
                                    )
                                  : OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          modoCalendario = true;
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.calendar_month_outlined,
                                      ),
                                      label: const Text('Calendário'),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.buscarAgendamentos(
                widget.uid,
                statusSelecionado,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _EstadoVazio(
                    icon: Icons.error_outline_rounded,
                    titulo: 'Erro ao carregar',
                    subtitulo: '${snapshot.error}',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.verdeEscuro,
                    ),
                  );
                }

                final documentos = snapshot.data!.docs.where((doc) {
                  if (tipoSelecionado == 'todos') return true;
                  final dados = doc.data() as Map<String, dynamic>;
                  return dados['tipo'] == tipoSelecionado;
                }).toList();

                if (modoCalendario) {
                  return construirCalendario(documentos);
                }

                return construirLista(documentos);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  final String texto;

  const _CabecalhoDia(this.texto);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.verdeMedio,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;

  const _EstadoVazio({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.verdeClaro,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 36, color: AppColors.verdeEscuro),
            ),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
