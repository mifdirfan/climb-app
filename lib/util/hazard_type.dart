enum HazardType {
  looseRock(
    key: 'loose_rock',
    title: 'Loose Rock',
    subtitle: 'Chossy rock, detached flakes, or active rockfall zone',
    iconEmoji: '🪨',
    tag: 'HIGH RISK',
  ),
  wasps(
    key: 'wasps',
    title: 'Wasps & Wildlife',
    subtitle: 'Active wasp/bee nests, hornet swarms, or aggressive wildlife',
    iconEmoji: '🐝',
    tag: 'ACTIVE SIGHTING',
  ),
  badBolt(
    key: 'bad_bolt',
    title: 'Bad Bolt / Anchor',
    subtitle: 'Loose/spinning hanger, rusted bolt, or worn anchor chains',
    iconEmoji: '🔩',
    tag: 'EQUIPMENT',
  ),
  other(
    key: 'other',
    title: 'Other Danger',
    subtitle: 'Trail erosion, flash flood risk, fallen tree, or access issues',
    iconEmoji: '⚠️',
    tag: 'GENERAL',
  );

  final String key;
  final String title;
  final String subtitle;
  final String iconEmoji;
  final String tag;

  const HazardType({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.tag,
  });

  /// Parse from DB string (e.g. 'loose_rock')
  static HazardType fromDb(String value) {
    return HazardType.values.firstWhere(
      (e) => e.key == value,
      orElse: () => HazardType.other,
    );
  }
}