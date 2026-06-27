import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/models/restaurant.dart';

void main() {
  group('Restaurant', () {
    test('adds and removes cart items while keeping totals in sync', () {
      final restaurant = Restaurant();
      final burger = restaurant.getMenu().first;

      restaurant.addToCart(burger);
      restaurant.addToCart(burger);

      expect(restaurant.getFoodQuantity(burger), 2);
      expect(restaurant.getTotalPrice(), '176.00');

      restaurant.removeFromCart(burger);

      expect(restaurant.getFoodQuantity(burger), 1);
      expect(restaurant.getTotalPrice(), '88.00');

      restaurant.removeFromCart(burger);

      expect(restaurant.getFoodQuantity(burger), 0);
      expect(restaurant.getTotalPrice(), '0.00');
    });

    test('places an order and clears the cart', () {
      final restaurant = Restaurant();
      final burger = restaurant.getMenu().first;

      restaurant.addToCart(burger);
      restaurant.placeOrder();

      expect(restaurant.getUniqueCartItems(), isEmpty);
      expect(restaurant.getOrderHistory(), hasLength(1));
      expect(restaurant.getOrderHistory().first['totalPrice'], '88.00');
      expect(restaurant.getOrderHistory().first['itemCount'], 1);
    });

    test('updates translated text when language changes', () {
      final restaurant = Restaurant();

      expect(restaurant.translate('start_session'), 'START SESSION');

      restaurant.setLanguage('ja');

      expect(restaurant.translate('start_session'), '注文を開始');
    });
  });
}
