import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../widgets/group_list_item.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _searchController = TextEditingController();
  String _searchText = ''; // Lokaler State für den Such-Text

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().loadGroups();
    });
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
      context.read<GroupProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gruppen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => groupProvider.loadGroups(),
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
                hintText: 'Gruppen suchen...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty // Verwende lokalen State statt Controller
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          // setState wird durch den Listener ausgelöst
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (groupProvider.errorMessage != null)
            ListTile(
              tileColor: Colors.red.shade50,
              leading: const Icon(Icons.error, color: Colors.red),
              title: Text(groupProvider.errorMessage!),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => groupProvider.clearError(),
              ),
            ),
          Expanded(
            child: groupProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupProvider.groups.isEmpty
                    ? const Center(
                        child: Text('Keine Gruppen gefunden'),
                      )
                    : ListView.builder(
                        itemCount: groupProvider.groups.length,
                        itemBuilder: (context, index) =>
                            GroupListItem(group: groupProvider.groups[index]),
                      ),
          ),
        ],
      ),
    );
  }
}