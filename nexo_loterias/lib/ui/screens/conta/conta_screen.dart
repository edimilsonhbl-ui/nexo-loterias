import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ContaScreen extends StatefulWidget {
  const ContaScreen({super.key});

  @override
  State<ContaScreen> createState() => _ContaScreenState();
}

class _ContaScreenState extends State<ContaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.entrar(email: _emailCtrl.text, senha: _senhaCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.cadastrar(email: _emailCtrl.text, senha: _senhaCtrl.text);
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _redefinirSenha() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite seu e-mail para redefinir a senha.')),
      );
      return;
    }
    await context.read<AuthProvider>().redefinirSenha(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de redefinição enviado!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final primary = Theme.of(context).colorScheme.primary;

    if (auth.estaLogado) {
      return _TelaLogado(
        usuario: auth.usuario!.email ?? 'Usuário',
        onSair: () async {
          await auth.sair();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/conta');
          }
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Conta')),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
            tabs: const [Tab(text: 'Entrar'), Tab(text: 'Cadastrar')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FormularioAuth(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  senhaCtrl: _senhaCtrl,
                  senhaVisivel: _senhaVisivel,
                  onToggleSenha: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  onSubmit: _entrar,
                  labelBotao: 'Entrar',
                  onRedefinir: _redefinirSenha,
                  carregando: auth.status == AuthStatus.carregando,
                  erro: auth.mensagemErro,
                  onLimparErro: auth.limparErro,
                ),
                _FormularioAuth(
                  formKey: _formKey,
                  emailCtrl: _emailCtrl,
                  senhaCtrl: _senhaCtrl,
                  senhaVisivel: _senhaVisivel,
                  onToggleSenha: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  onSubmit: _cadastrar,
                  labelBotao: 'Criar conta',
                  carregando: auth.status == AuthStatus.carregando,
                  erro: auth.mensagemErro,
                  onLimparErro: auth.limparErro,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioAuth extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController senhaCtrl;
  final bool senhaVisivel;
  final VoidCallback onToggleSenha;
  final VoidCallback onSubmit;
  final String labelBotao;
  final VoidCallback? onRedefinir;
  final bool carregando;
  final String erro;
  final VoidCallback onLimparErro;

  const _FormularioAuth({
    required this.formKey,
    required this.emailCtrl,
    required this.senhaCtrl,
    required this.senhaVisivel,
    required this.onToggleSenha,
    required this.onSubmit,
    required this.labelBotao,
    this.onRedefinir,
    required this.carregando,
    required this.erro,
    required this.onLimparErro,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
              onChanged: (_) { if (erro.isNotEmpty) onLimparErro(); },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: senhaCtrl,
              obscureText: !senhaVisivel,
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(senhaVisivel ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggleSenha,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a senha';
                if (v.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
              onChanged: (_) { if (erro.isNotEmpty) onLimparErro(); },
            ),
            if (erro.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Text(erro,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: carregando ? null : onSubmit,
                child: carregando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(labelBotao),
              ),
            ),
            if (onRedefinir != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRedefinir,
                child: const Text('Esqueci minha senha'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TelaLogado extends StatelessWidget {
  final String usuario;
  final VoidCallback onSair;

  const _TelaLogado({required this.usuario, required this.onSair});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Conta')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 48,
              backgroundColor: primary.withAlpha(30),
              child: Icon(Icons.person_rounded, size: 52, color: primary),
            ),
            const SizedBox(height: 16),
            Text(usuario,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Conta ativa',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
