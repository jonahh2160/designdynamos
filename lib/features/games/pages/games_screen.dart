import 'package:designdynamos/core/theme/app_colors.dart';
import 'package:designdynamos/features/games/models/game_info.dart';
import 'package:designdynamos/features/games/pages/pixel_adventure_screen.dart';
import 'package:designdynamos/providers/coin_provider.dart';
import 'package:designdynamos/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coinsProvider = context.watch<CoinProvider>();
    final gameProvider = context.watch<GameProvider>();
    final games = gameProvider.games;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final coinProvider = context.read<CoinProvider>();
            final gamesProvider = context.read<GameProvider>();
            await coinProvider.refresh();
            await gamesProvider.refresh();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GamesHeader(progress: 0.62, coins: coinsProvider.totalCoins),
                const SizedBox(height: 24),
                if (gameProvider.error != null)
                  _ErrorBanner(message: gameProvider.error!),
                if (gameProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (!gameProvider.isLoading && games.isEmpty)
                  _EmptyState(onRefresh: () => gameProvider.refresh()),
                if (games.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 1280
                          ? 3
                          : width >= 880
                          ? 2
                          : 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: games.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 1.45,
                        ),
                        itemBuilder: (context, index) {
                          final game = games[index];
                          return GameCard(
                            game: game,
                            userCoins: coinsProvider.totalCoins,
                            isUnlocking: gameProvider.isUnlockingGame(game),
                            isPlaying: gameProvider.isPlayingGame(game),
                            onUnlock: () => _handleUnlock(context, game),
                            onPlay: () => _handlePlay(context, game),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleUnlock(BuildContext context, GameInfo game) async {
    final gameProvider = context.read<GameProvider>();
    final coinProvider = context.read<CoinProvider>();

    try {
      await gameProvider.unlock(game, coinProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${game.title} unlocked!')));
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().replaceFirst('StateError: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _handlePlay(BuildContext context, GameInfo game) async {
    final gameProvider = context.read<GameProvider>();
    final coinProvider = context.read<CoinProvider>();

    try {
      await gameProvider.play(game, coinProvider);
      if (!context.mounted) return;

      if (game.slug.trim() == 'pixel_adventure') {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PixelAdventureScreen()),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${game.title} is launching soon.')));
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = e.toString().replaceFirst('StateError: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _GamesHeader extends StatelessWidget {
  const _GamesHeader({required this.progress, required this.coins});

  final double progress;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.sidebarActive.withOpacity(0.6),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 14,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      backgroundColor: AppColors.progressTrack.withOpacity(0.7),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.taskCardHighlight,
                      ),
                      minHeight: 14,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'XP until next reward',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _CoinPill(coins: coins),
      ],
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sidebarActive.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(coins.toString(), style: textStyle),
          const SizedBox(width: 6),
          const Icon(Icons.monetization_on, color: AppColors.accent),
        ],
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.userCoins,
    required this.isUnlocking,
    required this.isPlaying,
    required this.onUnlock,
    required this.onPlay,
  });

  final GameInfo game;
  final int userCoins;
  final bool isUnlocking;
  final bool isPlaying;
  final VoidCallback onUnlock;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isAlwaysAvailable = !game.unlockable;
    final isUnlocked = game.isUnlocked || isAlwaysAvailable;
    final showUnlock = game.unlockable && !isUnlocked;
    final canAfford = userCoins >= game.coinCost;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.detailCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: game.isFeatured
              ? AppColors.taskCardHighlight.withOpacity(0.9)
              : AppColors.sidebarActive.withOpacity(0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned.fill(child: _GameThumbnail(game: game)),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _CoinBadge(cost: game.coinCost),
                  ),
                  if (isUnlocked)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusChip(
                        label: isAlwaysAvailable
                            ? 'Always available'
                            : 'Unlocked',
                      ),
                    ),
                  if (showUnlock && !canAfford)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 62,
                      child: Text(
                        'Earn ${game.coinCost - userCoins} more coins to unlock',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: _ActionButton(
                      label: isUnlocked
                          ? game.ctaLabel
                          : 'Unlock for ${game.coinCost}',
                      loading: isUnlocking || isPlaying,
                      enabled: isUnlocked || (showUnlock && canAfford),
                      secondary: showUnlock && !canAfford,
                      onPressed: isUnlocked ? onPlay : onUnlock,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            game.title.toUpperCase(),
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            game.description,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.cost});

  final int cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cost.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.monetization_on, color: AppColors.accent, size: 18),
        ],
      ),
    );
  }
}

class _GameThumbnail extends StatelessWidget {
  const _GameThumbnail({required this.game});

  final GameInfo game;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Text(
        'Mini game',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (game.assetPath != null && game.assetPath!.isNotEmpty) {
      return Image.asset(
        game.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    if (game.thumbnailUrl != null && game.thumbnailUrl!.isNotEmpty) {
      return Image.network(
        game.thumbnailUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return placeholder;
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.loading = false,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = secondary
        ? AppColors.surface
        : AppColors.taskCardHighlight;
    final foregroundColor = secondary ? AppColors.textPrimary : Colors.black;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? backgroundColor : AppColors.sidebarActive,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      onPressed: enabled && !loading ? onPressed : null,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(label),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sidebarActive.withOpacity(0.8)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<GameProvider>().refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sidebarActive.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.videogame_asset_rounded,
            size: 38,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No games yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull to refresh to load the latest mini-games.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}
