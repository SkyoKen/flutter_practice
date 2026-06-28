import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

class GameStatusBar extends StatelessWidget {
  final Restaurant restaurant;
  final List<Food> menu;
  final bool showCustomerButton;
  final bool showActions;

  const GameStatusBar({
    super.key,
    required this.restaurant,
    required this.menu,
    this.showCustomerButton = true,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final isRetro = mode == AppThemeMode.retroOS;
        final borderColor = isTerminal ? theme.cyan : theme.border;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isRetro ? theme.surfaceHigh : theme.surface,
            border: Border(
              bottom: BorderSide(
                color: borderColor,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
            ),
            boxShadow: isTerminal ? theme.softGlow(theme.cyan) : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final stats = [
                _StatPill(
                  icon: Icons.monetization_on,
                  label: restaurant.translate('idle_coins'),
                  value: game.formatCoins(game.coins),
                  compact: compact,
                ),
                _StatPill(
                  icon: Icons.trending_up,
                  label: restaurant.translate('idle_yen_per_min'),
                  value: game.formatCoins(game.revenuePerMinute),
                  compact: compact,
                ),
                _StatPill(
                  icon: Icons.storefront,
                  label: restaurant.translate('idle_shop_level'),
                  value: game.restaurantLevel.toString(),
                  compact: compact,
                ),
              ];
              final actions = showActions
                  ? [
                      _buildGoalsButton(
                        context: context,
                        game: game,
                        borderColor: borderColor,
                      ),
                      _buildOfflineButton(
                        context: context,
                        game: game,
                        borderColor: borderColor,
                      ),
                      _buildUpgradeButton(
                        context: context,
                        borderColor: borderColor,
                      ),
                    ]
                  : <Widget>[];

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        for (var index = 0; index < stats.length; index++) ...[
                          if (index > 0) const SizedBox(width: 6),
                          Expanded(child: stats[index]),
                        ],
                      ],
                    ),
                    if (showCustomerButton) ...[
                      const SizedBox(height: 8),
                      _buildCustomerOrderButton(
                        context: context,
                        game: game,
                        compact: compact,
                        maxWidth: constraints.maxWidth,
                        borderColor: borderColor,
                      ),
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var index = 0;
                                index < actions.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: 8),
                              actions[index],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: compact ? 8 : 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...stats,
                  if (showCustomerButton)
                    _buildCustomerOrderButton(
                      context: context,
                      game: game,
                      compact: compact,
                      maxWidth: constraints.maxWidth,
                      borderColor: borderColor,
                    ),
                  ...actions,
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<int> get _menuIds => menu.map((food) => food.id).toList();

  Food? _customerOrderFood(GameController game) {
    final foodId = game.customerOrderFoodId;
    if (foodId == null) return null;
    for (final food in menu) {
      if (food.id == foodId) return food;
    }
    return null;
  }

  Widget _buildCustomerOrderButton({
    required BuildContext context,
    required GameController game,
    required bool compact,
    required double maxWidth,
    required Color borderColor,
  }) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (tick) => tick),
      builder: (context, snapshot) {
        return _buildCustomerOrderButtonBody(
          context: context,
          game: game,
          compact: compact,
          maxWidth: maxWidth,
          borderColor: borderColor,
        );
      },
    );
  }

  Widget _buildCustomerOrderButtonBody({
    required BuildContext context,
    required GameController game,
    required bool compact,
    required double maxWidth,
    required Color borderColor,
  }) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final manualCustomer = game.manualDiningCustomer;
    final activeFood =
        manualCustomer?.phase == GameDiningCustomerPhase.waitingForFood
            ? _customerOrderFood(game)
            : null;
    final hasOrder = activeFood != null && game.hasCustomerOrder;
    final arrivalRemaining = game.customerArrivalRemaining(DateTime.now());
    final busyWithManualCustomer = manualCustomer != null && !hasOrder;
    final waitingForCustomer = !hasOrder &&
        !busyWithManualCustomer &&
        arrivalRemaining > Duration.zero;
    final buttonWidth = compact ? maxWidth : 340.0;
    final label = hasOrder
        ? '${restaurant.translate('idle_customer_order')}: ${activeFood.name} +${game.formatCoins(game.customerOrderReward)}'
        : busyWithManualCustomer
            ? _manualCustomerStatusLabel(manualCustomer)
            : waitingForCustomer
                ? '${restaurant.translate('idle_next_customer_in')} ${_formatSeconds(arrivalRemaining)}'
                : restaurant.translate('idle_new_customer_order');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
      ),
    );
    final side = BorderSide(
      color: borderColor,
      width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
    );
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontFamily: isTerminal ? 'Courier' : null,
      ),
    );

    if (!hasOrder) {
      return SizedBox(
        width: buttonWidth,
        height: 36,
        child: OutlinedButton.icon(
          onPressed: busyWithManualCustomer
              ? null
              : () => _ensureCustomerOrder(context, game),
          style: OutlinedButton.styleFrom(
            foregroundColor: waitingForCustomer
                ? theme.ink.withValues(alpha: 0.62)
                : isTerminal
                    ? theme.cyan
                    : theme.ink,
            side: side,
            shape: shape,
          ),
          icon: Icon(
            busyWithManualCustomer
                ? _manualCustomerStatusIcon(manualCustomer.phase)
                : waitingForCustomer
                    ? Icons.hourglass_bottom
                    : Icons.person_add_alt_1,
            size: 16,
          ),
          label: labelWidget,
        ),
      );
    }

    return SizedBox(
      width: buttonWidth,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: () => _serveCustomerOrder(context, game),
        style: ElevatedButton.styleFrom(
          backgroundColor: isTerminal ? theme.cyan : theme.accent,
          foregroundColor: isTerminal ? Colors.black : theme.ink,
          side: side,
          shape: shape,
          elevation: 0,
        ),
        icon: const Icon(Icons.room_service, size: 16),
        label: labelWidget,
      ),
    );
  }

  Future<void> _ensureCustomerOrder(
    BuildContext context,
    GameController game,
  ) async {
    final seated = await game.ensureCustomerOrder(_menuIds);
    if (!context.mounted) return;
    if (seated) return;
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;
    final remaining = game.customerArrivalRemaining(DateTime.now());
    final message = remaining > Duration.zero
        ? '${restaurant.translate('idle_next_customer_in')} ${_formatSeconds(remaining)}'
        : restaurant.translate('rush_waiting_table');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.surfaceHigh,
        content: Text(
          message,
          style: TextStyle(
            color: isTerminal ? theme.cyan : theme.ink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _manualCustomerStatusLabel(GameDiningCustomer customer) {
    return switch (customer.phase) {
      GameDiningCustomerPhase.queueing ||
      GameDiningCustomerPhase.seating =>
        restaurant.translate('rush_seating_title'),
      GameDiningCustomerPhase.waitingForFood =>
        restaurant.translate('rush_order_label'),
      GameDiningCustomerPhase.servingFood =>
        restaurant.translate('rush_serving_title'),
      GameDiningCustomerPhase.eating =>
        restaurant.translate('rush_eating_title'),
      GameDiningCustomerPhase.checkout =>
        restaurant.translate('rush_checkout_title'),
      GameDiningCustomerPhase.leaving =>
        restaurant.translate('rush_leaving_title'),
    };
  }

  IconData _manualCustomerStatusIcon(GameDiningCustomerPhase phase) {
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

  String _formatSeconds(Duration duration) {
    var seconds = duration.inSeconds;
    if (duration.inMilliseconds % 1000 != 0) {
      seconds += 1;
    }
    if (seconds < 1) seconds = 1;
    return '${seconds}s';
  }

  Future<void> _serveCustomerOrder(
    BuildContext context,
    GameController game,
  ) async {
    final reward = await game.serveCustomerOrder(_menuIds);
    if (!context.mounted || reward <= 0) return;
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isTerminal ? theme.cyan : theme.accent,
        content: Text(
          '${restaurant.translate('idle_served_reward')} +${game.formatCoins(reward)}',
          style: TextStyle(
            color: isTerminal ? Colors.black : theme.ink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildGoalsButton({
    required BuildContext context,
    required GameController game,
    required Color borderColor,
  }) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final claimableCount = game.claimableMilestoneCount;
    final label = claimableCount > 0
        ? '${restaurant.translate('idle_goals')} $claimableCount'
        : restaurant.translate('idle_goals');

    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () => _showGoalsDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: isTerminal ? theme.cyan : theme.ink,
          side: BorderSide(
            color: claimableCount > 0 ? theme.accent : borderColor,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
            ),
          ),
        ),
        icon: Icon(
          claimableCount > 0 ? Icons.flag : Icons.outlined_flag,
          size: 16,
        ),
        label: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildOfflineButton({
    required BuildContext context,
    required GameController game,
    required Color borderColor,
  }) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: game.pendingClaimableEarnings <= 0
            ? null
            : () => _claimOffline(context, game),
        style: ElevatedButton.styleFrom(
          backgroundColor: game.pendingClaimableEarnings <= 0
              ? theme.surfaceHigh
              : isTerminal
                  ? theme.cyan
                  : theme.accent,
          foregroundColor: isTerminal ? Colors.black : theme.ink,
          disabledBackgroundColor: theme.surfaceHigh,
          disabledForegroundColor: theme.ink.withValues(alpha: 0.45),
          side: BorderSide(
            color: borderColor,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
            ),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.savings, size: 16),
        label: Text(
          game.pendingClaimableEarnings <= 0
              ? restaurant.translate('idle_no_idle')
              : '+${game.formatCoins(game.pendingClaimableEarnings)}',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: isTerminal ? 'Courier' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton({
    required BuildContext context,
    required Color borderColor,
  }) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: () => _showUpgradeDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: isTerminal ? theme.cyan : theme.ink,
          side: BorderSide(
            color: borderColor,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
            ),
          ),
        ),
        icon: const Icon(Icons.upgrade, size: 16),
        label: Text(
          restaurant.translate('idle_upgrades'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  void _showGoalsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            return ThemedAppDialog(
              title: restaurant.translate('idle_goals_title'),
              icon: Icons.flag,
              maxWidth: 560,
              actions: [
                ThemedDialogButton(
                  label: restaurant.translate('close'),
                  primary: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final milestone in game.milestones) ...[
                    _MilestoneTile(
                      milestone: milestone,
                      restaurant: restaurant,
                      onClaim: milestone.claimable
                          ? () => _claimMilestone(
                                context,
                                game,
                                milestone,
                              )
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _claimMilestone(
    BuildContext context,
    GameController game,
    GameMilestone milestone,
  ) async {
    final reward = await game.claimMilestone(milestone.id);
    if (!context.mounted || reward <= 0) return;
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isTerminal ? theme.cyan : theme.accent,
        content: Text(
          '${restaurant.translate('idle_goal_claimed')} +${game.formatCoins(reward)}',
          style: TextStyle(
            color: isTerminal ? Colors.black : theme.ink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _claimOffline(
    BuildContext context,
    GameController game,
  ) async {
    final claimed = game.pendingClaimableEarnings;
    await game.claimOfflineEarnings();
    if (!context.mounted) return;
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isTerminal ? theme.cyan : theme.accent,
        content: Text(
          '${restaurant.translate('idle_pending_income')} +${game.formatCoins(claimed)}',
          style: TextStyle(
            color: isTerminal ? Colors.black : theme.ink,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            return ThemedAppDialog(
              title: restaurant.translate('idle_upgrade_title'),
              icon: Icons.upgrade,
              maxWidth: 560,
              actions: [
                ThemedDialogButton(
                  label: restaurant.translate('close'),
                  primary: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UpgradeSectionLabel(
                    label: restaurant.translate('idle_operations'),
                  ),
                  const SizedBox(height: 8),
                  _UpgradeOption(
                    label:
                        '${restaurant.translate('idle_seats')} Lv ${game.seatLevel}',
                    description:
                        '${restaurant.translate('idle_cost')} ${game.formatCoins(game.seatUpgradeCost)} / ${restaurant.translate('idle_more_customer_flow')}',
                    canAfford: game.coins >= game.seatUpgradeCost,
                    onTap: () => _attemptUpgrade(
                      context,
                      game.upgradeSeats,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _UpgradeOption(
                    label:
                        '${restaurant.translate('idle_service')} Lv ${game.serviceLevel}',
                    description:
                        '${restaurant.translate('idle_cost')} ${game.formatCoins(game.serviceUpgradeCost)} / ${restaurant.translate('idle_faster_table_turns')}',
                    canAfford: game.coins >= game.serviceUpgradeCost,
                    onTap: () => _attemptUpgrade(
                      context,
                      game.upgradeService,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _UpgradeSectionLabel(
                    label: restaurant.translate('idle_menu'),
                  ),
                  const SizedBox(height: 8),
                  ...menu.map((food) {
                    final cost = game.menuUpgradeCost(food.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _UpgradeOption(
                        label: '${food.name} Lv ${game.menuLevel(food.id)}',
                        description:
                            '${restaurant.translate('idle_cost')} ${game.formatCoins(cost)} / ${restaurant.translate('idle_stronger_item_yield')}',
                        canAfford: game.coins >= cost,
                        onTap: () => _attemptUpgrade(
                          context,
                          () => game.upgradeMenuItem(food.id),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _attemptUpgrade(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final success = await action();
    if (!context.mounted || success) return;
    final theme = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.danger,
        content: Text(
          restaurant.translate('idle_not_enough_coins'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return Container(
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
      decoration: BoxDecoration(
        color: isTerminal
            ? theme.background.withValues(alpha: 0.42)
            : theme.surfaceHigh,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan.withValues(alpha: 0.52) : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isTerminal ? theme.cyan : theme.ink),
          SizedBox(width: compact ? 4 : 6),
          if (compact)
            Flexible(
              child: Text(
                '$label ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.62),
                  fontSize: 10,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Text(
              '$label ',
              style: TextStyle(
                color: theme.ink.withValues(alpha: 0.62),
                fontSize: 11,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w800,
              ),
            ),
          Text(
            value,
            maxLines: 1,
            style: TextStyle(
              color: isTerminal ? theme.cyan : theme.ink,
              fontSize: compact ? 12 : 13,
              fontFamily: 'Courier',
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeSectionLabel extends StatelessWidget {
  final String label;

  const _UpgradeSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Text(
      label,
      style: TextStyle(
        color: theme.ink.withValues(alpha: 0.72),
        fontFamily: 'Courier',
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  final GameMilestone milestone;
  final Restaurant restaurant;
  final VoidCallback? onClaim;

  const _MilestoneTile({
    required this.milestone,
    required this.restaurant,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final statusLabel = milestone.claimed
        ? restaurant.translate('idle_claimed')
        : milestone.claimable
            ? restaurant.translate('idle_claim')
            : '${milestone.progress}/${milestone.target}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTerminal
            ? theme.background.withValues(alpha: 0.38)
            : theme.surfaceHigh,
        border: Border.all(
          color: milestone.claimable ? theme.accent : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.2,
        ),
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        boxShadow: milestone.claimable && mode == AppThemeMode.neonTerminal
            ? theme.softGlow(theme.cyan)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  restaurant.translate(milestone.titleKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontWeight: FontWeight.w900,
                    fontFamily: isTerminal || isPaper ? 'Courier' : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${milestone.reward.round()}',
                style: TextStyle(
                  color: milestone.claimable ? theme.accent : theme.ink,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            restaurant.translate(milestone.descriptionKey),
            style: TextStyle(
              color: theme.ink.withValues(alpha: 0.68),
              fontSize: 12,
              fontFamily: isTerminal || isPaper ? 'Courier' : null,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: milestone.progressRatio,
              backgroundColor: theme.ink.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                milestone.completed ? theme.accent : theme.border,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onClaim,
              style: OutlinedButton.styleFrom(
                foregroundColor: milestone.claimable
                    ? isTerminal
                        ? theme.cyan
                        : theme.ink
                    : theme.ink.withValues(alpha: 0.54),
                side: BorderSide(
                  color: milestone.claimable ? theme.accent : theme.border,
                  width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                  ),
                ),
              ),
              child: Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontFamily: isTerminal || isPaper ? 'Courier' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeOption extends StatelessWidget {
  final String label;
  final String description;
  final bool canAfford;
  final VoidCallback onTap;

  const _UpgradeOption({
    required this.label,
    required this.description,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: canAfford ? 1 : 0.52,
      child: SizedBox(
        width: double.infinity,
        child: ThemedOptionTile(
          label: label,
          description: description,
          selected: canAfford,
          minWidth: 0,
          onTap: onTap,
        ),
      ),
    );
  }
}
