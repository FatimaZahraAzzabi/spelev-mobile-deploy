import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../shared/ai_assistant_screen.dart'; 

class ResponsableDrawer extends StatefulWidget {
  final String currentRoute;

  const ResponsableDrawer({super.key, required this.currentRoute});

  @override
  State<ResponsableDrawer> createState() => _ResponsableDrawerState();
}

class _ResponsableDrawerState extends State<ResponsableDrawer> {
  bool _isDemandesExpanded = false;

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
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.build, size: 60, color: AppColors.navy),
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
                  'Espace Responsable',
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
                _buildMenuItem(Icons.dashboard, 'Tableau de bord', '/responsable-dashboard', context),
                
                // Menu Demandes avec sous-menu expansible
                _buildExpandableMenuItem(
                  Icons.report_problem_outlined,
                  'Demandes',
                  () {
                    setState(() {
                      _isDemandesExpanded = !_isDemandesExpanded;
                    });
                  },
                  _isDemandesExpanded,
                  [
                     _buildSubMenuItem('Maintenance', '/responsable-demandes-attente', context),
                     _buildSubMenuItem('Nouvelles installations', '/responsable-demandes-installations', context), 
                     _buildSubMenuItem('Rapports à valider', '/responsable-demandes-rapports', context),
                  ],
                ),
                
                _buildMenuItem(Icons.assignment, 'Bons de travail', '/responsable-bons-travail', context),
                _buildMenuItem(Icons.elevator, 'Ascenseurs', '/responsable-ascenseur-list', context),
                _buildMenuItem(Icons.business, 'Sites', '/responsable-site-list', context),
                _buildMenuItem(Icons.location_city, 'Parcs', '/responsable-parc-list', context),
                _buildMenuItem(Icons.calendar_today, 'Calendrier', '/responsable-calendrier', context),
                _buildMenuItem(Icons.task, 'Mes tâches', '/responsable-mes-taches', context),
                _buildMenuItem(Icons.person, 'Mon Profil',  '/profil', context),

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
                      arguments: {'role': 'responsable'},
                    );
                  },
                ),

                const Divider(color: Colors.white24, height: 1),

                // Déconnexion
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Déconnexion',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    final storage = const FlutterSecureStorage();
                    await storage.delete(key: 'jwt_token');
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String route, BuildContext context) {
    final isActive = route == widget.currentRoute;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppColors.orange : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.orange : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.white.withOpacity(0.1),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },  
    );
  }

  Widget _buildExpandableMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isExpanded,
    List<Widget> children,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.white70),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.normal,
            ),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white70,
          ),
          onTap: onTap,
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildSubMenuItem(String title, String route, BuildContext context) {
    final isActive = route == widget.currentRoute;
    return Container(
      padding: const EdgeInsets.only(left: 56),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.orange : Colors.white60,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isActive,
        selectedTileColor: Colors.white.withOpacity(0.1),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}