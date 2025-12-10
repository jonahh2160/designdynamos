import 'package:designdynamos/data/services/game_service.dart';
import 'package:designdynamos/features/games/models/game_info.dart';
import 'package:designdynamos/providers/coin_provider.dart';
import 'package:flutter/foundation.dart';

class GameProvider extends ChangeNotifier {
  GameProvider(this._service);

  final GameService _service;

  bool _loading = false;
  List<GameInfo> _games = const [];
  String? _error;
  final Set<String> _unlocking = {};
  final Set<String> _playing = {};

  bool get isLoading => _loading;
  List<GameInfo> get games => _games;
  String? get error => _error;

  bool isUnlocking(String gameIdOrSlug) => _unlocking.contains(gameIdOrSlug);

  bool isUnlockingGame(GameInfo game) =>
      isUnlocking(game.id) || isUnlocking(game.slug);

  bool isPlaying(String gameIdOrSlug) => _playing.contains(gameIdOrSlug);

  bool isPlayingGame(GameInfo game) =>
      isPlaying(game.id) || isPlaying(game.slug);

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _games = await _service.fetchGames();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<GameInfo?> unlock(GameInfo game, CoinProvider coinProvider) async {
    if (_unlocking.contains(game.id) || _unlocking.contains(game.slug)) {
      return null;
    }

    _unlocking.add(game.id);
    _unlocking.add(game.slug);
    _error = null;
    notifyListeners();

    try {
      final result = await _service.unlockGame(game);
      coinProvider.updateBalance(result.balance);

      _games = _games.map((g) {
        if (g.id == game.id || g.slug == game.slug) {
          return result.game;
        }
        return g;
      }).toList();
      return result.game;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _unlocking.remove(game.id);
      _unlocking.remove(game.slug);
      notifyListeners();
    }
  }

  Future<void> play(GameInfo game, CoinProvider coinProvider) async {
    if (_playing.contains(game.id) || _playing.contains(game.slug)) {
      return;
    }

    _playing.add(game.id);
    _playing.add(game.slug);
    _error = null;
    notifyListeners();

    try {
      final balance = await _service.playGame(game);
      coinProvider.updateBalance(balance);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _playing.remove(game.id);
      _playing.remove(game.slug);
      notifyListeners();
    }
  }
}
