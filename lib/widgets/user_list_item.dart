import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ad_user.dart';
import '../providers/ad_provider.dart';
import '../screens/user_details_screen.dart'; // WICHTIG: Import hinzugefügt

class UserListItem extends StatelessWidget {
  final ADUser user;

  const UserListItem({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        // --- NEU: Klick auf die Kachel öffnet Details ---
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(user: user),
            ),
          );
        },
        // -----------------------------------------------
        leading: CircleAvatar(
          backgroundColor: user.isEnabled
              ? (user.isLocked ? Colors.orange : Colors.green)
              : Colors.red,
          child: Icon(
            user.isLocked
                ? Icons.lock
                : user.isEnabled
                    ? Icons.person
                    : Icons.person_off,
            color: Colors.white,
          ),
        ),
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.username),
            if (user.email.isNotEmpty) Text(user.email),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    user.isEnabled ? 'Aktiv' : 'Deaktiviert',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: user.isEnabled ? Colors.green.shade100 : Colors.red.shade100,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                if (user.isLocked)
                  Chip(
                    label: const Text('Gesperrt', style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.orange.shade100,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            if (user.isLocked)
              const PopupMenuItem<String>(
                value: 'unlock',
                child: ListTile(
                  leading: Icon(Icons.lock_open),
                  title: Text('Entsperren'),
                  contentPadding: EdgeInsets.zero,
                ),
              )
            else
              const PopupMenuItem<String>(
                value: 'lock',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Sperren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuDivider(),
            if (user.isEnabled)
              const PopupMenuItem<String>(
                value: 'disable',
                child: ListTile(
                  leading: Icon(Icons.person_off),
                  title: Text('Deaktivieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              )
            else
              const PopupMenuItem<String>(
                value: 'enable',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Aktivieren'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'reset_password',
              child: ListTile(
                leading: Icon(Icons.password),
                title: Text('Kennwort setzen'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
          onSelected: (value) => _handleAction(context, value),
        ),
        isThreeLine: true,
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    final adProvider = Provider.of<ADProvider>(context, listen: false);
    
    if (action == 'reset_password') {
      _showResetPasswordDialog(context, adProvider);
      return;
    }

    bool success = false;
    String message = '';

    switch (action) {
      case 'lock':
        success = await adProvider.lockUser(user.username);
        message = success ? 'Benutzer gesperrt' : 'Fehler beim Sperren';
        break;
      case 'unlock':
        success = await adProvider.unlockUser(user.username);
        message = success ? 'Benutzer entsperrt' : 'Fehler beim Entsperren';
        break;
      case 'disable':
        success = await adProvider.disableUser(user.username);
        message = success ? 'Benutzer deaktiviert' : 'Fehler beim Deaktivieren';
        break;
      case 'enable':
        success = await adProvider.enableUser(user.username);
        message = success ? 'Benutzer aktiviert' : 'Fehler beim Aktivieren';
        break;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showResetPasswordDialog(BuildContext context, ADProvider adProvider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kennwort für ${user.username} setzen'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Neues Kennwort',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = controller.text.trim();
              if (password.isEmpty) return;

              Navigator.pop(ctx);
              final success = await adProvider.resetPassword(user.username, password);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Kennwort erfolgreich gesetzt' : 'Fehler beim Setzen des Kennworts'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}