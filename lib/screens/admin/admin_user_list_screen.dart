import 'package:flutter/material.dart';
import 'admin_drawer.dart';
import '../../theme/app_theme.dart';
import '../../services/utilisateur_service.dart';
import '../../models/utilisateur_model.dart';
import 'admin_user_form_screen.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final _service = UtilisateurService();
  List<UtilisateurModel> _users = [];
  List<UtilisateurModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'TOUS';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _service.getUtilisateurs();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'TOUS') {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((u) => u.type == filter).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AdminDrawer(currentRoute: '/admin-users'),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Utilisateurs',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.orange),
            onPressed: _loadUsers,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Filtrer par :', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('TOUS'),
                        const SizedBox(width: 8),
                        _buildFilterChip('ADMINISTRATEUR'),
                        const SizedBox(width: 8),
                        _buildFilterChip('TECHNICIEN'),
                        const SizedBox(width: 8),
                        _buildFilterChip('CLIENT'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadUsers,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun utilisateur trouvé',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.navy.withOpacity(0.1),
                                    child: Icon(
                                      _getIconForType(user.type),
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  title: Text(
                                    '${user.prenom} ${user.nom}',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(user.email),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ✅ BOUTON MODIFIER (CRAYON)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.orange, size: 20),
                                        tooltip: 'Modifier',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AdminUserFormScreen(utilisateur: user),
                                            ),
                                          ).then((_) => _loadUsers());
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      // ✅ STATUS (ACTIF/INACTIF)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.actif
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          user.actif ? 'Actif' : 'Inactif',
                                          style: TextStyle(
                                            color: user.actif
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/admin-user-form').then((_) => _loadUsers());
        },
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Nouvel utilisateur'),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _applyFilter(label),
      selectedColor: AppColors.orange.withOpacity(0.2),
      checkmarkColor: AppColors.orange,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.orange : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ADMINISTRATEUR':
        return Icons.admin_panel_settings;
      case 'TECHNICIEN':
        return Icons.engineering;
      case 'RESPONSABLE_MAINTENANCE':
        return Icons.supervisor_account;
      case 'CLIENT':
        return Icons.business;
      default:
        return Icons.person;
    }
  }
}