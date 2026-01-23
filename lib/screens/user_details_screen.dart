import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ad_user.dart';
import '../providers/group_provider.dart';

class UserDetailsScreen extends StatefulWidget { // Zu StatefulWidget geändert für Suche
  final ADUser user;
  const UserDetailsScreen({super.key, required this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final groupProvider = context.watch<GroupProvider>();
    final memberOfGroups = groupProvider.groups.where(
      (g) => g.members.contains(widget.user.distinguishedName)
    ).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.user.displayName),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Info'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Gruppen'),
              Tab(icon: Icon(Icons.table_chart_outlined), text: 'Attribute'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(context),
            _buildGroupsTab(context, memberOfGroups),
            _buildAttributesTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(context, 'Benutzerkonto', [
            _InfoRow('Anzeigename', widget.user.displayName),
            _InfoRow('SAMAccountName', widget.user.samAccountName ?? '-', monospace: true, copyable: true),
            _InfoRow('Status', widget.user.isEnabled ? 'Aktiv' : 'Deaktiviert'),
            _InfoRow('Gesperrt', widget.user.isLocked ? 'Ja (Locked)' : 'Nein'),
            _InfoRow('Letzter Login', widget.user.lastLogon ?? 'Nie'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Kontaktdaten', [
            _InfoRow('E-Mail', (widget.user.mail != null && widget.user.mail!.isNotEmpty) ? widget.user.mail! : (widget.user.email.isNotEmpty ? widget.user.email : '-')),
            _InfoRow('Telefon', widget.user.telephoneNumber ?? '-'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard(context, 'Verzeichnis-Pfad', [
            _InfoRow('DN', widget.user.distinguishedName, monospace: true, copyable: true),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(BuildContext context, List<dynamic> groups) {
    if (groups.isEmpty) {
      return const Center(child: Text('Keine Gruppenmitgliedschaften gefunden.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.group, color: Colors.orange),
            title: Text(group.displayName.isNotEmpty ? group.displayName : group.name),
            subtitle: Text(group.distinguishedName, 
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }

  Widget _buildAttributesTab(BuildContext context) {
    // Filtern der Attribute nach Suche
    final filteredKeys = widget.user.attributes.keys
        .where((key) => key.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()..sort();

    if (widget.user.attributes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Roh-Attribute verfügbar.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Attribute durchsuchen...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredKeys.length,
            itemBuilder: (context, index) {
              final key = filteredKeys[index];
              final values = widget.user.attributes[key];
              final String valueText = values is List ? values.join('\n') : values.toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(valueText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(valueText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: valueText));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopiert!')));
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Wert kopieren'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<_InfoRow> rows) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
            const Divider(),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 130, child: Text('${row.label}:', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
                  Expanded(
                    child: SelectableText(
                      row.value,
                      style: TextStyle(
                        fontFamily: row.monospace ? 'monospace' : null,
                        fontSize: row.monospace ? 11 : 14,
                        color: _getValueColor(row.label, row.value),
                      ),
                    ),
                  ),
                  if (row.copyable && row.value != '-')
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: row.value));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${row.label} kopiert!')));
                      },
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color? _getValueColor(String label, String value) {
    if (label == 'Status') return value == 'Aktiv' ? Colors.green : Colors.red;
    if (label == 'Gesperrt') return value.contains('Ja') ? Colors.red : Colors.green;
    return null;
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool monospace;
  final bool copyable;
  _InfoRow(this.label, this.value, {this.monospace = false, this.copyable = false});
}