import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/services/agent_service.dart';
import 'package:dramus/models/agent_model.dart';
import 'add_edit_agent_screen.dart';

class AgentsListScreen extends StatefulWidget {
  const AgentsListScreen({super.key});

  @override
  State<AgentsListScreen> createState() => _AgentsListScreenState();
}

class _AgentsListScreenState extends State<AgentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AgentService>(context, listen: false).fetchAgents();
    });
  }

  Future<void> _deleteAgent(AgentModel agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'agent'),
        content:
            Text('Voulez-vous vraiment supprimer l\'agent ${agent.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: DramusColors.notificationRed),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final success = await Provider.of<AgentService>(context, listen: false)
          .deleteAgent(agent.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Agent supprimé' : 'Erreur lors de la suppression'),
          backgroundColor:
              success ? Colors.green : DramusColors.notificationRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DramusColors.lightBackground,
      appBar: AppBar(
        title: const Text('Mes Agents',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: DramusColors.white,
        foregroundColor: DramusColors.darkText,
        elevation: 0,
      ),
      body: Consumer<AgentService>(
        builder: (context, agentService, child) {
          if (agentService.isLoading && agentService.agents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (agentService.agents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_outlined,
                      size: 80, color: DramusColors.lightGray),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun agent trouvé',
                    style: TextStyle(
                        color: DramusColors.secondaryText, fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddEditAgentScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un agent'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DramusColors.primaryTeal,
                      foregroundColor: DramusColors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => agentService.fetchAgents(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: agentService.agents.length,
              itemBuilder: (context, index) {
                final agent = agentService.agents[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            DramusColors.primaryTeal.withOpacity(0.1),
                        child: Text(
                          agent.firstName[0].toUpperCase() +
                              agent.lastName[0].toUpperCase(),
                          style: const TextStyle(
                              color: DramusColors.primaryTeal,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        agent.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(agent.email,
                              style:
                                  TextStyle(color: DramusColors.secondaryText)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            children: agent.permissions
                                .map((p) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: DramusColors.primaryTeal
                                            .withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _mapPermissionLabel(p),
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: DramusColors.primaryTeal),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      AddEditAgentScreen(agent: agent)),
                            );
                          } else if (value == 'delete') {
                            _deleteAgent(agent);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Modifier'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete,
                                    size: 20,
                                    color: DramusColors.notificationRed),
                                const SizedBox(width: 8),
                                const Text('Supprimer',
                                    style: TextStyle(
                                        color: DramusColors.notificationRed)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditAgentScreen()),
          );
        },
        backgroundColor: DramusColors.primaryTeal,
        child: const Icon(Icons.add, color: DramusColors.white),
      ),
    );
  }

  String _mapPermissionLabel(String p) {
    switch (p) {
      case 'create_property':
        return 'Créer annonces';
      case 'edit_property':
        return 'Modifier annonces';
      case 'view_clients':
        return 'Voir clients';
      default:
        return p;
    }
  }
}
