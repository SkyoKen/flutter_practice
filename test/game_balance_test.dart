import 'package:cyber_table_order/models/game_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameBalance', () {
    test('calculates restaurant level from upgrades and XP', () {
      expect(
        GameBalance.restaurantLevel(
          seatLevel: 1,
          serviceLevel: 1,
          kitchenLevel: 1,
          totalMenuLevels: 0,
          restaurantXpLevel: 1,
        ),
        1,
      );
      expect(
        GameBalance.restaurantLevel(
          seatLevel: 2,
          serviceLevel: 2,
          kitchenLevel: 2,
          totalMenuLevels: 2,
          restaurantXpLevel: 1,
        ),
        2,
      );
      expect(
        GameBalance.restaurantLevel(
          seatLevel: 2,
          serviceLevel: 2,
          kitchenLevel: 2,
          totalMenuLevels: 2,
          restaurantXpLevel: 4,
        ),
        4,
      );
    });

    test('calculates arrival kitchen meal and checkout rates', () {
      expect(
        GameBalance.customerArrivalRatePerMinute(
          seatLevel: 1,
          restaurantLevel: 1,
        ),
        closeTo(12.2, 0.001),
      );
      expect(
        GameBalance.customerArrivalRatePerMinute(
          seatLevel: 1,
          restaurantLevel: 1,
          eventMultiplier: 1.3,
        ),
        closeTo(15.86, 0.001),
      );
      expect(GameBalance.kitchenOrdersPerMinute(1), closeTo(9.4, 0.001));
      expect(GameBalance.checkoutOrdersPerMinute(1), closeTo(9.4, 0.001));

      final defaultMeal = GameBalance.businessMealDuration(
        seatLevel: 1,
        serviceLevel: 1,
      );
      final cappedMeal = GameBalance.businessMealDuration(
        seatLevel: 5,
        serviceLevel: 5,
      );
      expect(defaultMeal, const Duration(seconds: 14));
      expect(cappedMeal, const Duration(seconds: 8));
      expect(GameBalance.diningCapacity(1), 2);
      expect(GameBalance.diningCapacity(4), 5);
      expect(
        GameBalance.seatTurnoverOrdersPerMinute(
          diningCapacity: 2,
          mealDuration: defaultMeal,
          kitchenRatePerMinute: 9.4,
          checkoutRatePerMinute: 9.4,
        ),
        closeTo(
          120 / (2 + 60 / 9.4 + 2 + 14 + 60 / 9.4 + 2),
          0.001,
        ),
      );
      expect(
        GameBalance.seatTurnoverOrdersPerMinute(
          diningCapacity: 5,
          mealDuration: cappedMeal,
          kitchenRatePerMinute: 15,
          checkoutRatePerMinute: 15,
        ),
        closeTo(300 / 22, 0.001),
      );
    });

    test('uses the minimum of the four stages as throughput', () {
      expect(
        GameBalance.minimumThroughputPerMinute(
          arrivalRatePerMinute: 12,
          kitchenRatePerMinute: 9,
          mealRatePerMinute: 5,
          checkoutRatePerMinute: 8,
        ),
        5,
      );
      expect(
        GameBalance.autoOrdersPerMinute(
          seatLevel: 1,
          serviceLevel: 1,
          kitchenLevel: 1,
          restaurantLevel: 1,
        ),
        closeTo(
          120 / (2 + 60 / 9.4 + 2 + 14 + 60 / 9.4 + 2),
          0.001,
        ),
      );
    });

    test('uses exponential upgrade costs with stable five-coin rounding', () {
      expect(
        GameBalance.operationUpgradeCost(baseCost: 100, currentLevel: 1),
        100,
      );
      expect(
        GameBalance.operationUpgradeCost(baseCost: 90, currentLevel: 2),
        165,
      );
      expect(
        GameBalance.operationUpgradeCost(baseCost: 100, currentLevel: 10),
        19840,
      );
      expect(GameBalance.menuUpgradeCost(0), 60);
      expect(GameBalance.menuUpgradeCost(1), 105);
      expect(GameBalance.menuUpgradeCost(10), 12100);
      expect(
        GameBalance.operationUpgradeCost(
          baseCost: 90,
          currentLevel: 2,
          eventMultiplier: 0.9,
        ),
        150,
      );
      expect(GameBalance.menuUpgradeCost(1, eventMultiplier: 0.9), 95);
    });

    test('stages offline efficiency and duration by restaurant level', () {
      expect(GameBalance.offlineMinuteCap(1), 60);
      expect(GameBalance.offlineMinuteCap(3), 120);
      expect(GameBalance.offlineMinuteCap(5), 240);
      expect(GameBalance.offlineMinuteCap(8), 360);
      expect(GameBalance.offlineMinuteCap(10), 480);
      expect(GameBalance.offlineEfficiency(1), 0.08);
      expect(GameBalance.offlineEfficiency(5), 0.12);
      expect(GameBalance.offlineEfficiency(10), 0.15);
      expect(
        GameBalance.offlineEarnings(
          baselineRevenuePerMinute: 100,
          elapsedMinutes: 480,
          restaurantLevel: 1,
        ),
        480,
      );
      expect(
        GameBalance.offlineEarnings(
          baselineRevenuePerMinute: 100,
          elapsedMinutes: 480,
          restaurantLevel: 3,
        ),
        1200,
      );
      expect(
        GameBalance.offlineEarnings(
          baselineRevenuePerMinute: 100,
          elapsedMinutes: 480,
          restaurantLevel: 10,
        ),
        7200,
      );
    });

    test('caps kitchen and checkout processing at one order per second', () {
      expect(GameBalance.kitchenOrdersPerMinute(100), 60);
      expect(GameBalance.checkoutOrdersPerMinute(100), 60);
    });

    test('formats compact numbers without redundant decimals', () {
      expect(GameBalance.formatCompactNumber(999), '999');
      expect(GameBalance.formatCompactNumber(1000), '1K');
      expect(GameBalance.formatCompactNumber(12345), '12.3K');
      expect(GameBalance.formatCompactNumber(999999), '1M');
      expect(GameBalance.formatCompactNumber(1200000), '1.2M');
      expect(GameBalance.formatCompactNumber(-1200000), '-1.2M');
    });
  });
}
