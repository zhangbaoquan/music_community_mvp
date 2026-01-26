class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String conditionType;
  final int threshold;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.conditionType,
    required this.threshold,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      iconUrl: map['icon_url'] ?? '',
      conditionType: map['condition_type'],
      threshold: map['threshold'],
    );
  }
}
