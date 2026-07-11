import 'dart:convert';
import 'dart:math';

import 'package:cyber_table_order/models/food_catalog.dart';
import 'package:cyber_table_order/models/game_balance.dart';
import 'package:cyber_table_order/models/game_models.dart';
import 'package:cyber_table_order/models/game_storage.dart';
import 'package:flutter/foundation.dart';

export 'package:cyber_table_order/models/game_balance.dart';
export 'package:cyber_table_order/models/game_models.dart';
export 'package:cyber_table_order/models/game_storage.dart';

class GameController extends ChangeNotifier {
  static const _snapshotKey = 'idle_game_snapshot_v2';
  static const _snapshotVersion = 2;
  static const _coinsKey = 'idle_coins';
  static const _lifetimeEarningsKey = 'idle_lifetime_earnings';
  static const _pendingOfflineEarningsKey = 'idle_pending_offline_earnings';
  static const _lastSavedAtKey = 'idle_last_saved_at';
  static const _customerOrderFoodIdKey = 'idle_customer_order_food_id';
  static const _customerOrderRewardKey = 'idle_customer_order_reward';
  static const _customerOrderCreatedAtKey = 'idle_customer_order_created_at';
  static const _nextCustomerAvailableAtKey = 'idle_next_customer_available_at';
  static const _customerOrdersServedKey = 'idle_customer_orders_served';
  static const _bestComboKey = 'idle_best_combo';
  static const _claimedMilestoneIdsKey = 'idle_claimed_milestone_ids';
  static const _seatLevelKey = 'idle_seat_level';
  static const _serviceLevelKey = 'idle_service_level';
  static const _kitchenLevelKey = 'idle_kitchen_level';
  static const _menuUpgradeLevelsKey = 'idle_menu_upgrade_levels';
  static const _menuMasteryXpKey = 'idle_menu_mastery_xp';
  static const _menuServeCountsKey = 'idle_menu_serve_counts';
  static const _restaurantXpKey = 'idle_restaurant_xp';
  static const _unlockedFoodIdsKey = 'idle_unlocked_food_ids';
  static const _shiftOrdersServedKey = 'idle_shift_orders_served';
  static const _shiftMissedOrdersKey = 'idle_shift_missed_orders';
  static const _shiftBestComboKey = 'idle_shift_best_combo';
  static const _shiftCoinsEarnedKey = 'idle_shift_coins_earned';
  static const _dailyTaskDateKey = 'idle_daily_task_date';
  static const _dailyOrdersServedKey = 'idle_daily_orders_served';
  static const _dailyBestComboKey = 'idle_daily_best_combo';
  static const _dailyUpgradesKey = 'idle_daily_upgrades';
  static const _claimedDailyTaskIdsKey = 'idle_claimed_daily_task_ids';
  static const _activeCustomerTypeKey = 'idle_active_customer_type';
  static const _pendingBusinessEarningsKey = 'idle_pending_business_earnings';
  static const _diningCustomersKey = 'idle_dining_customers';
  static const _nextDiningCustomerIdKey = 'idle_next_dining_customer_id';
  static const _businessQueueCountKey = 'idle_business_queue_count';
  static const _businessSeatedCountKey = 'idle_business_seated_count';
  static const _businessKitchenQueueCountKey = 'idle_business_kitchen_queue';
  static const _businessEatingCountKey = 'idle_business_eating_count';
  static const _businessCheckoutQueueCountKey = 'idle_business_checkout_queue';
  static const _arrivalCarryKey = 'idle_arrival_carry';
  static const _kitchenCarryKey = 'idle_kitchen_carry';
  static const _serviceCarryKey = 'idle_service_carry';

  static const startingCoins = 120.0;
  static const maxOfflineMinutes = GameBalance.maxOfflineMinutes;
  static const shiftTargetOrders = 4;
  static const restaurantXpPerLevel = 100;
  static const customerOrderBaseReward = 18.0;
  static const customerArrivalBaseSeconds = 12;
  static const customerArrivalMinSeconds = 4;
  static const customerPatienceBaseSeconds = 18;
  static const customerPatienceMaxSeconds = 30;
  static const businessMealBaseSeconds = GameBalance.businessMealBaseSeconds;
  static const businessMealMinSeconds = GameBalance.businessMealMinSeconds;
  static const customerSeatingDuration = Duration(
    seconds: GameBalance.customerSeatingSeconds,
  );
  static const foodServingDuration = Duration(
    seconds: GameBalance.foodServingSeconds,
  );
  static const customerLeavingDuration = Duration(
    seconds: GameBalance.customerLeavingSeconds,
  );
  static const menuMasteryXpPerLevel = 4;
  static const maxBusinessTickSeconds = 120;

  final GameStorage storage;

  double _coins = startingCoins;
  double _lifetimeEarnings = 0;
  double _pendingOfflineEarnings = 0;
  DateTime _lastSavedAt = DateTime.now();
  int? _customerOrderFoodId;
  double _customerOrderReward = 0;
  DateTime? _customerOrderCreatedAt;
  DateTime? _nextCustomerAvailableAt;
  int _customerOrdersServed = 0;
  int _bestCombo = 0;
  int _seatLevel = 1;
  int _serviceLevel = 1;
  int _kitchenLevel = 1;
  int _restaurantXp = 0;
  int _shiftOrdersServed = 0;
  int _shiftMissedOrders = 0;
  int _shiftBestCombo = 0;
  double _shiftCoinsEarned = 0;
  String _dailyTaskDate = '';
  int _dailyOrdersServed = 0;
  int _dailyBestCombo = 0;
  int _dailyUpgrades = 0;
  double _pendingBusinessEarnings = 0;
  int _businessQueueCount = 0;
  int _businessSeatedCount = 0;
  int _businessKitchenQueueCount = 0;
  int _businessEatingCount = 0;
  int _businessCheckoutQueueCount = 0;
  int _nextDiningCustomerId = 1;
  double _arrivalCarry = 0;
  double _kitchenCarry = 0;
  double _serviceCarry = 0;
  GameCustomerType _activeCustomerType = GameCustomerType.normal;
  bool _isLoaded = false;
  Map<int, int> _menuUpgradeLevels = {};
  Map<int, int> _menuMasteryXp = {};
  Map<int, int> _menuServeCounts = {};
  Set<int> _unlockedFoodIds = {...FoodCatalog.defaultUnlockedIds};
  Set<String> _claimedMilestoneIds = {};
  Set<String> _claimedDailyTaskIds = {};
  List<GameDiningCustomer> _diningCustomers = [];
  Future<void> _saveQueue = Future<void>.value();
  Object? _lastSaveError;

  GameController({GameStorage? storage})
      : storage = storage ?? SharedPreferencesGameStorage();

  double get coins => _coins;
  double get lifetimeEarnings => _lifetimeEarnings;
  double get pendingOfflineEarnings => _pendingOfflineEarnings;
  double get pendingBusinessEarnings => _pendingBusinessEarnings;
  double get pendingClaimableEarnings =>
      _pendingOfflineEarnings + _pendingBusinessEarnings;
  DateTime get lastSavedAt => _lastSavedAt;
  int? get customerOrderFoodId {
    final customer = _manualWaitingCustomer;
    return customer?.foodId ?? _customerOrderFoodId;
  }

  double get customerOrderReward {
    final customer = _manualWaitingCustomer;
    return customer?.reward ?? _customerOrderReward;
  }

  DateTime? get customerOrderCreatedAt {
    final customer = _manualWaitingCustomer;
    return customer?.phaseStartedAt ?? _customerOrderCreatedAt;
  }

  DateTime? get nextCustomerAvailableAt => _nextCustomerAvailableAt;
  int get customerOrdersServed => _customerOrdersServed;
  int get bestCombo => _bestCombo;
  bool get hasCustomerOrder => customerOrderFoodId != null;
  int get seatLevel => _seatLevel;
  int get serviceLevel => _serviceLevel;
  int get kitchenLevel => _kitchenLevel;
  int get restaurantXp => _restaurantXp;
  int get restaurantXpLevel => 1 + _restaurantXp ~/ restaurantXpPerLevel;
  int get restaurantXpProgress => _restaurantXp % restaurantXpPerLevel;
  int get restaurantXpProgressTarget => restaurantXpPerLevel;
  double get restaurantXpProgressRatio =>
      restaurantXpProgress / restaurantXpPerLevel;
  int get shiftOrdersServed => _shiftOrdersServed;
  int get shiftMissedOrders => _shiftMissedOrders;
  int get shiftBestCombo => _shiftBestCombo;
  double get shiftCoinsEarned => _shiftCoinsEarned;
  bool get shiftReadyToFinish => _shiftOrdersServed >= shiftTargetOrders;
  int get dailyOrdersServed => _dailyOrdersServed;
  int get dailyBestCombo => _dailyBestCombo;
  int get dailyUpgrades => _dailyUpgrades;
  List<GameDiningCustomer> get diningCustomers =>
      List.unmodifiable(_diningCustomers);
  GameDiningCustomer? get manualDiningCustomer {
    for (final customer in _diningCustomers) {
      if (customer.isManual) return customer;
    }
    return null;
  }

  int get businessQueueCount => _autoCustomers
      .where((customer) => customer.phase == GameDiningCustomerPhase.queueing)
      .length;
  int get businessSeatedCount => _autoCustomers
      .where((customer) =>
          customer.seatIndex != null &&
          customer.phase != GameDiningCustomerPhase.queueing)
      .length;
  int get businessKitchenQueueCount => _autoCustomers
      .where((customer) =>
          customer.phase == GameDiningCustomerPhase.waitingForFood ||
          customer.phase == GameDiningCustomerPhase.servingFood)
      .length;
  int get businessEatingCount => _autoCustomers
      .where((customer) => customer.phase == GameDiningCustomerPhase.eating)
      .length;
  int get businessCheckoutQueueCount => _autoCustomers
      .where((customer) => customer.phase == GameDiningCustomerPhase.checkout)
      .length;
  int get diningCapacity => GameBalance.diningCapacity(_seatLevel);
  int get businessMaxQueue => max(4, diningCapacity * 2);
  double get businessLoadRatio {
    if (diningCapacity <= 0) return 0;
    return (businessSeatedCount / diningCapacity).clamp(0, 1).toDouble();
  }

  double get kitchenLoadRatio {
    return (businessKitchenQueueCount / max(1, diningCapacity))
        .clamp(0, 1)
        .toDouble();
  }

  double get checkoutLoadRatio {
    return (businessCheckoutQueueCount / max(1, diningCapacity))
        .clamp(0, 1)
        .toDouble();
  }

  bool get hasBusinessActivity =>
      _autoCustomers.isNotEmpty || _pendingBusinessEarnings > 0;

  double get _arrivalEventMultiplier =>
      activeEventType == GameEventType.lunchRush ? 1.3 : 1;

  double get customerArrivalRatePerMinute =>
      GameBalance.customerArrivalRatePerMinute(
        seatLevel: _seatLevel,
        restaurantLevel: restaurantLevel,
        eventMultiplier: _arrivalEventMultiplier,
      );

  double get kitchenOrdersPerMinute =>
      GameBalance.kitchenOrdersPerMinute(_kitchenLevel);

  Duration get businessMealDuration => GameBalance.businessMealDuration(
        seatLevel: _seatLevel,
        serviceLevel: _serviceLevel,
      );

  double get mealOrdersPerMinute => GameBalance.seatTurnoverOrdersPerMinute(
        diningCapacity: diningCapacity,
        mealDuration: businessMealDuration,
        kitchenRatePerMinute: kitchenOrdersPerMinute,
        checkoutRatePerMinute: serviceOrdersPerMinute,
      );

  double get serviceOrdersPerMinute =>
      GameBalance.checkoutOrdersPerMinute(_serviceLevel);

  Duration get _checkoutDuration {
    final seconds = 8 - _serviceLevel;
    return Duration(seconds: max(2, seconds));
  }

  double get autoOrdersPerMinute => GameBalance.autoOrdersPerMinute(
        seatLevel: _seatLevel,
        serviceLevel: _serviceLevel,
        kitchenLevel: _kitchenLevel,
        restaurantLevel: restaurantLevel,
        arrivalEventMultiplier: _arrivalEventMultiplier,
      );

  double get baselineAutoOrdersPerMinute => GameBalance.autoOrdersPerMinute(
        seatLevel: _seatLevel,
        serviceLevel: _serviceLevel,
        kitchenLevel: _kitchenLevel,
        restaurantLevel: restaurantLevel,
      );

  double get averageAutoOrderReward => _averageAutoOrderRewardFor(
        seatLevel: _seatLevel,
        serviceLevel: _serviceLevel,
        kitchenLevel: _kitchenLevel,
        projectedRestaurantLevel: restaurantLevel,
      );

  double get baselineAverageAutoOrderReward => _averageAutoOrderRewardFor(
        seatLevel: _seatLevel,
        serviceLevel: _serviceLevel,
        kitchenLevel: _kitchenLevel,
        projectedRestaurantLevel: restaurantLevel,
        rewardMultiplier: 1,
      );

  double get autoRevenuePerMinute =>
      autoOrdersPerMinute * averageAutoOrderReward;

  double get baselineRevenuePerMinute =>
      baselineAutoOrdersPerMinute * baselineAverageAutoOrderReward;

  int get offlineMinuteCap => GameBalance.offlineMinuteCap(restaurantLevel);
  double get offlineEfficiency =>
      GameBalance.offlineEfficiency(restaurantLevel);

  GameBusinessDiagnosis get businessDiagnosis {
    final bottleneck = _diagnoseBusinessBottleneck();
    final limitingRate = switch (bottleneck) {
      GameBusinessBottleneck.kitchen => kitchenOrdersPerMinute,
      GameBusinessBottleneck.dining => mealOrdersPerMinute,
      GameBusinessBottleneck.checkout => serviceOrdersPerMinute,
      GameBusinessBottleneck.seats ||
      GameBusinessBottleneck.balanced =>
        autoOrdersPerMinute,
    };
    return GameBusinessDiagnosis(
      bottleneck: bottleneck,
      arrivalRatePerMinute: customerArrivalRatePerMinute,
      kitchenRatePerMinute: kitchenOrdersPerMinute,
      diningRatePerMinute: mealOrdersPerMinute,
      checkoutRatePerMinute: serviceOrdersPerMinute,
      estimatedOrdersPerMinute: autoOrdersPerMinute,
      limitingRatePerMinute: limitingRate,
      queueCount: businessQueueCount,
      occupiedSeats: businessSeatedCount,
      seatCapacity: diningCapacity,
      kitchenQueueCount: businessKitchenQueueCount,
      eatingCount: businessEatingCount,
      checkoutQueueCount: businessCheckoutQueueCount,
    );
  }

  GameBusinessBottleneck get businessBottleneck => businessDiagnosis.bottleneck;

  List<GameOperationUpgradePreview> get operationUpgradePreviews {
    final previews = GameOperationUpgradeType.values
        .map(_buildOperationUpgradePreview)
        .toList(growable: false);
    final candidates = GameOperationUpgradeType.values
        .map(
          (type) => _buildOperationUpgradePreview(
            type,
            applyEventDiscount: false,
          ),
        )
        .where((preview) => preview.coinsPerMinuteGain > 0)
        .toList();
    candidates.sort((left, right) {
      final payback = left.paybackMinutes!.compareTo(right.paybackMinutes!);
      if (payback != 0) return payback;
      final gain = right.coinsPerMinuteGain.compareTo(
        left.coinsPerMinuteGain,
      );
      if (gain != 0) return gain;
      final cost = left.cost.compareTo(right.cost);
      if (cost != 0) return cost;
      return left.type.index.compareTo(right.type.index);
    });
    GameOperationUpgradeType? recommendedType;
    if (candidates.isNotEmpty) {
      recommendedType = candidates.first.type;
    }
    return List.unmodifiable(
      previews.map(
        (preview) => preview.copyWith(
          isRecommended: preview.type == recommendedType,
        ),
      ),
    );
  }

  GameOperationUpgradePreview previewOperationUpgrade(
    GameOperationUpgradeType type,
  ) {
    return operationUpgradePreviews.firstWhere(
      (preview) => preview.type == type,
    );
  }

  GameOperationUpgradeType? get recommendedOperationUpgradeType {
    return recommendedOperationUpgradePreview?.type;
  }

  GameOperationUpgradePreview? get recommendedOperationUpgradePreview {
    for (final preview in operationUpgradePreviews) {
      if (preview.isRecommended) return preview;
    }
    return null;
  }

  GameCustomerType get activeCustomerType => _activeCustomerType;
  GameEventType? get activeEventType {
    if (_customerOrdersServed < 4) return null;
    final phase = (_customerOrdersServed - 4) % 9;
    if (phase == 0 || phase == 1) return GameEventType.lunchRush;
    if (phase == 4) return GameEventType.regularVisit;
    if (phase == 7) return GameEventType.ingredientDiscount;
    return null;
  }

  String? get activeEventTitleKey {
    return switch (activeEventType) {
      GameEventType.lunchRush => 'event_lunch_rush_title',
      GameEventType.regularVisit => 'event_regular_title',
      GameEventType.ingredientDiscount => 'event_discount_title',
      null => null,
    };
  }

  String? get activeEventDescriptionKey {
    return switch (activeEventType) {
      GameEventType.lunchRush => 'event_lunch_rush_desc',
      GameEventType.regularVisit => 'event_regular_desc',
      GameEventType.ingredientDiscount => 'event_discount_desc',
      null => null,
    };
  }

  double get activeEventRewardMultiplier {
    return switch (activeEventType) {
      GameEventType.lunchRush => 1.2,
      GameEventType.regularVisit => 1.35,
      GameEventType.ingredientDiscount => 1,
      null => 1,
    };
  }

  double get activeEventUpgradeCostMultiplier {
    return activeEventType == GameEventType.ingredientDiscount ? 0.9 : 1;
  }

  int get activeEventOrdersRemaining {
    if (_customerOrdersServed < 4) return 0;
    final phase = (_customerOrdersServed - 4) % 9;
    if (activeEventType == GameEventType.lunchRush) {
      return max(1, 2 - phase);
    }
    return activeEventType == null ? 0 : 1;
  }

  bool get isLoaded => _isLoaded;
  bool get hasSaveError => _lastSaveError != null;
  Map<int, int> get menuUpgradeLevels => Map.unmodifiable(_menuUpgradeLevels);
  Map<int, int> get menuMasteryXpByFood => Map.unmodifiable(_menuMasteryXp);
  Map<int, int> get menuServeCountsByFood => Map.unmodifiable(_menuServeCounts);
  Set<int> get unlockedFoodIds => Set.unmodifiable(_computedUnlockedFoodIds());
  Set<String> get claimedMilestoneIds => Set.unmodifiable(_claimedMilestoneIds);
  Set<String> get claimedDailyTaskIds => Set.unmodifiable(_claimedDailyTaskIds);

  List<GameMilestone> get milestones {
    final totalMenuLevels =
        _menuUpgradeLevels.values.fold<int>(0, (sum, level) => sum + level);
    return [
      _milestone(
        id: 'first_service',
        titleKey: 'idle_goal_first_service_title',
        descriptionKey: 'idle_goal_first_service_desc',
        progress: _customerOrdersServed,
        target: 1,
        reward: 40,
      ),
      _milestone(
        id: 'busy_shift',
        titleKey: 'idle_goal_busy_shift_title',
        descriptionKey: 'idle_goal_busy_shift_desc',
        progress: _customerOrdersServed,
        target: 5,
        reward: 140,
      ),
      _milestone(
        id: 'combo_three',
        titleKey: 'idle_goal_combo_three_title',
        descriptionKey: 'idle_goal_combo_three_desc',
        progress: _bestCombo,
        target: 3,
        reward: 100,
      ),
      _milestone(
        id: 'better_seats',
        titleKey: 'idle_goal_better_seats_title',
        descriptionKey: 'idle_goal_better_seats_desc',
        progress: max(0, _seatLevel - 1),
        target: 1,
        reward: 80,
      ),
      _milestone(
        id: 'quick_service',
        titleKey: 'idle_goal_quick_service_title',
        descriptionKey: 'idle_goal_quick_service_desc',
        progress: max(0, _serviceLevel - 1),
        target: 1,
        reward: 80,
      ),
      _milestone(
        id: 'signature_menu',
        titleKey: 'idle_goal_signature_menu_title',
        descriptionKey: 'idle_goal_signature_menu_desc',
        progress: totalMenuLevels,
        target: 2,
        reward: 120,
      ),
      _milestone(
        id: 'shop_level_two',
        titleKey: 'idle_goal_shop_level_two_title',
        descriptionKey: 'idle_goal_shop_level_two_desc',
        progress: max(0, restaurantLevel - 1),
        target: 1,
        reward: 180,
      ),
    ];
  }

  List<GameDailyTask> get dailyTasks {
    return [
      _dailyTask(
        id: 'daily_service_three',
        titleKey: 'daily_task_service_three_title',
        descriptionKey: 'daily_task_service_three_desc',
        progress: _dailyOrdersServed,
        target: 3,
        reward: 90,
      ),
      _dailyTask(
        id: 'daily_combo_two',
        titleKey: 'daily_task_combo_two_title',
        descriptionKey: 'daily_task_combo_two_desc',
        progress: _dailyBestCombo,
        target: 2,
        reward: 75,
      ),
      _dailyTask(
        id: 'daily_upgrade_once',
        titleKey: 'daily_task_upgrade_once_title',
        descriptionKey: 'daily_task_upgrade_once_desc',
        progress: _dailyUpgrades,
        target: 1,
        reward: 70,
      ),
    ];
  }

  int get claimableMilestoneCount =>
      milestones.where((milestone) => milestone.claimable).length;

  int get claimableDailyTaskCount =>
      dailyTasks.where((task) => task.claimable).length;

  int get claimableRewardCount =>
      claimableMilestoneCount + claimableDailyTaskCount;

  GameMilestone? get nextMilestone {
    final remaining = milestones
        .where((milestone) => !milestone.claimed)
        .toList(growable: false);
    for (final milestone in remaining) {
      if (milestone.claimable) return milestone;
    }
    GameMilestone? closest;
    for (final milestone in remaining) {
      if (closest == null || milestone.progressRatio > closest.progressRatio) {
        closest = milestone;
      }
    }
    return closest;
  }

  int get _totalMenuUpgradeLevels =>
      _menuUpgradeLevels.values.fold<int>(0, (sum, level) => sum + level);

  int get restaurantLevel => GameBalance.restaurantLevel(
        seatLevel: _seatLevel,
        serviceLevel: _serviceLevel,
        kitchenLevel: _kitchenLevel,
        totalMenuLevels: _totalMenuUpgradeLevels,
        restaurantXpLevel: restaurantXpLevel,
      );

  double get revenuePerMinute {
    return autoRevenuePerMinute;
  }

  int menuLevel(int foodId) => _menuUpgradeLevels[foodId] ?? 0;

  int masteryXpForFood(int foodId) => _menuMasteryXp[foodId] ?? 0;

  int servedCountForFood(int foodId) => _menuServeCounts[foodId] ?? 0;

  int masteryLevelForFood(int foodId) {
    return masteryXpForFood(foodId) ~/ menuMasteryXpPerLevel;
  }

  int masteryProgressForFood(int foodId) {
    return masteryXpForFood(foodId) % menuMasteryXpPerLevel;
  }

  int get masteryProgressTarget => menuMasteryXpPerLevel;

  double masteryProgressRatioForFood(int foodId) {
    return masteryProgressForFood(foodId) / menuMasteryXpPerLevel;
  }

  double menuUpgradeCost(int foodId) {
    final level = menuLevel(foodId);
    return GameBalance.menuUpgradeCost(
      level,
      eventMultiplier: activeEventUpgradeCostMultiplier,
    );
  }

  double get seatUpgradeCost => GameBalance.operationUpgradeCost(
        baseCost: 100,
        currentLevel: _seatLevel,
        eventMultiplier: activeEventUpgradeCostMultiplier,
      );

  double get serviceUpgradeCost => GameBalance.operationUpgradeCost(
        baseCost: 90,
        currentLevel: _serviceLevel,
        eventMultiplier: activeEventUpgradeCostMultiplier,
      );

  double get kitchenUpgradeCost => GameBalance.operationUpgradeCost(
        baseCost: 110,
        currentLevel: _kitchenLevel,
        eventMultiplier: activeEventUpgradeCostMultiplier,
      );

  String formatCoins(double value) => formatCompactCoins(value);

  String formatCompactCoins(double value) =>
      GameBalance.formatCompactNumber(value);

  double customerOrderRewardForFood(int foodId) {
    return _customerOrderRewardForFoodAtLevels(
      foodId,
      seatLevel: _seatLevel,
      serviceLevel: _serviceLevel,
      kitchenLevel: _kitchenLevel,
      projectedRestaurantLevel: restaurantLevel,
    );
  }

  GameBusinessBottleneck _diagnoseBusinessBottleneck() {
    if (_autoCustomers.isEmpty) return GameBusinessBottleneck.balanced;

    if (businessQueueCount > 0 && businessSeatedCount >= diningCapacity) {
      return GameBusinessBottleneck.seats;
    }

    final capacity = max(1, diningCapacity);
    final kitchenPressure = businessKitchenQueueCount / capacity;
    final diningPressure = businessEatingCount / capacity;
    final checkoutPressure = businessCheckoutQueueCount / capacity;

    if (businessKitchenQueueCount > 0 &&
        kitchenPressure >= diningPressure &&
        kitchenPressure >= checkoutPressure) {
      return GameBusinessBottleneck.kitchen;
    }
    if (businessCheckoutQueueCount > 0 &&
        checkoutPressure >= kitchenPressure &&
        checkoutPressure >= diningPressure) {
      return GameBusinessBottleneck.checkout;
    }
    if (businessEatingCount > 0 &&
        diningPressure >= kitchenPressure &&
        diningPressure >= checkoutPressure) {
      return GameBusinessBottleneck.dining;
    }

    if (businessSeatedCount <= 0) return GameBusinessBottleneck.balanced;
    final processingRate = min(
      kitchenOrdersPerMinute,
      min(mealOrdersPerMinute, serviceOrdersPerMinute),
    );
    if (customerArrivalRatePerMinute <= processingRate * 1.05) {
      return GameBusinessBottleneck.balanced;
    }
    if (kitchenOrdersPerMinute <= mealOrdersPerMinute &&
        kitchenOrdersPerMinute <= serviceOrdersPerMinute) {
      return GameBusinessBottleneck.kitchen;
    }
    if (serviceOrdersPerMinute <= kitchenOrdersPerMinute &&
        serviceOrdersPerMinute <= mealOrdersPerMinute) {
      return GameBusinessBottleneck.checkout;
    }
    return GameBusinessBottleneck.dining;
  }

  GameOperationUpgradePreview _buildOperationUpgradePreview(
    GameOperationUpgradeType type, {
    bool applyEventDiscount = true,
  }) {
    var projectedSeatLevel = _seatLevel;
    var projectedServiceLevel = _serviceLevel;
    var projectedKitchenLevel = _kitchenLevel;
    final currentLevel = switch (type) {
      GameOperationUpgradeType.seats => _seatLevel,
      GameOperationUpgradeType.kitchen => _kitchenLevel,
      GameOperationUpgradeType.service => _serviceLevel,
    };
    final eventMultiplier =
        applyEventDiscount ? activeEventUpgradeCostMultiplier : 1.0;
    final cost = switch (type) {
      GameOperationUpgradeType.seats => GameBalance.operationUpgradeCost(
          baseCost: 100,
          currentLevel: _seatLevel,
          eventMultiplier: eventMultiplier,
        ),
      GameOperationUpgradeType.kitchen => GameBalance.operationUpgradeCost(
          baseCost: 110,
          currentLevel: _kitchenLevel,
          eventMultiplier: eventMultiplier,
        ),
      GameOperationUpgradeType.service => GameBalance.operationUpgradeCost(
          baseCost: 90,
          currentLevel: _serviceLevel,
          eventMultiplier: eventMultiplier,
        ),
    };
    switch (type) {
      case GameOperationUpgradeType.seats:
        projectedSeatLevel += 1;
      case GameOperationUpgradeType.kitchen:
        projectedKitchenLevel += 1;
      case GameOperationUpgradeType.service:
        projectedServiceLevel += 1;
    }

    final projectedRestaurantLevel = GameBalance.restaurantLevel(
      seatLevel: projectedSeatLevel,
      serviceLevel: projectedServiceLevel,
      kitchenLevel: projectedKitchenLevel,
      totalMenuLevels: _totalMenuUpgradeLevels,
      restaurantXpLevel: restaurantXpLevel,
    );
    final projectedOrdersPerMinute = GameBalance.autoOrdersPerMinute(
      seatLevel: projectedSeatLevel,
      serviceLevel: projectedServiceLevel,
      kitchenLevel: projectedKitchenLevel,
      restaurantLevel: projectedRestaurantLevel,
    );
    final projectedReward = _averageAutoOrderRewardFor(
      seatLevel: projectedSeatLevel,
      serviceLevel: projectedServiceLevel,
      kitchenLevel: projectedKitchenLevel,
      projectedRestaurantLevel: projectedRestaurantLevel,
      rewardMultiplier: 1,
    );
    final projectedCoinsPerMinute = projectedOrdersPerMinute * projectedReward;
    return GameOperationUpgradePreview(
      type: type,
      currentLevel: currentLevel,
      upgradedLevel: currentLevel + 1,
      currentOrdersPerMinute: baselineAutoOrdersPerMinute,
      upgradedOrdersPerMinute: projectedOrdersPerMinute,
      currentCoinsPerMinute: baselineRevenuePerMinute,
      upgradedCoinsPerMinute: projectedCoinsPerMinute,
      coinsPerMinuteGain: projectedCoinsPerMinute - baselineRevenuePerMinute,
      cost: cost,
      canAfford: _coins >= cost,
      isRecommended: false,
    );
  }

  double _averageAutoOrderRewardFor({
    required int seatLevel,
    required int serviceLevel,
    required int kitchenLevel,
    required int projectedRestaurantLevel,
    double? rewardMultiplier,
  }) {
    final ids = _computedUnlockedFoodIdsFor(projectedRestaurantLevel).toList()
      ..sort();
    if (ids.isEmpty) return customerOrderBaseReward;
    final total = ids.fold<double>(
      0,
      (sum, foodId) =>
          sum +
          _customerOrderRewardForFoodAtLevels(
            foodId,
            seatLevel: seatLevel,
            serviceLevel: serviceLevel,
            kitchenLevel: kitchenLevel,
            projectedRestaurantLevel: projectedRestaurantLevel,
          ),
    );
    return (total / ids.length) *
        (rewardMultiplier ?? activeEventRewardMultiplier);
  }

  double _customerOrderRewardForFoodAtLevels(
    int foodId, {
    required int seatLevel,
    required int serviceLevel,
    required int kitchenLevel,
    required int projectedRestaurantLevel,
  }) {
    final baseReward =
        FoodCatalog.findById(foodId)?.baseRewardCoins.toDouble() ??
            customerOrderBaseReward;
    return baseReward +
        projectedRestaurantLevel * 4 +
        seatLevel * 2 +
        serviceLevel * 2 +
        kitchenLevel * 3 +
        menuLevel(foodId) * 5 +
        masteryLevelForFood(foodId) * 2;
  }

  int foodUnlockLevel(int foodId) {
    return FoodCatalog.findById(foodId)?.unlockLevel ?? 99;
  }

  bool isFoodUnlocked(int foodId) {
    return _computedUnlockedFoodIds().contains(foodId);
  }

  List<int> availableFoodIds(List<int> foodIds) {
    final ids = foodIds.where((id) => id > 0 && isFoodUnlocked(id)).toList()
      ..sort();
    return ids;
  }

  String customerTypeTitleKey(GameCustomerType type) {
    return switch (type) {
      GameCustomerType.normal => 'customer_type_normal',
      GameCustomerType.impatient => 'customer_type_impatient',
      GameCustomerType.vip => 'customer_type_vip',
    };
  }

  Duration get customerArrivalDelay {
    var seconds =
        customerArrivalBaseSeconds - (_serviceLevel - 1) * 2 - (_seatLevel - 1);
    if (activeEventType == GameEventType.lunchRush) {
      seconds -= 2;
    }
    return Duration(seconds: max(customerArrivalMinSeconds, seconds));
  }

  Duration get customerPatienceDuration {
    var seconds =
        customerPatienceBaseSeconds + (_serviceLevel - 1) * 2 + _seatLevel - 1;
    seconds += (_kitchenLevel - 1);
    seconds += switch (_activeCustomerType) {
      GameCustomerType.normal => 0,
      GameCustomerType.impatient => -5,
      GameCustomerType.vip => 3,
    };
    return Duration(
      seconds: max(6, min(customerPatienceMaxSeconds, seconds)),
    );
  }

  Duration customerPatienceRemaining(DateTime now) {
    if (customerOrderFoodId == null) return Duration.zero;
    final createdAt = customerOrderCreatedAt;
    if (createdAt == null) return customerPatienceDuration;
    final remaining = createdAt.add(customerPatienceDuration).difference(now);
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining;
  }

  double customerPatienceRatio(DateTime now) {
    if (customerOrderFoodId == null) return 0;
    final totalMilliseconds = customerPatienceDuration.inMilliseconds;
    if (totalMilliseconds <= 0) return 0;
    return (customerPatienceRemaining(now).inMilliseconds / totalMilliseconds)
        .clamp(0, 1)
        .toDouble();
  }

  bool customerOrderExpired(DateTime now) {
    return customerOrderFoodId != null &&
        customerPatienceRemaining(now) == Duration.zero;
  }

  Duration customerArrivalRemaining(DateTime now) {
    if (manualDiningCustomer != null || customerOrderFoodId != null) {
      return Duration.zero;
    }
    final availableAt = _nextCustomerAvailableAt;
    if (availableAt == null) return Duration.zero;
    final remaining = availableAt.difference(now);
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining;
  }

  bool canSeatCustomer(DateTime now) {
    return manualDiningCustomer == null &&
        customerArrivalRemaining(now) == Duration.zero &&
        _firstOpenSeatIndex() != null;
  }

  double customerArrivalProgress(DateTime now) {
    if (manualDiningCustomer != null || customerOrderFoodId != null) return 1;
    final availableAt = _nextCustomerAvailableAt;
    if (availableAt == null) return 1;
    final remaining = customerArrivalRemaining(now);
    if (remaining == Duration.zero) return 1;
    final totalMilliseconds = customerArrivalDelay.inMilliseconds;
    if (totalMilliseconds <= 0) return 1;
    final progress = 1 - remaining.inMilliseconds / totalMilliseconds;
    return progress.clamp(0, 1).toDouble();
  }

  Duration diningCustomerPhaseDuration(GameDiningCustomer customer) {
    return switch (customer.phase) {
      GameDiningCustomerPhase.queueing => Duration.zero,
      GameDiningCustomerPhase.seating => customerSeatingDuration,
      GameDiningCustomerPhase.waitingForFood =>
        customer.isManual ? customerPatienceDuration : Duration.zero,
      GameDiningCustomerPhase.servingFood => foodServingDuration,
      GameDiningCustomerPhase.eating => businessMealDuration,
      GameDiningCustomerPhase.checkout => _checkoutDuration,
      GameDiningCustomerPhase.leaving => customerLeavingDuration,
    };
  }

  Duration diningCustomerPhaseRemaining(
    GameDiningCustomer customer,
    DateTime now,
  ) {
    final duration = diningCustomerPhaseDuration(customer);
    if (duration <= Duration.zero) return Duration.zero;
    final remaining = customer.phaseStartedAt.add(duration).difference(now);
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining;
  }

  double diningCustomerPhaseProgress(
    GameDiningCustomer customer,
    DateTime now,
  ) {
    final duration = diningCustomerPhaseDuration(customer);
    if (duration <= Duration.zero) return 1;
    final elapsed = now.difference(customer.phaseStartedAt);
    if (elapsed <= Duration.zero) return 0;
    return (elapsed.inMilliseconds / duration.inMilliseconds)
        .clamp(0, 1)
        .toDouble();
  }

  Future<void> load({DateTime? now}) async {
    await _saveQueue;
    final currentTime = now ?? DateTime.now();
    final snapshotValues = _decodeSnapshot(
      await this.storage.getString(_snapshotKey),
    );
    final restoredFromSnapshot = snapshotValues != null;
    final GameStorage storage =
        restoredFromSnapshot ? MemoryGameStorage(snapshotValues) : this.storage;
    _coins = await storage.getDouble(_coinsKey) ?? startingCoins;
    _lifetimeEarnings = await storage.getDouble(_lifetimeEarningsKey) ?? 0;
    _seatLevel = max(1, await storage.getInt(_seatLevelKey) ?? 1);
    _serviceLevel = max(1, await storage.getInt(_serviceLevelKey) ?? 1);
    _kitchenLevel = max(1, await storage.getInt(_kitchenLevelKey) ?? 1);
    _restaurantXp = max(0, await storage.getInt(_restaurantXpKey) ?? 0);
    _menuUpgradeLevels = _decodeMenuLevels(
      await storage.getString(_menuUpgradeLevelsKey),
    );
    _menuMasteryXp = _decodeMenuLevels(
      await storage.getString(_menuMasteryXpKey),
    );
    _menuServeCounts = _decodeMenuLevels(
      await storage.getString(_menuServeCountsKey),
    );
    _unlockedFoodIds = {
      ...FoodCatalog.defaultUnlockedIds,
      ..._decodeIntSet(await storage.getString(_unlockedFoodIdsKey)),
    };
    _lastSavedAt = _parseSavedAt(
      await storage.getString(_lastSavedAtKey),
      currentTime,
    );
    final restoredPendingOfflineEarnings = max(
      0,
      await storage.getDouble(_pendingOfflineEarningsKey) ?? 0,
    ).toDouble();
    _customerOrdersServed = max(
      0,
      await storage.getInt(_customerOrdersServedKey) ?? 0,
    );
    _bestCombo = max(0, await storage.getInt(_bestComboKey) ?? 0);
    _shiftOrdersServed = max(
      0,
      await storage.getInt(_shiftOrdersServedKey) ?? 0,
    );
    _shiftMissedOrders = max(
      0,
      await storage.getInt(_shiftMissedOrdersKey) ?? 0,
    );
    _shiftBestCombo = max(0, await storage.getInt(_shiftBestComboKey) ?? 0);
    _shiftCoinsEarned = max(
      0,
      await storage.getDouble(_shiftCoinsEarnedKey) ?? 0,
    ).toDouble();
    _dailyTaskDate = await storage.getString(_dailyTaskDateKey) ?? '';
    _dailyOrdersServed = max(
      0,
      await storage.getInt(_dailyOrdersServedKey) ?? 0,
    );
    _dailyBestCombo = max(0, await storage.getInt(_dailyBestComboKey) ?? 0);
    _dailyUpgrades = max(0, await storage.getInt(_dailyUpgradesKey) ?? 0);
    _pendingBusinessEarnings = max(
      0,
      await storage.getDouble(_pendingBusinessEarningsKey) ?? 0,
    ).toDouble();
    _businessQueueCount = max(
      0,
      await storage.getInt(_businessQueueCountKey) ?? 0,
    );
    _businessSeatedCount = min(
      diningCapacity,
      max(0, await storage.getInt(_businessSeatedCountKey) ?? 0),
    );
    _businessKitchenQueueCount = max(
      0,
      await storage.getInt(_businessKitchenQueueCountKey) ?? 0,
    );
    _businessEatingCount = max(
      0,
      await storage.getInt(_businessEatingCountKey) ?? 0,
    );
    _businessCheckoutQueueCount = max(
      0,
      await storage.getInt(_businessCheckoutQueueCountKey) ?? 0,
    );
    _arrivalCarry = (await storage.getDouble(_arrivalCarryKey) ?? 0)
        .clamp(0, 0.999999)
        .toDouble();
    _kitchenCarry = (await storage.getDouble(_kitchenCarryKey) ?? 0)
        .clamp(0, 0.999999)
        .toDouble();
    _serviceCarry = (await storage.getDouble(_serviceCarryKey) ?? 0)
        .clamp(0, 0.999999)
        .toDouble();
    _normalizeBusinessState();
    final storedDiningCustomers = _decodeDiningCustomers(
      await storage.getString(_diningCustomersKey),
    );
    if (storedDiningCustomers.isEmpty) {
      _diningCustomers = _migrateLegacyDiningCustomers(currentTime);
    } else {
      _diningCustomers = _normalizeDiningCustomers(storedDiningCustomers);
    }
    final restoredNextCustomerId =
        await storage.getInt(_nextDiningCustomerIdKey);
    _nextDiningCustomerId = max(
      _nextDiningCustomerIdFrom(_diningCustomers),
      restoredNextCustomerId ?? 1,
    );
    _claimedMilestoneIds = _decodeStringSet(
      await storage.getString(_claimedMilestoneIdsKey),
    );
    _claimedDailyTaskIds = _decodeStringSet(
      await storage.getString(_claimedDailyTaskIdsKey),
    );
    _activeCustomerType = _decodeCustomerType(
      await storage.getString(_activeCustomerTypeKey),
    );
    _restoreCustomerOrder(
      foodId: await storage.getInt(_customerOrderFoodIdKey),
      reward: await storage.getDouble(_customerOrderRewardKey),
      createdAt: _parseOptionalDateTime(
        await storage.getString(_customerOrderCreatedAtKey),
      ),
    );
    _nextCustomerAvailableAt = _parseOptionalDateTime(
      await storage.getString(_nextCustomerAvailableAtKey),
    );
    if (_customerOrderFoodId == null) {
      _activeCustomerType = GameCustomerType.normal;
    }
    _restoreLegacyManualDiningCustomer(currentTime);
    _syncManualOrderFieldsFromDiningCustomers();
    _syncBusinessCountCache();
    _resetDailyTasksIfNeeded(currentTime);
    _syncUnlockedFoods();
    _pendingOfflineEarnings =
        restoredPendingOfflineEarnings + calculateOfflineEarnings(currentTime);
    _isLoaded = true;
    if (!restoredFromSnapshot) {
      await save();
    }
    notifyListeners();
  }

  double calculateOfflineEarnings(DateTime now) {
    final offlineMinutes =
        now.difference(_lastSavedAt).inSeconds / Duration.secondsPerMinute;
    return GameBalance.offlineEarnings(
      baselineRevenuePerMinute: baselineRevenuePerMinute,
      elapsedMinutes: offlineMinutes,
      restaurantLevel: restaurantLevel,
    );
  }

  Future<void> claimOfflineEarnings({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final earnings = pendingClaimableEarnings;
    if (earnings <= 0) {
      _lastSavedAt = currentTime;
      await save();
      notifyListeners();
      return;
    }

    _coins += earnings;
    _lifetimeEarnings += earnings;
    _pendingOfflineEarnings = 0;
    _pendingBusinessEarnings = 0;
    _lastSavedAt = currentTime;
    await save();
    notifyListeners();
  }

  Future<int> simulateBusinessTick(
    List<int> foodIds, {
    required Duration elapsed,
    DateTime? now,
  }) async {
    if (elapsed <= Duration.zero) return 0;
    final currentTime = now ?? DateTime.now();
    _resetDailyTasksIfNeeded(currentTime);
    final elapsedSeconds = min(
      offlineMinuteCap * 60,
      elapsed.inSeconds,
    );
    if (elapsedSeconds <= 0) return 0;
    if (elapsed.inSeconds > maxBusinessTickSeconds) {
      _pendingOfflineEarnings += GameBalance.offlineEarnings(
        baselineRevenuePerMinute: baselineRevenuePerMinute,
        elapsedMinutes: elapsedSeconds / Duration.secondsPerMinute,
        restaurantLevel: restaurantLevel,
      );
      await save(now: currentTime);
      notifyListeners();
      return 0;
    }

    final previousState = _diningStateSignature;
    final previousArrivalCarry = _arrivalCarry;
    final previousKitchenCarry = _kitchenCarry;
    final previousServiceCarry = _serviceCarry;
    var completedOrders = 0;
    for (var index = 0; index < elapsedSeconds; index += 1) {
      final tickTime = currentTime.subtract(
        Duration(seconds: elapsedSeconds - index - 1),
      );
      completedOrders += _simulateBusinessSecond(foodIds, tickTime);
    }

    if (_diningStateSignature != previousState ||
        completedOrders > 0 ||
        _arrivalCarry != previousArrivalCarry ||
        _kitchenCarry != previousKitchenCarry ||
        _serviceCarry != previousServiceCarry) {
      _syncManualOrderFieldsFromDiningCustomers();
      _syncBusinessCountCache();
      await save(now: currentTime);
      notifyListeners();
    }
    return completedOrders;
  }

  Future<bool> upgradeMenuItem(int foodId) async {
    if (!isFoodUnlocked(foodId)) return false;
    final cost = menuUpgradeCost(foodId);
    if (_coins < cost) return false;
    final currentTime = DateTime.now();
    _resetDailyTasksIfNeeded(currentTime);
    _coins -= cost;
    _menuUpgradeLevels = {
      ..._menuUpgradeLevels,
      foodId: menuLevel(foodId) + 1,
    };
    _recordUpgradeProgress();
    _addRestaurantXp(8);
    await save(now: currentTime);
    notifyListeners();
    return true;
  }

  int _simulateBusinessSecond(List<int> foodIds, DateTime now) {
    const seconds = 1;
    var completedOrders = _advanceTimedDiningPhases(now, foodIds);

    final arrivals = _consumeArrivalWork(seconds);
    if (arrivals > 0) {
      _addAutoArrivals(arrivals, foodIds, now);
    }

    final serviceOrders = businessCheckoutQueueCount > 0
        ? _consumeServiceWork(seconds)
        : _resetServiceWork();
    if (serviceOrders > 0) {
      _startCheckoutLeaving(min(1, serviceOrders), now);
    }

    final cookedOrders = businessKitchenQueueCount > 0
        ? _consumeKitchenWork(seconds)
        : _resetKitchenWork();
    if (cookedOrders > 0) {
      _startFoodServing(min(1, cookedOrders), now);
    }

    _seatWaitingCustomers(now);
    return completedOrders;
  }

  Future<bool> upgradeSeats() async {
    final cost = seatUpgradeCost;
    if (_coins < cost) return false;
    final currentTime = DateTime.now();
    _resetDailyTasksIfNeeded(currentTime);
    _coins -= cost;
    _seatLevel += 1;
    _recordUpgradeProgress();
    _addRestaurantXp(10);
    await save(now: currentTime);
    notifyListeners();
    return true;
  }

  Future<bool> upgradeService() async {
    final cost = serviceUpgradeCost;
    if (_coins < cost) return false;
    final currentTime = DateTime.now();
    _resetDailyTasksIfNeeded(currentTime);
    _coins -= cost;
    _serviceLevel += 1;
    _recordUpgradeProgress();
    _addRestaurantXp(10);
    await save(now: currentTime);
    notifyListeners();
    return true;
  }

  Future<bool> upgradeKitchen() async {
    final cost = kitchenUpgradeCost;
    if (_coins < cost) return false;
    final currentTime = DateTime.now();
    _resetDailyTasksIfNeeded(currentTime);
    _coins -= cost;
    _kitchenLevel += 1;
    _recordUpgradeProgress();
    _addRestaurantXp(12);
    await save(now: currentTime);
    notifyListeners();
    return true;
  }

  Future<void> addRestaurantXp(int amount, {DateTime? now}) async {
    _addRestaurantXp(amount);
    await save(now: now ?? DateTime.now());
    notifyListeners();
  }

  Future<bool> unlockFood(int foodId, {DateTime? now}) async {
    if (foodId <= 0 || isFoodUnlocked(foodId)) return false;
    _unlockedFoodIds = {..._unlockedFoodIds, foodId};
    await save(now: now ?? DateTime.now());
    notifyListeners();
    return true;
  }

  Future<void> startShift({DateTime? now}) async {
    _shiftOrdersServed = 0;
    _shiftMissedOrders = 0;
    _shiftBestCombo = 0;
    _shiftCoinsEarned = 0;
    await save(now: now ?? DateTime.now());
    notifyListeners();
  }

  Future<ShiftSummary> finishShift({DateTime? now}) async {
    final summary = ShiftSummary(
      ordersServed: _shiftOrdersServed,
      missedOrders: _shiftMissedOrders,
      bestCombo: _shiftBestCombo,
      coinsEarned: _shiftCoinsEarned,
    );
    _shiftOrdersServed = 0;
    _shiftMissedOrders = 0;
    _shiftBestCombo = 0;
    _shiftCoinsEarned = 0;
    await save(now: now ?? DateTime.now());
    notifyListeners();
    return summary;
  }

  Future<void> recordWrongDish({DateTime? now}) async {
    _shiftMissedOrders += 1;
    await save(now: now ?? DateTime.now());
    notifyListeners();
  }

  Future<double> claimDailyTask(String taskId, {DateTime? now}) async {
    _resetDailyTasksIfNeeded(now ?? DateTime.now());
    GameDailyTask? task;
    for (final candidate in dailyTasks) {
      if (candidate.id == taskId) {
        task = candidate;
        break;
      }
    }
    if (task == null || !task.claimable) return 0;

    _coins += task.reward;
    _lifetimeEarnings += task.reward;
    _claimedDailyTaskIds = {
      ..._claimedDailyTaskIds,
      task.id,
    };
    await save(now: now ?? DateTime.now());
    notifyListeners();
    return task.reward;
  }

  GameCustomerType generateCustomerType() {
    final seed = _customerOrdersServed +
        _shiftOrdersServed +
        _seatLevel +
        _serviceLevel +
        _kitchenLevel;
    if (restaurantLevel >= 4 && seed % 5 == 0) {
      return GameCustomerType.vip;
    }
    if (restaurantLevel >= 2 && seed % 3 == 0) {
      return GameCustomerType.impatient;
    }
    return GameCustomerType.normal;
  }

  Future<bool> ensureCustomerOrder(
    List<int> foodIds, {
    DateTime? now,
  }) async {
    if (manualDiningCustomer != null || _customerOrderFoodId != null) {
      return true;
    }
    final currentTime = now ?? DateTime.now();
    if (!canSeatCustomer(currentTime)) return false;
    final created = _createCustomerOrder(foodIds, currentTime);
    if (!created) return false;
    _syncManualOrderFieldsFromDiningCustomers();
    await save(now: currentTime);
    notifyListeners();
    return true;
  }

  Future<double> serveCustomerOrder(
    List<int> foodIds, {
    required int selectedFoodId,
    DateTime? now,
    double rewardMultiplier = 1,
    int combo = 0,
  }) async {
    final currentTime = now ?? DateTime.now();
    _resetDailyTasksIfNeeded(currentTime);
    final manualCustomer = _manualWaitingCustomer;
    final reward = manualCustomer?.reward ?? _customerOrderReward;
    if (manualCustomer == null || reward <= 0) {
      await ensureCustomerOrder(foodIds, now: currentTime);
      return 0;
    }
    if (manualCustomer.foodId != selectedFoodId) return 0;
    if (customerOrderExpired(currentTime)) {
      await missCustomerOrder(now: currentTime);
      return 0;
    }

    final multiplier = max(1.0, rewardMultiplier);
    final payout = reward * multiplier;
    _replaceDiningCustomer(
      manualCustomer.copyWith(
        phase: GameDiningCustomerPhase.servingFood,
        phaseStartedAt: currentTime,
        reward: payout,
        combo: max(0, combo),
      ),
    );
    _clearCustomerOrder();
    await save(now: currentTime);
    notifyListeners();
    return payout;
  }

  Future<bool> missCustomerOrder({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final manualCustomer = _manualWaitingCustomer;
    if (manualCustomer == null) return false;

    _shiftMissedOrders += 1;
    _replaceDiningCustomer(
      manualCustomer.copyWith(
        phase: GameDiningCustomerPhase.leaving,
        phaseStartedAt: currentTime,
        reward: 0,
        combo: 0,
      ),
    );
    _clearCustomerOrder();
    final retrySeconds = max(2, customerArrivalDelay.inSeconds ~/ 2);
    _nextCustomerAvailableAt = currentTime.add(Duration(seconds: retrySeconds));
    await save(now: currentTime);
    notifyListeners();
    return true;
  }

  Future<double> claimMilestone(String milestoneId, {DateTime? now}) async {
    GameMilestone? milestone;
    for (final candidate in milestones) {
      if (candidate.id == milestoneId) {
        milestone = candidate;
        break;
      }
    }
    if (milestone == null || !milestone.claimable) return 0;

    _coins += milestone.reward;
    _lifetimeEarnings += milestone.reward;
    _claimedMilestoneIds = {
      ..._claimedMilestoneIds,
      milestone.id,
    };
    await save(now: now ?? DateTime.now());
    notifyListeners();
    return milestone.reward;
  }

  Future<void> save({DateTime? now}) {
    if (now != null) {
      _lastSavedAt = now;
    }
    _syncManualOrderFieldsFromDiningCustomers();
    _syncBusinessCountCache();
    final encodedSnapshot = jsonEncode({
      'version': _snapshotVersion,
      'values': _snapshotValues(),
    });
    final operation = _saveQueue.then((_) async {
      try {
        await storage.setString(_snapshotKey, encodedSnapshot);
        _lastSaveError = null;
      } catch (error) {
        _lastSaveError = error;
      }
    });
    _saveQueue = operation;
    return operation;
  }

  Map<String, Object> _snapshotValues() {
    return {
      _coinsKey: _coins,
      _lifetimeEarningsKey: _lifetimeEarnings,
      _pendingOfflineEarningsKey: _pendingOfflineEarnings,
      _lastSavedAtKey: _lastSavedAt.toIso8601String(),
      _seatLevelKey: _seatLevel,
      _serviceLevelKey: _serviceLevel,
      _kitchenLevelKey: _kitchenLevel,
      _restaurantXpKey: _restaurantXp,
      _customerOrdersServedKey: _customerOrdersServed,
      _bestComboKey: _bestCombo,
      _shiftOrdersServedKey: _shiftOrdersServed,
      _shiftMissedOrdersKey: _shiftMissedOrders,
      _shiftBestComboKey: _shiftBestCombo,
      _shiftCoinsEarnedKey: _shiftCoinsEarned,
      _dailyTaskDateKey: _dailyTaskDate,
      _dailyOrdersServedKey: _dailyOrdersServed,
      _dailyBestComboKey: _dailyBestCombo,
      _dailyUpgradesKey: _dailyUpgrades,
      _pendingBusinessEarningsKey: _pendingBusinessEarnings,
      _diningCustomersKey: jsonEncode(
        _diningCustomers.map((customer) => customer.toJson()).toList(),
      ),
      _nextDiningCustomerIdKey: _nextDiningCustomerId,
      _businessQueueCountKey: businessQueueCount,
      _businessSeatedCountKey: businessSeatedCount,
      _businessKitchenQueueCountKey: businessKitchenQueueCount,
      _businessEatingCountKey: businessEatingCount,
      _businessCheckoutQueueCountKey: businessCheckoutQueueCount,
      _arrivalCarryKey: _arrivalCarry,
      _kitchenCarryKey: _kitchenCarry,
      _serviceCarryKey: _serviceCarry,
      _claimedMilestoneIdsKey:
          jsonEncode(_claimedMilestoneIds.toList()..sort()),
      _claimedDailyTaskIdsKey:
          jsonEncode(_claimedDailyTaskIds.toList()..sort()),
      _unlockedFoodIdsKey:
          jsonEncode(_computedUnlockedFoodIds().toList()..sort()),
      _menuUpgradeLevelsKey: jsonEncode(
        _menuUpgradeLevels.map(
          (foodId, level) => MapEntry(foodId.toString(), level),
        ),
      ),
      _menuMasteryXpKey: jsonEncode(
        _menuMasteryXp.map(
          (foodId, xp) => MapEntry(foodId.toString(), xp),
        ),
      ),
      _menuServeCountsKey: jsonEncode(
        _menuServeCounts.map(
          (foodId, count) => MapEntry(foodId.toString(), count),
        ),
      ),
      _activeCustomerTypeKey: _activeCustomerType.name,
      if (_customerOrderFoodId != null &&
          _customerOrderReward > 0 &&
          _customerOrderCreatedAt != null) ...{
        _customerOrderFoodIdKey: _customerOrderFoodId!,
        _customerOrderRewardKey: _customerOrderReward,
        _customerOrderCreatedAtKey: _customerOrderCreatedAt!.toIso8601String(),
      },
      if (_nextCustomerAvailableAt != null)
        _nextCustomerAvailableAtKey:
            _nextCustomerAvailableAt!.toIso8601String(),
    };
  }

  Map<String, Object>? _decodeSnapshot(String? encodedSnapshot) {
    if (encodedSnapshot == null || encodedSnapshot.isEmpty) return null;
    try {
      final decoded = jsonDecode(encodedSnapshot);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != _snapshotVersion ||
          decoded['values'] is! Map<String, dynamic>) {
        return null;
      }
      final values = decoded['values'] as Map<String, dynamic>;
      return values.map(
        (key, value) => MapEntry(key, value as Object),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> reset({DateTime? now}) async {
    await _saveQueue;
    await storage.clearGameData();
    _lastSaveError = null;
    _coins = startingCoins;
    _lifetimeEarnings = 0;
    _pendingOfflineEarnings = 0;
    _lastSavedAt = now ?? DateTime.now();
    _clearCustomerOrder();
    _nextCustomerAvailableAt = null;
    _customerOrdersServed = 0;
    _bestCombo = 0;
    _seatLevel = 1;
    _serviceLevel = 1;
    _kitchenLevel = 1;
    _restaurantXp = 0;
    _shiftOrdersServed = 0;
    _shiftMissedOrders = 0;
    _shiftBestCombo = 0;
    _shiftCoinsEarned = 0;
    _dailyTaskDate = _formatDateKey(now ?? DateTime.now());
    _dailyOrdersServed = 0;
    _dailyBestCombo = 0;
    _dailyUpgrades = 0;
    _pendingBusinessEarnings = 0;
    _businessQueueCount = 0;
    _businessSeatedCount = 0;
    _businessKitchenQueueCount = 0;
    _businessEatingCount = 0;
    _businessCheckoutQueueCount = 0;
    _diningCustomers = [];
    _nextDiningCustomerId = 1;
    _arrivalCarry = 0;
    _kitchenCarry = 0;
    _serviceCarry = 0;
    _activeCustomerType = GameCustomerType.normal;
    _menuUpgradeLevels = {};
    _menuMasteryXp = {};
    _menuServeCounts = {};
    _unlockedFoodIds = {...FoodCatalog.defaultUnlockedIds};
    _claimedMilestoneIds = {};
    _claimedDailyTaskIds = {};
    _isLoaded = true;
    await save();
    notifyListeners();
  }

  DateTime _parseSavedAt(String? value, DateTime fallback) {
    if (value == null) return fallback;
    return DateTime.tryParse(value) ?? fallback;
  }

  DateTime? _parseOptionalDateTime(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  GameMilestone _milestone({
    required String id,
    required String titleKey,
    required String descriptionKey,
    required int progress,
    required int target,
    required double reward,
  }) {
    return GameMilestone(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      progress: progress,
      target: target,
      reward: reward,
      claimed: _claimedMilestoneIds.contains(id),
    );
  }

  void _restoreCustomerOrder({
    required int? foodId,
    required double? reward,
    required DateTime? createdAt,
  }) {
    if (foodId == null || foodId <= 0 || reward == null || reward <= 0) {
      _clearCustomerOrder();
      return;
    }

    _customerOrderFoodId = foodId;
    _customerOrderReward = reward;
    _customerOrderCreatedAt = createdAt;
  }

  Iterable<GameDiningCustomer> get _autoCustomers =>
      _diningCustomers.where((customer) => customer.isAuto);

  GameDiningCustomer? get _manualWaitingCustomer {
    final manual = manualDiningCustomer;
    if (manual == null ||
        manual.phase != GameDiningCustomerPhase.waitingForFood) {
      return null;
    }
    return manual;
  }

  String get _diningStateSignature => _diningCustomers
      .map(
        (customer) =>
            '${customer.id}:${customer.source.name}:${customer.phase.name}:'
            '${customer.seatIndex}:${customer.foodId}:${customer.reward}:'
            '${customer.phaseStartedAt.millisecondsSinceEpoch}:'
            '${customer.combo}',
      )
      .join('|');

  int _consumeArrivalWork(int seconds) {
    _arrivalCarry += customerArrivalRatePerMinute * seconds / 60;
    final count = _arrivalCarry.floor();
    _arrivalCarry -= count;
    return count;
  }

  int _consumeKitchenWork(int seconds) {
    _kitchenCarry += kitchenOrdersPerMinute * seconds / 60;
    final count = _kitchenCarry.floor();
    _kitchenCarry -= count;
    return count;
  }

  int _resetKitchenWork() {
    _kitchenCarry = 0;
    return 0;
  }

  int _consumeServiceWork(int seconds) {
    _serviceCarry += serviceOrdersPerMinute * seconds / 60;
    final count = _serviceCarry.floor();
    _serviceCarry -= count;
    return count;
  }

  int _resetServiceWork() {
    _serviceCarry = 0;
    return 0;
  }

  void _normalizeBusinessState() {
    _businessQueueCount = min(businessMaxQueue, max(0, _businessQueueCount));
    _businessSeatedCount = min(diningCapacity, max(0, _businessSeatedCount));
    var remainingSeats = _businessSeatedCount;
    _businessKitchenQueueCount = min(
      remainingSeats,
      max(0, _businessKitchenQueueCount),
    );
    remainingSeats -= _businessKitchenQueueCount;
    _businessEatingCount = min(remainingSeats, max(0, _businessEatingCount));
    remainingSeats -= _businessEatingCount;
    _businessCheckoutQueueCount = min(
      remainingSeats,
      max(0, _businessCheckoutQueueCount),
    );
  }

  void _syncBusinessCountCache() {
    _businessQueueCount = businessQueueCount;
    _businessSeatedCount = businessSeatedCount;
    _businessKitchenQueueCount = businessKitchenQueueCount;
    _businessEatingCount = businessEatingCount;
    _businessCheckoutQueueCount = businessCheckoutQueueCount;
  }

  void _syncManualOrderFieldsFromDiningCustomers() {
    final manual = manualDiningCustomer;
    if (manual != null) {
      _activeCustomerType = manual.customerType;
    }
    final waiting = _manualWaitingCustomer;
    if (waiting == null) {
      _customerOrderFoodId = null;
      _customerOrderReward = 0;
      _customerOrderCreatedAt = null;
      if (manual == null) {
        _activeCustomerType = GameCustomerType.normal;
      }
      return;
    }

    _customerOrderFoodId = waiting.foodId;
    _customerOrderReward = waiting.reward;
    _customerOrderCreatedAt = waiting.phaseStartedAt;
    _activeCustomerType = waiting.customerType;
  }

  int _nextCustomerId() {
    final id = _nextDiningCustomerId;
    _nextDiningCustomerId += 1;
    return id;
  }

  int _nextDiningCustomerIdFrom(List<GameDiningCustomer> customers) {
    if (customers.isEmpty) return 1;
    final maxId = customers.fold<int>(0, (value, customer) {
      return max(value, customer.id);
    });
    return maxId + 1;
  }

  Set<int> _occupiedSeatIndexes({int? exceptCustomerId}) {
    return _diningCustomers
        .where(
          (customer) =>
              customer.id != exceptCustomerId &&
              customer.seatIndex != null &&
              customer.phase != GameDiningCustomerPhase.queueing,
        )
        .map((customer) => customer.seatIndex!)
        .toSet();
  }

  int? _firstOpenSeatIndex({Set<int>? occupied}) {
    final used = occupied ?? _occupiedSeatIndexes();
    for (var index = 0; index < diningCapacity; index += 1) {
      if (!used.contains(index)) return index;
    }
    return null;
  }

  void _replaceDiningCustomer(GameDiningCustomer customer) {
    final index =
        _diningCustomers.indexWhere((entry) => entry.id == customer.id);
    if (index < 0) return;
    _diningCustomers = [
      ..._diningCustomers.take(index),
      customer,
      ..._diningCustomers.skip(index + 1),
    ];
  }

  void _removeDiningCustomer(GameDiningCustomer customer) {
    _diningCustomers = [
      for (final entry in _diningCustomers)
        if (entry.id != customer.id) entry,
    ];
  }

  List<GameDiningCustomer> _normalizeDiningCustomers(
    List<GameDiningCustomer> customers,
  ) {
    final normalized = <GameDiningCustomer>[];
    final occupied = <int>{};
    var manualRestored = false;
    final sorted = [...customers]..sort((a, b) => a.id.compareTo(b.id));

    for (final customer in sorted) {
      if (customer.isManual) {
        if (manualRestored) continue;
        manualRestored = true;
      }

      var seatIndex = customer.seatIndex;
      final needsSeat = customer.phase != GameDiningCustomerPhase.queueing;
      if (seatIndex != null &&
          (seatIndex < 0 ||
              seatIndex >= diningCapacity ||
              occupied.contains(seatIndex))) {
        seatIndex = null;
      }
      if (needsSeat && seatIndex == null) {
        seatIndex = _firstOpenSeatIndex(occupied: occupied);
      }
      if (needsSeat && seatIndex == null) continue;
      if (seatIndex != null) occupied.add(seatIndex);

      normalized.add(customer.copyWith(seatIndex: seatIndex));
    }

    return normalized;
  }

  List<GameDiningCustomer> _migrateLegacyDiningCustomers(DateTime now) {
    final customers = <GameDiningCustomer>[];
    _nextDiningCustomerId = 1;
    final availableIds = _computedUnlockedFoodIds().toList()..sort();
    int? foodIdForIndex(int index) {
      if (availableIds.isEmpty) return null;
      return availableIds[index % availableIds.length];
    }

    GameDiningCustomer? buildCustomer({
      required GameDiningCustomerPhase phase,
      required int? seatIndex,
      required int index,
    }) {
      final foodId = foodIdForIndex(index);
      if (foodId == null) return null;
      return GameDiningCustomer(
        id: _nextCustomerId(),
        source: GameDiningCustomerSource.auto,
        phase: phase,
        seatIndex: seatIndex,
        foodId: foodId,
        reward:
            customerOrderRewardForFood(foodId) * activeEventRewardMultiplier,
        customerType: GameCustomerType.normal,
        phaseStartedAt: now,
      );
    }

    var seatIndex = 0;
    var sequence = 0;
    for (var index = 0; index < _businessKitchenQueueCount; index += 1) {
      final customer = buildCustomer(
        phase: GameDiningCustomerPhase.waitingForFood,
        seatIndex: seatIndex,
        index: sequence,
      );
      if (customer != null) customers.add(customer);
      seatIndex += 1;
      sequence += 1;
    }
    for (var index = 0; index < _businessEatingCount; index += 1) {
      final customer = buildCustomer(
        phase: GameDiningCustomerPhase.eating,
        seatIndex: seatIndex,
        index: sequence,
      );
      if (customer != null) customers.add(customer);
      seatIndex += 1;
      sequence += 1;
    }
    for (var index = 0; index < _businessCheckoutQueueCount; index += 1) {
      final customer = buildCustomer(
        phase: GameDiningCustomerPhase.checkout,
        seatIndex: seatIndex,
        index: sequence,
      );
      if (customer != null) customers.add(customer);
      seatIndex += 1;
      sequence += 1;
    }
    for (var index = 0; index < _businessQueueCount; index += 1) {
      final customer = buildCustomer(
        phase: GameDiningCustomerPhase.queueing,
        seatIndex: null,
        index: sequence,
      );
      if (customer != null) customers.add(customer);
      sequence += 1;
    }

    return _normalizeDiningCustomers(customers);
  }

  void _restoreLegacyManualDiningCustomer(DateTime now) {
    if (_customerOrderFoodId == null ||
        _customerOrderReward <= 0 ||
        manualDiningCustomer != null) {
      return;
    }
    final seatIndex = _firstOpenSeatIndex();
    if (seatIndex == null) return;
    _diningCustomers = [
      ..._diningCustomers,
      GameDiningCustomer(
        id: _nextCustomerId(),
        source: GameDiningCustomerSource.manual,
        phase: GameDiningCustomerPhase.waitingForFood,
        seatIndex: seatIndex,
        foodId: _customerOrderFoodId,
        reward: _customerOrderReward,
        customerType: _activeCustomerType,
        phaseStartedAt: _customerOrderCreatedAt ?? now,
      ),
    ];
  }

  List<GameDiningCustomer> _decodeDiningCustomers(String? value) {
    if (value == null || value.isEmpty) return [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List<dynamic>) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(GameDiningCustomer.fromJson)
          .whereType<GameDiningCustomer>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  int _advanceTimedDiningPhases(DateTime now, List<int> foodIds) {
    var completedAutoOrders = 0;
    for (final customer in [..._diningCustomers]) {
      final progress = diningCustomerPhaseProgress(customer, now);
      if (progress < 1) continue;

      switch (customer.phase) {
        case GameDiningCustomerPhase.queueing:
        case GameDiningCustomerPhase.waitingForFood:
          break;
        case GameDiningCustomerPhase.seating:
          _replaceDiningCustomer(
            customer.copyWith(
              phase: GameDiningCustomerPhase.waitingForFood,
              phaseStartedAt: now,
            ),
          );
          break;
        case GameDiningCustomerPhase.servingFood:
          _replaceDiningCustomer(
            customer.copyWith(
              phase: GameDiningCustomerPhase.eating,
              phaseStartedAt: now,
            ),
          );
          break;
        case GameDiningCustomerPhase.eating:
          _replaceDiningCustomer(
            customer.copyWith(
              phase: GameDiningCustomerPhase.checkout,
              phaseStartedAt: now,
            ),
          );
          break;
        case GameDiningCustomerPhase.checkout:
          if (customer.isManual) {
            _replaceDiningCustomer(
              customer.copyWith(
                phase: GameDiningCustomerPhase.leaving,
                phaseStartedAt: now,
              ),
            );
          }
          break;
        case GameDiningCustomerPhase.leaving:
          if (customer.isAuto) {
            completedAutoOrders += 1;
          }
          _completeDiningCustomer(customer, now, foodIds);
          break;
      }
    }
    _syncManualOrderFieldsFromDiningCustomers();
    return completedAutoOrders;
  }

  void _addAutoArrivals(int arrivals, List<int> foodIds, DateTime now) {
    for (var index = 0; index < arrivals; index += 1) {
      if (businessQueueCount >= businessMaxQueue) return;
      final customer = _createAutoCustomer(foodIds, now);
      if (customer == null) return;
      _diningCustomers = [..._diningCustomers, customer];
    }
  }

  GameDiningCustomer? _createAutoCustomer(List<int> foodIds, DateTime now) {
    final customerType = generateCustomerType();
    final foodId = _pickCustomerOrderFoodId(foodIds, customerType);
    if (foodId == null) return null;
    return GameDiningCustomer(
      id: _nextCustomerId(),
      source: GameDiningCustomerSource.auto,
      phase: GameDiningCustomerPhase.queueing,
      seatIndex: null,
      foodId: foodId,
      reward: customerOrderRewardForFood(foodId) *
          _customerTypeRewardMultiplier(customerType) *
          activeEventRewardMultiplier,
      customerType: customerType,
      phaseStartedAt: now,
    );
  }

  void _seatWaitingCustomers(DateTime now) {
    final seatIndex = _firstOpenSeatIndex();
    if (seatIndex == null) return;
    GameDiningCustomer? nextCustomer;
    for (final customer in _autoCustomers) {
      if (customer.phase == GameDiningCustomerPhase.queueing) {
        nextCustomer = customer;
        break;
      }
    }
    if (nextCustomer == null) return;
    _replaceDiningCustomer(
      nextCustomer.copyWith(
        phase: GameDiningCustomerPhase.seating,
        seatIndex: seatIndex,
        phaseStartedAt: now,
      ),
    );
  }

  void _startFoodServing(int count, DateTime now) {
    if (count <= 0) return;
    final waiting = _autoCustomers
        .where(
          (customer) =>
              customer.phase == GameDiningCustomerPhase.waitingForFood,
        )
        .toList()
      ..sort((a, b) => a.phaseStartedAt.compareTo(b.phaseStartedAt));
    for (final customer in waiting.take(count)) {
      _replaceDiningCustomer(
        customer.copyWith(
          phase: GameDiningCustomerPhase.servingFood,
          phaseStartedAt: now,
        ),
      );
    }
  }

  void _startCheckoutLeaving(int count, DateTime now) {
    if (count <= 0) return;
    final checkout = _autoCustomers
        .where((customer) => customer.phase == GameDiningCustomerPhase.checkout)
        .toList()
      ..sort((a, b) => a.phaseStartedAt.compareTo(b.phaseStartedAt));
    for (final customer in checkout.take(count)) {
      _replaceDiningCustomer(
        customer.copyWith(
          phase: GameDiningCustomerPhase.leaving,
          phaseStartedAt: now,
        ),
      );
    }
  }

  void _completeDiningCustomer(
    GameDiningCustomer customer,
    DateTime now,
    List<int> foodIds,
  ) {
    _removeDiningCustomer(customer);
    if (customer.isAuto) {
      _rewardAutoServedOrder(customer, foodIds);
      return;
    }
    if (customer.reward > 0) {
      _rewardManualServedOrder(customer);
    }
    if (manualDiningCustomer == null &&
        (_nextCustomerAvailableAt == null ||
            _nextCustomerAvailableAt!.isBefore(now))) {
      _nextCustomerAvailableAt = now.add(customerArrivalDelay);
    }
  }

  void _rewardAutoServedOrder(
    GameDiningCustomer customer,
    List<int> foodIds,
  ) {
    var foodId = customer.foodId;
    if (foodId == null || !isFoodUnlocked(foodId)) {
      final fallbackIds = availableFoodIds(foodIds);
      if (fallbackIds.isEmpty) return;
      foodId = fallbackIds[_customerOrdersServed % fallbackIds.length];
    }
    final payout = customer.reward > 0
        ? customer.reward
        : customerOrderRewardForFood(foodId) * activeEventRewardMultiplier;
    _pendingBusinessEarnings += payout;
    _customerOrdersServed += 1;
    _dailyOrdersServed += 1;
    _addRestaurantXp(2);
    _addMenuMasteryXp(foodId, 1);
    _addMenuServeCount(foodId, 1);
  }

  void _rewardManualServedOrder(GameDiningCustomer customer) {
    final foodId = customer.foodId;
    final payout = max(0, customer.reward);
    final combo = max(0, customer.combo);
    _coins += payout;
    _lifetimeEarnings += payout;
    _customerOrdersServed += 1;
    _shiftOrdersServed += 1;
    _shiftCoinsEarned += payout;
    if (combo > _bestCombo) {
      _bestCombo = combo;
    }
    if (combo > _shiftBestCombo) {
      _shiftBestCombo = combo;
    }
    _dailyOrdersServed += 1;
    if (combo > _dailyBestCombo) {
      _dailyBestCombo = combo;
    }
    _addRestaurantXp(6 + combo.clamp(0, 3).toInt());
    if (foodId != null) {
      _addMenuMasteryXp(foodId, 1);
      _addMenuServeCount(foodId, 1);
    }
  }

  bool _createCustomerOrder(List<int> foodIds, DateTime now) {
    final seatIndex = _firstOpenSeatIndex();
    if (seatIndex == null) return false;
    final customerType = generateCustomerType();
    final foodId = _pickCustomerOrderFoodId(foodIds, customerType);
    if (foodId == null) {
      _clearCustomerOrder();
      return false;
    }

    final reward = customerOrderRewardForFood(foodId) *
        _customerTypeRewardMultiplier(customerType) *
        activeEventRewardMultiplier;
    _diningCustomers = [
      ..._diningCustomers,
      GameDiningCustomer(
        id: _nextCustomerId(),
        source: GameDiningCustomerSource.manual,
        phase: GameDiningCustomerPhase.seating,
        seatIndex: seatIndex,
        foodId: foodId,
        reward: reward,
        customerType: customerType,
        phaseStartedAt: now,
      ),
    ];
    _customerOrderFoodId = null;
    _customerOrderReward = 0;
    _customerOrderCreatedAt = null;
    _activeCustomerType = customerType;
    _nextCustomerAvailableAt = null;
    return true;
  }

  int? _pickCustomerOrderFoodId(
    List<int> foodIds,
    GameCustomerType customerType,
  ) {
    final unlockedFoodIds = availableFoodIds(foodIds);
    if (unlockedFoodIds.isEmpty) return null;
    if (customerType == GameCustomerType.vip) {
      final upgradedIds =
          unlockedFoodIds.where((foodId) => menuLevel(foodId) > 0).toList();
      if (upgradedIds.isNotEmpty) {
        return upgradedIds[_customerOrdersServed % upgradedIds.length];
      }
      return unlockedFoodIds.last;
    }
    return unlockedFoodIds[_customerOrdersServed % unlockedFoodIds.length];
  }

  void _clearCustomerOrder() {
    _customerOrderFoodId = null;
    _customerOrderReward = 0;
    _customerOrderCreatedAt = null;
    _activeCustomerType = GameCustomerType.normal;
  }

  double _customerTypeRewardMultiplier(GameCustomerType type) {
    return switch (type) {
      GameCustomerType.normal => 1,
      GameCustomerType.impatient => 1.16,
      GameCustomerType.vip => 1.45,
    };
  }

  void _addRestaurantXp(int amount) {
    if (amount <= 0) return;
    _restaurantXp += amount;
    _syncUnlockedFoods();
  }

  void _recordUpgradeProgress() {
    _dailyUpgrades += 1;
  }

  GameDailyTask _dailyTask({
    required String id,
    required String titleKey,
    required String descriptionKey,
    required int progress,
    required int target,
    required double reward,
  }) {
    return GameDailyTask(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      progress: progress,
      target: target,
      reward: reward,
      claimed: _claimedDailyTaskIds.contains(id),
    );
  }

  String _formatDateKey(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _resetDailyTasksIfNeeded(DateTime now) {
    final today = _formatDateKey(now);
    if (_dailyTaskDate == today) return;
    _dailyTaskDate = today;
    _dailyOrdersServed = 0;
    _dailyBestCombo = 0;
    _dailyUpgrades = 0;
    _claimedDailyTaskIds = {};
  }

  Set<int> _computedUnlockedFoodIds() {
    return _computedUnlockedFoodIdsFor(restaurantLevel);
  }

  Set<int> _computedUnlockedFoodIdsFor(int projectedRestaurantLevel) {
    final unlocked = <int>{
      ...FoodCatalog.defaultUnlockedIds,
      ..._unlockedFoodIds,
    };
    for (final foodId in FoodCatalog.ids) {
      if (projectedRestaurantLevel >= foodUnlockLevel(foodId)) {
        unlocked.add(foodId);
      }
    }
    return unlocked.where((foodId) => foodId > 0).toSet();
  }

  void _syncUnlockedFoods() {
    _unlockedFoodIds = _computedUnlockedFoodIds();
  }

  void _addMenuMasteryXp(int foodId, int amount) {
    if (foodId <= 0 || amount <= 0) return;
    _menuMasteryXp = {
      ..._menuMasteryXp,
      foodId: masteryXpForFood(foodId) + amount,
    };
  }

  void _addMenuServeCount(int foodId, int amount) {
    if (foodId <= 0 || amount <= 0) return;
    _menuServeCounts = {
      ..._menuServeCounts,
      foodId: servedCountForFood(foodId) + amount,
    };
  }

  Map<int, int> _decodeMenuLevels(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return {};
      return decoded.map((foodId, level) {
        return MapEntry(int.parse(foodId), level is int ? level : 0);
      })
        ..removeWhere((foodId, level) => foodId <= 0 || level <= 0);
    } catch (_) {
      return {};
    }
  }

  Set<String> _decodeStringSet(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List<dynamic>) return {};
      return decoded.whereType<String>().where((id) => id.isNotEmpty).toSet();
    } catch (_) {
      return {};
    }
  }

  Set<int> _decodeIntSet(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List<dynamic>) return {};
      return decoded
          .map((entry) {
            if (entry is int) return entry;
            if (entry is num) return entry.toInt();
            if (entry is String) return int.tryParse(entry);
            return null;
          })
          .whereType<int>()
          .where((foodId) => foodId > 0)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  GameCustomerType _decodeCustomerType(String? value) {
    for (final type in GameCustomerType.values) {
      if (type.name == value) return type;
    }
    return GameCustomerType.normal;
  }
}
