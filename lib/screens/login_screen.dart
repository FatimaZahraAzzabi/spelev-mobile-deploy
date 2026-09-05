import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import '../theme/app_theme.dart';
import '../services/auth_service.dart'; 
import 'forgot_password_screen.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authService = AuthService();
    final userData = await authService.login(email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (userData != null) {
      final String role = userData['type'] ?? 'INCONNU';
      
      final String token = userData['token'] ?? '';
      if (token.isNotEmpty) {
        await _storage.write(key: 'jwt_token', value: token);
        print("Token JWT sauvegardé avec succès !");
      }

      String targetRoute;
      switch (role) {
        case 'ADMINISTRATEUR':
          targetRoute = '/admin-dashboard';
          break;
        case 'TECHNICIEN':
          targetRoute = '/technicien-dashboard';
          break;
        case 'CLIENT':
          targetRoute = '/client-dashboard';
          break;
        case 'RESPONSABLE_MAINTENANCE':
          targetRoute = '/responsable-dashboard';
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rôle non reconnu ou accès non autorisé.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return; 
      }

      Navigator.of(context).pushNamedAndRemoveUntil(targetRoute, (route) => false);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email ou mot de passe incorrect'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),
                  _buildLogo(),
                  const SizedBox(height: 8),
                  const Text(
                    'ELEVATOR & INDUSTRY',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Connexion', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black87)),
                          const SizedBox(height: 4),
                          const Text('Accédez à votre espace de gestion', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          const SizedBox(height: 24),
                          const Text('Adresse email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'votre.email@exemple.com', 
                              prefixIcon: Icon(Icons.mail_outline, color: Colors.black54),
                            ),
                            validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                          ),
                          const SizedBox(height: 18),
                          const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black54),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 4) ? 'Mot de passe trop court' : null,
                          ),
                          
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: AppColors.orange, 
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12), // Espacement ajusté
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _seConnecter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                    )
                                  : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text('© SPELEV — Elevator & Industry', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Image.asset(
        'assets/images/logo.png', 
        height: 56,
        fit: BoxFit.contain,
      ),
    );
  }
}