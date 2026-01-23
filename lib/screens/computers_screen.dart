import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/computer_provider.dart';
import '../widgets/computer_list_item.dart';

class ComputersScreen extends StatefulWidget {
  const ComputersScreen({super.key});

  @override
  State<ComputersScreen> createState() => _ComputersScreenState();
}

class _ComputersScreenState extends State<ComputersScreen> {
  final _searchController = TextEditingController();
  String _searchText = ''; // Lokaler State für den Such-Text

  @override
  void initState() {
    super.initState();
    // Computer laden, sobald der Screen angezeigt wird
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComputerProvider>().loadComputers();
    });
    
    // Such-Filter an den Provider weitergeben
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
      context.read<ComputerProvider>().setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final computerProvider = context.watch<ComputerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Computer-Verwaltung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => computerProvider.loadComputers(),
            tooltip: 'Liste aktualisieren',
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
                hintText: 'Nach Name, OS oder OU suchen...',
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
          if (computerProvider.errorMessage != null)
            Container(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: Text(computerProvider.errorMessage!),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => computerProvider.clearError(),
                ),
              ),
            ),
          Expanded(
            child: computerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : computerProvider.computers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.computer_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Keine Computer gefunden'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: computerProvider.computers.length,
                        itemBuilder: (context, index) =>
                            ComputerListItem(computer: computerProvider.computers[index]),
                      ),
          ),
        ],
      ),
    );
  }
}