import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ad_computer.dart';
import '../models/ad_group.dart'; // WICHTIG: Import für Typ-Check
import '../providers/group_provider.dart';

class ComputerDetailsScreen extends StatelessWidget {
  final ADComputer computer;

  const ComputerDetailsScreen({super.key, required this.computer});

  @override
  Widget build(BuildContext context) {
    // Holen aller Gruppen, in denen dieser Computer Mitglied ist
    final groupProvider = context.watch<GroupProvider>();
    
    // Sicherer Filter: Wir vergleichen DNs
    final memberOfGroups = groupProvider.groups.where(
      (g) => g.members.contains(computer.distinguishedName)
    ).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(computer.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Info'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Mitglied von'),
              Tab(icon: Icon(Icons.table_chart), text: 'Attribute'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(context),
            _buildMembershipTab(context, memberOfGroups),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context,
            'Allgemein',
            [
              _InfoRow('Name', computer.name),
              _InfoRow('DNS Hostname', (computer.dnsHostName?.isNotEmpty ?? false) ? computer.dnsHostName! : '-'),
              _InfoRow('Status', computer.isEnabled ? 'Aktiv' : 'Deaktiviert'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Betriebssystem',
            [
              _InfoRow('OS', computer.operatingSystem ?? 'Unbekannt'),
              _InfoRow('Version', (computer.operatingSystemVersion?.isNotEmpty ?? false) ? computer.operatingSystemVersion! : '-'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Standort',
            [
              _InfoRow('Organisationseinheit', computer.organizationalUnit ?? 'Root / Unbekannt'),
              _InfoRow('Distinguished Name', computer.distinguishedName, monospace: true, copyable: true),
            ],
          ),
          if (computer.lastLogon != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Aktivität',
              [
                _InfoRow('Letzte Anmeldung', computer.lastLogon ?? '-'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembershipTab(BuildContext context, List<dynamic> groups) {
    if (groups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Dieser Computer ist in keinen Gruppen gefunden worden.', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final item = groups[index];
        
        // SICHERHEITS-CHECK: Wir bestimmen den Namen basierend auf dem Objekttyp
        String titleText = 'Unbekannt';
        String subtitleText = '';

        if (item is ADGroup) {
          // Wenn es eine Gruppe ist, nutzen wir displayName oder name
          titleText = (item.displayName.isNotEmpty) ? item.displayName : item.name;
          subtitleText = item.distinguishedName;
        } else {
          // Fallback für alle anderen Typen (wie ADComputer), falls die Liste vermischt ist
          try {
            titleText = item.name;
            subtitleText = item.distinguishedName;
          } catch (e) {
            titleText = item.toString();
          }
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.group, color: Colors.blueGrey),
            title: Text(titleText),
            subtitle: Text(
              subtitleText,
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttributesTab(BuildContext context) {
    final sortedKeys = computer.attributes.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final values = computer.attributes[key];
        final valueText = values is List ? values.join('\n') : values.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('In Zwischenablage kopiert')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Kopieren'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<_InfoRow> rows) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 140, child: Text('${row.label}:', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54))),
                  Expanded(
                    child: SelectableText(
                      row.value,
                      style: TextStyle(
                        fontFamily: row.monospace ? 'monospace' : null,
                        fontSize: row.monospace ? 11 : 14,
                      ),
                    ),
                  ),
                  if (row.copyable)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 14),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: row.value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('In Zwischenablage kopiert')),
                        );
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool monospace;
  final bool copyable;
  _InfoRow(this.label, this.value, {this.monospace = false, this.copyable = false});
}