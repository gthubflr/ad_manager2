class ADComputer {
final String name;
  final String? dnsHostName;
  final String operatingSystem;
  final String? operatingSystemVersion;
  final String distinguishedName;
  final String organizationalUnit;
  final bool isEnabled;
  final String? lastLogon;
  // NEU:
  final Map<String, dynamic> attributes;

  ADComputer({
    required this.name,
    this.dnsHostName,
    required this.operatingSystem,
    this.operatingSystemVersion,
    required this.distinguishedName,
    required this.organizationalUnit,
    required this.isEnabled,
    this.lastLogon,
    this.attributes = const {}, // Standardmäßig leere Map
  });

  factory ADComputer.fromMap(Map<String, dynamic> map) => ADComputer(
        name: map['name'] ?? '',
        dnsHostName: map['dnsHostName'],
        operatingSystem: map['operatingSystem'] ?? 'Unbekannt',
        operatingSystemVersion: map['operatingSystemVersion'],
        distinguishedName: map['dn'] ?? '',
        organizationalUnit: map['ou'],
        isEnabled: map['isEnabled'] ?? false,
        lastLogon: map['lastLogon'],
        attributes: Map<String, dynamic>.from(map['attributes'] ?? {}),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'dnsHostName': dnsHostName,
        'operatingSystem': operatingSystem,
        'operatingSystemVersion': operatingSystemVersion,
        'dn': distinguishedName,
        'ou': organizationalUnit,
        'isEnabled': isEnabled,
        'lastLogon': lastLogon,
        'attributes': attributes,
      };
}