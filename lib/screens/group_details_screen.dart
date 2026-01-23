import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ad_group.dart';
import '../models/ad_user.dart';
import '../models/ad_computer.dart';
import '../providers/group_provider.dart';
import '../providers/ad_provider.dart';
import '../providers/computer_provider.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupDN;

  const GroupDetailsScreen({super.key, required this.groupDN});

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        final group = groupProvider.getGroupByDN(groupDN);

        if (group == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Gruppe nicht gefunden')));
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(group.displayName.isNotEmpty ? group.displayName : group.name),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.info_outline), text: 'Info'),
                  Tab(icon: Icon(Icons.people), text: 'Mitglieder'),
                  Tab(icon: Icon(Icons.table_chart), text: 'Attribute'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildInfoTab(context, group),
                _buildMembersTab(context, group),
                _buildAttributesTab(context, group),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddMemberSheet(context, group),
              label: const Text('Hinzufügen'),
              icon: const Icon(Icons.person_add_alt_1),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(BuildContext context, ADGroup group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(context, 'Allgemein', [
            _InfoRow('Name', group.name),
            _InfoRow('Anzeigename', group.displayName),
            _InfoRow('Beschreibung', group.description.isNotEmpty ? group.description : '-'),
            _InfoRow('Gruppen-Typ', group.groupType),
            _InfoRow('Anzahl Mitglieder', group.members.length.toString()),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Distinguished Name', [
            _InfoRow('DN', group.distinguishedName, monospace: true, copyable: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildMembersTab(BuildContext context, ADGroup group) {
    if (group.members.isEmpty) {
      return const Center(child: Text('Keine Mitglieder'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: group.members.length,
      itemBuilder: (context, index) {
        final memberDN = group.members[index];
        final memberName = _extractCNFromDN(memberDN);
        
        IconData icon = Icons.person;
        Color iconColor = Colors.green;
        
        if (memberDN.toUpperCase().contains('OU=COMPUTERS') || memberDN.contains('\$')) {
          icon = Icons.computer;
          iconColor = Colors.blueGrey;
        } else if (memberDN.toUpperCase().contains('OU=GROUPS')) {
          icon = Icons.group_work;
          iconColor = Colors.orange;
        }

        return Card(
          child: ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(memberName),
            subtitle: Text(memberDN, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _handleRemove(context, memberDN, group),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttributesTab(BuildContext context, ADGroup group) {
    final sortedKeys = group.attributes.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final values = group.attributes[key];
        final valueText = values is List ? values.join('\n') : values.toString();
        return Card(
          child: ExpansionTile(
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [
              ListTile(title: SelectableText(valueText, style: const TextStyle(fontSize: 12))),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberSheet(BuildContext context, ADGroup currentGroup) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMemberModal(currentGroup: currentGroup),
    );
  }

  void _handleRemove(BuildContext context, String memberDN, ADGroup group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entfernen'),
        content: Text('${_extractCNFromDN(memberDN)} wirklich aus dieser Gruppe entfernen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await Provider.of<GroupProvider>(context, listen: false)
          .removeUserFromGroup(memberDN, group.distinguishedName);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Erfolgreich entfernt' : 'Fehler beim Entfernen'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoCard(BuildContext context, String title, List<_InfoRow> rows) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 120, child: Text("${row.label}:", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
                  Expanded(child: SelectableText(row.value, style: TextStyle(fontFamily: row.monospace ? 'monospace' : null, fontSize: row.monospace ? 12 : 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _extractCNFromDN(String dn) {
    final match = RegExp(r'CN=([^,]+)', caseSensitive: false).firstMatch(dn);
    return match?.group(1) ?? dn;
  }
}

class _AddMemberModal extends StatefulWidget {
  final ADGroup currentGroup;
  const _AddMemberModal({required this.currentGroup});

  @override
  State<_AddMemberModal> createState() => _AddMemberModalState();
}

class _AddMemberModalState extends State<_AddMemberModal> {
  String filterType = 'User'; 
  String searchQuery = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final adProvider = context.watch<ADProvider>();
    final groupProvider = context.watch<GroupProvider>();
    final computerProvider = context.watch<ComputerProvider>();

    List<dynamic> currentList = [];
    if (filterType == 'User') currentList = adProvider.users;
    if (filterType == 'Group') currentList = groupProvider.groups;
    if (filterType == 'Computer') currentList = computerProvider.computers;

    final filteredList = currentList.where((item) {
      String nameToSearch = "";
      
      if (item is ADGroup) {
        nameToSearch = item.displayName.isNotEmpty ? item.displayName : item.name;
      } else if (item is ADComputer) {
        nameToSearch = item.name;
      } else if (item is ADUser) {
        nameToSearch = item.displayName;
      } else {
        try { nameToSearch = item.name; } catch (_) { nameToSearch = item.toString(); }
      }
      
      return nameToSearch.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '$filterType suchen...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['User', 'Group', 'Computer'].map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(type),
                      selected: filterType == type,
                      onSelected: (val) {
                        if (val) setState(() => filterType = type);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final item = filteredList[index];
                  
                  String dn = "";
                  String display = "";
                  
                  if (item is ADGroup) {
                    dn = item.distinguishedName;
                    display = item.displayName.isNotEmpty ? item.displayName : item.name;
                  } else if (item is ADComputer) {
                    dn = item.distinguishedName;
                    display = item.name;
                  } else if (item is ADUser) {
                    dn = item.distinguishedName;
                    display = item.displayName;
                  }

                  final bool isMember = widget.currentGroup.members.contains(dn);

                  return ListTile(
                    leading: Icon(
                      filterType == 'User' ? Icons.person : 
                      filterType == 'Group' ? Icons.group : Icons.computer
                    ),
                    title: Text(display),
                    subtitle: Text(dn, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: isMember 
                        ? const Icon(Icons.check_circle, color: Colors.green) 
                        : const Icon(Icons.add_circle_outline),
                    enabled: !_isLoading,
                    onTap: isMember ? null : () => _handleAdd(context, dn, display),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context, String memberDN, String displayName) async {
    setState(() => _isLoading = true);
    
    print('[GroupDetails] Versuche hinzuzufügen:');
    print('  Member DN: $memberDN');
    print('  Group DN: ${widget.currentGroup.distinguishedName}');
    
    try {
      final success = await context.read<GroupProvider>().addUserToGroup(
        memberDN, 
        widget.currentGroup.distinguishedName
      );
      
      print('[GroupDetails] Ergebnis: $success');
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$displayName erfolgreich hinzugefügt'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Modal schließen nach erfolgreichem Hinzufügen
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Hinzufügen. Überprüfen Sie die Berechtigungen.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[GroupDetails] Exception: $e');
      
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool monospace;
  final bool copyable;
  _InfoRow(this.label, this.value, {this.monospace = false, this.copyable = false});
}