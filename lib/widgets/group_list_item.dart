import 'package:flutter/material.dart';
import '../models/ad_group.dart';
import '../screens/group_details_screen.dart';

class GroupListItem extends StatelessWidget {
  final ADGroup group;

  const GroupListItem({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(
            group.members.isEmpty ? Icons.group_outlined : Icons.group,
            color: Colors.white,
          ),
        ),
        title: Text(
          group.displayName.isNotEmpty ? group.displayName : group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name),
            if (group.description.isNotEmpty) 
              Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                '${group.members.length} Mitglieder',
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor: Colors.blue.shade100,
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
              // ÄNDERUNG HIER: 'groupDN' statt 'group' übergeben
              builder: (context) => GroupDetailsScreen(groupDN: group.distinguishedName),
            ),
          );
        },
      ),
    );
  }
}