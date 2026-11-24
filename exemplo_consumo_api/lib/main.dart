import 'package:flutter/material.dart';
import 'distritos.dart';
import 'nomes.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "IBGE",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _indice = 0;

  final List<Widget> _telas = const [Distritos(), Nomes()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantém o estado de cada tela ao alternar
      body: IndexedStack(index: _indice, children: _telas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Distritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search),
            label: 'Nomes',
          ),
        ],
      ),
    );
  }
}