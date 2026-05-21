/// Repräsentiert einen einzelnen BitLocker-Recovery-Eintrag aus dem AD
/// (Objekt der Klasse msFVE-RecoveryInformation).
class BitLockerInfo {
  /// Distinguished Name des übergeordneten Computer-Objekts
  final String computerDN;

  /// Der 48-stellige BitLocker-Wiederherstellungsschlüssel
  final String recoveryKey;

  /// Die Volume-GUID als formatierte Hex-Zeichenkette (z.B. "2A-4F-...")
  final String volumeGuid;

  /// Erstellungsdatum des Eintrags im AD (whenCreated, optional)
  final String? whenCreated;

  const BitLockerInfo({
    required this.computerDN,
    required this.recoveryKey,
    required this.volumeGuid,
    this.whenCreated,
  });

  @override
  String toString() =>
      'BitLockerInfo(volumeGuid: $volumeGuid, whenCreated: $whenCreated)';
}
