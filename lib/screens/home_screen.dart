import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart'; 
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/computer_provider.dart';
import '../widgets/user_list_item.dart';
import '../screens/group_screen.dart'; // Prüfe, ob die Datei wirklich so heißt
import '../screens/computers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialisierung aller Provider nach dem ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final adService = authProvider.adService;
      
      // Service in allen Providern setzen
      context.read<ADProvider>().setADService(adService);
      context.read<GroupProvider>().setADService(adService);
      context.read<ComputerProvider>().setADService(adService);
      
      // Daten laden (User für den Home-Screen)
      context.read<ADProvider>().loadUsers();
      
      // Optional: Gruppen und Computer bereits im Hintergrund vorladen
      context.read<GroupProvider>().loadGroups();
      context.read<ComputerProvider>().loadComputers();
    });

    // Listener für Suchfeld (Benutzer-Suche)
    _searchController.addListener(() {
      context.read<ADProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adProvider = context.watch<ADProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AD Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Benutzer aktualisieren',
            onPressed: () => adProvider.loadUsers(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
              } else if (value == 'groups') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GroupsScreen()),
                );
              } else if (value == 'computers') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ComputersScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  authProvider.config?.username ?? 'Admin',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'groups',
                child: ListTile(
                  leading: Icon(Icons.group),
                  title: Text('Gruppen'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'computers',
                child: ListTile(
                  leading: Icon(Icons.computer),
                  title: Text('Computer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Abmelden', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Benutzer suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          adProvider.setSearchQuery('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (adProvider.errorMessage != null)
            ListTile(
              tileColor: Colors.red.shade50,
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(adProvider.errorMessage!),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => adProvider.clearError(),
              ),
            ),
          Expanded(
            child: adProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : adProvider.users.isEmpty
                    ? const Center(child: Text('Keine Benutzer gefunden'))
                    : ListView.builder(
                        itemCount: adProvider.users.length,
                        itemBuilder: (context, index) =>
                            UserListItem(user: adProvider.users[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'groups_fab',
            tooltip: 'Gruppen',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupsScreen()),
              );
            },
            child: const Icon(Icons.group),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'computers_fab',
            tooltip: 'Computer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ComputersScreen()),
              );
            },
            child: const Icon(Icons.computer),
          ),
        ],
      ),
    );
  }
}