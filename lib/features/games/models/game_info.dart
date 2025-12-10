class GameInfo {
  const GameInfo({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.coinCost,
    this.thumbnailUrl,
    this.assetPath,
    this.isFeatured = false,
    this.isPlayable = false,
    this.isUnlocked = false,
    this.unlockable = true,
    this.ctaLabel = 'Play',
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final int coinCost;
  final String? thumbnailUrl;
  final String? assetPath;
  final bool isFeatured;
  final bool isPlayable;
  final bool isUnlocked;
  final bool unlockable;
  final String ctaLabel;

  GameInfo copyWith({
    String? id,
    String? slug,
    String? title,
    String? description,
    int? coinCost,
    String? thumbnailUrl,
    String? assetPath,
    bool? isFeatured,
    bool? isPlayable,
    bool? isUnlocked,
    bool? unlockable,
    String? ctaLabel,
  }) {
    return GameInfo(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      description: description ?? this.description,
      coinCost: coinCost ?? this.coinCost,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      assetPath: assetPath ?? this.assetPath,
      isFeatured: isFeatured ?? this.isFeatured,
      isPlayable: isPlayable ?? this.isPlayable,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockable: unlockable ?? this.unlockable,
      ctaLabel: ctaLabel ?? this.ctaLabel,
    );
  }
}
