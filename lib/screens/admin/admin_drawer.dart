import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../shared/ai_assistant_screen.dart'; 

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppColors.navy,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              color: AppColors.navy,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.business, size: 60, color: AppColors.navy);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SPELEV',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Espace Administrateur',
                    style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),

            // Menu
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(Icons.dashboard, 'Tableau de bord', '/admin-dashboard', context),
                  _buildMenuItem(Icons.people, 'Utilisateurs', '/admin-users', context),
                  _buildMenuItem(Icons.task, 'Gestion des Tâches', '/admin-taches', context),
                  _buildMenuItem(Icons.person, 'Mon Profil', '/profil', context),
                  
                  const Divider(color: Colors.white24, height: 1),

                  ListTile(
                    leading: const Icon(Icons.smart_toy, color: AppColors.orange),
                    title: const Text(
                      'Assistant IA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        '/ai-assistant',
                        arguments: {'role': 'admin'},
                      );
                    },
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.2), 
              child: TextButton.icon(
                onPressed: () async {
                  final storage = const FlutterSecureStorage();
                  await storage.delete(key: 'jwt_token');
                  await storage.delete(key: 'user_data'); 
                  
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String route, BuildContext context) {
    final isActive = route == currentRoute;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppColors.orange : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.orange : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? Colors.white.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}