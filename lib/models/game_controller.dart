import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class GameStorage {
  Future<double?> getDouble(String key);
  Future<int?> getInt(String key);
  Future<String?> getString(String key);
  Future<void> setDouble(String key, double value);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
  Future<void> clearGameData();
}

class SharedPreferencesGameStorage implements GameStorage {
  static const _gameKeys = [
    GameController._coinsKey,
    GameController._lifetimeEarningsKey,
    GameController._lastSavedAtKey,
    GameController._lastOrderRewardAtKey,
    GameController._customerOrderFoodIdKey,
    GameController._customerOrderRewardKey,
    GameController._customerOrderCreatedAtKey,
    GameController._nextCustomerAvailableAtKey,
    GameController._customerOrdersServedKey,
    GameController._bestComboKey,
    GameController._claimedMilestoneIdsKey,
    GameController._seatLevelKey,
    GameController._serviceLevelKey,
    GameController._kitchenLevelKey,
    GameController._menuUpgradeLevelsKey,
    GameController._menuMasteryXpKey,
    GameController._menuServeCountsKey,
    GameController._restaurantXpKey,
    GameController._unlockedFoodIdsKey,
    GameController._shiftOrdersServedKey,
    GameController._shiftMissedOrdersKey,
    GameController._shiftBestComboKey,
    GameController._shiftCoinsEarnedKey,
    GameController._dailyTaskDateKey,
    GameController._dailyOrdersServedKey,
    GameController._dailyBestComboKey,
    GameController._dailyUpgradesKey,
    GameController._claimedDailyTaskIdsKey,
    GameController._activeCustomerTypeKey,
    GameController._pendingBusinessEarningsKey,
    GameController._diningCustomersKey,
    GameController._nextDiningCustomerIdKey,
    GameController._businessQueueCountKey,
    GameController._businessSeatedCountKey,
    GameController._businessKitchenQueueCountKey,
    GameController._businessEatingCountKey,
    GameController._businessCheckoutQueueCountKey,
  ];

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<double?> getDouble(String key) async {
    return (await _prefs).getDouble(key);
  }

  @override
  Future<int?> getInt(String key) async {
    return (await _prefs).getInt(key);
  }

  @override
  Future<String?> getString(String key) async {
    return (await _prefs).getString(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await (await _prefs).setDouble(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await (await _prefs).setInt(key, value);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _prefs).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await _prefs).remove(key);
  }

  @override
  Future<void> clearGameData() async {
    final prefs = await _prefs;
    for (final key in _gameKeys) {
      await prefs.remove(key);
    }
  }
}

class MemoryGameStorage implements GameStorage {
  final Map<String, Object> _values;

  MemoryGameStorage([Map<String, Object>? values]) : _values = values ?? {};

  @override
  Future<double?> getDouble(String key) async {
    final value = _values[key];
    return value is double ? value : null;
  }

  @override
  Future<int?> getInt(String key) async {
    final value = _values[key];
    return value is int ? value : null;
  }

  @override
  Future<String?> getString(String key) async {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clearGameData() async {
    _values.clear();
  }
}

class GameMilestone {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final int progress;
  final int target;
  final double reward;
  final bool claimed;

  const GameMilestone({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimed,
  });

  bool get completed => progress >= target;
  bool get claimable => completed && !claimed;
  double get progressRatio {
    if (target <= 0) return 1;
    return (progress / target).clamp(0, 1).toDouble();
  }
}

enum GameCustomerType { normal, impatient, vip }

enum GameEventType { lunchRush, regularVisit, ingredientDiscount }

enum GameDiningCustomerSource { auto, manual }

enum GameDiningCustomerPhase {
  queueing,
  seating,
  waitingForFood,
  servingFood,
  eating,
  checkout,
  leaving,
}

class GameDiningCustomer {
  final int id;
  final GameDiningCustomerSource source;
  final GameDiningCustomerPhase phase;
  final int? seatIndex;
  final int? foodId;
  final double reward;
  final GameCustomerType customerType;
  final DateTime phaseStartedAt;
  final int combo;

  const GameDiningCustomer({
    required this.id,
    required this.source,
    required this.phase,
    required this.seatIndex,
    required this.foodId,
    required this.reward,
    required this.customerType,
    required this.phaseStartedAt,
    this.combo = 0,
  });

  bool get isManual => source == GameDiningCustomerSource.manual;
  bool get isAuto => source == GameDiningCustomerSource.auto;
  bool get hasSeat => seatIndex != null;
  bool get isWaitingForManualDish =>
      isManual && phase == GameDiningCustomerPhase.waitingForFood;

  GameDiningCustomer copyWith({
    GameDiningCustomerSource? source,
    GameDiningCustomerPhase? phase,
    Object? seatIndex = _copySentinel,
    Object? foodId = _copySentinel,
    double? reward,
    GameCustomerType? customerType,
    DateTime? phaseStartedAt,
    int? combo,
  }) {
    return GameDiningCustomer(
      id: id,
      source: source ?? this.source,
      phase: phase ?? this.phase,
      seatIndex: identical(seatIndex, _copySentinel)
          ? this.seatIndex
          : seatIndex as int?,
      foodId: identical(foodId, _copySentinel) ? this.foodId : foodId as int?,
      reward: reward ?? this.reward,
      customerType: customerType ?? this.customerType,
      phaseStartedAt: phaseStartedAt ?? this.phaseStartedAt,
      combo: combo ?? this.combo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.name,
      'phase': phase.name,
      'seatIndex': seatIndex,
      'foodId': foodId,
      'reward': reward,
      'customerType': customerType.name,
      'phaseStartedAt': phaseStartedAt.toIso8601String(),
      'combo': combo,
    };
  }

  static GameDiningCustomer? fromJson(Map<String, dynamic> json) {
    final id = _readInt(json['id']);
    if (id == null || id <= 0) return null;
    final phaseStartedAt = DateTime.tryParse('${json['phaseStartedAt']}');
    if (phaseStartedAt == null) return null;

    return GameDiningCustomer(
      id: id,
      source: _decodeSource(json['source']),
      phase: _decodePhase(json['phase']),
      seatIndex: _readInt(json['seatIndex']),
      foodId: _readInt(json['foodId']),
      reward: _readDouble(json['reward']) ?? 0,
      customerType: _decodeCustomerType(json['customerType']),
      phaseStartedAt: phaseStartedAt,
      combo: max(0, _readInt(json['combo']) ?? 0),
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static GameDiningCustomerSource _decodeSource(Object? value) {
    for (final source in GameDiningCustomerSource.values) {
      if (source.name == value) return source;
    }
    return GameDiningCustomerSource.auto;
  }

  static GameDiningCustomerPhase _decodePhase(Object? value) {
    for (final phase in GameDiningCustomerPhase.values) {
      if (phase.name == value) return phase;
    }
    return GameDiningCustomerPhase.queueing;
  }

  static GameCustomerType _decodeCustomerType(Object? value) {
    for (final type in GameCustomerType.values) {
      if (type.name == value) return type;
    }
    return GameCustomerType.normal;
  }
}

const Object _copySentinel = Object();

class GameDailyTask {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final int progress;
  final int target;
  final double reward;
  final bool claimed;

  const GameDailyTask({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.progress,
    required this.target,
    required this.reward,
    required this.claimed,
  });

  bool get completed => progress >= target;
  bool get claimable => completed && !claimed;
  double get progressRatio {
    if (target <= 0) return 1;
    return (progress / target).clamp(0, 1).toDouble();
  }
}

class ShiftSummary {
  final int ordersServed;
  final int missedOrders;
  final int bestCombo;
  final double coinsEarned;

  const ShiftSummary({
    required this.ordersServed,
    required this.missedOrders,
    required this.bestCombo,
    required this.coinsEarned,
  });

  bool get hasActivity =>
      ordersServed > 0 || missedOrders > 0 || coinsEarned > 0;
}

class GameController extends ChangeNotifier {
  static const _coinsKey = 'idle_coins';
  static const _lifetimeEarningsKey = 'idle_lifetime_earnings';
  static const _lastSavedAtKey = 'idle_last_saved_at';
  static const _lastOrderRewardAtKey = 'idle_last_order_reward_at';
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

  static const startingCoins = 120.0;
  static const maxOfflineMinutes = 480;
  static const shiftTargetOrders = 4;
  static const restaurantXpPerLevel = 100;
  static const manualOrderRewardCoins = 5.0;
  static const manualOrderRewardCooldown = Duration(seconds: 30);
  static const customerOrderBaseReward = 18.0;
  static const customerArrivalBaseSeconds = 12;
  static const customerArrivalMinSeconds = 4;
  static const customerPatienceBaseSeconds = 18;
  static const customerPatienceMaxSeconds = 30;
  static const businessMealBaseSeconds = 14;
  static const businessMealMinSeconds = 8;
  static const customerSeatingDuration = Duration(seconds: 2);
  static const foodServingDuration = Duration(seconds: 2);
  static const customerLeavingDuration = Duration(seconds: 2);
  static const menuMasteryXpPerLevel = 4;
  static const maxBusinessTickSeconds = 120;
  static const _knownFoodIds = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  static const _defaultUnlockedFoodIds = {1, 2, 3, 4, 5};

  final GameStorage storage;

  double _coins = startingCoins;
  double _lifetimeEarnings = 0;
  double _pendingOfflineEarnings = 0;
  DateTime _lastSavedAt = DateTime.now();
  DateTime? _lastOrderRewardAt;
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
  Set<int> _unlockedFoodIds = {..._defaultUnlockedFoodIds};
  Set<String> _claimedMilestoneIds = {};
  Set<String> _claimedDailyTaskIds = {};
  List<GameDiningCustomer> _diningCustomers = [];

  GameController({GameStorage? storage})
      : storage = storage ?? SharedPreferencesGameStorage();

  double get coins => _coins;
  double get lifetimeEarnings => _lifetimeEarnings;
  double get pendingOfflineEarnings => _pendingOfflineEarnings;
  double get pendingBusinessEarnings => _pendingBusinessEarnings;
  double get pendingClaimableEarnings =>
      _pendingOfflineEarnings + _pendingBusinessEarnings;
  DateTime get lastSavedAt => _lastSavedAt;
  DateTime? get lastOrderRewardAt => _lastOrderRewardAt;
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
  int get diningCapacity => max(2, _seatLevel + 1);
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

  double get customerArrivalRatePerMinute {
    final eventMultiplier =
        activeEventType == GameEventType.lunchRush ? 1.3 : 1;
    return (10 + restaurantLevel * 1.2 + _seatLevel) * eventMultiplier;
  }

  double get kitchenOrdersPerMinute => 8 + _kitchenLevel * 1.4;

  Duration get businessMealDuration {
    final seconds =
        businessMealBaseSeconds - (_seatLevel - 1) - (_serviceLevel - 1);
    return Duration(seconds: max(businessMealMinSeconds, seconds));
  }

  double get mealOrdersPerMinute => 60 / businessMealDuration.inSeconds;

  double get serviceOrdersPerMinute => 8 + _serviceLevel * 1.4;

  Duration get _checkoutDuration {
    final seconds = 8 - _serviceLevel;
    return Duration(seconds: max(2, seconds));
  }

  double get autoOrdersPerMinute {
    return min(
      customerArrivalRatePerMinute,
      min(
        kitchenOrdersPerMinute,
        min(mealOrdersPerMinute, serviceOrdersPerMinute),
      ),
    );
  }

  double get averageAutoOrderReward {
    final ids = _computedUnlockedFoodIds().toList()..sort();
    if (ids.isEmpty) return customerOrderBaseReward;
    final total = ids.fold<double>(
      0,
      (sum, foodId) => sum + customerOrderRewardForFood(foodId),
    );
    return (total / ids.length) * activeEventRewardMultiplier;
  }

  double get autoRevenuePerMinute =>
      autoOrdersPerMinute * averageAutoOrderReward;
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
        progress: _seatLevel,
        target: 2,
        reward: 80,
      ),
      _milestone(
        id: 'quick_service',
        titleKey: 'idle_goal_quick_service_title',
        descriptionKey: 'idle_goal_quick_service_desc',
        progress: _serviceLevel,
        target: 2,
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
        progress: restaurantLevel,
        target: 2,
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
    for (final milestone in milestones) {
      if (!milestone.claimed) return milestone;
    }
    return null;
  }

  int get restaurantLevel {
    final totalMenuLevels =
        _menuUpgradeLevels.values.fold<int>(0, (sum, level) => sum + level);
    final upgradeLevel = 1 +
        ((_seatLevel - 1) +
                (_serviceLevel - 1) +
                (_kitchenLevel - 1) +
                totalMenuLevels) ~/
            5;
    return max(upgradeLevel, restaurantXpLevel);
  }

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
    return (60 + level * 40) * activeEventUpgradeCostMultiplier;
  }

  double get seatUpgradeCost =>
      (100 + (_seatLevel - 1) * 75) * activeEventUpgradeCostMultiplier;

  double get serviceUpgradeCost =>
      (90 + (_serviceLevel - 1) * 70) * activeEventUpgradeCostMultiplier;

  double get kitchenUpgradeCost =>
      (110 + (_kitchenLevel - 1) * 80) * activeEventUpgradeCostMultiplier;

  String formatCoins(double value) => value.round().toString();

  double customerOrderRewardForFood(int foodId) {
    return customerOrderBaseReward +
        restaurantLevel * 4 +
        _seatLevel * 2 +
        _serviceLevel * 2 +
        _kitchenLevel * 3 +
        menuLevel(foodId) * 5 +
        masteryLevelForFood(foodId) * 2;
  }

  int foodUnlockLevel(int foodId) {
    if (foodId <= 5) return 1;
    if (foodId <= 9) return foodId - 4;
    return 99;
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

  Duration orderRewardCooldownRemaining(DateTime now) {
    final lastRewardAt = _lastOrderRewardAt;
    if (lastRewardAt == null) return Duration.zero;
    final elapsed = now.difference(lastRewardAt);
    if (elapsed >= manualOrderRewardCooldown) return Duration.zero;
    if (elapsed.isNegative) return manualOrderRewardCooldown;
    return manualOrderRewardCooldown - elapsed;
  }

  Future<void> load({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
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
      ..._defaultUnlockedFoodIds,
      ..._decodeIntSet(await storage.getString(_unlockedFoodIdsKey)),
    };
    _lastSavedAt = _parseSavedAt(
      await storage.getString(_lastSavedAtKey),
      currentTime,
    );
    _lastOrderRewardAt = _parseOptionalDateTime(
      await storage.getString(_lastOrderRewardAtKey),
    );
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
    _pendingOfflineEarnings = calculateOfflineEarnings(currentTime);
    _isLoaded = true;
    notifyListeners();
  }

  double calculateOfflineEarnings(DateTime now) {
    final offlineMinutes = now.difference(_lastSavedAt).inMinutes;
    if (offlineMinutes <= 0) return 0;
    final cappedMinutes = min(offlineMinutes, maxOfflineMinutes);
    return cappedMinutes * revenuePerMinute;
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
    final seconds = min(maxBusinessTickSeconds, elapsed.inSeconds);
    if (seconds <= 0) return 0;

    final previousState = _diningStateSignature;
    var completedOrders = 0;
    for (var index = 0; index < seconds; index += 1) {
      final tickTime = currentTime.subtract(
        Duration(seconds: seconds - index - 1),
      );
      completedOrders += _simulateBusinessSecond(foodIds, tickTime);
    }

    if (_diningStateSignature != previousState || completedOrders > 0) {
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

  Future<double> rewardOrder(String totalPrice, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    if (orderRewardCooldownRemaining(currentTime) > Duration.zero) {
      await save(now: currentTime);
      notifyListeners();
      return 0;
    }

    _coins += manualOrderRewardCoins;
    _lifetimeEarnings += manualOrderRewardCoins;
    _lastOrderRewardAt = currentTime;
    await save(now: currentTime);
    notifyListeners();
    return manualOrderRewardCoins;
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

  Future<void> save({DateTime? now}) async {
    if (now != null) {
      _lastSavedAt = now;
    }
    _syncManualOrderFieldsFromDiningCustomers();
    _syncBusinessCountCache();
    await storage.setDouble(_coinsKey, _coins);
    await storage.setDouble(_lifetimeEarningsKey, _lifetimeEarnings);
    await storage.setInt(_seatLevelKey, _seatLevel);
    await storage.setInt(_serviceLevelKey, _serviceLevel);
    await storage.setInt(_kitchenLevelKey, _kitchenLevel);
    await storage.setInt(_restaurantXpKey, _restaurantXp);
    await storage.setInt(_customerOrdersServedKey, _customerOrdersServed);
    await storage.setInt(_bestComboKey, _bestCombo);
    await storage.setInt(_shiftOrdersServedKey, _shiftOrdersServed);
    await storage.setInt(_shiftMissedOrdersKey, _shiftMissedOrders);
    await storage.setInt(_shiftBestComboKey, _shiftBestCombo);
    await storage.setDouble(_shiftCoinsEarnedKey, _shiftCoinsEarned);
    await storage.setString(_dailyTaskDateKey, _dailyTaskDate);
    await storage.setInt(_dailyOrdersServedKey, _dailyOrdersServed);
    await storage.setInt(_dailyBestComboKey, _dailyBestCombo);
    await storage.setInt(_dailyUpgradesKey, _dailyUpgrades);
    await storage.setDouble(
      _pendingBusinessEarningsKey,
      _pendingBusinessEarnings,
    );
    await storage.setString(
      _diningCustomersKey,
      jsonEncode(
          _diningCustomers.map((customer) => customer.toJson()).toList()),
    );
    await storage.setInt(_nextDiningCustomerIdKey, _nextDiningCustomerId);
    await storage.setInt(_businessQueueCountKey, businessQueueCount);
    await storage.setInt(_businessSeatedCountKey, businessSeatedCount);
    await storage.setInt(
      _businessKitchenQueueCountKey,
      businessKitchenQueueCount,
    );
    await storage.setInt(_businessEatingCountKey, businessEatingCount);
    await storage.setInt(
      _businessCheckoutQueueCountKey,
      businessCheckoutQueueCount,
    );
    await storage.setString(
      _claimedMilestoneIdsKey,
      jsonEncode(_claimedMilestoneIds.toList()..sort()),
    );
    await storage.setString(
      _claimedDailyTaskIdsKey,
      jsonEncode(_claimedDailyTaskIds.toList()..sort()),
    );
    await storage.setString(
      _unlockedFoodIdsKey,
      jsonEncode(_computedUnlockedFoodIds().toList()..sort()),
    );
    await storage.setString(
      _menuUpgradeLevelsKey,
      jsonEncode(
        _menuUpgradeLevels.map(
          (foodId, level) => MapEntry(foodId.toString(), level),
        ),
      ),
    );
    await storage.setString(
      _menuMasteryXpKey,
      jsonEncode(
        _menuMasteryXp.map(
          (foodId, xp) => MapEntry(foodId.toString(), xp),
        ),
      ),
    );
    await storage.setString(
      _menuServeCountsKey,
      jsonEncode(
        _menuServeCounts.map(
          (foodId, count) => MapEntry(foodId.toString(), count),
        ),
      ),
    );
    await storage.setString(_lastSavedAtKey, _lastSavedAt.toIso8601String());
    if (_lastOrderRewardAt != null) {
      await storage.setString(
        _lastOrderRewardAtKey,
        _lastOrderRewardAt!.toIso8601String(),
      );
    }
    if (_customerOrderFoodId != null &&
        _customerOrderReward > 0 &&
        _customerOrderCreatedAt != null) {
      await storage.setInt(_customerOrderFoodIdKey, _customerOrderFoodId!);
      await storage.setDouble(_customerOrderRewardKey, _customerOrderReward);
      await storage.setString(_activeCustomerTypeKey, _activeCustomerType.name);
      await storage.setString(
        _customerOrderCreatedAtKey,
        _customerOrderCreatedAt!.toIso8601String(),
      );
    } else {
      await storage.remove(_customerOrderFoodIdKey);
      await storage.remove(_customerOrderRewardKey);
      await storage.remove(_customerOrderCreatedAtKey);
      await storage.remove(_activeCustomerTypeKey);
    }
    if (_nextCustomerAvailableAt != null) {
      await storage.setString(
        _nextCustomerAvailableAtKey,
        _nextCustomerAvailableAt!.toIso8601String(),
      );
    } else {
      await storage.remove(_nextCustomerAvailableAtKey);
    }
  }

  Future<void> reset({DateTime? now}) async {
    await storage.clearGameData();
    _coins = startingCoins;
    _lifetimeEarnings = 0;
    _pendingOfflineEarnings = 0;
    _lastSavedAt = now ?? DateTime.now();
    _lastOrderRewardAt = null;
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
    _unlockedFoodIds = {..._defaultUnlockedFoodIds};
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
    final unlocked = <int>{
      ..._defaultUnlockedFoodIds,
      ..._unlockedFoodIds,
    };
    for (final foodId in _knownFoodIds) {
      if (restaurantLevel >= foodUnlockLevel(foodId)) {
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
