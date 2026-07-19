import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/services/message_service.dart';
import 'package:dramus/core/state/auth_controller.dart';
import 'home_screen_new.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'map.dart';
import 'listings_screen.dart';

class MainAppScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? selectedConversationId;
  final String? propertyId;
  final String? ownerName;
  final String? prefilledMessage;

  const MainAppScreen({
    super.key,
    this.initialTabIndex = 0,
    this.selectedConversationId,
    this.propertyId,
    this.ownerName,
    this.prefilledMessage,
  });

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late int _selectedIndex;
  // Conversation pré-sélectionnée consommée une seule fois
  String? _pendingConversationId;
  String? _pendingPropertyId;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _pendingConversationId = widget.selectedConversationId;
    _pendingPropertyId = widget.propertyId;
    _pendingPrefilledMessage = widget.prefilledMessage;
  }

  String? _pendingPrefilledMessage;
  bool? _wasLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Consumer2<MessageService, AuthController>(
      builder: (context, messageService, authController, _) {
        final isLoggedIn = authController.user != null;
        final unreadCount = messageService.getUnreadCount();

        // Gérer le décalage d'index lors de la connexion/déconnexion
        if (_wasLoggedIn != null && _wasLoggedIn != isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                if (!isLoggedIn) {
                  // Déconnexion : si on était sur Profil (4) ou Messages (3), on va sur Profil (3)
                  if (_selectedIndex >= 3) {
                    _selectedIndex = 3;
                  }
                } else {
                  // Connexion : si on était sur Profil (3), on va sur Profil (4)
                  if (_selectedIndex == 3) {
                    _selectedIndex = 4;
                  }
                }
              });
            }
          });
        }
        _wasLoggedIn = isLoggedIn;

        return Scaffold(
          body: _buildBody(isLoggedIn),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              selectedIndex: _selectedIndex.clamp(0, isLoggedIn ? 4 : 3),
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
                  icon: Icon(
                    _selectedIndex == 2 ? Icons.map : Icons.map_outlined,
                    color: _selectedIndex == 2
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  label: 'Carte',
                ),
                if (isLoggedIn)
                  NavigationDestination(
                    icon: Stack(
                      children: [
                        Icon(
                          _selectedIndex == 3
                              ? Icons.mail
                              : Icons.mail_outlined,
                          color: _selectedIndex == 3
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
                                color: Theme.of(context).colorScheme.error,
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
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.onError,
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
                    (_selectedIndex == (isLoggedIn ? 4 : 3))
                        ? Icons.person
                        : Icons.person_outlined,
                    color: (_selectedIndex == (isLoggedIn ? 4 : 3))
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(bool isLoggedIn) {
    if (!isLoggedIn && _selectedIndex >= 3) {
      // Pour les invités, l'index 3 correspond au Profil
      if (_selectedIndex == 3) return const ProfileScreen();
      return const HomeScreen();
    }

    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ListingsScreen();
      case 2:
        return const ClientsMapScreen();
      case 3:
        if (isLoggedIn) {
          return MessagesScreen(
            preselectedConversationId: _pendingConversationId,
            propertyId: _pendingPropertyId,
            prefilledMessage: _pendingPrefilledMessage,
            ownerName: widget.ownerName,
            onConversationOpened: () {
              // Consommer le pré-sélection une seule fois
              if (_pendingConversationId != null ||
                  _pendingPrefilledMessage != null) {
                setState(() {
                  _pendingConversationId = null;
                  _pendingPropertyId = null;
                  _pendingPrefilledMessage = null;
                });
              }
            },
          );
        }
        return const ProfileScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
}
