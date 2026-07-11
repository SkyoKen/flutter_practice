import 'package:cyber_table_order/models/food.dart';

class FoodCatalog {
  const FoodCatalog._();

  static const List<Food> items = [
    Food(
      id: 1,
      nameKey: 'dish_1_name',
      descriptionKey: 'dish_1_description',
      unlockLevel: 1,
      baseRewardCoins: 18,
      tags: {'popular', 'meat', 'beef'},
    ),
    Food(
      id: 2,
      nameKey: 'dish_2_name',
      descriptionKey: 'dish_2_description',
      unlockLevel: 1,
      baseRewardCoins: 22,
      tags: {'popular', 'fish', 'tuna'},
    ),
    Food(
      id: 3,
      nameKey: 'dish_3_name',
      descriptionKey: 'dish_3_description',
      unlockLevel: 1,
      baseRewardCoins: 16,
      tags: {'noodles'},
    ),
    Food(
      id: 4,
      nameKey: 'dish_4_name',
      descriptionKey: 'dish_4_description',
      unlockLevel: 1,
      baseRewardCoins: 14,
      tags: {'popular', 'side'},
    ),
    Food(
      id: 5,
      nameKey: 'dish_5_name',
      descriptionKey: 'dish_5_description',
      unlockLevel: 1,
      baseRewardCoins: 28,
      tags: {'bento', 'fish', 'meat'},
    ),
    Food(
      id: 6,
      nameKey: 'dish_6_name',
      descriptionKey: 'dish_6_description',
      unlockLevel: 2,
      baseRewardCoins: 21,
      tags: {'fish', 'salmon'},
    ),
    Food(
      id: 7,
      nameKey: 'dish_7_name',
      descriptionKey: 'dish_7_description',
      unlockLevel: 3,
      baseRewardCoins: 8,
      tags: {'drink'},
    ),
    Food(
      id: 8,
      nameKey: 'dish_8_name',
      descriptionKey: 'dish_8_description',
      unlockLevel: 4,
      baseRewardCoins: 19,
      tags: {'fish', 'mackerel'},
    ),
    Food(
      id: 9,
      nameKey: 'dish_9_name',
      descriptionKey: 'dish_9_description',
      unlockLevel: 5,
      baseRewardCoins: 36,
      tags: {'meat', 'beef'},
    ),
  ];

  static const Set<int> defaultUnlockedIds = {1, 2, 3, 4, 5};

  static List<int> get ids =>
      List<int>.unmodifiable(items.map((food) => food.id));

  static Food? findById(int foodId) {
    for (final food in items) {
      if (food.id == foodId) return food;
    }
    return null;
  }
}
