import 'dart:math' as math;

/// Итог мини-игры: клиент сообщает только наблюдаемые показатели,
/// награды и опыт считает сервер.
class GameOutcome {
  const GameOutcome({
    required this.score,
    required this.stars,
    this.pairs = 0,
    this.moves = 0,
    this.errors = 0,
    this.details = const {},
  });

  final int score;
  final int stars;
  final int pairs;
  final int moves;
  final int errors;
  final Map<String, num> details;
}

/// Общие формулы оценки — зеркало серверных правил для мгновенного фидбэка.
/// Награды всё равно выдаёт сервер.
class Scoring {
  static int stars(int score) => score >= 85 ? 3 : score >= 60 ? 2 : score >= 30 ? 1 : 0;

  static int clamp100(num value) => value.round().clamp(0, 100).toInt();

  /// Пары: эффективность ходов + скорость.
  static int match({required int pairs, required int moves, required int seconds}) {
    if (pairs == 0) return 0;
    final efficiency = math.min(1.0, pairs / math.max(moves, pairs));
    final speed = (1 - math.max(0.0, seconds - pairs * 3.0) / (pairs * 7.0)).clamp(0.0, 1.0).toDouble();
    return clamp100(100 * (0.8 * efficiency + 0.2 * speed));
  }

  /// Поиск лишнего: точность и скорость реакции.
  static int odd({required int rounds, required int errors, required int msPerRound}) {
    final accuracy = (rounds - errors).clamp(0, rounds).toInt() / rounds;
    final speed = (1 - (msPerRound - 1600) / 5200).clamp(0.0, 1.0).toDouble();
    return clamp100(100 * (0.75 * accuracy + 0.25 * speed));
  }

  /// Светлячки: сколько целей поймано из нужного числа.
  static int firefly({required int targets, required int caught, required int decoys}) {
    final accuracy = (caught / targets).clamp(0.0, 1.0).toDouble();
    final purity = decoys == 0 ? 1.0 : (1 - decoys / (caught + decoys + 2)).clamp(0.0, 1.0).toDouble();
    return clamp100(100 * (0.8 * accuracy + 0.2 * purity));
  }

  /// Мелодия: длина верно повторённой последовательности.
  static int simon({required int rounds, required int cleared}) {
    if (rounds == 0) return 0;
    return clamp100(100 * (cleared / rounds));
  }

  /// Искры: точность ответов и скорость.
  static int count({required int correct, required int rounds, required int msPerRound}) {
    if (rounds == 0) return 0;
    final accuracy = correct / rounds;
    final speed = (1 - (msPerRound - 1500) / 4000).clamp(0.0, 1.0).toDouble();
    return clamp100(100 * (0.85 * accuracy + 0.15 * speed));
  }
}
