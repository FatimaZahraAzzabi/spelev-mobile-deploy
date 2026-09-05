import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class TechnicienDrawer extends StatelessWidget {
  final String currentRoute;

  const TechnicienDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navy,
      child: Column(
        children: [
          // Header avec logo
          Container(
            padding: const EdgeInsets.all(24),
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
                      return const Icon(Icons.build, size: 60, color: AppColors.navy);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SPELEV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Espace Technicien',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white24, height: 1),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  Icons.dashboard,
                  'Tableau de bord',
                  '/technicien-dashboard',
                  context,
                ),
                _buildMenuItem(
                  Icons.build,
                  'Mes tâches',
                  '/technicien-taches',
                  context,
                ),
                _buildMenuItem(
                  Icons.assignment_turned_in,
                  'Mes Interventions',
                  '/technicien-interventions',
                  context,
                ),
                _buildMenuItem(
                  Icons.calendar_today,
                  'Calendrier',
                  '/technicien-calendrier',
                  context,
                ),
                _buildMenuItem(Icons.person, 'Mon Profil',  '/profil', context),

              ],
            ),
          ),

          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2), // Léger fond pour le détacher du reste
                border: Border(top: BorderSide(color: Colors.white24, width: 1)),
              ),
              child: TextButton.icon(
                onPressed: () async {
                  final storage = const FlutterSecureStorage();
                  await storage.delete(key: 'jwt_token');
                  await storage.delete(key: 'user_data');
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                label: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ],
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
      tileColor: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route).catchError((_) {});
      },
    );
  }
}