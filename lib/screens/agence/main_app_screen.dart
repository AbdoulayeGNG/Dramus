import 'package:dramus/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/services/auth_service.dart';
import 'listings_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'publish_screen.dart';

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
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
              color: DramusColors.darkPetroleum,
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
                            color: DramusColors.lightGray,
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
                          : DramusColors.darkText,
                    ),
                    title: Text(
                      'Tableau de bord',
                      style: TextStyle(
                        color: _selectedIndex == 0
                            ? DramusColors.primaryTeal
                            : DramusColors.darkText,
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
                          : DramusColors.darkText,
                    ),
                    title: Text(
                      'Rechercher des annonces',
                      style: TextStyle(
                        color: _selectedIndex == 1
                            ? DramusColors.primaryTeal
                            : DramusColors.darkText,
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
                      color: DramusColors.darkText,
                    ),
                    title: const Text('Mes favoris'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Naviguer vers FavoritesScreen
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.home_work,
                      color: DramusColors.darkText,
                    ),
                    title: const Text('Mes annonces'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Naviguer vers MyListingsScreen
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.group,
                      color: DramusColors.darkText,
                    ),
                    title: const Text('Mes agents'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Naviguer vers MyListingsScreen
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.bar_chart,
                      color: DramusColors.darkText,
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
                      color: DramusColors.darkText,
                    ),
                    title: const Text('Visites prévues'),
                    onTap: () {
                      Navigator.of(context).pop();
                      // TODO: Naviguer vers VisitsScreen
                    },
                  ),

                  const Divider(),

                  // Section secondaire
                  ListTile(
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
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: DramusColors.darkText),
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
                  color: DramusColors.secondaryText,
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageService()),
        ChangeNotifierProvider(create: (_) => UserService()),
      ],
      child: Scaffold(
        key: _scaffoldKey, // CLÉ DU SCAFFOLD AJOUTÉE ICI
        appBar: AppBar(
          backgroundColor: DramusColors.white,
          foregroundColor: DramusColors.darkText,
          elevation: 0,
          title: Text(
            _appBarTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              color: DramusColors.darkText,
            ),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            // Bouton notifications
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              color: DramusColors.darkText,
              onPressed: () {
                // TODO: Naviguer vers NotificationsScreen
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: Consumer<UserService>(
          builder: (context, userService, _) {
            return _pages[_selectedIndex];
          },
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DramusColors.white,
        border: Border(
          top: BorderSide(
            color: DramusColors.border,
            width: 1,
          ),
        ),
      ),
      child: Consumer<MessageService>(
        builder: (context, messageService, _) {
          final unreadCount = messageService.getUnreadCount();

          return NavigationBar(
            backgroundColor: DramusColors.white,
            indicatorColor: DramusColors.primaryTeal.withValues(alpha: 0.1),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? DramusColors.primaryTeal
                      : DramusColors.secondaryText,
                ),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(
                  _selectedIndex == 1
                      ? Icons.apartment
                      : Icons.apartment_outlined,
                  color: _selectedIndex == 1
                      ? DramusColors.primaryTeal
                      : DramusColors.secondaryText,
                ),
                label: 'Annonces',
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    Icon(
                      _selectedIndex == 2 ? Icons.mail : Icons.mail_outlined,
                      color: _selectedIndex == 2
                          ? DramusColors.primaryTeal
                          : DramusColors.secondaryText,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: DramusColors.notificationRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: DramusColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
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
                      ? DramusColors.primaryTeal
                      : DramusColors.secondaryText,
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
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PublishScreen()),
        );
      },
      backgroundColor: DramusColors.primaryTeal,
      foregroundColor: DramusColors.white,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Publier'),
    );
  }
}
