import 'package:attention_detector/games/outcome.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Оценка результатов', () {
    test('звёзды по очкам', () {
      expect(Scoring.stars(90), 3);
      expect(Scoring.stars(85), 3);
      expect(Scoring.stars(84), 2);
      expect(Scoring.stars(60), 2);
      expect(Scoring.stars(59), 1);
      expect(Scoring.stars(30), 1);
      expect(Scoring.stars(10), 0);
    });

    test('пары: идеальная игра без ошибок', () {
      final score = Scoring.match(pairs: 4, moves: 4, seconds: 10);
      expect(score, greaterThanOrEqualTo(95));
    });

    test('пары: лишние ходы снижают результат', () {
      final perfect = Scoring.match(pairs: 4, moves: 4, seconds: 10);
      final sloppy = Scoring.match(pairs: 4, moves: 10, seconds: 40);
      expect(sloppy, lessThan(perfect));
      expect(sloppy, greaterThanOrEqualTo(0));
    });

    test('лишний: ошибки уменьшают точность', () {
      final clean = Scoring.odd(rounds: 5, errors: 0, msPerRound: 1800);
      final messy = Scoring.odd(rounds: 5, errors: 3, msPerRound: 1800);
      expect(messy, lessThan(clean));
    });

    test('светлячки: обманки штрафуются', () {
      final clean = Scoring.firefly(targets: 8, caught: 8, decoys: 0);
      final decoyed = Scoring.firefly(targets: 8, caught: 8, decoys: 3);
      expect(decoyed, lessThan(clean));
    });

    test('мелодия и искры', () {
      expect(Scoring.simon(rounds: 5, cleared: 5), 100);
      expect(Scoring.simon(rounds: 5, cleared: 0), 0);
      expect(Scoring.count(correct: 5, rounds: 5, msPerRound: 1500), greaterThan(80));
      expect(Scoring.count(correct: 0, rounds: 5, msPerRound: 1500), lessThan(30));
    });

    test('очки не выходят за 0..100', () {
      expect(Scoring.match(pairs: 0, moves: 0, seconds: 0), 0);
      expect(Scoring.count(correct: 9, rounds: 5, msPerRound: 1000), 100);
    });
  });
}
