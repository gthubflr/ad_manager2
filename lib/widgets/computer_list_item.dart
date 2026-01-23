import 'package:flutter/material.dart';
import '../models/ad_computer.dart';
import '../screens/computer_details_screen.dart';

class ComputerListItem extends StatelessWidget {
  final ADComputer computer;

  const ComputerListItem({super.key, required this.computer});

  IconData _getOSIcon() {
    // FEHLERBEHEBUNG: Sicherer Check auf null
    final os = (computer.operatingSystem ?? '').toLowerCase();
    if (os.contains('windows')) return Icons.desktop_windows;
    if (os.contains('linux')) return Icons.laptop_chromebook;
    if (os.contains('mac')) return Icons.laptop_mac;
    return Icons.computer;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          // FEHLERBEHEBUNG: isEnabled könnte null sein
          backgroundColor: (computer.isEnabled ?? true) ? Colors.green : Colors.grey,
          child: Icon(
            _getOSIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(
          computer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FEHLERBEHEBUNG: Sicherer Check für dnsHostName
            if (computer.dnsHostName != null && computer.dnsHostName!.isNotEmpty)
              Text(computer.dnsHostName!),
            
            Text(
              computer.operatingSystem ?? 'Betriebssystem unbekannt',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.folder_outlined, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    computer.organizationalUnit ?? 'Keine OU',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // FEHLERBEHEBUNG: Chip darf nicht abstürzen
            Chip(
              label: Text(
                (computer.isEnabled ?? true) ? 'Aktiv' : 'Deaktiviert',
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: (computer.isEnabled ?? true) 
                  ? Colors.green.shade100 
                  : Colors.grey.shade300,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComputerDetailsScreen(computer: computer),
            ),
          );
        },
      ),
    );
  }
}