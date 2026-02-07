import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/services/listing_service.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/services/user_service.dart';
import 'package:dramus/services/admin_service.dart';
import 'package:dramus/services/favorites_service.dart';
import 'package:dramus/theme.dart';
import 'home_screen_new.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'map.dart';
import 'listings_screen.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MessageService()),
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
      ],
      child: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(context),
        //floatingActionButton: _buildFAB(context),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return HomeScreen();
      case 1:
        return ListingsScreen();
      case 2:
        return ClientsMapScreen();
      case 3:
        return MessagesScreen();
      case 4:
        return ProfileScreen();
      default:
        return HomeScreen();
    }
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
                icon: Icon(
                  _selectedIndex == 2
                      ? Icons.apartment
                      : Icons.apartment_outlined,
                  color: _selectedIndex == 2
                      ? DramusColors.primaryTeal
                      : DramusColors.secondaryText,
                ),
                label: 'Carte',
              ),
              NavigationDestination(
                icon: Stack(
                  children: [
                    Icon(
                      _selectedIndex == 3 ? Icons.mail : Icons.mail_outlined,
                      color: _selectedIndex == 3
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
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
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
                  _selectedIndex == 4 ? Icons.person : Icons.person_outlined,
                  color: _selectedIndex == 4
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
}
