import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';

// Écrans globaux
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';

// Écrans Admin
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_user_list_screen.dart';
import 'screens/admin/admin_user_form_screen.dart';
import 'screens/admin/admin_taches_screen.dart';

// Écrans Responsable
import 'screens/responsable/responsable_dashboard_screen.dart'; 
import 'screens/responsable/ascenseur_list_screen.dart';
import 'screens/responsable/nouvel_ascenseur_screen.dart';
import 'screens/responsable/site_list_screen.dart';
import 'screens/responsable/nouveau_site_screen.dart';
import 'screens/responsable/mes_taches_screen.dart';
import 'screens/responsable/parc_list_screen.dart';
import 'screens/responsable/nouveau_parc_screen.dart';
import 'screens/responsable/responsable_demandes_en_attente_screen.dart'; 
import 'screens/responsable/responsable_demande_detail_screen.dart';
import 'screens/responsable/bon_travail_list_screen.dart';
import 'screens/responsable/nouveau_bon_travail_screen.dart';
import 'screens/responsable/rapports_a_valider_screen.dart';
import 'screens/responsable/rapport_detail_screen.dart';
import 'screens/responsable/demandes_installations_screen.dart';
import 'screens/responsable/demande_evaluation_detail_screen.dart';
import 'screens/responsable/assemblage_tree_screen.dart';

// Écrans Technicien
import 'screens/technicien/technicien_dashboard_screen.dart';
import 'screens/technicien/technicien_taches_screen.dart';
import 'screens/technicien/technicien_interventions_screen.dart';

// Écrans Client
import 'screens/client/client_dashboard_screen.dart';
import 'screens/client/nouvelle_demande_screen.dart';
import 'screens/client/client_ascenseurs_screen.dart';
import 'screens/client/client_demandes_screen.dart';
import 'screens/client/demande_detail_screen.dart';
import 'screens/client/nouvelle_evaluation_screen.dart';
import 'screens/client/mes_evaluations_screen.dart';

// Écrans Partagés
import 'screens/shared/profil_screen.dart'; 
import 'screens/shared/calendrier_screen.dart';
import 'screens/shared/ai_assistant_screen.dart'; 

void main() {
  initializeDateFormatting('fr_FR', null).then((_) => runApp(const SpelevApp()));
}

class SpelevApp extends StatelessWidget {
  const SpelevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPELEV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profil': (context) => const ProfilScreen(),
        
        '/ai-assistant': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final role = args?['role'] ?? 'admin';
          return AIAssistantScreen(role: role);
        },
        
        // ─── Routes Admin ─────────────────────────────────────
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/admin-users': (context) => const AdminUserListScreen(),
        '/admin-user-form': (context) => const AdminUserFormScreen(),
        '/admin-taches': (context) => const AdminTachesScreen(),
        
        // ─── Routes Technicien ────────────────────────────────
        '/technicien-dashboard': (context) => const TechnicienDashboardScreen(),
        '/technicien-taches': (context) => const TechnicienTachesScreen(),
        '/technicien-interventions': (context) => const TechnicienInterventionsScreen(),

        // ─── Routes Client ────────────────────────────────────
        '/client-dashboard': (context) => const ClientDashboardScreen(),
        '/client-ascenseurs': (context) => const ClientAscenseursScreen(),
        '/client-demandes': (context) => const ClientDemandesScreen(),
        '/client-nouvelle-demande': (context) => const NouvelleDemandeScreen(),
        '/client-nouvelle-evaluation': (context) => const NouvelleEvaluationScreen(),
        '/client-mes-evaluations': (context) => const MesEvaluationsScreen(),
        
        // ─── Routes Responsable ───────────────────────────────
        '/responsable-dashboard': (context) => const ResponsableDashboardScreen(),
        '/responsable-ascenseur-list': (context) => const AscenseurListScreen(),
        '/responsable-nouvel-ascenseur': (context) => const NouvelAscenseurScreen(),
        '/responsable-site-list': (context) => const SiteListScreen(),
        '/responsable-nouveau-site': (context) => const NouveauSiteScreen(),
        '/responsable-mes-taches': (context) => const MesTachesScreen(),
        '/responsable-parc-list': (context) => const ParcListScreen(),
        '/responsable-nouveau-parc': (context) => const NouveauParcScreen(),
        '/responsable-bons-travail': (context) => const BonTravailListScreen(),
        '/responsable-nouveau-bon-travail': (context) => const NouveauBonTravailScreen(),
        '/responsable-demandes-rapports': (context) => const RapportsAValiderScreen(),
        '/responsable-demandes-installations': (context) => const DemandesInstallationsScreen(),
       
        '/responsable-calendrier': (context) => const CalendrierScreen(technicienId: null),
        '/technicien-calendrier': (context) => const CalendrierScreen(technicienId: null),
        '/responsable-demandes-attente': (context) => const ResponsableDemandesEnAttenteScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(email: ''), 
      },
      onGenerateRoute: (settings) {
        // ─── Client ────────────────────────────────────────────
        if (settings.name == '/client-demande-detail') {
          final demandeId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => DemandeDetailScreen(demandeId: demandeId),
          );
        }

        // ─── Responsable : Détail d'une demande en attente ────
        if (settings.name == '/responsable-demande-detail') {
          return MaterialPageRoute(
            builder: (context) => ResponsableDemandeDetailScreen(
              demande: settings.arguments as dynamic,
            ),
          );
        }

        if (settings.name == '/responsable-demande-evaluation-detail') {
          final demande = settings.arguments as dynamic;
          return MaterialPageRoute(
            builder: (context) => DemandeEvaluationDetailScreen(
              demande: demande,
            ),
          );
        }

        // ─── Rapport détail ────────────────────────────────────
        if (settings.name == '/responsable-rapport-detail') {
          final rapportId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => RapportDetailScreen(rapportId: rapportId),
          );
        }

        return null;
      },
    );
  }
}