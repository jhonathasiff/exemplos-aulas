import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'auth_service.dart';
import 'firebase_options.dart';
import 'firestore_service.dart';
import 'funcionaria_page.dart';
import 'login_page.dart';
import 'medico_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clínica Fácil',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<User?> _usuarioInicial;

  @override
  void initState() {
    super.initState();
    _usuarioInicial = FirebaseAuth.instance.authStateChanges().first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _usuarioInicial,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final usuario = snapshot.data;
        if (usuario == null) {
          return const LoginPage();
        }

        return _AuthenticatedHome(key: ValueKey(usuario.uid), usuario: usuario);
      },
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome({required this.usuario, super.key});

  final User usuario;

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late Future<Map<String, dynamic>?> _dadosUsuario;

  @override
  void initState() {
    super.initState();
    _dadosUsuario = _firestoreService.buscarUsuario(widget.usuario.uid);
  }

  Future<void> _voltarParaLogin() async {
    try {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sair da conta: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _dadosUsuario,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          final mensagem = snapshot.hasError
              ? 'Não foi possível carregar seu perfil: ${snapshot.error}'
              : 'Não encontramos o perfil desta conta no Firestore.';

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mensagem, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _voltarParaLogin,
                      child: const Text('Voltar ao login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final dados = snapshot.data!;
        final tipo = '${dados['tipo'] ?? ''}'.toLowerCase().trim();
        final nome = '${dados['nome'] ?? 'Usuário'}';

        if (tipo == 'medico') {
          return MedicoPage(
            uid: widget.usuario.uid,
            nome: nome,
            especialidade:
                '${dados['especialidade'] ?? 'Especialidade não informada'}',
          );
        }

        return FuncionariaPage(nome: nome);
      },
    );
  }
}
