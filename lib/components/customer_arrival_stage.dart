import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/game_controller.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

class CustomerArrivalStage extends StatefulWidget {
  final Restaurant restaurant;
  final List<Food> menu;
  final double? height;
  final bool prominent;
  final int recentCompletedOrders;
  final int coinBurstSeed;

  const CustomerArrivalStage({
    super.key,
    required this.restaurant,
    required this.menu,
    this.height,
    this.prominent = false,
    this.recentCompletedOrders = 0,
    this.coinBurstSeed = 0,
  });

  @override
  State<CustomerArrivalStage> createState() => _CustomerArrivalStageState();
}

class _CustomerArrivalStageState extends State<CustomerArrivalStage>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _coinController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationPolicy();
  }

  @override
  void didUpdateWidget(CustomerArrivalStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimationPolicy();
    if (widget.coinBurstSeed != oldWidget.coinBurstSeed &&
        widget.recentCompletedOrders > 0 &&
        !MediaQuery.disableAnimationsOf(context)) {
      _coinController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  void _syncAnimationPolicy() {
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (disabled) {
      _loopController.stop();
      _coinController.stop();
      return;
    }
    if (!_loopController.isAnimating) {
      _loopController.repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, game, child) {
        return AnimatedBuilder(
          animation: _loopController,
          builder: (context, child) {
            return AnimatedBuilder(
              animation: _coinController,
              builder: (context, child) {
                return _buildFloor(
                  context,
                  game,
                  MediaQuery.disableAnimationsOf(context)
                      ? 0
                      : _loopController.value,
                  MediaQuery.disableAnimationsOf(context)
                      ? 1
                      : _coinController.value,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFloor(
    BuildContext context,
    GameController game,
    double loopProgress,
    double coinProgress,
  ) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isRetro = mode == AppThemeMode.retroOS;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final now = DateTime.now();
    final customers = game.diningCustomers;
    final manualCustomer = game.manualDiningCustomer;
    final activeFood = _foodForCustomer(manualCustomer) ?? _activeFood(game);
    final remaining = game.customerArrivalRemaining(now);
    final waiting = manualCustomer == null && remaining > Duration.zero;
    final ready = manualCustomer == null && !waiting;
    final tableCount = _visibleTableCount(game);
    final staffCount = _visibleStaffCount(game);
    final activeTableIndex = manualCustomer?.seatIndex ??
        (tableCount == 0
            ? 0
            : game.customerOrdersServed % math.max(1, tableCount));
    final title = _stageTitle(game, manualCustomer, activeFood);
    final detail = _stageDetail(game, manualCustomer);
    final serviceActive = customers.any(
      (customer) =>
          customer.phase == GameDiningCustomerPhase.waitingForFood ||
          customer.phase == GameDiningCustomerPhase.servingFood ||
          customer.phase == GameDiningCustomerPhase.checkout,
    );
    final stageHeight = widget.height ??
        (widget.prominent
            ? MediaQuery.sizeOf(context).width < 620
                ? 260.0
                : 320.0
            : MediaQuery.sizeOf(context).width < 620
                ? 150.0
                : 178.0);

    return Container(
      height: stageHeight,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: isRetro ? theme.surfaceHigh : theme.surface,
        border: Border(
          bottom: BorderSide(
            color: isTerminal ? theme.cyan : theme.border,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
          ),
        ),
        boxShadow: isTerminal ? theme.softGlow(theme.cyan) : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compact = width < 620;
          final tall = stageHeight >= 220;
          final serviceWidth = compact ? 70.0 : 108.0;
          final floorTop = tall
              ? compact
                  ? 86.0
                  : 92.0
              : compact
                  ? 56.0
                  : 58.0;
          final floorHeight = tall
              ? math.max(82.0, stageHeight - floorTop - 30)
              : compact
                  ? 62.0
                  : 92.0;
          final entranceX = 12.0;
          final floorLeft = compact ? 42.0 : 56.0;
          final floorRight = math.max(
            floorLeft + 80,
            width - serviceWidth - 16,
          );
          final counterCenter = Offset(
            width - serviceWidth / 2,
            floorTop + floorHeight * 0.5,
          );
          final exitPoint = Offset(entranceX, floorTop + floorHeight / 2);
          final tableCenters = _tableCenters(
            tableCount: tableCount,
            floorLeft: floorLeft,
            floorRight: floorRight,
            floorTop: floorTop,
            floorHeight: floorHeight,
            compact: compact,
          );
          final fallbackTable = tableCenters.isEmpty
              ? Offset(floorLeft, floorTop + floorHeight / 2)
              : tableCenters[
                  activeTableIndex.clamp(0, tableCenters.length - 1).toInt()];
          final cycle = loopProgress * math.pi * 2;
          final queueCustomers = customers
              .where(
                (customer) =>
                    customer.phase == GameDiningCustomerPhase.queueing,
              )
              .toList();
          final servingCustomers = customers
              .where(
                (customer) =>
                    customer.phase == GameDiningCustomerPhase.servingFood,
              )
              .toList();
          final checkoutCustomers = customers
              .where(
                (customer) =>
                    customer.phase == GameDiningCustomerPhase.checkout,
              )
              .toList();
          final leavingPoint = Offset(
            lerpDouble(counterCenter.dx, exitPoint.dx, coinProgress)!,
            lerpDouble(counterCenter.dy, exitPoint.dy, coinProgress)!,
          );

          Offset tablePointFor(GameDiningCustomer customer) {
            if (tableCenters.isEmpty) return fallbackTable;
            final index = (customer.seatIndex ?? 0)
                .clamp(0, tableCenters.length - 1)
                .toInt();
            return tableCenters[index];
          }

          Offset queuePointFor(GameDiningCustomer customer) {
            final queueIndex = math.max(
                0, queueCustomers.indexWhere((c) => c.id == customer.id));
            return Offset(
              entranceX +
                  queueIndex * (compact ? 13 : 17) +
                  math.sin(cycle + queueIndex * 0.7) * 2,
              floorTop +
                  floorHeight / 2 +
                  math.sin(cycle + queueIndex * 1.1) * 2,
            );
          }

          Offset customerPointFor(GameDiningCustomer customer) {
            final tablePoint = tablePointFor(customer);
            final phaseProgress =
                game.diningCustomerPhaseProgress(customer, now);
            if (customer.phase == GameDiningCustomerPhase.queueing) {
              return queuePointFor(customer);
            }
            if (customer.phase == GameDiningCustomerPhase.seating) {
              final from = Offset(entranceX, floorTop + floorHeight / 2);
              return Offset(
                lerpDouble(from.dx, tablePoint.dx, phaseProgress)!,
                lerpDouble(from.dy, tablePoint.dy, phaseProgress)!,
              );
            }
            if (customer.phase == GameDiningCustomerPhase.leaving) {
              return Offset(
                lerpDouble(tablePoint.dx, exitPoint.dx, phaseProgress)!,
                lerpDouble(tablePoint.dy, exitPoint.dy, phaseProgress)!,
              );
            }
            return tablePoint;
          }

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _stageIcon(manualCustomer, waiting),
                          size: 16,
                          color: manualCustomer != null || ready
                              ? theme.accent
                              : isTerminal
                                  ? theme.cyan
                                  : theme.ink.withValues(alpha: 0.72),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isTerminal ? theme.cyan : theme.ink,
                              fontWeight: FontWeight.w900,
                              fontFamily:
                                  isTerminal || isPaper ? 'Courier' : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          detail,
                          style: TextStyle(
                            color: manualCustomer != null || ready
                                ? theme.accent
                                : theme.ink,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _StageStat(
                          icon: Icons.people_alt,
                          label: widget.restaurant
                              .translate('idle_business_queue'),
                          value:
                              '${game.businessQueueCount}/${game.businessMaxQueue}',
                        ),
                        const SizedBox(width: 8),
                        _StageStat(
                          icon: Icons.table_restaurant,
                          label: widget.restaurant
                              .translate('idle_business_tables'),
                          value:
                              '${game.businessSeatedCount}/${game.diningCapacity}',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StageStat(
                            icon: Icons.kitchen,
                            label: widget.restaurant
                                .translate('idle_business_flow'),
                            value:
                                'K${game.businessKitchenQueueCount} E${game.businessEatingCount} P${game.businessCheckoutQueueCount}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                left: entranceX,
                top: floorTop + floorHeight / 2 - 18,
                child: _EntranceMarker(
                  active: ready ||
                      waiting ||
                      customers.any(
                        (customer) =>
                            customer.phase ==
                                GameDiningCustomerPhase.queueing ||
                            customer.phase == GameDiningCustomerPhase.seating,
                      ),
                ),
              ),
              Positioned(
                left: floorLeft - 12,
                right: serviceWidth - 2,
                top: floorTop + floorHeight / 2 - 1,
                child: Container(
                  height: mode == AppThemeMode.neoBrutalism ? 4 : 2,
                  color: (isTerminal ? theme.cyan : theme.border).withValues(
                    alpha: waiting || customers.isNotEmpty ? 0.34 : 0.18,
                  ),
                ),
              ),
              for (var index = 0; index < tableCenters.length; index++)
                Positioned(
                  left: tableCenters[index].dx - (compact ? 20 : 23),
                  top: tableCenters[index].dy - (compact ? 15 : 19),
                  child: _DiningTable(
                    index: index + 1,
                    size: compact ? 34 : 46,
                    active: index == activeTableIndex,
                    phase: _businessTablePhaseForCustomer(
                      _customerForSeat(customers, index),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                top: floorTop - 4,
                child: _ServiceCounter(
                  width: serviceWidth,
                  height: floorHeight + 10,
                  staffCount: staffCount,
                  active: serviceActive,
                ),
              ),
              for (var index = 0; index < staffCount; index++)
                Positioned(
                  right: 14 + (index % 2) * (compact ? 24 : 28),
                  top: floorTop +
                      8 +
                      (index ~/ 2) * (compact ? 22 : 31) +
                      math.sin(cycle + index) * (serviceActive ? 2 : 0.8),
                  child: _ServerSprite(
                    size: compact ? 20 : 26,
                    active: serviceActive,
                  ),
                ),
              for (final customer in servingCustomers)
                Positioned(
                  left: lerpDouble(
                        counterCenter.dx,
                        tablePointFor(customer).dx,
                        game.diningCustomerPhaseProgress(customer, now),
                      )! -
                      (compact ? 10 : 12),
                  top: lerpDouble(
                        counterCenter.dy,
                        tablePointFor(customer).dy,
                        game.diningCustomerPhaseProgress(customer, now),
                      )! -
                      (compact ? 10 : 12),
                  child: _OrderFlowChip(
                    index: customer.id,
                    active: true,
                    checkout: false,
                  ),
                ),
              for (final customer in checkoutCustomers)
                Positioned(
                  left: tablePointFor(customer).dx + (compact ? 7 : 12),
                  top: tablePointFor(customer).dy - (compact ? 22 : 28),
                  child: _OrderFlowChip(
                    index: customer.id,
                    active: true,
                    checkout: true,
                  ),
                ),
              for (final customer in customers)
                if (_customerVisibleOnStage(customer, tableCenters.length))
                  Positioned(
                    left: customerPointFor(customer).dx - (compact ? 12 : 14),
                    top: customerPointFor(customer).dy -
                        (compact ? 12 : 14) +
                        _customerBob(customer, game, now, cycle),
                    child: _CustomerSprite(
                      key: ValueKey('dining-customer-${customer.id}'),
                      size: customer.isManual
                          ? compact
                              ? 27
                              : 34
                          : compact
                              ? 24
                              : 30,
                      waiting: customer.phase ==
                              GameDiningCustomerPhase.queueing ||
                          customer.phase == GameDiningCustomerPhase.seating ||
                          customer.phase == GameDiningCustomerPhase.leaving,
                      ready: customer.phase ==
                          GameDiningCustomerPhase.waitingForFood,
                      serving: customer.phase ==
                              GameDiningCustomerPhase.servingFood ||
                          customer.phase == GameDiningCustomerPhase.eating ||
                          customer.phase == GameDiningCustomerPhase.checkout,
                    ),
                  ),
              if (widget.recentCompletedOrders > 0 && widget.coinBurstSeed > 0)
                Positioned(
                  left: leavingPoint.dx - (compact ? 12 : 14),
                  top: leavingPoint.dy -
                      (compact ? 12 : 14) +
                      math.sin(cycle * 2) * 2,
                  child: Opacity(
                    opacity: (1 - coinProgress).clamp(0, 1).toDouble(),
                    child: _CustomerSprite(
                      key: const ValueKey('business-leaving-customer'),
                      size: compact ? 24 : 28,
                      waiting: true,
                      ready: false,
                      serving: false,
                    ),
                  ),
                ),
              if (widget.recentCompletedOrders > 0 && widget.coinBurstSeed > 0)
                Positioned(
                  right: compact ? 8 : 18,
                  top: floorTop +
                      floorHeight * 0.34 -
                      coinProgress * (compact ? 18 : 26),
                  child: Opacity(
                    opacity: (1 - coinProgress).clamp(0, 1).toDouble(),
                    child: _CoinBurst(
                      key: const ValueKey('coin-burst'),
                      label:
                          '+${game.formatCoins(game.averageAutoOrderReward * widget.recentCompletedOrders)} x${widget.recentCompletedOrders}',
                    ),
                  ),
                ),
              Positioned(
                left: floorLeft,
                right: serviceWidth + 10,
                bottom: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: manualCustomer == null
                        ? game.businessLoadRatio
                        : game.diningCustomerPhaseProgress(
                            manualCustomer,
                            now,
                          ),
                    backgroundColor: theme.ink.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      manualCustomer != null || ready
                          ? theme.accent
                          : isTerminal
                              ? theme.cyan
                              : theme.accentSoft,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Food? _activeFood(GameController game) {
    final foodId = game.customerOrderFoodId;
    if (foodId == null) return null;
    for (final food in widget.menu) {
      if (food.id == foodId) return food;
    }
    return null;
  }

  Food? _foodForCustomer(GameDiningCustomer? customer) {
    final foodId = customer?.foodId;
    if (foodId == null) return null;
    for (final food in widget.menu) {
      if (food.id == foodId) return food;
    }
    return null;
  }

  String _stageTitle(
    GameController game,
    GameDiningCustomer? manualCustomer,
    Food? activeFood,
  ) {
    if (manualCustomer == null) {
      return widget.restaurant.translate('idle_auto_running');
    }
    return switch (manualCustomer.phase) {
      GameDiningCustomerPhase.queueing ||
      GameDiningCustomerPhase.seating =>
        widget.restaurant.translate('idle_customer_stage_waiting'),
      GameDiningCustomerPhase.waitingForFood =>
        '${widget.restaurant.translate('idle_customer_stage_serving')}: ${activeFood?.name ?? ''}',
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

  String _stageDetail(
    GameController game,
    GameDiningCustomer? manualCustomer,
  ) {
    if (manualCustomer == null) {
      return '+${game.formatCoins(game.pendingBusinessEarnings)}';
    }
    final reward = manualCustomer.reward > 0
        ? manualCustomer.reward
        : game.customerOrderReward;
    if (manualCustomer.phase == GameDiningCustomerPhase.seating) {
      return widget.restaurant.translate('idle_new_customer_order');
    }
    if (manualCustomer.phase == GameDiningCustomerPhase.waitingForFood) {
      return '+${game.formatCoins(reward)}';
    }
    if (manualCustomer.phase == GameDiningCustomerPhase.leaving) {
      return widget.restaurant.translate('rush_leaving_title');
    }
    return '+${game.formatCoins(reward)}';
  }

  IconData _stageIcon(GameDiningCustomer? manualCustomer, bool waiting) {
    if (manualCustomer == null) {
      return waiting ? Icons.hourglass_bottom : Icons.storefront;
    }
    return switch (manualCustomer.phase) {
      GameDiningCustomerPhase.queueing ||
      GameDiningCustomerPhase.seating =>
        Icons.directions_walk,
      GameDiningCustomerPhase.waitingForFood => Icons.receipt_long,
      GameDiningCustomerPhase.servingFood => Icons.room_service,
      GameDiningCustomerPhase.eating => Icons.local_dining,
      GameDiningCustomerPhase.checkout => Icons.point_of_sale,
      GameDiningCustomerPhase.leaving => Icons.directions_walk,
    };
  }

  int _visibleTableCount(GameController game) {
    return (game.seatLevel + 1).clamp(2, 6).toInt();
  }

  int _visibleStaffCount(GameController game) {
    return game.serviceLevel.clamp(1, 4).toInt();
  }

  GameDiningCustomer? _customerForSeat(
    List<GameDiningCustomer> customers,
    int index,
  ) {
    for (final customer in customers) {
      if (customer.seatIndex == index &&
          customer.phase != GameDiningCustomerPhase.queueing) {
        return customer;
      }
    }
    return null;
  }

  _BusinessTablePhase _businessTablePhaseForCustomer(
    GameDiningCustomer? customer,
  ) {
    if (customer == null) return _BusinessTablePhase.empty;
    return switch (customer.phase) {
      GameDiningCustomerPhase.queueing => _BusinessTablePhase.empty,
      GameDiningCustomerPhase.seating ||
      GameDiningCustomerPhase.waitingForFood =>
        _BusinessTablePhase.waitingForFood,
      GameDiningCustomerPhase.servingFood => _BusinessTablePhase.servingFood,
      GameDiningCustomerPhase.eating => _BusinessTablePhase.eating,
      GameDiningCustomerPhase.checkout ||
      GameDiningCustomerPhase.leaving =>
        _BusinessTablePhase.checkout,
    };
  }

  bool _customerVisibleOnStage(
    GameDiningCustomer customer,
    int visibleTableCount,
  ) {
    if (customer.phase == GameDiningCustomerPhase.queueing) return true;
    final seatIndex = customer.seatIndex;
    return seatIndex != null && seatIndex >= 0 && seatIndex < visibleTableCount;
  }

  double _customerBob(
    GameDiningCustomer customer,
    GameController game,
    DateTime now,
    double cycle,
  ) {
    if (customer.phase == GameDiningCustomerPhase.seating) {
      final progress = game.diningCustomerPhaseProgress(customer, now);
      return math.sin(progress * math.pi * 8) * 2.5;
    }
    if (customer.phase == GameDiningCustomerPhase.queueing ||
        customer.phase == GameDiningCustomerPhase.leaving) {
      return math.sin(cycle + customer.id * 0.7) * 2;
    }
    return 0;
  }

  List<Offset> _tableCenters({
    required int tableCount,
    required double floorLeft,
    required double floorRight,
    required double floorTop,
    required double floorHeight,
    required bool compact,
  }) {
    final columns = math.min(compact ? 3 : 4, tableCount);
    final rows = (tableCount / columns).ceil();
    final width = floorRight - floorLeft;
    final cellWidth = width / columns;
    final cellHeight = floorHeight / rows;

    return [
      for (var index = 0; index < tableCount; index++)
        Offset(
          floorLeft + cellWidth * (index % columns + 0.5),
          floorTop + cellHeight * (index ~/ columns + 0.5),
        ),
    ];
  }
}

class _StageStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StageStat({
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
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isTerminal
            ? theme.background.withValues(alpha: 0.38)
            : theme.surfaceHigh,
        border: Border.all(
          color: isTerminal ? theme.cyan.withValues(alpha: 0.5) : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isTerminal ? theme.cyan : theme.ink),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label $value',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.ink,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFlowChip extends StatelessWidget {
  final int index;
  final bool active;
  final bool checkout;

  const _OrderFlowChip({
    required this.index,
    required this.active,
    required this.checkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final accent = checkout ? theme.accent : theme.amber;

    return Container(
      key: ValueKey(
        checkout ? 'checkout-order-chip-$index' : 'kitchen-order-chip-$index',
      ),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: isTerminal
            ? theme.background.withValues(alpha: 0.68)
            : accent.withValues(alpha: active ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 2,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan : accent,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
        boxShadow: isTerminal ? theme.softGlow(theme.cyan) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            checkout ? Icons.point_of_sale : Icons.receipt_long,
            size: 12,
            color: isTerminal ? theme.cyan : accent,
          ),
          const SizedBox(width: 4),
          Text(
            checkout ? '\$' : '${index + 1}',
            style: TextStyle(
              color: isTerminal ? theme.cyan : theme.ink,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinBurst extends StatelessWidget {
  final String label;

  const _CoinBurst({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isTerminal ? theme.cyan : theme.accent,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 999,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
        ),
        boxShadow: isTerminal
            ? theme.softGlow(theme.cyan)
            : mode == AppThemeMode.neoBrutalism
                ? theme.hardShadow(offset: const Offset(3, 3))
                : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isTerminal ? theme.background : theme.ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
        ),
      ),
    );
  }
}

enum _BusinessTablePhase {
  empty,
  waitingForFood,
  servingFood,
  eating,
  checkout,
}

class _DiningTable extends StatelessWidget {
  final int index;
  final double size;
  final bool active;
  final _BusinessTablePhase phase;

  const _DiningTable({
    required this.index,
    required this.size,
    required this.active,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final occupied = phase != _BusinessTablePhase.empty;
    final statusIcon = switch (phase) {
      _BusinessTablePhase.waitingForFood => Icons.receipt_long,
      _BusinessTablePhase.servingFood => Icons.room_service,
      _BusinessTablePhase.eating => Icons.local_dining,
      _BusinessTablePhase.checkout => Icons.point_of_sale,
      _BusinessTablePhase.empty => Icons.table_restaurant,
    };
    final statusColor = switch (phase) {
      _BusinessTablePhase.waitingForFood => theme.amber,
      _BusinessTablePhase.servingFood => theme.amber,
      _BusinessTablePhase.eating => theme.accent,
      _BusinessTablePhase.checkout => isTerminal ? theme.cyan : theme.accent,
      _BusinessTablePhase.empty => theme.ink.withValues(alpha: 0.45),
    };

    return SizedBox(
      width: size,
      height: size * 0.78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 1,
            right: 1,
            top: size * 0.12,
            bottom: size * 0.12,
            child: Container(
              decoration: BoxDecoration(
                color: occupied
                    ? theme.accent.withValues(alpha: 0.22)
                    : active
                        ? theme.amber.withValues(alpha: 0.22)
                        : theme.surfaceHigh,
                border: Border.all(
                  color: occupied || active
                      ? theme.accent
                      : isTerminal
                          ? theme.cyan.withValues(alpha: 0.55)
                          : theme.border,
                  width: mode == AppThemeMode.neoBrutalism ? 3 : 1.4,
                ),
                borderRadius: BorderRadius.circular(
                  mode == AppThemeMode.neoBrutalism ? theme.radius : 2,
                ),
              ),
              child: Center(
                child: Text(
                  'T$index',
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
          ),
          if (occupied)
            Positioned(
              top: 0,
              right: 2,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isTerminal ? 1 : 0.2),
                  border: Border.all(
                    color: statusColor,
                    width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(
                    mode == AppThemeMode.neoBrutalism
                        ? theme.radius
                        : size * 0.16,
                  ),
                ),
                child: Icon(
                  statusIcon,
                  size: size * 0.18,
                  color: isTerminal && phase != _BusinessTablePhase.empty
                      ? Colors.black
                      : statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceCounter extends StatelessWidget {
  final double width;
  final double height;
  final int staffCount;
  final bool active;

  const _ServiceCounter({
    required this.width,
    required this.height,
    required this.staffCount,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: active
            ? theme.accent.withValues(alpha: 0.14)
            : theme.ink.withValues(alpha: 0.06),
        border: Border.all(
          color: active
              ? theme.accent
              : isTerminal
                  ? theme.cyan.withValues(alpha: 0.45)
                  : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.2,
        ),
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Icon(
          Icons.room_service,
          size: 18,
          color: active
              ? theme.accent
              : isTerminal
                  ? theme.cyan
                  : theme.ink.withValues(alpha: 0.62),
        ),
      ),
    );
  }
}

class _EntranceMarker extends StatelessWidget {
  final bool active;

  const _EntranceMarker({required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    return Container(
      width: 28,
      height: 36,
      decoration: BoxDecoration(
        color: active
            ? theme.accent.withValues(alpha: 0.16)
            : theme.ink.withValues(alpha: 0.06),
        border: Border.all(
          color: active
              ? theme.accent
              : isTerminal
                  ? theme.cyan.withValues(alpha: 0.45)
                  : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.2,
        ),
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
        ),
      ),
      child: Icon(
        Icons.sensor_door,
        size: 18,
        color: active
            ? theme.accent
            : isTerminal
                ? theme.cyan
                : theme.ink.withValues(alpha: 0.62),
      ),
    );
  }
}

class _CustomerSprite extends StatelessWidget {
  final double size;
  final bool waiting;
  final bool ready;
  final bool serving;

  const _CustomerSprite({
    super.key,
    required this.size,
    required this.waiting,
    required this.ready,
    required this.serving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final fillColor = serving
        ? theme.accent
        : ready
            ? theme.amber
            : isTerminal
                ? theme.cyan
                : theme.surfaceHigh;
    final iconColor = serving || ready
        ? (isTerminal ? Colors.black : theme.ink)
        : isTerminal
            ? Colors.black
            : theme.ink;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : size / 2,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
        boxShadow: isTerminal
            ? theme.softGlow(theme.cyan)
            : mode == AppThemeMode.neoBrutalism
                ? theme.hardShadow(offset: const Offset(3, 3))
                : null,
      ),
      child: Icon(
        serving
            ? Icons.restaurant
            : waiting
                ? Icons.directions_walk
                : Icons.person,
        size: size * 0.58,
        color: iconColor,
      ),
    );
  }
}

class _ServerSprite extends StatelessWidget {
  final double size;
  final bool active;

  const _ServerSprite({
    required this.size,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active
            ? theme.accent
            : isTerminal
                ? theme.cyan
                : theme.surfaceHigh,
        borderRadius: BorderRadius.circular(
          mode == AppThemeMode.neoBrutalism ? theme.radius : size / 2,
        ),
        border: Border.all(
          color: isTerminal ? theme.cyan : theme.border,
          width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
        ),
        boxShadow: active
            ? mode == AppThemeMode.neonTerminal
                ? theme.softGlow(theme.cyan)
                : mode == AppThemeMode.neoBrutalism
                    ? theme.hardShadow(offset: const Offset(3, 3))
                    : null
            : null,
      ),
      child: Icon(
        Icons.room_service,
        size: size * 0.58,
        color: active || isTerminal ? Colors.black : theme.ink,
      ),
    );
  }
}
