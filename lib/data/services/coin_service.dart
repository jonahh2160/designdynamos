import 'package:supabase_flutter/supabase_flutter.dart';

class CoinBalance {
  const CoinBalance({required this.totalCoins, required this.todayCoins});

  final int totalCoins;
  final int todayCoins;
}

class CoinService {
  CoinService(this._client);

  final SupabaseClient _client;

  Future<CoinBalance> fetchBalance() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return const CoinBalance(totalCoins: 0, todayCoins: 0);
    }

    final response = await _client.rpc('get_coin_balance');

    Map<String, dynamic>? row;
    if (response is Map<String, dynamic>) {
      row = response;
    } else if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        row = first;
      }
    }

    if (row == null) {
      return const CoinBalance(totalCoins: 0, todayCoins: 0);
    }

    final rawTotal = (row['total_coins'] ?? 0) as int;
    final rawToday = (row['today_coins'] ?? 0) as int;

    final balance = CoinBalance(
      totalCoins: rawTotal < 0 ? 0 : rawTotal,
      todayCoins: rawToday,
    );

    //Keep the denormalized profile.coins in sync for leaderboard/UI.
    await syncProfileCoins(balance.totalCoins);
    return balance;
  }

  Future<void> syncProfileCoins(int coins) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final clamped = coins < 0 ? 0 : coins;

    try {
      await _client
          .from('profiles')
          .update({'coins': clamped}).eq('id', userId);
    } catch (_) {
      //Swallow errors so coin display doesn't break.
    }
  }
}
