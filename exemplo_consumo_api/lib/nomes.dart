import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class _FrequenciaDecada {
  /// Ano inicial da década. 0 = "antes de 1930".
  final int inicio;
  final int frequencia;

  const _FrequenciaDecada(this.inicio, this.frequencia);

  String get rotulo => _rotuloDecada(inicio);
}

String _rotuloDecada(int inicio) {
  if (inicio == 0) return 'Antes de 1930';
  return '$inicio–${inicio + 9}';
}

String _formatarNumero(int n) {
  return n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
}

class Nomes extends StatefulWidget {
  const Nomes({super.key});

  @override
  State<Nomes> createState() => _NomesState();
}

class _NomesState extends State<Nomes> {
  // Opções do seletor: null = todas, 0 = antes de 1930, demais = ano inicial
  static const List<int?> _opcoesDecada = [
    null,
    0,
    1930,
    1940,
    1950,
    1960,
    1970,
    1980,
    1990,
    2000,
  ];

  final TextEditingController _controller = TextEditingController();

  int? _decadaSelecionada;
  List<_FrequenciaDecada> _resultados = [];
  String _nomePesquisado = '';
  bool _carregando = false;
  bool _jaBuscou = false;
  String? _erro;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _extrairInicio(String periodo) {
    // Formatos retornados pela API: "1930[" (antes de 1930) e "[1930,1940["
    if (!periodo.startsWith('[')) return 0;
    final match = RegExp(r'\d{4}').firstMatch(periodo);
    return match == null ? 0 : int.parse(match.group(0)!);
  }

  Future<void> _buscar() async {
    final nome = _controller.text.trim();
    if (nome.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final url = Uri.parse(
        'https://servicodados.ibge.gov.br/api/v2/censos/nomes/${Uri.encodeComponent(nome)}',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Status ${response.statusCode}');
      }

      final jsonData = json.decode(response.body) as List<dynamic>;
      final lista = <_FrequenciaDecada>[];

      if (jsonData.isNotEmpty) {
        final res = jsonData.first['res'] as List<dynamic>;
        for (final item in res) {
          lista.add(
            _FrequenciaDecada(
              _extrairInicio(item['periodo'] as String),
              item['frequencia'] as int,
            ),
          );
        }
        lista.sort((a, b) => a.inicio.compareTo(b.inicio));
      }

      if (!mounted) return;
      setState(() {
        _resultados = lista;
        _nomePesquisado = nome;
        _jaBuscou = true;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível buscar os dados. Verifique sua conexão.';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Frequência de Nomes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                labelText: 'Digite um nome',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _buscar,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Década',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  isExpanded: true,
                  value: _decadaSelecionada,
                  items: _opcoesDecada.map((decada) {
                    return DropdownMenuItem<int?>(
                      value: decada,
                      child: Text(
                        decada == null
                            ? 'Todas as décadas'
                            : _rotuloDecada(decada),
                      ),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() => _decadaSelecionada = valor);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildConteudo()),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(child: Text(_erro!, textAlign: TextAlign.center));
    }

    if (!_jaBuscou) {
      return const Center(
        child: Text('Digite um nome e toque na lupa para pesquisar.'),
      );
    }

    if (_resultados.isEmpty) {
      return Center(
        child: Text('Nenhum resultado encontrado para "$_nomePesquisado".'),
      );
    }

    // Filtra pela década escolhida (null = todas)
    final filtrados = _decadaSelecionada == null
        ? _resultados
        : _resultados.where((r) => r.inicio == _decadaSelecionada).toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Text(
          'Sem dados de "$_nomePesquisado" em '
          '${_rotuloDecada(_decadaSelecionada!)}.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final maior = _resultados
        .map((r) => r.frequencia)
        .reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      itemCount: filtrados.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _nomePesquisado.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        final item = filtrados[index - 1];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.rotulo),
                    Text(
                      _formatarNumero(item.frequencia),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: maior == 0 ? 0 : item.frequencia / maior,
                  minHeight: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}