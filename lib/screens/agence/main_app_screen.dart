import 'package:dramus/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/screens/agence/favorites_screen.dart';
import 'package:dramus/screens/notifications_screen.dart';
import 'package:dramus/services/favorites_service.dart';
import 'listings_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/services/notification_service.dart';
import 'publish_screen.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'agents_list_screen.dart';

class MainAppScreenAgence extends StatefulWidget {
  const MainAppScreenAgence({super.key});

  @override
  State<MainAppScreenAgence> createState() => _MainAppScreenAgenceState();
}

class _MainAppScreenAgenceState extends State<MainAppScreenAgence> {
  int _selectedIndex = 0; // UNE SEULE VARIABLE D'ÉTAT
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
        const HomeScreen(),
        const ListingsScreen(),
        const MessagesScreen(),
        const ProfileScreen(),
      ];

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Accueil';
      case 1:
        return 'Annonces';
      case 2:
        return 'Messages';
      case 3:
        return 'Profil';
      default:
        return 'DRAMUS';
    }
  }

  void _setIndexAndClose(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop(); // fermer le drawer
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Déconnexion'),
            content: const Text('Voulez-vous vraiment vous déconnecter ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldLogout) {
      // Réinitialiser tous les services avant la déconnexion
      if (mounted) {
        try {
          context.read<ListingService>().reset();
          context.read<FavoritesService>().clearFavorites();
          context.read<MessageService>().clear();
          context.read<AgentService>().clear();

          try {
            final notifs = context.read<NotificationService>();
            notifs.unregisterToken();
            notifs.reset();
          } catch (e) {
            debugPrint('Could not reset NotificationService: $e');
          }
        } catch (e) {
          debugPrint('Error during services reset: $e');
        }

        await context.read<AuthController>().signOut();

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final user = userService.currentUser;
    final displayName =
        user.firstName.isNotEmpty ? user.firstName : 'Utilisateur';
    final email = user.email;
    final profileImage = user.avatar;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header utilisateur
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              color: Theme.of(context).colorScheme.primary,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: DramusColors.primaryTeal,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage) as ImageProvider
                        : null,
                    child: profileImage.isEmpty
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          email,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Options principales
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.dashboard,
                      color: _selectedIndex == 0
                          ? DramusColors.primaryTeal
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    title: Text(
                      'Tableau de bord',
                      style: TextStyle(
                        color: _selectedIndex == 0
                            ? DramusColors.primaryTeal
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _setIndexAndClose(0),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.search,
                      color: _selectedIndex == 1
                          ? DramusColors.primaryTeal
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    title: Text(
                      'Rechercher des annonces',
                      style: TextStyle(
                        color: _selectedIndex == 1
                            ? DramusColors.primaryTeal
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: _selectedIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _setIndexAndClose(1),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.favorite,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('Mes favoris'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.home_work,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('Mes annonces'),
                    onTap: () => _setIndexAndClose(1),
                  ),
                  if (user.role.toLowerCase() == "agency_admin")
                    ListTile(
                      leading: Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      title: const Text('Mes agents'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AgentsListScreen()),
                        );
                      },
                    ),

                  /* ListTile(
                    leading: Icon(
                      Icons.bar_chart,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('Nos statistiques'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Naviguer vers MyListingsScreen
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    title: const Text('Visites prévues'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Naviguer vers VisitsScreen
                    },
                  ),*/

                  const Divider(),

                  // Section secondaire
                  /* ListTile(
                    leading: Icon(Icons.settings, color: DramusColors.darkText),
                    title: const Text('Paramètres'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: push SettingsScreen()
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.help, color: DramusColors.darkText),
                    title: const Text('Aide & Support'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: push HelpScreen()
                    },
                  ),*/
                  ListTile(
                    leading: Icon(Icons.logout,
                        color: Theme.of(context).colorScheme.onSurface),
                    title: const Text('Déconnexion'),
                    onTap: _confirmLogout,
                  ),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text(
                'DRAMUS © ${DateTime.now().year}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _selectedIndex == 2
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
              elevation: 0,
              title: Text(
                _appBarTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                // Bouton notifications
                IconButton(
                  icon: Icon(Icons.notifications_outlined,
                      color: Theme.of(context).appBarTheme.foregroundColor),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
              ],
            ),
      drawer: _buildDrawer(context),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(context),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Consumer<MessageService>(
        builder: (context, messageService, _) {
          final unreadCount = messageService.getUnreadCount();

          return NavigationBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 1
                      ? Icons.apartment
                      : Icons.apartment_outlined,
                  color: _selectedIndex == 1
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: 'Annonces',
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    Icon(
                      _selectedIndex == 2 ? Icons.mail : Icons.mail_outlined,
                      color: _selectedIndex == 2
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: DramusColors.notificationRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Messages',
              ),
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 3 ? Icons.person : Icons.person_outlined,
                  color: _selectedIndex == 3
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }

  // Floating Action Button
  Widget? _buildFAB(BuildContext context) {
    // Masquer le FAB sur l'écran des messages pour libérer l'espace pour la saisie
    if (_selectedIndex == 2) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PublishScreen()),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Publier'),
    );
  }
}
