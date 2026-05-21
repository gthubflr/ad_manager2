import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ad_computer.dart';
import '../models/ad_group.dart';
import '../models/bitlocker_info.dart';
import '../providers/computer_provider.dart';
import '../providers/group_provider.dart';

class ComputerDetailsScreen extends StatefulWidget {
  final ADComputer computer;

  const ComputerDetailsScreen({super.key, required this.computer});

  @override
  State<ComputerDetailsScreen> createState() => _ComputerDetailsScreenState();
}

class _ComputerDetailsScreenState extends State<ComputerDetailsScreen> {
  // Steuert, welche Recovery-Keys im Klartext sichtbar sind
  final Set<int> _visibleKeys = {};

  @override
  void initState() {
    super.initState();
    // BitLocker-Daten beim Öffnen des Screens im Hintergrund laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<ComputerProvider>()
          .loadBitLockerInfo(widget.computer.distinguishedName);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watcht nur den GroupProvider für den Gruppen-Tab
    final groupProvider = context.watch<GroupProvider>();
    
    final memberOfGroups = groupProvider.groups.where(
      (g) => g.members.contains(widget.computer.distinguishedName)
    ).toList();

    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.computer.name),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline),      text: 'Info'),
              Tab(icon: Icon(Icons.groups_outlined),   text: 'Mitglied von'),
              Tab(icon: Icon(Icons.lock_outline),      text: 'BitLocker'),
              Tab(icon: Icon(Icons.table_chart),       text: 'Attribute'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(context),
            _buildMembershipTab(context, memberOfGroups),
            
            // Verwendung von Consumer verhindert das Neuladen des gesamten Screens
            Consumer<ComputerProvider>(
              builder: (context, computerProvider, child) {
                return _buildBitLockerTab(context, computerProvider);
              },
            ),
            
            _buildAttributesTab(context),
          ],
        ),
      ),
    );
  }

  // ==================== INFO-TAB ====================

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
              _InfoRow('Name', widget.computer.name),
              _InfoRow('DNS Hostname', (widget.computer.dnsHostName?.isNotEmpty ?? false) ? widget.computer.dnsHostName! : '-'),
              _InfoRow('Status', widget.computer.isEnabled ? 'Aktiv' : 'Deaktiviert'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Betriebssystem',
            [
              _InfoRow('OS', widget.computer.operatingSystem ?? 'Unbekannt'),
              _InfoRow('Version', (widget.computer.operatingSystemVersion?.isNotEmpty ?? false) ? widget.computer.operatingSystemVersion! : '-'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Standort',
            [
              _InfoRow('Organisationseinheit', widget.computer.organizationalUnit ?? 'Root / Unbekannt'),
              _InfoRow('Distinguished Name', widget.computer.distinguishedName, monospace: true, copyable: true),
            ],
          ),
          if (widget.computer.lastLogon != null) ...[
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              'Aktivität',
              [
                _InfoRow('Letzte Anmeldung', widget.computer.lastLogon ?? '-'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== MITGLIED-VON-TAB ====================

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
        
        String titleText = 'Unbekannt';
        String subtitleText = '';

        if (item is ADGroup) {
          titleText = (item.displayName.isNotEmpty) ? item.displayName : item.name;
          subtitleText = item.distinguishedName;
        } else {
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

  // ==================== BITLOCKER-TAB ====================

  Widget _buildBitLockerTab(BuildContext context, ComputerProvider computerProvider) {
    final dn = widget.computer.distinguishedName;

    final isLoading = computerProvider.isBitLockerLoading(dn);
    final errorMsg  = computerProvider.getBitLockerError(dn);
    final infos     = computerProvider.getBitLockerInfoFor(dn);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => computerProvider.loadBitLockerInfo(dn, forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'BitLocker Recovery-Schlüssel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Aktualisieren',
                    onPressed: () => computerProvider.loadBitLockerInfo(dn, forceRefresh: true),
                  ),
                ],
              ),
            ),
          ),

          if (errorMsg != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: Text(errorMsg),
                  ),
                ),
              ),
            ),

          if (!isLoading && errorMsg == null && infos.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_encryption_gmailerrorred_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Keine BitLocker-Schlüssel gefunden.'),
                    SizedBox(height: 4),
                    Text(
                      'Entweder ist das Laufwerk nicht verschlüsselt\noder die Schlüssel wurden nicht ins AD gespeichert.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          if (infos.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildBitLockerCard(context, infos[index], index),
                  childCount: infos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBitLockerCard(BuildContext context, BitLockerInfo info, int index) {
    final isVisible = _visibleKeys.contains(index);
    final isLatest  = index == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isLatest ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isLatest
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.vpn_key,
                  color: isLatest
                      ? Theme.of(context).colorScheme.primary
                      : Colors.blueGrey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isLatest ? 'Aktuellster Schlüssel' : 'Schlüssel ${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLatest ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (info.volumeGuid.isNotEmpty) ...[
              _buildLabeledRow(context, 'Volume GUID', info.volumeGuid, monospace: true),
              const SizedBox(height: 8),
            ],

            if (info.whenCreated != null && info.whenCreated!.isNotEmpty) ...[
              _buildLabeledRow(context, 'Erstellt am', info.whenCreated!),
              const SizedBox(height: 8),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 110,
                  child: Text(
                    'Recovery Key:',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    isVisible
                        ? info.recoveryKey
                        : '••••••••-••••••••-••••••••-••••••••-••••••••-••••••••',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: isVisible ? 12 : 14,
                      letterSpacing: isVisible ? 0.5 : 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility, size: 18),
                  tooltip: isVisible ? 'Verbergen' : 'Anzeigen',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    if (isVisible) {
                      _visibleKeys.remove(index);
                    } else {
                      _visibleKeys.add(index);
                    }
                  }),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Key kopieren'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: info.recoveryKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recovery Key in Zwischenablage kopiert'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                if (info.volumeGuid.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('GUID kopieren'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: info.volumeGuid));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Volume GUID in Zwischenablage kopiert'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledRow(BuildContext context, String label, String value, {bool monospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              fontFamily: monospace ? 'monospace' : null,
              fontSize: monospace ? 11 : 14,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== ATTRIBUTE-TAB ====================

  Widget _buildAttributesTab(BuildContext context) {
    final sortedKeys = widget.computer.attributes.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final values = widget.computer.attributes[key];
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

  // ==================== SHARED WIDGETS ====================

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