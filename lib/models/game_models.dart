import 'dart:math';

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

enum GameBusinessBottleneck { seats, kitchen, dining, checkout, balanced }

enum GameOperationUpgradeType { seats, kitchen, service }

class GameBusinessDiagnosis {
  final GameBusinessBottleneck bottleneck;
  final double arrivalRatePerMinute;
  final double kitchenRatePerMinute;
  final double diningRatePerMinute;
  final double checkoutRatePerMinute;
  final double estimatedOrdersPerMinute;
  final double limitingRatePerMinute;
  final int queueCount;
  final int occupiedSeats;
  final int seatCapacity;
  final int kitchenQueueCount;
  final int eatingCount;
  final int checkoutQueueCount;

  const GameBusinessDiagnosis({
    required this.bottleneck,
    required this.arrivalRatePerMinute,
    required this.kitchenRatePerMinute,
    required this.diningRatePerMinute,
    required this.checkoutRatePerMinute,
    required this.estimatedOrdersPerMinute,
    required this.limitingRatePerMinute,
    required this.queueCount,
    required this.occupiedSeats,
    required this.seatCapacity,
    required this.kitchenQueueCount,
    required this.eatingCount,
    required this.checkoutQueueCount,
  });

  double get seatUtilization {
    if (seatCapacity <= 0) return 0;
    return (occupiedSeats / seatCapacity).clamp(0, 1).toDouble();
  }

  double get kitchenPressure {
    if (seatCapacity <= 0) return 0;
    return (kitchenQueueCount / seatCapacity).clamp(0, 1).toDouble();
  }

  double get diningPressure {
    if (seatCapacity <= 0) return 0;
    return (eatingCount / seatCapacity).clamp(0, 1).toDouble();
  }

  double get checkoutPressure {
    if (seatCapacity <= 0) return 0;
    return (checkoutQueueCount / seatCapacity).clamp(0, 1).toDouble();
  }
}

class GameOperationUpgradePreview {
  final GameOperationUpgradeType type;
  final int currentLevel;
  final int upgradedLevel;
  final double currentOrdersPerMinute;
  final double upgradedOrdersPerMinute;
  final double currentCoinsPerMinute;
  final double upgradedCoinsPerMinute;
  final double coinsPerMinuteGain;
  final double cost;
  final bool canAfford;
  final bool isRecommended;

  const GameOperationUpgradePreview({
    required this.type,
    required this.currentLevel,
    required this.upgradedLevel,
    required this.currentOrdersPerMinute,
    required this.upgradedOrdersPerMinute,
    required this.currentCoinsPerMinute,
    required this.upgradedCoinsPerMinute,
    required this.coinsPerMinuteGain,
    required this.cost,
    required this.canAfford,
    required this.isRecommended,
  });

  double get gainPerCoinSpent {
    if (cost <= 0) return 0;
    return coinsPerMinuteGain / cost;
  }

  double? get paybackMinutes {
    if (coinsPerMinuteGain <= 0) return null;
    return cost / coinsPerMinuteGain;
  }

  GameOperationUpgradePreview copyWith({bool? isRecommended}) {
    return GameOperationUpgradePreview(
      type: type,
      currentLevel: currentLevel,
      upgradedLevel: upgradedLevel,
      currentOrdersPerMinute: currentOrdersPerMinute,
      upgradedOrdersPerMinute: upgradedOrdersPerMinute,
      currentCoinsPerMinute: currentCoinsPerMinute,
      upgradedCoinsPerMinute: upgradedCoinsPerMinute,
      coinsPerMinuteGain: coinsPerMinuteGain,
      cost: cost,
      canAfford: canAfford,
      isRecommended: isRecommended ?? this.isRecommended,
    );
  }
}
