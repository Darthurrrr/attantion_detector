import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/palette.dart';
import '../widgets/game_ui.dart';
import 'outcome.dart';

/// «Повтори мелодию»: кристаллы вспыхивают по порядку, игрок повторяет.
class SimonGame extends StatefulWidget {
  const SimonGame({
    super.key,
    required this.sequence,
    required this.onFinish,
    required this.onSound,
  });

  final int sequence;
  final void Function(GameOutcome outcome) onFinish;
  final void Function(String sound) onSound;

  @override
  State<SimonGame> createState() => _SimonGameState();
}

class _SimonGameState extends State<SimonGame> {
  static const _colors = [
    Color(0xFFFF8FBE),
    Color(0xFF7FD8FF),
    Color(0xFFFFD766),
    Color(0xFF8EF0C0),
  ];
  static const _labels = ['Роза', 'Небо', 'Золото', 'Мята'];

  final _rand = math.Random();
  final List<int> _sequence = [];
  final List<int> _input = [];
  int _active = -1;
  bool _showing = false;
  bool _accepting = false;
  int _round = 0;
  int _cleared = 0;
  int _best = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sequence.add(_rand.nextInt(4));
    _playSequence();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _flash(int index, {int duration = 420}) async {
    setState(() => _active = index);
    widget.onSound('tap');
    await Future<void>.delayed(Duration(milliseconds: duration ~/ 2));
    if (!mounted) return;
    setState(() => _active = -1);
    await Future<void>.delayed(Duration(milliseconds: duration ~/ 2));
  }

  Future<void> _playSequence() async {
    setState(() {
      _showing = true;
      _accepting = false;
      _input.clear();
    });
    await Future<void>.delayed(const Duration(milliseconds: 420));
    for (final index in _sequence) {
      if (!mounted) return;
      await _flash(index);
    }
    if (!mounted) return;
    setState(() {
      _showing = false;
      _accepting = true;
    });
  }

  void _tap(int index) {
    if (!_accepting) return;
    // Игрок отвечает ровно столько раз, сколько сигналов запомнил.
    if (_input.length >= _sequence.length) return;
    _input.add(index);
    _flash(index, duration: 220);
    final position = _input.length - 1;
    if (_sequence[position] != index) {
      _accepting = false;
      widget.onSound('error');
      _timer = Timer(const Duration(milliseconds: 520), _fail);
      return;
    }
    if (_input.length == _sequence.length) {
      _accepting = false;
      _cleared = _sequence.length;
      _best = math.max(_best, _cleared);
      if (_sequence.length >= widget.sequence) {
        _timer = Timer(const Duration(milliseconds: 520), _win);
        return;
      }
      _timer = Timer(const Duration(milliseconds: 620), () {
        if (!mounted) return;
        setState(() {
          _round++;
          _sequence.add(_rand.nextInt(4));
        });
        widget.onSound('crystal');
        _playSequence();
      });
    }
  }

  void _fail() {
    final score = Scoring.simon(rounds: widget.sequence, cleared: _best);
    widget.onFinish(GameOutcome(
      score: score,
      stars: Scoring.stars(score),
      errors: 1,
      moves: _round + 1,
      details: {'cleared': _best},
    ));
  }

  void _win() {
    final score = Scoring.simon(rounds: widget.sequence, cleared: widget.sequence);
    widget.onFinish(GameOutcome(score: score, stars: Scoring.stars(score), moves: _round + 1));
  }

  @override
  Widget build(BuildContext context) {
    final status = _showing
        ? 'Смотрите и запоминайте'
        : _accepting
            ? 'Повторите последовательность'
            : 'Пауза…';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.violet.withOpacity(0.6)),
                ),
                child: Text('Сигналов: ${_sequence.length}/${widget.sequence}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Expanded(child: ProgressBar(value: _sequence.length / widget.sequence, height: 9)),
              const SizedBox(width: 8),
              Text(_showing ? 'Смотрим' : 'Повторяем', style: AppText.tiny),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final side = math.min(constraints.maxWidth, constraints.maxHeight) * 0.92;
                final pad = side * 0.06;
                return SizedBox(
                  width: side,
                  height: side,
                  child: Column(
                    children: [
                      Text(status, style: AppText.h2),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(pad * 0.4),
                                  child: GestureDetector(
                                    onTap: () => _tap(i),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 120),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color.lerp(_colors[i], Colors.white, _active == i ? 0.55 : 0.1)!,
                                            _colors[i],
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: _active == i ? Colors.white : Colors.white.withOpacity(0.35),
                                          width: _active == i ? 3 : 1.4,
                                        ),
                                        boxShadow: [
                                          if (_active == i)
                                            BoxShadow(
                                              color: _colors[i].withOpacity(0.9),
                                              blurRadius: 26,
                                              spreadRadius: 4,
                                            ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.diamond_rounded, size: side * 0.09, color: Colors.white.withOpacity(0.9)),
                                          const SizedBox(height: 4),
                                          Text(
                                            _labels[i],
                                            style: TextStyle(
                                              fontSize: side * 0.038,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (_showing)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Сейчас мелодию играет лес. Не нажимайте раньше времени.', style: AppText.tiny),
          ),
      ],
    );
  }
}
