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
      expect(
        GameBalance.mealOrdersPerMinute(defaultMeal),
        closeTo(60 / 14, 0.001),
      );
      expect(GameBalance.mealOrdersPerMinute(cappedMeal), 7.5);
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
        closeTo(60 / 14, 0.001),
      );
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
