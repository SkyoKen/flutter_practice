import 'package:flutter/material.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/utils/translations.dart'; // 导入 Translations
import 'dart:math';

class Restaurant extends ChangeNotifier {
  // --- I18N STATE ---
  String _languageCode = 'en'; // Default language

  String get languageCode => _languageCode;

  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }

  String translate(String key) {
    return Translations.get(key, _languageCode);
  }
  // ------------------

  // --- AUTHENTICATION STATE ---
  bool _isLoggedIn = false;
  String _userName = "GUEST"; // Default state
  String _memberId = "GC-0000"; // Simulated Member ID
  final List<String> _coupons = [
    "FREE RAMEN",
    "20% OFF",
    "10 OFF 100"
  ]; // Simulated Coupons

  bool get getIsLoggedIn => _isLoggedIn;
  String get getUserName => _userName;
  String get getMemberId => _memberId;
  List<String> get getCoupons => List.unmodifiable(_coupons);

  void login(String memberId, String userName) {
    _isLoggedIn = true;
    _userName = userName;
    _memberId = memberId;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _userName = "GUEST";
    _memberId = "GC-0000";
    notifyListeners();
  }
  // ----------------------------

  // 1. 菜单列表 (Menu)
  final List<Food> _menu = [
    Food(
      id: 1, // Unique ID
      name: "招牌和牛汉堡",
      price: "88.00",
      imagePath: "lib/images/burger.png",
      rating: 4.9,
      description: "澳洲进口和牛，搭配秘制酱汁。",
      tags: ["popular", "meat", "beef"], // tags for filtering
    ),
    Food(
      id: 2,
      name: "极品金枪鱼寿司",
      price: "128.50",
      imagePath: "lib/images/sushi.png",
      rating: 4.8,
      description: "深海蓝鳍金枪鱼，入口即化。",
      tags: ["popular", "fish", "tuna"],
    ),
    Food(
      id: 3,
      name: "豚骨拉面",
      price: "58.00",
      imagePath: "lib/images/ramen.png",
      rating: 4.7,
      description: "浓郁骨汤，熬制24小时。",
      tags: ["noodles"],
    ),
    Food(
      id: 4,
      name: "凯撒沙拉",
      price: "45.00",
      imagePath: "lib/images/salad.png",
      rating: 4.5,
      description: "新鲜有机蔬菜，健康首选。",
      tags: ["popular", "side"],
    ),
    Food(
      id: 5,
      name: "豪华海鲜便当",
      price: "168.00",
      imagePath: "lib/images/bento.png",
      rating: 4.9,
      description: "包含金枪鱼、三文鱼、烤肉。",
      tags: ["bento", "fish", "meat"],
    ),
    Food(
      id: 6,
      name: "烤三文鱼定食",
      price: "99.00",
      imagePath: "lib/images/salmon.png",
      rating: 4.6,
      description: "香烤三文鱼，搭配米饭和味增汤。",
      tags: ["fish", "salmon"],
    ),
    Food(
      id: 7,
      name: "可口可乐",
      price: "8.00",
      imagePath: "lib/images/soda.png",
      rating: 4.0,
      description: "冰镇可乐。",
      tags: ["beer"],
    ),
    Food(
      id: 8,
      name: "香烤鲭鱼定食",
      price: "90.00",
      imagePath: "lib/images/mackerel.png",
      rating: 4.5,
      description: "传统日式烤鱼。",
      tags: ["fish", "mackerel"],
    ),
    Food(
      id: 9,
      name: "战斧牛排",
      price: "320.00",
      imagePath: "lib/images/steak.png",
      rating: 5.0,
      description: "顶级和牛肉，碳烤慢熟。",
      tags: ["meat", "beef"],
    ),
  ];

  // 2. 顾客购物车 (User Cart) - 使用 Map 存储 Food 和 数量
  final Map<Food, int> _userCart = {};

  // 3. 订单历史记录
  final List<Map<String, dynamic>> _orderHistory = [];

  // --- GETTERS ---

  // 获取菜单
  List<Food> getMenu() {
    return List.unmodifiable(_menu);
  }

  // 获取购物车中的唯一 Food 列表 (用于 CartPage 显示)
  List<Food> getUniqueCartItems() {
    return _userCart.keys.toList();
  }

  // 获取某个菜品的数量
  int getFoodQuantity(Food food) {
    return _userCart[food] ?? 0;
  }

  // 获取订单历史记录
  List<Map<String, dynamic>> getOrderHistory() {
    return List.unmodifiable(_orderHistory);
  }

  // 根据 tag 筛选菜单
  List<Food> getMenuByTag(String tag) {
    if (tag.isEmpty) return getMenu();
    // 检查 food.tags 是否包含传入的 tag
    return _menu.where((food) => food.tags.contains(tag)).toList();
  }

  // --- OPERATIONS ---

  // 添加菜品到购物车 (数量 + 1)
  void addToCart(Food food) {
    _userCart.update(
      food,
      (currentQuantity) => currentQuantity + 1,
      ifAbsent: () => 1,
    );
    notifyListeners();
  }

  // 从购物车中移除菜品 (数量 - 1)
  void removeFromCart(Food food) {
    if (_userCart.containsKey(food)) {
      int currentQuantity = _userCart[food]!;
      if (currentQuantity > 1) {
        _userCart[food] = currentQuantity - 1;
      } else {
        // 数量为 1 时，移除该 Food 键值对
        _userCart.remove(food);
      }
      notifyListeners();
    }
  }

  // 计算总价
  String getTotalPrice() {
    double total = 0.0;
    _userCart.forEach((food, quantity) {
      // 使用括号确保先处理 null，再进行乘法
      total += (double.tryParse(food.price) ?? 0.0) * quantity;
    });
    return total.toStringAsFixed(2);
  }

  // 下单并将购物车内容移入历史记录
  void placeOrder() {
    if (_userCart.isEmpty) return;

    // 生成一个随机的订单 ID (简短的 UUID 模拟)
    final String orderId = DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(999).toString();

    final order = {
      'id': orderId,
      'timestamp': DateTime.now(),
      // 拷贝当前的购物车内容
      'items': Map<Food, int>.from(_userCart),
      'totalPrice': getTotalPrice(),
      'itemCount': _userCart.values.fold(0, (sum, count) => sum + count),
    };

    _orderHistory.insert(0, order); // 将新订单放在列表最前面
    _userCart.clear(); // 清空购物车
    notifyListeners();
  }
}
