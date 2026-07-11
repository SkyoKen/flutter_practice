import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/customer_arrival_stage.dart';
import 'package:cyber_table_order/components/game_status_bar.dart';
import 'package:cyber_table_order/components/kitchen_rush_panel.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/utils/app_message.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Timer? _businessTimer;
  final ScrollController _dashboardScrollController = ScrollController();
  DateTime _lastBusinessTickAt = DateTime.now();
  bool _businessTickInProgress = false;
  bool _saveRetryInProgress = false;
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
    _dashboardScrollController.dispose();
    super.dispose();
  }

  Future<void> _runBusinessTick() async {
    if (!mounted || _businessTickInProgress) return;
    final game = context.read<GameController>();
    if (!game.isLoaded) return;
    _businessTickInProgress = true;
    final restaurant = context.read<Restaurant>();
    final now = DateTime.now();
    final elapsed = now.difference(_lastBusinessTickAt);
    _lastBusinessTickAt = now;
    try {
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
    } finally {
      _businessTickInProgress = false;
    }
  }

  void _showKitchenRush(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final availableHeight = (MediaQuery.sizeOf(context).height - 190)
                .clamp(260.0, 390.0)
                .toDouble();
            final preferredHeight =
                largeText || game.customerOrderFoodId != null ? 390.0 : 260.0;
            final contentHeight =
                preferredHeight.clamp(260.0, availableHeight).toDouble();

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
              child: AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                child: SizedBox(
                  key: const ValueKey('kitchen-rush-dialog-content'),
                  height: contentHeight,
                  child: KitchenRushPanel(
                    restaurant: restaurant,
                    menu: restaurant.getMenu(),
                  ),
                ),
              ),
            );
          },
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
    final isTerminal = AppTheme.modeOf(context) == AppThemeMode.neonTerminal;
    AppMessage.show(
      context,
      backgroundColor: isTerminal ? theme.cyan : theme.accent,
      content: Text(
        '${restaurant.translate('idle_pending_income')} +${game.formatCoins(claimed)}',
        style: TextStyle(
          color: AppTheme.foregroundOn(
            isTerminal ? theme.cyan : theme.accent,
          ),
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
      duration: const Duration(seconds: 1),
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
    AppMessage.show(
      context,
      backgroundColor: theme.danger,
      content: Text(
        restaurant.translate('idle_not_enough_coins'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _retrySave(GameController game) async {
    if (_saveRetryInProgress) return;
    setState(() => _saveRetryInProgress = true);
    try {
      await game.save();
    } finally {
      if (mounted) {
        setState(() => _saveRetryInProgress = false);
      }
    }
  }

  Widget _buildSaveErrorStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        if (!game.hasSaveError) return const SizedBox.shrink();
        final theme = AppTheme.of(context);
        final mode = AppTheme.modeOf(context);
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

        return Container(
          key: const ValueKey('save-error-strip'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: mode == AppThemeMode.retroOS
              ? theme.surfaceHigh
              : theme.background,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.danger.withValues(alpha: isTerminal ? 0.14 : 0.1),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isTerminal ? theme.cyan : theme.danger,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.sync_problem, color: theme.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    restaurant.translate('idle_save_failed'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    key: const ValueKey('save-retry-action'),
                    onPressed:
                        _saveRetryInProgress ? null : () => _retrySave(game),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isTerminal ? theme.cyan : theme.ink,
                      side: BorderSide(
                        color: isTerminal ? theme.cyan : theme.danger,
                        width: mode == AppThemeMode.neoBrutalism ? 2 : 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text(
                      restaurant.translate('idle_retry'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                          actionKey: ValueKey('dish-upgrade-${food.id}'),
                          icon: locked ? Icons.lock : _foodIcon(food),
                          title: locked
                              ? restaurant.translate('idle_locked_dish')
                              : restaurant.foodName(food),
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
                          actionTooltip: locked
                              ? restaurant.translate('idle_locked')
                              : '${restaurant.translate('upgrade_action')}: ${restaurant.foodName(food)}',
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

  String _businessBottleneckKey(GameBusinessBottleneck bottleneck) {
    return switch (bottleneck) {
      GameBusinessBottleneck.seats => 'business_bottleneck_seats',
      GameBusinessBottleneck.kitchen => 'business_bottleneck_kitchen',
      GameBusinessBottleneck.dining => 'business_bottleneck_dining',
      GameBusinessBottleneck.checkout => 'business_bottleneck_checkout',
      GameBusinessBottleneck.balanced => 'business_bottleneck_balanced',
    };
  }

  String _formatRate(double value) {
    final formatted = value.toStringAsFixed(1);
    return formatted.endsWith('.0')
        ? formatted.substring(0, formatted.length - 2)
        : formatted;
  }

  void _showOperations(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<GameController>(
          builder: (context, game, child) {
            final diagnosis = game.businessDiagnosis;
            final previews = game.operationUpgradePreviews.toList()
              ..sort((left, right) {
                if (left.isRecommended != right.isRecommended) {
                  return left.isRecommended ? -1 : 1;
                }
                return left.type.index.compareTo(right.type.index);
              });

            return ThemedAppDialog(
              title: restaurant.translate('rush_operations'),
              icon: Icons.storefront,
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
                  _BusinessDiagnosisBanner(
                    diagnosis: diagnosis,
                    title: restaurant.translate('business_bottleneck_title'),
                    value: restaurant.translate(
                      _businessBottleneckKey(diagnosis.bottleneck),
                    ),
                    details:
                        '${restaurant.translate('business_throughput')} ${_formatRate(diagnosis.estimatedOrdersPerMinute)} ${restaurant.translate('business_orders_per_min')} · ${restaurant.translate('business_queue')} ${diagnosis.queueCount} · ${restaurant.translate('business_seat_load')} ${diagnosis.occupiedSeats}/${diagnosis.seatCapacity}',
                  ),
                  const SizedBox(height: 10),
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
                  for (var index = 0; index < previews.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _OperationUpgradeTile(
                      icon: switch (previews[index].type) {
                        GameOperationUpgradeType.seats =>
                          Icons.table_restaurant,
                        GameOperationUpgradeType.kitchen => Icons.kitchen,
                        GameOperationUpgradeType.service => Icons.support_agent,
                      },
                      title: restaurant.translate(
                        switch (previews[index].type) {
                          GameOperationUpgradeType.seats => 'idle_seats',
                          GameOperationUpgradeType.kitchen => 'idle_kitchen',
                          GameOperationUpgradeType.service => 'idle_service',
                        },
                      ),
                      preview: previews[index],
                      restaurant: restaurant,
                      game: game,
                      onTap: () => _attemptUpgrade(
                        context,
                        switch (previews[index].type) {
                          GameOperationUpgradeType.seats => game.upgradeSeats,
                          GameOperationUpgradeType.kitchen =>
                            game.upgradeKitchen,
                          GameOperationUpgradeType.service =>
                            game.upgradeService,
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showGoals(BuildContext context, Restaurant restaurant) {
    var showClaimedRewards = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer<GameController>(
              builder: (context, game, child) {
                final milestones = game.milestones;
                final dailyTasks = game.dailyTasks;
                final claimableMilestones = milestones
                    .where((milestone) => milestone.claimable)
                    .toList(growable: false);
                final claimableDailyTasks = dailyTasks
                    .where((task) => task.claimable)
                    .toList(growable: false);
                final activeMilestones = milestones
                    .where(
                      (milestone) => !milestone.claimed && !milestone.claimable,
                    )
                    .toList(growable: false);
                final activeDailyTasks = dailyTasks
                    .where((task) => !task.claimed && !task.claimable)
                    .toList(growable: false);
                final claimedMilestones = milestones
                    .where((milestone) => milestone.claimed)
                    .toList(growable: false);
                final claimedDailyTasks = dailyTasks
                    .where((task) => task.claimed)
                    .toList(growable: false);
                final hasClaimable = claimableMilestones.isNotEmpty ||
                    claimableDailyTasks.isNotEmpty;
                final claimedCount =
                    claimedMilestones.length + claimedDailyTasks.length;

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
                      if (hasClaimable) ...[
                        _DialogSectionLabel(
                          key: const ValueKey('claimable-rewards-section'),
                          label: restaurant.translate('rewards_ready_title'),
                        ),
                        const SizedBox(height: 10),
                        for (final milestone in claimableMilestones) ...[
                          _GoalTile(
                            milestone: milestone,
                            restaurant: restaurant,
                            onClaim: () =>
                                _claimMilestone(context, game, milestone),
                          ),
                          const SizedBox(height: 10),
                        ],
                        for (final task in claimableDailyTasks) ...[
                          _DailyTaskTile(
                            task: task,
                            restaurant: restaurant,
                            onClaim: () => _claimDailyTask(context, game, task),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                      if (activeMilestones.isNotEmpty) ...[
                        _DialogSectionLabel(
                          key: const ValueKey('active-goals-section'),
                          label:
                              restaurant.translate('goals_in_progress_title'),
                        ),
                        const SizedBox(height: 10),
                        for (final milestone in activeMilestones) ...[
                          _GoalTile(
                            milestone: milestone,
                            restaurant: restaurant,
                            onClaim: null,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                      if (activeDailyTasks.isNotEmpty) ...[
                        _DialogSectionLabel(
                          key: const ValueKey('active-daily-section'),
                          label: restaurant.translate('daily_tasks_title'),
                        ),
                        const SizedBox(height: 10),
                        for (final task in activeDailyTasks) ...[
                          _DailyTaskTile(
                            task: task,
                            restaurant: restaurant,
                            onClaim: null,
                          ),
                          const SizedBox(height: 10),
                        ],
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
                                '${game.claimedMilestoneIds.length}/${milestones.length}',
                          ),
                          _StatItem(
                            icon: Icons.today,
                            label: restaurant.translate('stat_today_claimed'),
                            value:
                                '${game.claimedDailyTaskIds.length}/${dailyTasks.length}',
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
                            label:
                                restaurant.translate('stat_lifetime_earnings'),
                            value: game.formatCoins(game.lifetimeEarnings),
                          ),
                          _StatItem(
                            icon: Icons.restaurant_menu,
                            label: restaurant.translate('stat_favorite_dish'),
                            value: _favoriteDishName(restaurant, game),
                          ),
                        ],
                      ),
                      if (claimedCount > 0) ...[
                        const SizedBox(height: 10),
                        _ClaimedRewardsToggle(
                          key: const ValueKey('claimed-rewards-toggle'),
                          label: restaurant.translate('claimed_rewards_title'),
                          count: claimedCount,
                          expanded: showClaimedRewards,
                          onTap: () => setDialogState(
                            () => showClaimedRewards = !showClaimedRewards,
                          ),
                        ),
                        if (showClaimedRewards) ...[
                          const SizedBox(height: 10),
                          for (final milestone in claimedMilestones) ...[
                            _GoalTile(
                              milestone: milestone,
                              restaurant: restaurant,
                              onClaim: null,
                            ),
                            const SizedBox(height: 10),
                          ],
                          for (final task in claimedDailyTasks) ...[
                            _DailyTaskTile(
                              task: task,
                              restaurant: restaurant,
                              onClaim: null,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ],
                    ],
                  ),
                );
              },
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
    final isTerminal = AppTheme.modeOf(context) == AppThemeMode.neonTerminal;
    AppMessage.show(
      context,
      backgroundColor: isTerminal ? theme.cyan : theme.accent,
      content: Text(
        '${restaurant.translate('idle_goal_claimed')} +${game.formatCoins(reward)}',
        style: TextStyle(
          color: AppTheme.foregroundOn(
            isTerminal ? theme.cyan : theme.accent,
          ),
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
      duration: const Duration(seconds: 1),
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
    final isTerminal = AppTheme.modeOf(context) == AppThemeMode.neonTerminal;
    AppMessage.show(
      context,
      backgroundColor: isTerminal ? theme.cyan : theme.accent,
      content: Text(
        '${restaurant.translate('idle_goal_claimed')} +${game.formatCoins(reward)}',
        style: TextStyle(
          color: AppTheme.foregroundOn(
            isTerminal ? theme.cyan : theme.accent,
          ),
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
        ),
      ),
      duration: const Duration(seconds: 1),
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
    return restaurant.foodName(menu.first);
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

  Widget _buildEventStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final titleKey = game.activeEventTitleKey;
        final descriptionKey = game.activeEventDescriptionKey;
        if (titleKey == null || descriptionKey == null) {
          return const SizedBox.shrink();
        }
        final theme = AppTheme.of(context);
        final mode = AppTheme.modeOf(context);
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
            key: const ValueKey('active-event-strip'),
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isTerminal ? theme.background : theme.amber,
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
                  key: const ValueKey('active-event-icon'),
                  isDiscount ? Icons.sell : Icons.bolt,
                  color: isTerminal
                      ? theme.cyan
                      : AppTheme.foregroundOn(theme.amber),
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

  _GoalStripData? _nextRewardGoal(GameController game) {
    final goals = <_GoalStripData>[
      for (final milestone in game.milestones)
        if (!milestone.claimed) _GoalStripData.fromMilestone(milestone),
      for (final task in game.dailyTasks)
        if (!task.claimed) _GoalStripData.fromDailyTask(task),
    ];
    if (goals.isEmpty) return null;

    for (final goal in goals) {
      if (goal.claimable) return goal;
    }

    var closest = goals.first;
    for (final goal in goals.skip(1)) {
      if (goal.progressRatio > closest.progressRatio) {
        closest = goal;
      }
    }
    return closest;
  }

  Widget _buildPriorityStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final goal = _nextRewardGoal(game);
        if (goal?.claimable ?? false) {
          return _buildNextGoalStrip(restaurant);
        }
        if (game.activeEventTitleKey != null) {
          return _buildEventStrip(restaurant);
        }
        return _buildNextGoalStrip(restaurant);
      },
    );
  }

  Widget _buildNextGoalStrip(Restaurant restaurant) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final goal = _nextRewardGoal(game);
        if (goal == null) return const SizedBox.shrink();
        final theme = AppTheme.of(context);
        final mode = AppTheme.modeOf(context);
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final highlighted = goal.claimable;
        final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;
        final onTap = !highlighted
            ? () => _showGoals(context, restaurant)
            : goal.milestone != null
                ? () => _claimMilestone(context, game, goal.milestone!)
                : () => _claimDailyTask(context, game, goal.dailyTask!);
        final displayProgress = goal.progress.clamp(0, goal.target);

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: mode == AppThemeMode.retroOS
              ? theme.surfaceHigh
              : theme.background,
          child: Ink(
            height: 54,
            decoration: BoxDecoration(
              color: highlighted && !isTerminal
                  ? theme.accent.withValues(alpha: 0.18)
                  : mode == AppThemeMode.retroOS
                      ? theme.surface
                      : theme.surfaceHigh,
              borderRadius: BorderRadius.circular(radius),
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
            child: Semantics(
              button: true,
              label:
                  '${restaurant.translate('rush_next_goal')}: ${restaurant.translate(goal.titleKey)}',
              hint: restaurant.translate(
                highlighted ? 'idle_claim' : 'idle_goals',
              ),
              child: InkWell(
                key: ValueKey('next-goal-action-${goal.id}'),
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              '${restaurant.translate('rush_next_goal')}: ${restaurant.translate(goal.titleKey)}',
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
                              borderRadius: BorderRadius.circular(radius),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value: goal.progressRatio,
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
                        _GoalClaimChip(
                          label: restaurant.translate('idle_claim'),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$displayProgress/${goal.target}',
                              style: TextStyle(
                                color: isTerminal ? theme.cyan : theme.ink,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Courier',
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              color: isTerminal ? theme.cyan : theme.ink,
                              size: 18,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
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
        ];

        final theme = AppTheme.of(context);
        final mode = AppTheme.modeOf(context);
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
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
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
        _buildSaveErrorStrip(restaurant),
        _buildPriorityStrip(restaurant),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bodyConstraints) {
              if (wideLandscape) {
                const minWideDashboardHeight = 190.0;
                final sidePanelWidth = (constraints.maxWidth * 0.34)
                    .clamp(300.0, 430.0)
                    .toDouble();

                Widget buildWideDashboard(double height) {
                  return SizedBox(
                    key: const ValueKey('wide-dashboard-row'),
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomerArrivalStage(
                            restaurant: restaurant,
                            menu: menu,
                            prominent: true,
                            height: height,
                            recentCompletedOrders: _recentCompletedOrders,
                            coinBurstSeed: _coinBurstSeed,
                          ),
                        ),
                        SizedBox(
                          width: sidePanelWidth,
                          height: height,
                          child: _IdleControlPanel(
                            restaurant: restaurant,
                            menu: menu,
                            sideRail: true,
                            onClaim: () => _claimOfflineEarnings(
                              context,
                              restaurant,
                            ),
                            onRush: () => _showKitchenRush(
                              context,
                              restaurant,
                            ),
                            onOperations: () =>
                                _showOperations(context, restaurant),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (bodyConstraints.maxHeight < minWideDashboardHeight) {
                  return Scrollbar(
                    key: const ValueKey('dashboard-scrollbar'),
                    controller: _dashboardScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      key: const ValueKey('wide-dashboard-scroll'),
                      controller: _dashboardScrollController,
                      child: buildWideDashboard(minWideDashboardHeight),
                    ),
                  );
                }

                return buildWideDashboard(bodyConstraints.maxHeight);
              }

              const minStageHeight = 190.0;
              final panelHeight = largeText ? 244.0 : 176.0;

              Widget buildStackedDashboard(double stageHeight) {
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
                      height: panelHeight,
                      child: _IdleControlPanel(
                        restaurant: restaurant,
                        menu: menu,
                        onClaim: () => _claimOfflineEarnings(
                          context,
                          restaurant,
                        ),
                        onRush: () => _showKitchenRush(context, restaurant),
                        onOperations: () =>
                            _showOperations(context, restaurant),
                      ),
                    ),
                  ],
                );
              }

              if (bodyConstraints.maxHeight < minStageHeight + panelHeight) {
                return Scrollbar(
                  key: const ValueKey('dashboard-scrollbar'),
                  controller: _dashboardScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _dashboardScrollController,
                    child: buildStackedDashboard(minStageHeight),
                  ),
                );
              }

              final stageHeight = bodyConstraints.maxHeight - panelHeight;

              return buildStackedDashboard(stageHeight);
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
          backgroundColor: AppTheme.of(context).background,
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

class _GoalStripData {
  final GameMilestone? milestone;
  final GameDailyTask? dailyTask;

  const _GoalStripData._({this.milestone, this.dailyTask});

  factory _GoalStripData.fromMilestone(GameMilestone milestone) {
    return _GoalStripData._(milestone: milestone);
  }

  factory _GoalStripData.fromDailyTask(GameDailyTask task) {
    return _GoalStripData._(dailyTask: task);
  }

  String get id => milestone?.id ?? dailyTask!.id;
  String get titleKey => milestone?.titleKey ?? dailyTask!.titleKey;
  int get progress => milestone?.progress ?? dailyTask!.progress;
  int get target => milestone?.target ?? dailyTask!.target;
  bool get claimable => milestone?.claimable ?? dailyTask!.claimable;
  double get progressRatio =>
      milestone?.progressRatio ?? dailyTask!.progressRatio;
}

class _IdleControlPanel extends StatelessWidget {
  final Restaurant restaurant;
  final List<Food> menu;
  final bool sideRail;
  final VoidCallback onClaim;
  final VoidCallback onRush;
  final VoidCallback onOperations;

  const _IdleControlPanel({
    required this.restaurant,
    required this.menu,
    this.sideRail = false,
    required this.onClaim,
    required this.onRush,
    required this.onOperations,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.modeOf(context);
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final isRetro = mode == AppThemeMode.retroOS;
        final borderColor = isTerminal ? theme.cyan : theme.border;
        final canClaim = game.pendingClaimableEarnings > 0;
        final recommendation = game.recommendedOperationUpgradePreview;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

        return Container(
          key: const ValueKey('idle-control-panel'),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              const metricGap = 8.0;
              final useMetricGrid =
                  sideRail && !largeText && constraints.maxHeight >= 390;
              final metricWidth = useMetricGrid
                  ? (constraints.maxWidth - metricGap) / 2
                  : (constraints.maxWidth * 0.44)
                      .clamp(132.0, 180.0)
                      .toDouble();
              final compactRecommendationWidth =
                  (constraints.maxWidth * 0.72).clamp(236.0, 280.0).toDouble();
              final buttonSide = BorderSide(
                color: borderColor,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              );
              final buttonShape = RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                ),
              );
              final metrics = [
                _AutoMetricChip(
                  key: const ValueKey('auto-metric-queue'),
                  width: metricWidth,
                  icon: Icons.people_alt,
                  label: restaurant.translate('idle_business_queue'),
                  value: '${game.businessQueueCount}/${game.businessMaxQueue}',
                ),
                _AutoMetricChip(
                  key: const ValueKey('auto-metric-tables'),
                  width: metricWidth,
                  icon: Icons.table_restaurant,
                  label: restaurant.translate('idle_business_tables'),
                  value: '${game.businessSeatedCount}/${game.diningCapacity}',
                ),
                _AutoMetricChip(
                  key: const ValueKey('auto-metric-kitchen'),
                  width: metricWidth,
                  icon: Icons.kitchen,
                  label: restaurant.translate('idle_business_kitchen'),
                  value: '${game.businessKitchenQueueCount}',
                ),
                _AutoMetricChip(
                  key: const ValueKey('auto-metric-dining'),
                  width: metricWidth,
                  icon: Icons.local_dining,
                  label: restaurant.translate('idle_business_eating'),
                  value: '${game.businessEatingCount}',
                ),
                _AutoMetricChip(
                  key: const ValueKey('auto-metric-checkout'),
                  width: useMetricGrid ? constraints.maxWidth : metricWidth,
                  icon: Icons.point_of_sale,
                  label: restaurant.translate('idle_business_checkout'),
                  value: '${game.businessCheckoutQueueCount}',
                ),
              ];

              final header = Row(
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
              );
              final metricSection = useMetricGrid
                  ? Column(
                      key: const ValueKey('idle-metrics-grid'),
                      children: [
                        Row(
                          children: [
                            metrics[0],
                            const SizedBox(width: metricGap),
                            metrics[1],
                          ],
                        ),
                        const SizedBox(height: metricGap),
                        Row(
                          children: [
                            metrics[2],
                            const SizedBox(width: metricGap),
                            metrics[3],
                          ],
                        ),
                        const SizedBox(height: metricGap),
                        metrics[4],
                      ],
                    )
                  : SizedBox(
                      key: const ValueKey('idle-metrics-scroll'),
                      height: largeText ? 96 : 58,
                      child: SingleChildScrollView(
                        primary: false,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (recommendation != null) ...[
                              _RecommendedUpgradeCard(
                                key: const ValueKey(
                                  'recommended-upgrade-compact',
                                ),
                                restaurant: restaurant,
                                game: game,
                                preview: recommendation,
                                width: compactRecommendationWidth,
                                compact: true,
                                onTap: onOperations,
                              ),
                              const SizedBox(width: metricGap),
                            ],
                            for (var index = 0;
                                index < metrics.length;
                                index++) ...[
                              if (index > 0) const SizedBox(width: metricGap),
                              metrics[index],
                            ],
                          ],
                        ),
                      ),
                    );
              final actions = Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        key: const ValueKey('idle-rush-action'),
                        onPressed: onRush,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isTerminal ? theme.cyan : theme.accent,
                          foregroundColor: AppTheme.foregroundOn(
                            isTerminal ? theme.cyan : theme.accent,
                          ),
                          side: buttonSide,
                          shape: buttonShape,
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.local_fire_department,
                          size: 18,
                        ),
                        label: Text(
                          restaurant.translate('rush_open_boost'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: Tooltip(
                        message: canClaim
                            ? '${restaurant.translate('idle_claim_income')} +${game.formatCoins(game.pendingClaimableEarnings)}'
                            : restaurant.translate('idle_claim_income'),
                        child: OutlinedButton.icon(
                          key: const ValueKey('idle-claim-action'),
                          onPressed: canClaim ? onClaim : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                isTerminal ? theme.cyan : theme.ink,
                            disabledForegroundColor:
                                theme.ink.withValues(alpha: 0.45),
                            side: buttonSide,
                            shape: buttonShape,
                          ),
                          icon: const Icon(Icons.savings, size: 18),
                          label: Text(
                            canClaim
                                ? '${restaurant.translate('idle_claim')} +${game.formatCoins(game.pendingClaimableEarnings)}'
                                : restaurant.translate('idle_claim'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
              final headerAndMetrics = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 10),
                  metricSection,
                ],
              );

              if (useMetricGrid) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerAndMetrics,
                    if (recommendation != null) ...[
                      const SizedBox(height: 10),
                      _RecommendedUpgradeCard(
                        key: const ValueKey('recommended-upgrade-full'),
                        restaurant: restaurant,
                        game: game,
                        preview: recommendation,
                        width: constraints.maxWidth,
                        onTap: onOperations,
                      ),
                    ],
                    const Spacer(),
                    actions,
                  ],
                );
              }

              return SingleChildScrollView(
                primary: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    headerAndMetrics,
                    const SizedBox(height: 10),
                    actions,
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RecommendedUpgradeCard extends StatelessWidget {
  final Restaurant restaurant;
  final GameController game;
  final GameOperationUpgradePreview preview;
  final double width;
  final bool compact;
  final VoidCallback onTap;

  const _RecommendedUpgradeCard({
    super.key,
    required this.restaurant,
    required this.game,
    required this.preview,
    required this.width,
    this.compact = false,
    required this.onTap,
  });

  String get _titleKey => switch (preview.type) {
        GameOperationUpgradeType.seats => 'idle_seats',
        GameOperationUpgradeType.kitchen => 'idle_kitchen',
        GameOperationUpgradeType.service => 'idle_service',
      };

  IconData get _icon => switch (preview.type) {
        GameOperationUpgradeType.seats => Icons.table_restaurant,
        GameOperationUpgradeType.kitchen => Icons.kitchen,
        GameOperationUpgradeType.service => Icons.support_agent,
      };

  String _formatPayback() {
    final fixed = (preview.paybackMinutes ?? 0).toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final accent = isTerminal ? theme.cyan : theme.accent;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;
    final title = restaurant.translate(_titleKey);
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final shortfall =
        (preview.cost - game.coins).clamp(0, double.infinity).toDouble();
    final needsCoins = shortfall > 0;
    final gainLabel = '+${game.formatCoins(preview.coinsPerMinuteGain)}/min';

    Widget buildCompactContent() {
      return Row(
        children: [
          Icon(_icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.translate('upgrade_next_best'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.62),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$title Lv ${preview.currentLevel} → ${preview.upgradedLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            gainLabel,
            style: TextStyle(
              color: accent,
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          Icon(Icons.chevron_right, color: accent, size: 17),
        ],
      );
    }

    Widget infoLabel({
      required String label,
      Key? key,
      bool emphasized = false,
    }) {
      return Text(
        key: key,
        label,
        style: TextStyle(
          color: emphasized ? accent : theme.ink.withValues(alpha: 0.72),
          fontFamily: 'Courier',
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    Widget buildFullContent() {
      return Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent, width: 1.5),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(_icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.translate('upgrade_next_best'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: isTerminal ? 'Courier' : null,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$title Lv ${preview.currentLevel} → ${preview.upgradedLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 9,
                  runSpacing: 2,
                  children: [
                    infoLabel(label: gainLabel, emphasized: true),
                    infoLabel(
                      key: const ValueKey('recommended-upgrade-payback'),
                      label:
                          '${restaurant.translate('upgrade_payback')} ${_formatPayback()} ${restaurant.translate('upgrade_minutes_short')}',
                    ),
                    infoLabel(
                      key: needsCoins
                          ? const ValueKey('recommended-upgrade-shortfall')
                          : null,
                      label: needsCoins
                          ? '${restaurant.translate('upgrade_shortfall')} ${game.formatCoins(shortfall)}'
                          : '${restaurant.translate('idle_cost')} ${game.formatCoins(preview.cost)}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.chevron_right, color: accent, size: 20),
        ],
      );
    }

    return SizedBox(
      width: width,
      height: compact
          ? largeText
              ? 96
              : 58
          : largeText
              ? 136
              : 108,
      child: Material(
        key: const ValueKey('recommended-upgrade-card'),
        color: Colors.transparent,
        child: Semantics(
          button: true,
          label:
              '${restaurant.translate('upgrade_next_best')}: $title Lv ${preview.upgradedLevel}',
          child: Ink(
            decoration: BoxDecoration(
              color: isTerminal
                  ? theme.background.withValues(alpha: 0.48)
                  : theme.surfaceHigh,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: accent,
                width: mode == AppThemeMode.neoBrutalism ? 2.5 : 1.5,
              ),
            ),
            child: InkWell(
              key: ValueKey('recommended-upgrade-action-${preview.type.name}'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 11,
                  vertical: compact ? 6 : 8,
                ),
                child: compact ? buildCompactContent() : buildFullContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoMetricChip extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _AutoMetricChip({
    super.key,
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;

    return SizedBox(
      width: width,
      child: Container(
        height: largeText ? 96 : 58,
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
    final mode = AppTheme.modeOf(context);
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
    final mode = AppTheme.modeOf(context);
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
          color: AppTheme.foregroundOn(
            isTerminal ? theme.cyan : theme.accent,
          ),
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
    final mode = AppTheme.modeOf(context);
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
  final Key actionKey;
  final IconData icon;
  final String title;
  final String menuLevelLabel;
  final String masteryLabel;
  final String servedLabel;
  final String rewardLabel;
  final String costLabel;
  final String actionTooltip;
  final double masteryProgress;
  final String masteryProgressLabel;
  final bool canAfford;
  final bool locked;
  final VoidCallback? onTap;

  const _DishBookTile({
    required this.actionKey,
    required this.icon,
    required this.title,
    required this.menuLevelLabel,
    required this.masteryLabel,
    required this.servedLabel,
    required this.rewardLabel,
    required this.costLabel,
    required this.actionTooltip,
    required this.masteryProgress,
    required this.masteryProgressLabel,
    required this.canAfford,
    this.locked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
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
                Tooltip(
                  message: actionTooltip,
                  child: Semantics(
                    button: true,
                    enabled: canAfford && !locked,
                    label: actionTooltip,
                    excludeSemantics: true,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: actionKey,
                        onPressed: canAfford && !locked ? onTap : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: accent,
                          foregroundColor: AppTheme.foregroundOn(accent),
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
                        child: Icon(
                          locked ? Icons.lock : Icons.upgrade,
                          size: 18,
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
    final mode = AppTheme.modeOf(context);
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

class _BusinessDiagnosisBanner extends StatelessWidget {
  final GameBusinessDiagnosis diagnosis;
  final String title;
  final String value;
  final String details;

  const _BusinessDiagnosisBanner({
    required this.diagnosis,
    required this.title,
    required this.value,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isBalanced = diagnosis.bottleneck == GameBusinessBottleneck.balanced;
    final accent = isBalanced
        ? isTerminal
            ? theme.cyan
            : theme.accent
        : theme.amber;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;
    final backgroundColor = isTerminal
        ? theme.background
        : Color.alphaBlend(
            accent.withValues(alpha: 0.16),
            theme.surface,
          );

    return Container(
      key: ValueKey('business-diagnosis-${diagnosis.bottleneck.name}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isTerminal ? theme.cyan : accent,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
        boxShadow: mode == AppThemeMode.neoBrutalism
            ? theme.hardShadow(offset: const Offset(3, 3))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle : Icons.warning_amber,
            color: accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.66),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.68),
                    fontFamily: 'Courier',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _OperationUpgradeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final GameOperationUpgradePreview preview;
  final Restaurant restaurant;
  final GameController game;
  final VoidCallback onTap;

  const _OperationUpgradeTile({
    required this.icon,
    required this.title,
    required this.preview,
    required this.restaurant,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;
    final accent = preview.isRecommended
        ? isTerminal
            ? theme.cyan
            : theme.accent
        : isTerminal
            ? theme.cyan
            : theme.border;
    final currentLabel = restaurant.translate('upgrade_preview_current');
    final projectedLabel = restaurant.translate('upgrade_preview_projected');
    final gainLabel = restaurant.translate('upgrade_preview_gain');
    final rateLabel = restaurant.translate('idle_coins_per_min');
    final costLabel = restaurant.translate('idle_cost');

    return Container(
      key: ValueKey('operation-preview-${preview.type.name}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
        boxShadow: preview.isRecommended && mode == AppThemeMode.neoBrutalism
            ? theme.hardShadow(offset: const Offset(3, 3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isTerminal ? theme.cyan : theme.accent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title Lv ${preview.currentLevel} → ${preview.upgradedLevel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (preview.isRecommended) ...[
                const SizedBox(width: 8),
                _OperationPreviewChip(
                  label: restaurant.translate('upgrade_recommended'),
                  emphasized: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$currentLabel ${game.formatCoins(preview.currentCoinsPerMinute)}',
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.68),
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: isTerminal ? theme.cyan : theme.accent,
              ),
              Text(
                '$projectedLabel ${game.formatCoins(preview.upgradedCoinsPerMinute)} $rateLabel',
                style: TextStyle(
                  color: theme.ink,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 5,
                  children: [
                    _OperationPreviewChip(
                      label:
                          '$gainLabel +${game.formatCoins(preview.coinsPerMinuteGain)} $rateLabel',
                      emphasized: preview.isRecommended,
                    ),
                    _OperationPreviewChip(
                      label: '$costLabel ${game.formatCoins(preview.cost)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: '$title Lv ${preview.upgradedLevel}',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    key: ValueKey('operation-upgrade-${preview.type.name}'),
                    onPressed: preview.canAfford ? onTap : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: isTerminal ? theme.cyan : theme.accent,
                      foregroundColor: AppTheme.foregroundOn(
                        isTerminal ? theme.cyan : theme.accent,
                      ),
                      disabledBackgroundColor: theme.surfaceHigh,
                      disabledForegroundColor:
                          theme.ink.withValues(alpha: 0.42),
                      side: BorderSide(color: accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.upgrade, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationPreviewChip extends StatelessWidget {
  final String label;
  final bool emphasized;

  const _OperationPreviewChip({
    required this.label,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final accent = isTerminal ? theme.cyan : theme.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized ? accent.withValues(alpha: 0.18) : theme.surfaceHigh,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
        border: Border.all(
          color: emphasized ? accent : theme.border.withValues(alpha: 0.7),
          width: emphasized && mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.ink,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
        ),
      ),
    );
  }
}

class _DialogSectionLabel extends StatelessWidget {
  final String label;

  const _DialogSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.modeOf(context) == AppThemeMode.neonTerminal;

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

class _ClaimedRewardsToggle extends StatelessWidget {
  final String label;
  final int count;
  final bool expanded;
  final VoidCallback onTap;

  const _ClaimedRewardsToggle({
    super.key,
    required this.label,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Semantics(
      button: true,
      expanded: expanded,
      label: '$label ($count)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: mode == AppThemeMode.retroOS
                  ? theme.surfaceHigh
                  : theme.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isTerminal ? theme.cyan : theme.border,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: theme.ink, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$label ($count)',
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: isTerminal ? theme.cyan : theme.ink,
                ),
              ],
            ),
          ),
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
    final mode = AppTheme.modeOf(context);
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
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    return Container(
      key: ValueKey('goal-tile-${milestone.id}'),
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
            height: 48,
            child: ElevatedButton(
              key: ValueKey('goal-claim-${milestone.id}'),
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: isTerminal ? theme.cyan : theme.accent,
                foregroundColor: AppTheme.foregroundOn(
                  isTerminal ? theme.cyan : theme.accent,
                ),
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
    final mode = AppTheme.modeOf(context);
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final radius = mode == AppThemeMode.neoBrutalism ? theme.radius : 0.0;

    final displayProgress = task.progress.clamp(0, task.target);

    return Container(
      key: ValueKey('daily-task-tile-${task.id}'),
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
                      '$displayProgress/${task.target}',
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
            height: 48,
            child: ElevatedButton(
              key: ValueKey('daily-task-claim-${task.id}'),
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: isTerminal ? theme.cyan : theme.accent,
                foregroundColor: AppTheme.foregroundOn(
                  isTerminal ? theme.cyan : theme.accent,
                ),
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
