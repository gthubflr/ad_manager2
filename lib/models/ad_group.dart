class ADGroup {
  final String name;
  final String displayName;
  final String description;
  final String distinguishedName;
  final String groupType;
  final List<String> members;
  final Map<String, dynamic> attributes;

  ADGroup({
    required this.name,
    required this.displayName,
    required this.description,
    required this.distinguishedName,
    required this.groupType,
    required this.members,
    required this.attributes,
  });

  factory ADGroup.fromMap(Map<String, dynamic> map) => ADGroup(
        name: map['name'] ?? '',
        displayName: map['displayName'] ?? '',
        description: map['description'] ?? '',
        distinguishedName: map['dn'] ?? '',
        groupType: map['groupType'] ?? '',
        members: List<String>.from(map['members'] ?? []),
        attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'displayName': displayName,
        'description': description,
        'dn': distinguishedName,
        'groupType': groupType,
        'members': members,
        'attributes': attributes,
      };
}