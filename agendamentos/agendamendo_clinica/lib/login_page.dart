import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'auth_service.dart';
import 'cadastro_medico_page.dart';
import 'firestore_service.dart';
import 'funcionaria_page.dart';
import 'medico_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController senhaController =
      TextEditingController();

  final AuthService authService = AuthService();
  final FirestoreService firestoreService =
      FirestoreService();

  bool loginMedico = false;
  bool lembrarEmail = false;
  bool carregando = false;
  bool ocultarSenha = true;

  @override
  void initState() {
    super.initState();
    carregarEmailSalvo();
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  String get chaveEmail =>
      loginMedico ? 'email_medico' : 'email_funcionaria';

  Future<void> carregarEmailSalvo() async {
    final prefs =
        await SharedPreferences.getInstance();

    // Mantém compatibilidade com o e-mail salvo pela versão antiga.
    final email =
        prefs.getString(chaveEmail) ??
        prefs.getString('email');

    if (!mounted) return;

    setState(() {
      emailController.text = email ?? '';
      lembrarEmail = email != null &&
          email.isNotEmpty;
    });
  }

  Future<void> trocarPerfil(bool medico) async {
    if (carregando || loginMedico == medico) {
      return;
    }

    setState(() {
      loginMedico = medico;
      senhaController.clear();
      ocultarSenha = true;
      emailController.clear();
      lembrarEmail = false;
    });

    await carregarEmailSalvo();
  }

  Future<void> fazerLogin() async {
    final email =
        emailController.text.trim();

    final senha =
        senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Preencha e-mail e senha.',
          ),
        ),
      );
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final usuario =
          await authService.login(
        email,
        senha,
      );

      if (usuario == null) {
        return;
      }

      final dadosUsuario =
          await firestoreService.buscarUsuario(
        usuario.uid,
      );

      if (dadosUsuario == null) {
        await authService.logout();

        throw Exception(
          'Usuário não encontrado no Firestore.',
        );
      }

      final tipo =
          '${dadosUsuario['tipo'] ?? ''}'
              .toLowerCase()
              .trim();

      final contaEhMedico =
          tipo == 'medico';

      /*
       * Impede que um médico entre pelo botão Funcionária
       * ou que uma funcionária entre pelo botão Médico.
       */
      if (loginMedico != contaEhMedico) {
        await authService.logout();

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              loginMedico
                  ? 'Esta conta não é de médico. Selecione "Funcionária".'
                  : 'Esta conta é de médico. Selecione "Médico".',
            ),
          ),
        );

        return;
      }

      final prefs =
          await SharedPreferences.getInstance();

      if (lembrarEmail) {
        await prefs.setString(
          chaveEmail,
          email,
        );
      } else {
        await prefs.remove(
          chaveEmail,
        );
      }

      // Remove a chave antiga após a migração.
      await prefs.remove('email');

      final nome =
          '${dadosUsuario['nome'] ?? 'Usuário'}';

      final especialidade =
          '${dadosUsuario['especialidade'] ?? 'Especialidade não informada'}';

      if (!mounted) return;

      if (contaEhMedico) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MedicoPage(
              uid: usuario.uid,
              nome: nome,
              especialidade:
                  especialidade,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FuncionariaPage(
              nome: nome,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Erro ao fazer login: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> abrirCadastroMedico() async {
    if (carregando) return;

    final resultado =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CadastroMedicoPage(),
      ),
    );

    if (!mounted ||
        resultado == null ||
        resultado.isEmpty) {
      return;
    }

    setState(() {
      emailController.text = resultado;
      senhaController.clear();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Cadastro concluído. Agora faça login com a conta do médico.',
        ),
      ),
    );
  }

  Widget botaoPerfil({
    required bool medico,
    required IconData icon,
    required String texto,
  }) {
    final selecionado =
        loginMedico == medico;

    return Expanded(
      child: SizedBox(
        height: 48,
        child: selecionado
            ? ElevatedButton.icon(
                onPressed: carregando
                    ? null
                    : () =>
                        trocarPerfil(medico),
                icon: Icon(icon),
                label: Text(texto),
                style:
                    ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: carregando
                    ? null
                    : () =>
                        trocarPerfil(medico),
                icon: Icon(icon),
                label: Text(texto),
                style:
                    OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  backgroundColor:
                      AppColors.branco,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                minWidth: 280,
                maxWidth: 470,
              ),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .verdeEscuro,
                            borderRadius:
                                BorderRadius
                                    .circular(22),
                          ),
                          child: const Icon(
                            Icons
                                .local_hospital_rounded,
                            color: AppColors
                                .dourado,
                            size: 42,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        'Clínica Fácil',
                        textAlign:
                            TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall,
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        loginMedico
                            ? 'Acesso do médico'
                            : 'Acesso da funcionária',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors
                              .grey.shade600,
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      /*
                       * Botões comuns com altura fixa no lugar de
                       * controles mais complexos. Isso evita widgets
                       * interativos sem dimensão válida no Flutter Web.
                       */
                      Row(
                        children: [
                          botaoPerfil(
                            medico: false,
                            icon: Icons
                                .badge_outlined,
                            texto:
                                'Funcionária',
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          botaoPerfil(
                            medico: true,
                            icon: Icons
                                .medical_services_outlined,
                            texto: 'Médico',
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      TextField(
                        controller:
                            emailController,
                        enabled: !carregando,
                        keyboardType:
                            TextInputType
                                .emailAddress,
                        decoration:
                            InputDecoration(
                          labelText:
                              loginMedico
                                  ? 'E-mail do médico'
                                  : 'E-mail da funcionária',
                          prefixIcon:
                              const Icon(
                            Icons
                                .email_outlined,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      TextField(
                        controller:
                            senhaController,
                        enabled: !carregando,
                        obscureText:
                            ocultarSenha,
                        onSubmitted: (_) {
                          if (!carregando) {
                            fazerLogin();
                          }
                        },
                        decoration:
                            InputDecoration(
                          labelText: 'Senha',
                          prefixIcon:
                              const Icon(
                            Icons
                                .lock_outline_rounded,
                          ),
                          suffixIcon:
                              IconButton(
                            tooltip: ocultarSenha
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed:
                                carregando
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            ocultarSenha =
                                                !ocultarSenha;
                                          },
                                        );
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

                      const SizedBox(
                        height: 4,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            CheckboxListTile(
                          contentPadding:
                              EdgeInsets.zero,
                          dense: true,
                          value:
                              lembrarEmail,
                          activeColor:
                              AppColors
                                  .verdeEscuro,
                          checkColor:
                              AppColors.branco,
                          controlAffinity:
                              ListTileControlAffinity
                                  .leading,
                          title: const Text(
                            'Lembrar meu e-mail',
                          ),
                          onChanged: carregando
                              ? null
                              : (valor) {
                                  setState(
                                    () {
                                      lembrarEmail =
                                          valor ??
                                              false;
                                    },
                                  );
                                },
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        height: 50,
                        child:
                            ElevatedButton.icon(
                          onPressed: carregando
                              ? null
                              : fazerLogin,
                          icon: carregando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        AppColors
                                            .branco,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .login_rounded,
                                ),
                          label: Text(
                            carregando
                                ? 'Entrando...'
                                : loginMedico
                                    ? 'Entrar como médico'
                                    : 'Entrar como funcionária',
                          ),
                        ),
                      ),

                      /*
                       * Cadastro existe APENAS no login de médico.
                       */
                      if (loginMedico) ...[
                        const SizedBox(
                          height: 14,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          height: 48,
                          child:
                              OutlinedButton.icon(
                            onPressed:
                                carregando
                                    ? null
                                    : abrirCadastroMedico,
                            icon: const Icon(
                              Icons
                                  .person_add_alt_1_rounded,
                            ),
                            label: const Text(
                              'Cadastrar novo médico',
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 20,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors
                                  .grey.shade300,
                            ),
                          ),
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Icon(
                              Icons
                                  .health_and_safety_outlined,
                              size: 20,
                              color: AppColors
                                  .dourado,
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors
                                  .grey.shade300,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      const Text(
                        'Sistema de gerenciamento da clínica',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
