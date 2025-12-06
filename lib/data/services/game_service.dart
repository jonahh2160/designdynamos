import 'package:designdynamos/data/services/coin_service.dart';
import 'package:designdynamos/features/games/models/game_info.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameService {
  GameService(this._client, {CoinService? coinService})
    : _coinService = coinService ?? CoinService(_client);

  final SupabaseClient _client;
  final CoinService _coinService;

  static const _localMeta = <String, _LocalGameMeta>{
    'dumb_race': _LocalGameMeta(
      title: 'Dumb Race',
      description: 'Quick-tap sprint with cartoon chaos.',
      assetPath: 'assets/images/games/dumb_race.png',
      coinCost: 750,
      isFeatured: true,
      isPlayable: true,
      ctaLabel: 'Race',
    ),
    'space_runner': _LocalGameMeta(
      title: 'Space Runner',
      description: 'Hyperspeed dash through neon space lanes.',
      assetPath: 'assets/images/games/space_runner.png',
      coinCost: 250,
      ctaLabel: 'Boost',
    ),
    'pixel_adventure': _LocalGameMeta(
      title: 'Pixel Adventure',
      description: 'Loading...',
      assetPath: 'assets/images/games/pixel_level.jpg',
      coinCost: 0,
      isFeatured: true,
      isPlayable: true,
      unlockable: false,
    ),
  };

  static const _seedGames = [
    {'slug': 'dumb_race', 'title': 'Dumb Race', 'coin_cost': 750},
    {'slug': 'space_runner', 'title': 'Space Runner', 'coin_cost': 250},
  ];

  Future<List<GameInfo>> fetchGames() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return _localFallback();
    }

    var rows = await _fetchRawGames();
    if (rows.isEmpty) {
      await _seedDefaultsIfMissing();
      rows = await _fetchRawGames();
    }

    if (rows.isEmpty) {
      return _localFallback();
    }

    final mapped = rows.map((row) => _mapGame(row, userId)).toList();
    const pinnedSlug = 'pixel_adventure';
    if (_localMeta.containsKey(pinnedSlug) &&
        !mapped.any((game) => game.slug == pinnedSlug)) {
      mapped.add(_buildLocalMetaGame(pinnedSlug));
    }
    return mapped;
  }

  Future<GameUnlockResult> unlockGame(GameInfo game) async {
    if (!game.unlockable) {
      return GameUnlockResult(
        game: game.copyWith(isUnlocked: true),
        balance: await _coinService.fetchBalance(),
      );
    }

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('You need to be signed in to unlock games.');
    }

    if (game.isUnlocked) {
      return GameUnlockResult(
        game: game,
        balance: await _coinService.fetchBalance(),
      );
    }

    final balance = await _coinService.fetchBalance();
    if (balance.totalCoins < game.coinCost) {
      throw StateError('Not enough coins to unlock ${game.title}.');
    }

    final ensured = await _ensureGameRecord(game);
    final gameId = (ensured['id'] as String?) ?? game.id;
    final cleanedTitle =
        (ensured['title'] as String?)?.trim().isNotEmpty == true
        ? ensured['title'] as String
        : game.title;

    await _client.from('coin_transactions').insert({
      'user_id': userId,
      'amount': -game.coinCost,
      'reason': 'Unlocked $cleanedTitle',
      'kind': 'task_uncomplete',
    });

    await _client.from('user_games').upsert({
      'user_id': userId,
      'game_id': gameId,
    }, onConflict: 'user_id,game_id');

    final updatedBalance = await _coinService.fetchBalance();
    return GameUnlockResult(
      game: game.copyWith(
        id: gameId,
        title: cleanedTitle,
        coinCost: _parseCost(ensured['coin_cost'], game.coinCost),
        isUnlocked: true,
      ),
      balance: updatedBalance,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRawGames() async {
    final List<dynamic> response = await _client
        .from('games')
        .select(
          'id, slug, title, thumbnail_url, coin_cost, user_games(user_id)',
        )
        .order('created_at');

    return response.cast<Map<String, dynamic>>();
  }

  Future<void> _seedDefaultsIfMissing() async {
    await _client.from('games').upsert(_seedGames, onConflict: 'slug');
  }

  Future<Map<String, dynamic>> _ensureGameRecord(GameInfo game) async {
    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidPattern.hasMatch(game.id)) {
      return {
        'id': game.id,
        'slug': game.slug,
        'title': game.title,
        'coin_cost': game.coinCost,
      };
    }

    final payload = {
      'slug': game.slug,
      'title': game.title,
      'coin_cost': game.coinCost,
      if (game.thumbnailUrl != null && game.thumbnailUrl!.isNotEmpty)
        'thumbnail_url': game.thumbnailUrl,
    };

    final Map<String, dynamic> upserted = await _client
        .from('games')
        .upsert(payload, onConflict: 'slug')
        .select('id, slug, title, thumbnail_url, coin_cost')
        .single();

    return upserted;
  }

  List<GameInfo> _localFallback() {
    final entries = [
      ..._seedGames,
      {'slug': 'pixel_adventure'},
    ];

    return entries.map((row) {
      final slug = row['slug'] as String;
      final meta = _localMeta[slug];
      final coinCost = _parseCost(row['coin_cost'], meta?.coinCost ?? 0);

      return GameInfo(
        id: slug,
        slug: slug,
        title: (row['title'] as String?) ?? meta?.title ?? slug,
        description: meta?.description ?? 'Mini game',
        coinCost: coinCost,
        assetPath: meta?.assetPath,
        isFeatured: meta?.isFeatured ?? false,
        isPlayable: meta?.isPlayable ?? false,
        isUnlocked: !(meta?.unlockable ?? true),
        unlockable: meta?.unlockable ?? true,
        ctaLabel: meta?.ctaLabel ?? 'Play',
      );
    }).toList();
  }

  GameInfo _mapGame(Map<String, dynamic> row, String userId) {
    final slug = (row['slug'] as String? ?? '').trim();
    final meta = _localMeta[slug];
    final coinCost = _parseCost(row['coin_cost'], meta?.coinCost ?? 0);
    final rawUserGames = row['user_games'];
    final unlocked = _isUnlockedByUser(rawUserGames, userId);
    final unlockable = meta?.unlockable ?? true;

    return GameInfo(
      id: (row['id'] as String? ?? slug).trim(),
      slug: slug.isNotEmpty ? slug : (row['id'] as String? ?? slug),
      title: (row['title'] as String?) ?? meta?.title ?? 'Untitled game',
      description: meta?.description ?? 'Mini game',
      coinCost: coinCost,
      thumbnailUrl: row['thumbnail_url'] as String?,
      assetPath: meta?.assetPath,
      isFeatured: meta?.isFeatured ?? false,
      isPlayable: meta?.isPlayable ?? false,
      isUnlocked: unlockable ? unlocked : true,
      unlockable: unlockable,
      ctaLabel: meta?.ctaLabel ?? 'Play',
    );
  }

  bool _isUnlockedByUser(dynamic rawUserGames, String userId) {
    if (rawUserGames is List) {
      return rawUserGames.any(
        (row) => row is Map<String, dynamic> && row['user_id'] == userId,
      );
    }
    if (rawUserGames is Map<String, dynamic>) {
      return rawUserGames['user_id'] == userId;
    }
    return false;
  }

  int _parseCost(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  GameInfo _buildLocalMetaGame(String slug) {
    final meta = _localMeta[slug];
    if (meta == null) {
      return GameInfo(
        id: slug,
        slug: slug,
        title: slug,
        description: 'Mini game',
        coinCost: 0,
        isUnlocked: true,
        unlockable: false,
      );
    }

    return GameInfo(
      id: slug,
      slug: slug,
      title: meta.title ?? slug,
      description: meta.description,
      coinCost: meta.coinCost ?? 0,
      assetPath: meta.assetPath,
      isFeatured: meta.isFeatured,
      isPlayable: meta.isPlayable,
      isUnlocked: !meta.unlockable,
      unlockable: meta.unlockable,
      ctaLabel: meta.ctaLabel,
    );
  }
}

class GameUnlockResult {
  const GameUnlockResult({required this.game, required this.balance});

  final GameInfo game;
  final CoinBalance balance;
}

class _LocalGameMeta {
  const _LocalGameMeta({
    required this.description,
    required this.assetPath,
    this.title,
    this.coinCost,
    this.isFeatured = false,
    this.isPlayable = false,
    this.unlockable = true,
    this.ctaLabel = 'Play',
  });

  final String? title;
  final String description;
  final String assetPath;
  final int? coinCost;
  final bool isFeatured;
  final bool isPlayable;
  final bool unlockable;
  final String ctaLabel;
}
