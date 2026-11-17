import 'package:flutter/material.dart';
import 'distritos.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Distritos IBGE",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Distritos(),
    );
  }
}