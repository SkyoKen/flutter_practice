import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

enum _RushResultKind { success, miss, timeout }

class KitchenRushPanel extends StatefulWidget {
  final Restaurant restaurant;
  final List<Food> menu;

  const KitchenRushPanel({
    super.key,
    required this.restaurant,
    required this.menu,
  });

  @override
  State<KitchenRushPanel> createState() => _KitchenRushPanelState();
}

class _KitchenRushPanelState extends State<KitchenRushPanel> {
  int _combo = 0;
  int? _lastChoiceId;
  bool? _lastChoiceCorrect;
  String? _lastResultText;
  _RushResultKind? _lastResultKind;
  bool _handlingTimeout = false;

  double _comboMultiplier(int combo) {
    final cappedCombo = combo.clamp(0, 8);
    return 1 + cappedCombo * 0.08;
  }

  double _speedMultiplier(double patienceRatio) {
    if (patienceRatio >= 0.72) return 1.15;
    if (patienceRatio >= 0.44) return 1.06;
    return 1;
  }

  String _formatMultiplier(double multiplier) {
    return 'x${multiplier.toStringAsFixed(2)}';
  }

  Food? _activeFood(GameController game) {
    final foodId = game.customerOrderFoodId;
    if (foodId == null) return null;
    for (final food in widget.menu) {
      if (food.id == foodId) return food;
    }
    return null;
  }

  List<Food> _choicePool(Food activeFood, GameController game) {
    final unlockedMenu = widget.menu
        .where(
            (food) => game.isFoodUnlocked(food.id) || food.id == activeFood.id)
        .toList();
    final wrongChoices = unlockedMenu
        .where((food) => food.id != activeFood.id)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final choices = <Food>[activeFood, ...wrongChoices.take(2)];
    if (choices.length <= 1) return choices;
    final shift = game.customerOrdersServed % choices.length;
    return [
      ...choices.skip(shift),
      ...choices.take(shift),
    ];
  }

  String _formatSeconds(Duration duration) {
    var seconds = duration.inSeconds;
    if (duration.inMilliseconds % 1000 != 0) seconds += 1;
    if (seconds < 1) seconds = 1;
    return '${seconds}s';
  }

  Future<void> _seatCustomer(BuildContext context, GameController game) async {
    final seated = await game.ensureCustomerOrder(
      widget.menu.map((food) => food.id).toList(),
    );
    if (!context.mounted || seated) return;
    final theme = AppTheme.of(context);
    final remaining = game.customerArrivalRemaining(DateTime.now());
    final message = remaining > Duration.zero
        ? '${widget.restaurant.translate('idle_next_customer_in')} ${_formatSeconds(remaining)}'
        : widget.restaurant.translate('rush_waiting_table');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.surfaceHigh,
        content: Text(
          message,
          style: TextStyle(
            color: theme.ink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _queueTimeout(BuildContext context, GameController game) {
    if (_handlingTimeout) return;
    _handlingTimeout = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final missed = await game.missCustomerOrder();
      if (!mounted) return;
      setState(() {
        if (missed) {
          _combo = 0;
          _lastChoiceId = null;
          _lastChoiceCorrect = null;
          _lastResultText = widget.restaurant.translate('rush_timeout');
          _lastResultKind = _RushResultKind.timeout;
        }
        _handlingTimeout = false;
      });
    });
  }

  Future<void> _chooseDish(
    BuildContext context,
    GameController game,
    Food choice,
    Food activeFood,
  ) async {
    final isCorrect = choice.id == activeFood.id;
    setState(() {
      _lastChoiceId = choice.id;
      _lastChoiceCorrect = isCorrect;
      if (!isCorrect) {
        _combo = 0;
        _lastResultText = widget.restaurant.translate('rush_wrong');
        _lastResultKind = _RushResultKind.miss;
      }
    });

    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;

    if (!isCorrect) {
      await game.recordWrongDish();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.danger,
          content: Text(
            widget.restaurant.translate('rush_wrong'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    final nextCombo = _combo + 1;
    final newBestCombo = nextCombo > game.bestCombo;
    final patienceRatio = game.customerPatienceRatio(DateTime.now());
    final speedMultiplier = _speedMultiplier(patienceRatio);
    final multiplier = _comboMultiplier(nextCombo) * speedMultiplier;
    final reward = await game.serveCustomerOrder(
      widget.menu.map((food) => food.id).toList(),
      rewardMultiplier: multiplier,
      combo: nextCombo,
    );
    if (!context.mounted || reward <= 0) return;

    setState(() {
      _combo = nextCombo;
      _lastChoiceId = null;
      _lastChoiceCorrect = null;
      _lastResultText = newBestCombo
          ? '${widget.restaurant.translate('rush_new_best')} x$nextCombo'
          : '${widget.restaurant.translate('rush_correct')} '
              '${_formatMultiplier(multiplier)} / '
              '${widget.restaurant.translate('rush_mastery')} +1';
      _lastResultKind = _RushResultKind.success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isTerminal ? theme.cyan : theme.accent,
        content: Text(
          '${widget.restaurant.translate('rush_correct')} '
          '+${game.formatCoins(reward)} / '
          '${widget.restaurant.translate('rush_mastery')} +1',
          style: TextStyle(
            color: isTerminal ? Colors.black : theme.ink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    if (game.shiftReadyToFinish && context.mounted) {
      final summary = await game.finishShift();
      if (context.mounted && summary.hasActivity) {
        setState(() {
          _combo = 0;
        });
        _showShiftSummary(context, summary);
      }
    }
  }

  void _showShiftSummary(BuildContext context, ShiftSummary summary) {
    final game = context.read<GameController>();
    showDialog(
      context: context,
      builder: (context) {
        return ThemedAppDialog(
          title: widget.restaurant.translate('shift_summary_title'),
          icon: Icons.fact_check,
          maxWidth: 420,
          actions: [
            ThemedDialogButton(
              label: widget.restaurant.translate('close'),
              primary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShiftSummaryRow(
                icon: Icons.room_service,
                label: widget.restaurant.translate('shift_orders'),
                value: '${summary.ordersServed}',
              ),
              const SizedBox(height: 8),
              _ShiftSummaryRow(
                icon: Icons.error_outline,
                label: widget.restaurant.translate('shift_missed'),
                value: '${summary.missedOrders}',
              ),
              const SizedBox(height: 8),
              _ShiftSummaryRow(
                icon: Icons.local_fire_department,
                label: widget.restaurant.translate('shift_best_combo'),
                value: 'x${summary.bestCombo}',
              ),
              const SizedBox(height: 8),
              _ShiftSummaryRow(
                icon: Icons.toll,
                label: widget.restaurant.translate('shift_earned'),
                value: '+${game.formatCoins(summary.coinsEarned)}',
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        return StreamBuilder<int>(
          stream: Stream.periodic(const Duration(seconds: 1), (tick) => tick),
          builder: (context, snapshot) {
            final activeFood = _activeFood(game);
            final now = DateTime.now();
            final expired =
                activeFood != null && game.customerOrderExpired(now);
            if (expired) {
              _queueTimeout(context, game);
            }
            final manualCustomer = game.manualDiningCustomer;
            final remaining = game.customerArrivalRemaining(now);
            final waiting = activeFood == null &&
                manualCustomer == null &&
                remaining > Duration.zero;

            return _KitchenRushFrame(
              combo: _combo,
              bestCombo: game.bestCombo,
              bonusLabel: _formatMultiplier(_comboMultiplier(_combo + 1)),
              resultText: _lastResultText,
              resultKind: _lastResultKind,
              restaurant: widget.restaurant,
              child: expired
                  ? _buildTimedOut(context)
                  : activeFood != null
                      ? _buildQuestion(context, game, activeFood)
                      : manualCustomer != null
                          ? _buildManualStatus(context, game, manualCustomer)
                          : waiting
                              ? _buildWaiting(context, remaining)
                              : _buildReady(context, game),
            );
          },
        );
      },
    );
  }

  Widget _buildReady(BuildContext context, GameController game) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PromptLine(
          icon: Icons.sensor_door,
          title: widget.restaurant.translate('rush_ready_title'),
          body: widget.restaurant.translate('rush_ready_body'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _seatCustomer(context, game),
            style: ElevatedButton.styleFrom(
              backgroundColor: isTerminal ? theme.cyan : theme.accent,
              foregroundColor: isTerminal ? Colors.black : theme.ink,
              side: BorderSide(
                color: isTerminal ? theme.cyan : theme.border,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                ),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: Text(
              widget.restaurant.translate('rush_start'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaiting(BuildContext context, Duration remaining) {
    return _PromptLine(
      icon: Icons.hourglass_bottom,
      title: widget.restaurant.translate('rush_waiting_title'),
      body:
          '${widget.restaurant.translate('idle_next_customer_in')} ${_formatSeconds(remaining)}',
    );
  }

  Widget _buildManualStatus(
    BuildContext context,
    GameController game,
    GameDiningCustomer customer,
  ) {
    final now = DateTime.now();
    final remaining = game.diningCustomerPhaseRemaining(customer, now);
    final body = _manualStatusBody(customer, remaining);

    return _PromptLine(
      icon: _manualStatusIcon(customer.phase),
      title: _manualStatusTitle(customer.phase),
      body: body,
    );
  }

  Widget _buildTimedOut(BuildContext context) {
    return _PromptLine(
      icon: Icons.person_off,
      title: widget.restaurant.translate('rush_customer_left'),
      body: widget.restaurant.translate('rush_try_next'),
    );
  }

  IconData _manualStatusIcon(GameDiningCustomerPhase phase) {
    return switch (phase) {
      GameDiningCustomerPhase.queueing ||
      GameDiningCustomerPhase.seating =>
        Icons.directions_walk,
      GameDiningCustomerPhase.waitingForFood => Icons.receipt_long,
      GameDiningCustomerPhase.servingFood => Icons.room_service,
      GameDiningCustomerPhase.eating => Icons.local_dining,
      GameDiningCustomerPhase.checkout => Icons.point_of_sale,
      GameDiningCustomerPhase.leaving => Icons.logout,
    };
  }

  String _manualStatusTitle(GameDiningCustomerPhase phase) {
    return switch (phase) {
      GameDiningCustomerPhase.queueing ||
      GameDiningCustomerPhase.seating =>
        widget.restaurant.translate('rush_seating_title'),
      GameDiningCustomerPhase.waitingForFood =>
        widget.restaurant.translate('rush_order_label'),
      GameDiningCustomerPhase.servingFood =>
        widget.restaurant.translate('rush_serving_title'),
      GameDiningCustomerPhase.eating =>
        widget.restaurant.translate('rush_eating_title'),
      GameDiningCustomerPhase.checkout =>
        widget.restaurant.translate('rush_checkout_title'),
      GameDiningCustomerPhase.leaving =>
        widget.restaurant.translate('rush_leaving_title'),
    };
  }

  String _manualStatusBody(GameDiningCustomer customer, Duration remaining) {
    final countdown =
        remaining > Duration.zero ? ' ${_formatSeconds(remaining)}' : '';
    return switch (customer.phase) {
      GameDiningCustomerPhase.queueing ||
      GameDiningCustomerPhase.seating =>
        widget.restaurant.translate('rush_seating_body'),
      GameDiningCustomerPhase.waitingForFood =>
        widget.restaurant.translate('rush_choose_dish'),
      GameDiningCustomerPhase.servingFood =>
        widget.restaurant.translate('rush_serving_body'),
      GameDiningCustomerPhase.eating =>
        '${widget.restaurant.translate('rush_eating_body')}$countdown',
      GameDiningCustomerPhase.checkout =>
        '${widget.restaurant.translate('rush_checkout_body')}$countdown',
      GameDiningCustomerPhase.leaving =>
        widget.restaurant.translate('rush_leaving_body'),
    };
  }

  Widget _buildQuestion(
    BuildContext context,
    GameController game,
    Food activeFood,
  ) {
    final theme = AppTheme.of(context);
    final now = DateTime.now();
    final choices = _choicePool(activeFood, game);
    final nextMultiplier = _comboMultiplier(_combo + 1);
    final patienceRatio = game.customerPatienceRatio(now);
    final patienceRemaining = game.customerPatienceRemaining(now);
    final patienceColor = patienceRatio <= 0.28 ? theme.danger : theme.accent;
    final speedMultiplier = _speedMultiplier(patienceRatio);
    final totalMultiplier = nextMultiplier * speedMultiplier;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.surfaceHigh,
            borderRadius: BorderRadius.circular(
              AppTheme.activeMode == AppThemeMode.neoBrutalism
                  ? theme.radius
                  : 0,
            ),
            border: Border.all(
              color: AppTheme.activeMode == AppThemeMode.neonTerminal
                  ? theme.cyan
                  : theme.border,
              width: AppTheme.activeMode == AppThemeMode.neoBrutalism ? 3 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: theme.accent, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.restaurant.translate('rush_order_label')} / '
                      '${widget.restaurant.translate(
                        game.customerTypeTitleKey(game.activeCustomerType),
                      )}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.ink.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeFood.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${game.formatCoins(game.customerOrderReward * totalMultiplier)}',
                    style: TextStyle(
                      color: theme.accent,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.restaurant.translate('rush_bonus')} ${_formatMultiplier(totalMultiplier)}',
                    style: TextStyle(
                      color: theme.ink.withValues(alpha: 0.62),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _PatienceMeter(
          label: widget.restaurant.translate('rush_patience'),
          remaining: _formatSeconds(patienceRemaining),
          ratio: patienceRatio,
          color: patienceColor,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 150;
              return Column(
                children: [
                  for (var index = 0; index < choices.length; index++) ...[
                    if (index > 0) SizedBox(height: compact ? 6 : 8),
                    Expanded(
                      child: _DishChoiceButton(
                        food: choices[index],
                        selected: _lastChoiceId == choices[index].id,
                        correct: _lastChoiceCorrect,
                        feedbackSeed:
                            '${_lastChoiceId ?? 0}-${_lastChoiceCorrect ?? false}',
                        onTap: () => _chooseDish(
                          context,
                          game,
                          choices[index],
                          activeFood,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShiftSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ShiftSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isTerminal ? theme.cyan : theme.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.ink.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: theme.ink,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _KitchenRushFrame extends StatelessWidget {
  final Restaurant restaurant;
  final int combo;
  final int bestCombo;
  final String bonusLabel;
  final String? resultText;
  final _RushResultKind? resultKind;
  final Widget child;

  const _KitchenRushFrame({
    required this.restaurant,
    required this.combo,
    required this.bestCombo,
    required this.bonusLabel,
    required this.resultText,
    required this.resultKind,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isRetro = mode == AppThemeMode.retroOS;
    final borderColor = isTerminal ? theme.cyan : theme.border;

    return Container(
      decoration: BoxDecoration(
        color: isRetro ? theme.surfaceHigh : theme.surface,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
          ),
          bottom: BorderSide(
            color: borderColor,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
          ),
        ),
        boxShadow: isTerminal ? theme.softGlow(theme.cyan) : null,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isTerminal ? Icons.terminal : Icons.local_fire_department,
                color: isTerminal ? theme.cyan : theme.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurant.translate('rush_title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontFamily: isTerminal ? 'Courier' : null,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.end,
                  children: [
                    _RushBadge(
                      label: '${restaurant.translate('rush_combo')} x$combo',
                    ),
                    if (bestCombo > 0)
                      _RushBadge(
                        label:
                            '${restaurant.translate('rush_best')} x$bestCombo',
                      ),
                    _RushBadge(
                      label:
                          '${restaurant.translate('rush_bonus')} $bonusLabel',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (resultText != null && resultKind != null) ...[
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _ResultBanner(
                key: ValueKey('$resultText-$resultKind'),
                text: resultText!,
                kind: resultKind!,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final String text;
  final _RushResultKind kind;

  const _ResultBanner({
    super.key,
    required this.text,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final color = switch (kind) {
      _RushResultKind.success => theme.accent,
      _RushResultKind.miss => theme.danger,
      _RushResultKind.timeout => theme.amber,
    };
    final icon = switch (kind) {
      _RushResultKind.success => Icons.check_circle,
      _RushResultKind.miss => Icons.cancel,
      _RushResultKind.timeout => Icons.person_off,
    };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isTerminal ? 0.16 : 0.2),
          borderRadius: BorderRadius.circular(
            mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
          ),
          border: Border.all(
            color: isTerminal ? theme.cyan : color,
            width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RushBadge extends StatelessWidget {
  final String label;

  const _RushBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.surfaceHigh,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
        ),
      ),
    );
  }
}

class _PatienceMeter extends StatelessWidget {
  final String label;
  final String remaining;
  final double ratio;
  final Color color;

  const _PatienceMeter({
    required this.label,
    required this.remaining,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.68),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),
            ),
            Text(
              remaining,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(
            mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
          ),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: theme.surfaceHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PromptLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PromptLine({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceHigh,
        borderRadius: BorderRadius.circular(
          AppTheme.activeMode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        border: Border.all(
          color: AppTheme.activeMode == AppThemeMode.neonTerminal
              ? theme.cyan
              : theme.border,
          width: AppTheme.activeMode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.66),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DishChoiceButton extends StatelessWidget {
  final Food food;
  final bool selected;
  final bool? correct;
  final String feedbackSeed;
  final VoidCallback onTap;

  const _DishChoiceButton({
    required this.food,
    required this.selected,
    required this.correct,
    required this.feedbackSeed,
    required this.onTap,
  });

  IconData get _foodIcon {
    if (food.tags.contains('fish') || food.tags.contains('tuna')) {
      return Icons.set_meal;
    }
    if (food.tags.contains('meat') || food.tags.contains('beef')) {
      return Icons.dinner_dining;
    }
    if (food.tags.contains('beer')) return Icons.local_drink;
    if (food.tags.contains('bento')) return Icons.rice_bowl;
    if (food.tags.contains('side')) return Icons.eco;
    return Icons.ramen_dining;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isCorrect = selected && correct == true;
    final isWrong = selected && correct == false;
    final backgroundColor = isCorrect
        ? theme.accent
        : isWrong
            ? theme.danger.withValues(alpha: 0.22)
            : isTerminal
                ? theme.background.withValues(alpha: 0.35)
                : theme.surface;
    final foregroundColor = isCorrect && isTerminal ? Colors.black : theme.ink;

    return TweenAnimationBuilder<double>(
      key: ValueKey(feedbackSeed),
      tween: Tween<double>(
        begin: selected
            ? isCorrect
                ? 1.04
                : 0.96
            : 1,
        end: 1,
      ),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
              ),
              border: Border.all(
                color: isWrong
                    ? theme.danger
                    : isCorrect
                        ? theme.accent
                        : isTerminal
                            ? theme.cyan
                            : theme.border,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
              boxShadow: selected && mode == AppThemeMode.neoBrutalism
                  ? theme.hardShadow(offset: const Offset(3, 3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(_foodIcon, color: foregroundColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '¥${food.price}',
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? theme.accent : theme.danger,
                    size: 17,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
