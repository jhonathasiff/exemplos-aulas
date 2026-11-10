import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'homepage.dart'; 
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://utbdvlwesxykoalnfgci.supabase.co',
    publishableKey: 'sb_publishable_4M73dTgoqq_oqaQt8vnANw_l9XSfCj0',
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUpabase Storage App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}