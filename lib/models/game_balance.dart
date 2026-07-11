import 'dart:math';

class GameBalance {
  const GameBalance._();

  static const businessMealBaseSeconds = 14;
  static const businessMealMinSeconds = 8;

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
    return 8 + kitchenLevel * 1.4;
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

  static double mealOrdersPerMinute(Duration mealDuration) {
    return 60 / mealDuration.inSeconds;
  }

  static double checkoutOrdersPerMinute(int serviceLevel) {
    return 8 + serviceLevel * 1.4;
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
    final mealDuration = businessMealDuration(
      seatLevel: seatLevel,
      serviceLevel: serviceLevel,
      baseSeconds: mealBaseSeconds,
      minSeconds: mealMinSeconds,
    );
    return minimumThroughputPerMinute(
      arrivalRatePerMinute: customerArrivalRatePerMinute(
        seatLevel: seatLevel,
        restaurantLevel: restaurantLevel,
        eventMultiplier: arrivalEventMultiplier,
      ),
      kitchenRatePerMinute: kitchenOrdersPerMinute(kitchenLevel),
      mealRatePerMinute: mealOrdersPerMinute(mealDuration),
      checkoutRatePerMinute: checkoutOrdersPerMinute(serviceLevel),
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
}
