import 'dart:math';

class GameBalance {
  const GameBalance._();

  static const businessMealBaseSeconds = 14;
  static const businessMealMinSeconds = 8;
  static const customerSeatingSeconds = 2;
  static const foodServingSeconds = 2;
  static const customerLeavingSeconds = 2;
  static const maxOfflineMinutes = 480;
  static const operationUpgradeGrowth = 1.8;
  static const menuUpgradeGrowth = 1.7;

  static int diningCapacity(int seatLevel) => max(2, seatLevel + 1);

  static int restaurantLevel({
    required int seatLevel,
    required int serviceLevel,
    required int kitchenLevel,
    required int totalMenuLevels,
    required int restaurantXpLevel,
  }) {
    final upgradeLevel = 1 +
        ((seatLevel - 1) +
                (serviceLevel - 1) +
                (kitchenLevel - 1) +
                totalMenuLevels) ~/
            5;
    return max(upgradeLevel, restaurantXpLevel);
  }

  static double customerArrivalRatePerMinute({
    required int seatLevel,
    required int restaurantLevel,
    double eventMultiplier = 1,
  }) {
    return (10 + restaurantLevel * 1.2 + seatLevel) * eventMultiplier;
  }

  static double kitchenOrdersPerMinute(int kitchenLevel) {
    return min(60, 8 + kitchenLevel * 1.4);
  }

  static Duration businessMealDuration({
    required int seatLevel,
    required int serviceLevel,
    int baseSeconds = businessMealBaseSeconds,
    int minSeconds = businessMealMinSeconds,
  }) {
    final seconds = baseSeconds - (seatLevel - 1) - (serviceLevel - 1);
    return Duration(seconds: max(minSeconds, seconds));
  }

  static double seatTurnoverOrdersPerMinute({
    required int diningCapacity,
    required Duration mealDuration,
    required double kitchenRatePerMinute,
    required double checkoutRatePerMinute,
  }) {
    if (diningCapacity <= 0) return 0;

    final kitchenSeconds = 60 / max(0.001, kitchenRatePerMinute);
    final checkoutSeconds = 60 / max(0.001, checkoutRatePerMinute);
    final occupiedSeconds = customerSeatingSeconds +
        kitchenSeconds +
        foodServingSeconds +
        mealDuration.inSeconds +
        checkoutSeconds +
        customerLeavingSeconds;
    return diningCapacity * 60 / occupiedSeconds;
  }

  static double checkoutOrdersPerMinute(int serviceLevel) {
    return min(60, 8 + serviceLevel * 1.4);
  }

  static double operationUpgradeCost({
    required double baseCost,
    required int currentLevel,
    double eventMultiplier = 1,
  }) {
    return _roundUpToFive(
      baseCost *
          pow(operationUpgradeGrowth, max(0, currentLevel - 1)) *
          eventMultiplier,
    );
  }

  static double menuUpgradeCost(
    int currentLevel, {
    double eventMultiplier = 1,
  }) {
    return _roundUpToFive(
      60 * pow(menuUpgradeGrowth, max(0, currentLevel)) * eventMultiplier,
    );
  }

  static int offlineMinuteCap(int restaurantLevel) {
    if (restaurantLevel >= 10) return maxOfflineMinutes;
    if (restaurantLevel >= 8) return 360;
    if (restaurantLevel >= 5) return 240;
    if (restaurantLevel >= 3) return 120;
    return 60;
  }

  static double offlineEfficiency(int restaurantLevel) {
    if (restaurantLevel >= 10) return 0.15;
    if (restaurantLevel >= 8) return 0.14;
    if (restaurantLevel >= 5) return 0.12;
    if (restaurantLevel >= 3) return 0.10;
    return 0.08;
  }

  static double offlineEarnings({
    required double baselineRevenuePerMinute,
    required double elapsedMinutes,
    required int restaurantLevel,
  }) {
    if (elapsedMinutes <= 0 || baselineRevenuePerMinute <= 0) return 0;
    final creditedMinutes = min(
      elapsedMinutes,
      offlineMinuteCap(restaurantLevel).toDouble(),
    );
    return creditedMinutes *
        baselineRevenuePerMinute *
        offlineEfficiency(restaurantLevel);
  }

  static double minimumThroughputPerMinute({
    required double arrivalRatePerMinute,
    required double kitchenRatePerMinute,
    required double mealRatePerMinute,
    required double checkoutRatePerMinute,
  }) {
    return min(
      arrivalRatePerMinute,
      min(
        kitchenRatePerMinute,
        min(mealRatePerMinute, checkoutRatePerMinute),
      ),
    );
  }

  static double autoOrdersPerMinute({
    required int seatLevel,
    required int serviceLevel,
    required int kitchenLevel,
    required int restaurantLevel,
    double arrivalEventMultiplier = 1,
    int mealBaseSeconds = businessMealBaseSeconds,
    int mealMinSeconds = businessMealMinSeconds,
  }) {
    final kitchenRate = kitchenOrdersPerMinute(kitchenLevel);
    final checkoutRate = checkoutOrdersPerMinute(serviceLevel);
    final mealDuration = businessMealDuration(
      seatLevel: seatLevel,
      serviceLevel: serviceLevel,
      baseSeconds: mealBaseSeconds,
      minSeconds: mealMinSeconds,
    );
    final seatTurnoverRate = seatTurnoverOrdersPerMinute(
      diningCapacity: diningCapacity(seatLevel),
      mealDuration: mealDuration,
      kitchenRatePerMinute: kitchenRate,
      checkoutRatePerMinute: checkoutRate,
    );
    return minimumThroughputPerMinute(
      arrivalRatePerMinute: customerArrivalRatePerMinute(
        seatLevel: seatLevel,
        restaurantLevel: restaurantLevel,
        eventMultiplier: arrivalEventMultiplier,
      ),
      kitchenRatePerMinute: kitchenRate,
      mealRatePerMinute: seatTurnoverRate,
      checkoutRatePerMinute: checkoutRate,
    );
  }

  static String formatCompactNumber(double value) {
    final absoluteValue = value.abs();
    if (absoluteValue < 1000) return value.round().toString();

    const units = [
      (threshold: 1000000000000.0, suffix: 'T'),
      (threshold: 1000000000.0, suffix: 'B'),
      (threshold: 1000000.0, suffix: 'M'),
      (threshold: 1000.0, suffix: 'K'),
    ];
    for (var index = 0; index < units.length; index += 1) {
      var unit = units[index];
      if (absoluteValue < unit.threshold) continue;
      var scaled = value / unit.threshold;
      var fractionDigits = scaled.abs() >= 100 ? 0 : 1;
      var rounded = double.parse(scaled.toStringAsFixed(fractionDigits));
      if (rounded.abs() >= 1000 && index > 0) {
        unit = units[index - 1];
        scaled = value / unit.threshold;
        fractionDigits = scaled.abs() >= 100 ? 0 : 1;
        rounded = double.parse(scaled.toStringAsFixed(fractionDigits));
      }
      var number = rounded.toStringAsFixed(fractionDigits);
      if (number.endsWith('.0')) {
        number = number.substring(0, number.length - 2);
      }
      return '$number${unit.suffix}';
    }
    return value.round().toString();
  }

  static double _roundUpToFive(num value) {
    return (value / 5).ceilToDouble() * 5;
  }
}
