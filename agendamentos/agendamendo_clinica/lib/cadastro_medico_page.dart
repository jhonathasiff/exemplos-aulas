import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'firebase_options.dart';

class CadastroMedicoPage extends StatefulWidget {
  const CadastroMedicoPage({
    super.key,
  });

  @override
  State<CadastroMedicoPage> createState() =>
      _CadastroMedicoPageState();
}

class _CadastroMedicoPageState
    extends State<CadastroMedicoPage> {
  final TextEditingController nomeController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final TextEditingController confirmarSenhaController =
      TextEditingController();

  final List<String> especialidades = const [
    'Fisioterapeuta',
    'Pediatra',
    'Cardiologista',
  ];

  String? especialidadeSelecionada;

  bool carregando = false;
  bool ocultarSenha = true;
  bool ocultarConfirmacao = true;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  String mensagemErroFirebase(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Já existe uma conta cadastrada com este e-mail.';
      case 'invalid-email':
        return 'O e-mail informado é inválido.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'operation-not-allowed':
        return 'O cadastro por e-mail e senha não está habilitado no Firebase.';
      default:
        return 'Não foi possível cadastrar o médico: ${e.message ?? e.code}';
    }
  }

  Future<void> cadastrarMedico() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final confirmarSenha =
        confirmarSenhaController.text;

    if (nome.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty ||
        especialidadeSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha todos os campos.',
          ),
        ),
      );
      return;
    }

    if (!email.contains('@') ||
        !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Digite um e-mail válido.',
          ),
        ),
      );
      return;
    }

    if (senha.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A senha precisa ter pelo menos 6 caracteres.',
          ),
        ),
      );
      return;
    }

    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'As senhas não coincidem.',
          ),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    FirebaseApp? appSecundario;
    UserCredential? credencial;

    try {
      /*
       * Usamos uma instância secundária do Firebase Authentication.
       *
       * Isso é importante porque createUserWithEmailAndPassword()
       * normalmente troca o usuário logado para a nova conta criada.
       *
       * Com o app secundário, o cadastro não altera a sessão principal
       * do aplicativo. Isso funciona tanto vindo da tela de login quanto
       * se futuramente o cadastro for aberto por uma área administrativa.
       */
      appSecundario = await Firebase.initializeApp(
        name:
            'cadastro_medico_${DateTime.now().microsecondsSinceEpoch}',
        options:
            DefaultFirebaseOptions.currentPlatform,
      );

      final authSecundario =
          FirebaseAuth.instanceFor(
        app: appSecundario,
      );

      credencial =
          await authSecundario
              .createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final uid = credencial.user!.uid;

      try {
        final firestoreSecundario =
            FirebaseFirestore.instanceFor(
          app: appSecundario,
        );

        await firestoreSecundario
            .collection('usuarios')
            .doc(uid)
            .set({
          'nome': nome,
          'email': email,
          'tipo': 'medico',
          'especialidade':
              especialidadeSelecionada,
          'criadoEm':
              FieldValue.serverTimestamp(),
        });
      } catch (e) {
        /*
         * Se a gravação no Firestore falhar,
         * removemos a conta do Authentication
         * para não deixar um usuário incompleto.
         */
        try {
          await credencial.user?.delete();
        } catch (_) {}

        rethrow;
      }

      try {
        await authSecundario.signOut();
      } catch (_) {}

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.dourado,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$nome foi cadastrado como $especialidadeSelecionada.',
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.pop(context, email);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensagemErroFirebase(e),
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro no Firebase: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao cadastrar médico: $e',
          ),
        ),
      );
    } finally {
      if (appSecundario != null) {
        try {
          await appSecundario.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.dourado,
            ),
            SizedBox(width: 10),
            Text(
              'Cadastrar médico',
            ),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color:
                            AppColors.verdeClaro,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .medical_services_outlined,
                        size: 30,
                        color:
                            AppColors.verdeEscuro,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novo médico',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Crie a conta e defina a especialidade.',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade600,
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
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        TextField(
                          controller:
                              nomeController,
                          textCapitalization:
                              TextCapitalization.words,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Nome do médico',
                            prefixIcon: Icon(
                              Icons
                                  .person_outline_rounded,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller:
                              emailController,
                          keyboardType:
                              TextInputType
                                  .emailAddress,
                          decoration:
                              const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(
                              Icons
                                  .email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<
                            String>(
                          isExpanded: true,
                          initialValue:
                              especialidadeSelecionada,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Especialidade',
                            prefixIcon: Icon(
                              Icons
                                  .health_and_safety_outlined,
                            ),
                          ),
                          items: especialidades
                              .map(
                                (especialidade) =>
                                    DropdownMenuItem<
                                        String>(
                                  value:
                                      especialidade,
                                  child: Text(
                                    especialidade,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (valor) {
                            setState(() {
                              especialidadeSelecionada =
                                  valor;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller:
                              senhaController,
                          obscureText:
                              ocultarSenha,
                          decoration:
                              InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(
                              Icons
                                  .lock_outline_rounded,
                            ),
                            suffixIcon:
                                IconButton(
                              tooltip: ocultarSenha
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              onPressed: () {
                                setState(() {
                                  ocultarSenha =
                                      !ocultarSenha;
                                });
                              },
                              icon: Icon(
                                ocultarSenha
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller:
                              confirmarSenhaController,
                          obscureText:
                              ocultarConfirmacao,
                          onSubmitted: (_) {
                            if (!carregando) {
                              cadastrarMedico();
                            }
                          },
                          decoration:
                              InputDecoration(
                            labelText:
                                'Confirmar senha',
                            prefixIcon: const Icon(
                              Icons
                                  .lock_reset_outlined,
                            ),
                            suffixIcon:
                                IconButton(
                              tooltip:
                                  ocultarConfirmacao
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                              onPressed: () {
                                setState(() {
                                  ocultarConfirmacao =
                                      !ocultarConfirmacao;
                                });
                              },
                              icon: Icon(
                                ocultarConfirmacao
                                    ? Icons
                                        .visibility_outlined
                                    : Icons
                                        .visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child:
                              ElevatedButton.icon(
                            onPressed: carregando
                                ? null
                                : cadastrarMedico,
                            icon: carregando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          AppColors
                                              .branco,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .person_add_alt_1_rounded,
                                  ),
                            label: Text(
                              carregando
                                  ? 'Cadastrando...'
                                  : 'Cadastrar médico',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.verdeClaro,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color:
                            AppColors.verdeEscuro,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'O médico poderá entrar normalmente usando o e-mail e a senha cadastrados.',
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
    );
  }
}
