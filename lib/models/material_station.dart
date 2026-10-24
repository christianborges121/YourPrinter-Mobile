class MaterialSlot {
  final int id;
  final String? type;
  final String? colorHex;
  final double? remainingPercent;
  final bool isActive;
  final String? materialName;
  final double? targetTemp;

  const MaterialSlot({
    required this.id,
    this.type,
    this.colorHex,
    this.remainingPercent,
    required this.isActive,
    this.materialName,
    this.targetTemp,
  });

  factory MaterialSlot.fromJson(Map<String, dynamic> json) {
    return MaterialSlot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? json['material'] as String?,
      colorHex: json['colorHex'] as String? ?? json['color'] as String?,
      remainingPercent: (json['remainingPercent'] as num?)?.toDouble() ?? (json['remain'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? false,
      materialName: json['materialName'] as String? ?? json['name'] as String?,
      targetTemp: (json['targetTemp'] as num?)?.toDouble(),
    );
  }
}

class MaterialStationStatus {
  final bool connected;
  final List<MaterialSlot> slots;
  final int? activeSlotIndex;

  const MaterialStationStatus({
    required this.connected,
    required this.slots,
    this.activeSlotIndex,
  });

  factory MaterialStationStatus.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'] as List<dynamic>? ?? [];
    return MaterialStationStatus(
      connected: json['connected'] as bool? ?? false,
      slots: rawSlots.map((e) => MaterialSlot.fromJson(e as Map<String, dynamic>)).toList(),
      activeSlotIndex: (json['activeSlotIndex'] as num?)?.toInt(),
    );
  }
}

class ActiveSpoolData {
  final int id;
  final String name;
  final String? vendor;
  final String? material;
  final String colorHex;
  final double remainingWeight;
  final double remainingLength;

  const ActiveSpoolData({
    required this.id,
    required this.name,
    this.vendor,
    this.material,
    required this.colorHex,
    required this.remainingWeight,
    required this.remainingLength,
  });

  factory ActiveSpoolData.fromJson(Map<String, dynamic> json) {
    return ActiveSpoolData(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Spool',
      vendor: json['vendor'] as String?,
      material: json['material'] as String?,
      colorHex: json['colorHex'] as String? ?? '#00AE42',
      remainingWeight: (json['remainingWeight'] as num?)?.toDouble() ?? 0.0,
      remainingLength: (json['remainingLength'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
