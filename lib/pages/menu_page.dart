import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/customer_arrival_stage.dart';
import 'package:cyber_table_order/components/game_status_bar.dart';
import 'package:cyber_table_order/components/kitchen_rush_panel.dart';
import 'package:cyber_table_order/components/order_history_dialog.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Timer? _businessTimer;
  DateTime _lastBusinessTickAt = DateTime.now();
  int _recentCompletedOrders = 0;
  int _coinBurstSeed = 0;

  @override
  void initState() {
    super.initState();
    _businessTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _runBusinessTick(),
    );
  }

  @override
  void dispose() {
    _businessTimer?.cancel();
    super.dispose();
  }

  Future<void> _runBusinessTick() async {
    if (!mounted) return;
    final game = context.read<GameController>();
    if (!game.isLoaded) return;
    final restaurant = context.read<Restaurant>();
    final now = DateTime.now();
    final elapsed = now.difference(_lastBusinessTickAt);
    _lastBusinessTickAt = now;
    final completed = await game.simulateBusinessTick(
      restaurant.getMenu().map((food) => food.id).toList(),
      elapsed: elapsed,
      now: now,
    );
    if (!mounted || completed <= 0) return;
    setState(() {
      _recentCompletedOrders = completed;
      _coinBurstSeed += 1;
    });
  }

  void _showHistoryLog(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => OrderHistoryDialog(restaurant: restaurant),
    );
  }

  void _showKitchenRush(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) {
        return ThemedAppDialog(
          title: restaurant.translate('rush_title'),
          icon: Icons.local_fire_department,
          maxWidth: 520,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('close'),
              primary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
          child: SizedBox(
            height: 390,
            child: KitchenRushPanel(
              restaurant: restaurant,
              menu: restaurant.getMenu(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _claimOfflineEarnings(
    BuildContext context,
    Restaurant restaurant,
  ) async {
    final game = context.read<GameController>();
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

  Future<void> _attemptUpgrade(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    final success = await action();
    if (!context.mounted || success) return;
    final restaurant = context.read<Restaurant>();
    final theme = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: theme.danger,
        content: Text(
          restaurant.translate('idle_not_enough_coins'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showDishBook(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            return ThemedAppDialog(
              title: restaurant.translate('rush_dish_book'),
              icon: Icons.menu_book,
              maxWidth: 620,
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
                  for (final food in restaurant.getMenu()) ...[
                    Builder(
                      builder: (context) {
                        final locked = !game.isFoodUnlocked(food.id);
                        return _DishBookTile(
                          icon: locked ? Icons.lock : _foodIcon(food),
                          title: locked
                              ? restaurant.translate('idle_locked_dish')
                              : food.name,
                          menuLevelLabel: locked
                              ? restaurant.translate('idle_locked')
                              : '${restaurant.translate('idle_menu')} Lv ${game.menuLevel(food.id)}',
                          masteryLabel: locked
                              ? '${restaurant.translate('idle_unlock_level')} ${game.foodUnlockLevel(food.id)}'
                              : '${restaurant.translate('rush_mastery')} Lv ${game.masteryLevelForFood(food.id)}',
                          servedLabel: locked
                              ? restaurant.translate('idle_not_in_order_pool')
                              : '${restaurant.translate('rush_served')} ${game.servedCountForFood(food.id)}',
                          rewardLabel: locked
                              ? '--'
                              : '+${game.formatCoins(
                                  game.customerOrderRewardForFood(food.id),
                                )}',
                          costLabel: locked
                              ? 'Lv ${game.foodUnlockLevel(food.id)}'
                              : '${restaurant.translate('idle_cost')} ${game.formatCoins(game.menuUpgradeCost(food.id))}',
                          masteryProgress: locked
                              ? 0
                              : game.masteryProgressRatioForFood(food.id),
                          masteryProgressLabel: locked
                              ? '0/${game.masteryProgressTarget}'
                              : '${game.masteryProgressForFood(food.id)}/${game.masteryProgressTarget}',
                          canAfford: !locked &&
                              game.coins >= game.menuUpgradeCost(food.id),
                          locked: locked,
                          onTap: locked
                              ? null
                              : () => _attemptUpgrade(
                                    context,
                                    () => game.upgradeMenuItem(food.id),
                                  ),
                        );
                      },
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

  void _showOperations(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            return ThemedAppDialog(
              title: restaurant.translate('rush_operations'),
              icon: Icons.storefront,
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
                  _ProgressInfoTile(
                    icon: Icons.trending_up,
                    title:
                        '${restaurant.translate('idle_shop_xp')} Lv ${game.restaurantXpLevel}',
                    description: restaurant.translate('idle_shop_xp_desc'),
                    progress: game.restaurantXpProgressRatio,
                    trailingLabel:
                        '${game.restaurantXpProgress}/${game.restaurantXpProgressTarget}',
                  ),
                  const SizedBox(height: 10),
                  _UpgradeTile(
                    icon: Icons.table_restaurant,
                    title:
                        '${restaurant.translate('idle_seats')} Lv ${game.seatLevel}',
                    description:
                        '${restaurant.translate('idle_cost')} ${game.formatCoins(game.seatUpgradeCost)} / ${restaurant.translate('idle_more_customer_flow')}',
                    trailingLabel:
                        '+${game.formatCoins(game.revenuePerMinute)}/min',
                    canAfford: game.coins >= game.seatUpgradeCost,
                    onTap: () => _attemptUpgrade(context, game.upgradeSeats),
                  ),
                  const SizedBox(height: 10),
                  _UpgradeTile(
                    icon: Icons.support_agent,
                    title:
                        '${restaurant.translate('idle_service')} Lv ${game.serviceLevel}',
                    description:
                        '${restaurant.translate('idle_cost')} ${game.formatCoins(game.serviceUpgradeCost)} / ${restaurant.translate('idle_faster_table_turns')}',
                    trailingLabel: '${game.customerArrivalDelay.inSeconds}s',
                    canAfford: game.coins >= game.serviceUpgradeCost,
                    onTap: () => _attemptUpgrade(context, game.upgradeService),
                  ),
                  const SizedBox(height: 10),
                  _UpgradeTile(
                    icon: Icons.kitchen,
                    title:
                        '${restaurant.translate('idle_kitchen')} Lv ${game.kitchenLevel}',
                    description:
                        '${restaurant.translate('idle_cost')} ${game.formatCoins(game.kitchenUpgradeCost)} / ${restaurant.translate('idle_kitchen_boost')}',
                    trailingLabel:
                        '+${game.formatCoins((game.kitchenLevel * 3).toDouble())}',
                    canAfford: game.coins >= game.kitchenUpgradeCost,
                    onTap: () => _attemptUpgrade(context, game.upgradeKitchen),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGoals(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            return ThemedAppDialog(
              title: restaurant.translate('idle_goals_title'),
              icon: Icons.flag,
              maxWidth: 580,
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
                    _GoalTile(
                      milestone: milestone,
                      restaurant: restaurant,
                      onClaim: milestone.claimable
                          ? () => _claimMilestone(context, game, milestone)
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _DialogSectionLabel(
                    label: restaurant.translate('daily_tasks_title'),
                  ),
                  const SizedBox(height: 10),
                  for (final task in game.dailyTasks) ...[
                    _DailyTaskTile(
                      task: task,
                      restaurant: restaurant,
                      onClaim: task.claimable
                          ? () => _claimDailyTask(context, game, task)
                          : null,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _DialogSectionLabel(
                    label: restaurant.translate('achievements_title'),
                  ),
                  const SizedBox(height: 10),
                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.flag,
                        label: restaurant.translate('stat_claimed_goals'),
                        value:
                            '${game.claimedMilestoneIds.length}/${game.milestones.length}',
                      ),
                      _StatItem(
                        icon: Icons.today,
                        label: restaurant.translate('stat_today_claimed'),
                        value:
                            '${game.claimedDailyTaskIds.length}/${game.dailyTasks.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _DialogSectionLabel(
                    label: restaurant.translate('stats_title'),
                  ),
                  const SizedBox(height: 10),
                  _StatsGrid(
                    items: [
                      _StatItem(
                        icon: Icons.room_service,
                        label: restaurant.translate('stat_total_served'),
                        value: '${game.customerOrdersServed}',
                      ),
                      _StatItem(
                        icon: Icons.local_fire_department,
                        label: restaurant.translate('stat_best_combo'),
                        value: 'x${game.bestCombo}',
                      ),
                      _StatItem(
                        icon: Icons.toll,
                        label: restaurant.translate('stat_lifetime_earnings'),
                        value: game.formatCoins(game.lifetimeEarnings),
                      ),
                      _StatItem(
                        icon: Icons.restaurant_menu,
                        label: restaurant.translate('stat_favorite_dish'),
                        value: _favoriteDishName(restaurant, game),
                      ),
                    ],
                  ),
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
    final restaurant = context.read<Restaurant>();
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

  Future<void> _claimDailyTask(
    BuildContext context,
    GameController game,
    GameDailyTask task,
  ) async {
    final restaurant = context.read<Restaurant>();
    final reward = await game.claimDailyTask(task.id);
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

  String _favoriteDishName(Restaurant restaurant, GameController game) {
    final menu = restaurant.getMenu().toList()
      ..sort((a, b) {
        final servedCompare = game
            .servedCountForFood(b.id)
            .compareTo(game.servedCountForFood(a.id));
        if (servedCompare != 0) return servedCompare;
        return a.id.compareTo(b.id);
      });
    if (menu.isEmpty || game.servedCountForFood(menu.first.id) <= 0) {
      return '-';
    }
    return menu.first.name;
  }

  IconData _foodIcon(Food food) {
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

  Widget _buildOfflineClaimStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        if (game.pendingClaimableEarnings <= 0) {
          return const SizedBox.shrink();
        }
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: mode == AppThemeMode.retroOS
              ? theme.surfaceHigh
              : theme.background,
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _claimOfflineEarnings(context, restaurant),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTerminal ? theme.cyan : theme.amber,
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
              icon: const Icon(Icons.savings, size: 18),
              label: Text(
                '${restaurant.translate('idle_claim_income')} +${game.formatCoins(game.pendingClaimableEarnings)}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final titleKey = game.activeEventTitleKey;
        final descriptionKey = game.activeEventDescriptionKey;
        if (titleKey == null || descriptionKey == null) {
          return const SizedBox.shrink();
        }
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final isDiscount =
            game.activeEventType == GameEventType.ingredientDiscount;
        final valueLabel = isDiscount
            ? '-10%'
            : 'x${game.activeEventRewardMultiplier.toStringAsFixed(2)}';

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: mode == AppThemeMode.retroOS
              ? theme.surfaceHigh
              : theme.background,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isTerminal
                  ? theme.background.withValues(alpha: 0.38)
                  : theme.amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(
                mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
              ),
              border: Border.all(
                color: isTerminal ? theme.cyan : theme.amber,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
              boxShadow: mode == AppThemeMode.neoBrutalism
                  ? theme.hardShadow(offset: const Offset(3, 3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isDiscount ? Icons.sell : Icons.bolt,
                  color: isTerminal ? theme.cyan : theme.amber,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.translate(titleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurant.translate(descriptionKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink.withValues(alpha: 0.64),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  valueLabel,
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNextGoalStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final milestone = game.nextMilestone;
        if (milestone == null) return const SizedBox.shrink();
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final highlighted = milestone.claimable;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: mode == AppThemeMode.retroOS
              ? theme.surfaceHigh
              : theme.background,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: highlighted && !isTerminal
                  ? theme.accent.withValues(alpha: 0.18)
                  : mode == AppThemeMode.retroOS
                      ? theme.surface
                      : theme.surfaceHigh,
              borderRadius: BorderRadius.circular(
                mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
              ),
              border: Border.all(
                color: highlighted
                    ? theme.accent
                    : isTerminal
                        ? theme.cyan
                        : theme.border,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
              boxShadow: highlighted && mode == AppThemeMode.neoBrutalism
                  ? theme.hardShadow(offset: const Offset(3, 3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  highlighted ? Icons.flag : Icons.outlined_flag,
                  color: highlighted ? theme.accent : theme.ink,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${restaurant.translate('rush_next_goal')}: ${restaurant.translate(milestone.titleKey)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                        ),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: milestone.progressRatio,
                          backgroundColor: theme.surface,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(theme.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (highlighted)
                  _GoalClaimChip(label: restaurant.translate('idle_claim'))
                else
                  Text(
                    '${milestone.progress}/${milestone.target}',
                    style: TextStyle(
                      color: isTerminal ? theme.cyan : theme.ink,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionDock(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final actions = [
          _DockAction(
            icon: Icons.menu_book,
            label: restaurant.translate('rush_dish_book'),
            onTap: (context) => _showDishBook(context, restaurant),
          ),
          _DockAction(
            icon: Icons.storefront,
            label: restaurant.translate('rush_operations'),
            onTap: (context) => _showOperations(context, restaurant),
          ),
          _DockAction(
            icon: Icons.flag,
            label: restaurant.translate('idle_goals'),
            badgeCount: game.claimableRewardCount,
            onTap: (context) => _showGoals(context, restaurant),
          ),
          _DockAction(
            icon: Icons.history,
            label: restaurant.translate('history_log'),
            onTap: (context) => _showHistoryLog(context, restaurant),
          ),
        ];

        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final borderColor = isTerminal ? theme.cyan : theme.border;

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: mode == AppThemeMode.retroOS
                  ? theme.surfaceHigh
                  : theme.surface,
              border: Border(
                top: BorderSide(
                  color: borderColor,
                  width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
                ),
              ),
              boxShadow: isTerminal ? theme.softGlow(theme.cyan) : null,
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: _DockButton(action: actions[index])),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboard(Restaurant restaurant, BoxConstraints constraints) {
    final menu = restaurant.getMenu();
    final wideLandscape = constraints.maxWidth >= 820 &&
        constraints.maxWidth > constraints.maxHeight;

    return Column(
      children: [
        GameStatusBar(
          restaurant: restaurant,
          menu: menu,
          showCustomerButton: false,
          showActions: false,
        ),
        _buildOfflineClaimStrip(restaurant),
        _buildEventStrip(restaurant),
        _buildNextGoalStrip(restaurant),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bodyConstraints) {
              if (wideLandscape) {
                final stageHeight = bodyConstraints.maxHeight;
                return Row(
                  children: [
                    Expanded(
                      child: CustomerArrivalStage(
                        restaurant: restaurant,
                        menu: menu,
                        prominent: true,
                        height: stageHeight,
                        recentCompletedOrders: _recentCompletedOrders,
                        coinBurstSeed: _coinBurstSeed,
                      ),
                    ),
                    SizedBox(
                      width: (constraints.maxWidth * 0.34)
                          .clamp(340.0, 430.0)
                          .toDouble(),
                      child: _IdleControlPanel(
                        restaurant: restaurant,
                        menu: menu,
                        onClaim: () => _claimOfflineEarnings(
                          context,
                          restaurant,
                        ),
                        onRush: () => _showKitchenRush(context, restaurant),
                      ),
                    ),
                  ],
                );
              }

              final minPanelHeight =
                  bodyConstraints.maxHeight < 560 ? 220.0 : 252.0;
              var stageHeight = (bodyConstraints.maxHeight * 0.58)
                  .clamp(220.0, 420.0)
                  .toDouble();
              if (bodyConstraints.maxHeight - stageHeight < minPanelHeight) {
                stageHeight = (bodyConstraints.maxHeight - minPanelHeight)
                    .clamp(190.0, 420.0)
                    .toDouble();
              }
              final panelHeight =
                  (bodyConstraints.maxHeight - stageHeight).clamp(
                minPanelHeight,
                bodyConstraints.maxHeight,
              );

              return Column(
                children: [
                  CustomerArrivalStage(
                    restaurant: restaurant,
                    menu: menu,
                    prominent: true,
                    height: stageHeight,
                    recentCompletedOrders: _recentCompletedOrders,
                    coinBurstSeed: _coinBurstSeed,
                  ),
                  SizedBox(
                    height: panelHeight.toDouble(),
                    child: _IdleControlPanel(
                      restaurant: restaurant,
                      menu: menu,
                      onClaim: () => _claimOfflineEarnings(
                        context,
                        restaurant,
                      ),
                      onRush: () => _showKitchenRush(context, restaurant),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _buildActionDock(restaurant),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return _buildDashboard(restaurant, constraints);
            },
          ),
        );
      },
    );
  }
}

class _IdleControlPanel extends StatelessWidget {
  final Restaurant restaurant;
  final List<Food> menu;
  final VoidCallback onClaim;
  final VoidCallback onRush;

  const _IdleControlPanel({
    required this.restaurant,
    required this.menu,
    required this.onClaim,
    required this.onRush,
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
        final canClaim = game.pendingClaimableEarnings > 0;

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
                    isTerminal ? Icons.terminal : Icons.storefront,
                    color: isTerminal ? theme.cyan : theme.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurant.translate('idle_auto_panel_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isTerminal ? theme.cyan : theme.ink,
                        fontWeight: FontWeight.w900,
                        fontFamily: isTerminal ? 'Courier' : null,
                      ),
                    ),
                  ),
                  Text(
                    '+${game.formatCoins(game.revenuePerMinute)}/min',
                    style: TextStyle(
                      color: theme.accent,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 420;
                    final itemWidth = compact
                        ? (constraints.maxWidth - 8) / 2
                        : (constraints.maxWidth - 24) / 4;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _AutoMetricChip(
                          width: itemWidth,
                          icon: Icons.people_alt,
                          label: restaurant.translate('idle_business_queue'),
                          value:
                              '${game.businessQueueCount}/${game.businessMaxQueue}',
                        ),
                        _AutoMetricChip(
                          width: itemWidth,
                          icon: Icons.table_restaurant,
                          label: restaurant.translate('idle_business_tables'),
                          value:
                              '${game.businessSeatedCount}/${game.diningCapacity}',
                        ),
                        _AutoMetricChip(
                          width: itemWidth,
                          icon: Icons.kitchen,
                          label: restaurant.translate('idle_business_kitchen'),
                          value: '${game.businessKitchenQueueCount}',
                        ),
                        _AutoMetricChip(
                          width: itemWidth,
                          icon: Icons.local_dining,
                          label: restaurant.translate('idle_business_eating'),
                          value: '${game.businessEatingCount}',
                        ),
                        _AutoMetricChip(
                          width: itemWidth,
                          icon: Icons.point_of_sale,
                          label: restaurant.translate('idle_business_checkout'),
                          value: '${game.businessCheckoutQueueCount}',
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: canClaim ? onClaim : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isTerminal ? theme.cyan : theme.accent,
                          foregroundColor:
                              isTerminal ? Colors.black : theme.ink,
                          disabledBackgroundColor: theme.surfaceHigh,
                          disabledForegroundColor:
                              theme.ink.withValues(alpha: 0.45),
                          side: BorderSide(
                            color: borderColor,
                            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              mode == AppThemeMode.neoBrutalism
                                  ? theme.radius
                                  : 0,
                            ),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.savings, size: 18),
                        label: Text(
                          canClaim
                              ? '+${game.formatCoins(game.pendingClaimableEarnings)}'
                              : restaurant.translate('idle_auto_running'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: onRush,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isTerminal ? theme.cyan : theme.ink,
                        side: BorderSide(
                          color: borderColor,
                          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            mode == AppThemeMode.neoBrutalism
                                ? theme.radius
                                : 0,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.local_fire_department, size: 18),
                      label: Text(
                        restaurant.translate('rush_open_boost'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AutoMetricChip extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _AutoMetricChip({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return SizedBox(
      width: width,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: isTerminal
              ? theme.background.withValues(alpha: 0.38)
              : theme.surfaceHigh,
          borderRadius: BorderRadius.circular(
            mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
          ),
          border: Border.all(
            color:
                isTerminal ? theme.cyan.withValues(alpha: 0.62) : theme.border,
            width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isTerminal ? theme.cyan : theme.accent, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.ink.withValues(alpha: 0.62),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockAction {
  final IconData icon;
  final String label;
  final int badgeCount;
  final void Function(BuildContext context) onTap;

  const _DockAction({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });
}

class _DockButton extends StatelessWidget {
  final _DockAction action;

  const _DockButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return SizedBox(
      height: 58,
      child: Material(
        color: isTerminal
            ? theme.background.withValues(alpha: 0.36)
            : theme.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: () => action.onTap(context),
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isTerminal ? theme.cyan : theme.border,
                width: mode == AppThemeMode.neoBrutalism ? 2 : 1.5,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        action.icon,
                        size: 19,
                        color: isTerminal ? theme.cyan : theme.ink,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action.badgeCount > 0)
                  Positioned(
                    top: 5,
                    right: 4,
                    child: _DockBadge(count: action.badgeCount),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalClaimChip extends StatelessWidget {
  final String label;

  const _GoalClaimChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isTerminal ? theme.cyan : theme.accent,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isTerminal ? Colors.black : theme.ink,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
        ),
      ),
    );
  }
}

class _DockBadge extends StatelessWidget {
  final int count;

  const _DockBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final label = count > 9 ? '9+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: theme.danger,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 999,
        ),
        border: Border.all(color: theme.border, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
          height: 1,
        ),
      ),
    );
  }
}

class _DishBookTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String menuLevelLabel;
  final String masteryLabel;
  final String servedLabel;
  final String rewardLabel;
  final String costLabel;
  final double masteryProgress;
  final String masteryProgressLabel;
  final bool canAfford;
  final bool locked;
  final VoidCallback? onTap;

  const _DishBookTile({
    required this.icon,
    required this.title,
    required this.menuLevelLabel,
    required this.masteryLabel,
    required this.servedLabel,
    required this.rewardLabel,
    required this.costLabel,
    required this.masteryProgress,
    required this.masteryProgressLabel,
    required this.canAfford,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;
    final borderWidth = mode == AppThemeMode.neoBrutalism ? 3.0 : 1.5;
    final accent = locked
        ? theme.ink.withValues(alpha: 0.38)
        : isTerminal
            ? theme.cyan
            : theme.accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: locked
              ? theme.border.withValues(alpha: 0.56)
              : isTerminal
                  ? theme.cyan
                  : theme.border,
          width: borderWidth,
        ),
        boxShadow: mode == AppThemeMode.neoBrutalism
            ? theme.hardShadow(offset: const Offset(3, 3))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink.withValues(alpha: locked ? 0.58 : 1),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rewardLabel,
                      style: TextStyle(
                        color: theme.ink.withValues(alpha: locked ? 0.44 : 1),
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _DishStatText(label: menuLevelLabel),
                    _DishStatText(label: masteryLabel),
                    _DishStatText(label: servedLabel),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(radius),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: masteryProgress,
                          backgroundColor: theme.surfaceHigh,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: Text(
                        masteryProgressLabel,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: theme.ink.withValues(alpha: 0.68),
                          fontSize: 11,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  costLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.ink.withValues(
                      alpha: canAfford && !locked ? 0.74 : 0.44,
                    ),
                    fontSize: 10,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: canAfford && !locked ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: accent,
                      foregroundColor: isTerminal ? Colors.black : theme.ink,
                      disabledBackgroundColor: theme.surfaceHigh,
                      disabledForegroundColor:
                          theme.ink.withValues(alpha: 0.42),
                      side: BorderSide(
                        color: isTerminal ? theme.cyan : theme.border,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      elevation: 0,
                    ),
                    child: Icon(locked ? Icons.lock : Icons.upgrade, size: 18),
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

class _DishStatText extends StatelessWidget {
  final String label;

  const _DishStatText({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Text(
      label,
      style: TextStyle(
        color: theme.ink.withValues(alpha: 0.66),
        fontSize: 11,
        height: 1.15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ProgressInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double progress;
  final String trailingLabel;

  const _ProgressInfoTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.progress,
    required this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;
    final accent = isTerminal ? theme.cyan : theme.accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
        boxShadow: mode == AppThemeMode.neoBrutalism
            ? theme.hardShadow(offset: const Offset(3, 3))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trailingLabel,
                      style: TextStyle(
                        color: theme.ink,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.64),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress,
                    backgroundColor: theme.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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

class _UpgradeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String trailingLabel;
  final bool canAfford;
  final VoidCallback onTap;

  const _UpgradeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailingLabel,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
        boxShadow: mode == AppThemeMode.neoBrutalism
            ? theme.hardShadow(offset: const Offset(3, 3))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isTerminal ? theme.cyan : theme.accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.64),
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailingLabel,
                style: TextStyle(
                  color: theme.ink,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 42,
                height: 34,
                child: ElevatedButton(
                  onPressed: canAfford ? onTap : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: isTerminal ? theme.cyan : theme.accent,
                    foregroundColor: isTerminal ? Colors.black : theme.ink,
                    disabledBackgroundColor: theme.surfaceHigh,
                    disabledForegroundColor: theme.ink.withValues(alpha: 0.42),
                    side: BorderSide(
                      color: isTerminal ? theme.cyan : theme.border,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.upgrade, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  final String label;

  const _DialogSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: isTerminal ? theme.cyan : theme.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
        ),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 420;
        final itemWidth =
            twoColumns ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: _StatTile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final _StatItem item;

  const _StatTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isTerminal ? theme.cyan.withValues(alpha: 0.62) : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            color: isTerminal ? theme.cyan : theme.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.ink.withValues(alpha: 0.68),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.ink,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final GameMilestone milestone;
  final Restaurant restaurant;
  final VoidCallback? onClaim;

  const _GoalTile({
    required this.milestone,
    required this.restaurant,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: milestone.claimable
              ? theme.accent
              : isTerminal
                  ? theme.cyan.withValues(alpha: 0.62)
                  : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            milestone.claimed ? Icons.check_circle : Icons.flag,
            color: milestone.claimable ? theme.accent : theme.ink,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.translate(milestone.titleKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  restaurant.translate(milestone.descriptionKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.64),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: milestone.progressRatio,
                    backgroundColor: theme.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            height: 38,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: isTerminal ? theme.cyan : theme.accent,
                foregroundColor: isTerminal ? Colors.black : theme.ink,
                disabledBackgroundColor: theme.surfaceHigh,
                disabledForegroundColor: theme.ink.withValues(alpha: 0.5),
                side: BorderSide(
                  color: isTerminal ? theme.cyan : theme.border,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  milestone.claimed
                      ? restaurant.translate('idle_claimed')
                      : restaurant.translate('idle_claim'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskTile extends StatelessWidget {
  final GameDailyTask task;
  final Restaurant restaurant;
  final VoidCallback? onClaim;

  const _DailyTaskTile({
    required this.task,
    required this.restaurant,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: task.claimable
              ? theme.accent
              : isTerminal
                  ? theme.cyan.withValues(alpha: 0.62)
                  : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            task.claimed ? Icons.check_circle : Icons.today,
            color: task.claimable ? theme.accent : theme.ink,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.translate(task.titleKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task.progress}/${task.target}',
                      style: TextStyle(
                        color: theme.ink.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  restaurant.translate(task.descriptionKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.64),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: task.progressRatio,
                    backgroundColor: theme.surfaceHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            height: 38,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: isTerminal ? theme.cyan : theme.accent,
                foregroundColor: isTerminal ? Colors.black : theme.ink,
                disabledBackgroundColor: theme.surfaceHigh,
                disabledForegroundColor: theme.ink.withValues(alpha: 0.5),
                side: BorderSide(
                  color: isTerminal ? theme.cyan : theme.border,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
                elevation: 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  task.claimed
                      ? restaurant.translate('idle_claimed')
                      : restaurant.translate('idle_claim'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
