import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/food_tile.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:intl/intl.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _selectedCategory = "popular";
  String _selectedSubCategoryTag = "";

  final List<Map<String, String>> _categories = [
    {"id": "popular", "key": "popular"},
    {"id": "fish", "key": "seafood"},
    {"id": "meat", "key": "meat"},
    {"id": "beer", "key": "drinks"},
    {"id": "side", "key": "sides"},
    {"id": "bento", "key": "bento"},
  ];

  final Map<String, List<Map<String, String>>> _subCategoryMap = {
    "fish": [
      {"id": "fish", "key": "all_fish"},
      {"id": "salmon", "key": "salmon"},
      {"id": "mackerel", "key": "mackerel"},
      {"id": "tuna", "key": "tuna"},
      {"id": "red_fish", "key": "red_fish"},
      {"id": "seasonal", "key": "seasonal"},
    ],
    "meat": [
      {"id": "meat", "key": "all_meat"},
      {"id": "beef", "key": "beef"},
      {"id": "pork", "key": "pork"},
      {"id": "chicken", "key": "chicken"},
    ],
    "popular": [
      {"id": "popular", "key": "all_popular"},
    ],
    "noodles": [
      {"id": "noodles", "key": "all_noodles"},
    ],
    "side": [
      {"id": "side", "key": "all_sides"},
    ],
    "bento": [
      {"id": "bento", "key": "all_bento"},
    ],
  };

  void _onMainCategoryTap(String categoryId) {
    setState(() {
      _selectedCategory = categoryId;
      _selectedSubCategoryTag = "";
    });
  }

  void _onSubCategoryTap(String subTag) {
    setState(() {
      if (subTag == _selectedCategory || subTag == _selectedSubCategoryTag) {
        _selectedSubCategoryTag = "";
      } else {
        _selectedSubCategoryTag = subTag;
      }
    });
  }

  // ----------------------------------------------------------------------
  // 历史记录弹窗
  // ----------------------------------------------------------------------
  void _showHistoryLog(BuildContext context, Restaurant restaurant) {
    final List<Map<String, dynamic>> history = restaurant.getOrderHistory();
    double grandTotal = 0.0;
    for (var order in history) {
      grandTotal += double.tryParse(order['totalPrice']!) ?? 0.0;
    }

    Widget buildOrderItemRow(Food food, int quantity) {
      double itemPrice = (double.tryParse(food.price) ?? 0.0);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                food.name,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Text('x$quantity',
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 50,
                  child: Text(
                    '¥${(itemPrice * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(restaurant.translate('history_log'),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  )),
              Text(
                'TTL: ¥${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: history.isEmpty
                ? Center(
                    child: Text(restaurant.translate('no_history'),
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontFamily: 'Courier',
                            fontSize: 16)))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final order = history[index];
                      final DateTime timestamp = order['timestamp'];
                      final String formattedTime =
                          DateFormat('HH:mm:ss').format(timestamp);
                      final Map<Food, int> items = order['items'];
                      final String totalPrice = order['totalPrice'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${restaurant.translate('order')} #${history.length - index} ($formattedTime)',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                Text('¥$totalPrice',
                                    style: const TextStyle(
                                        color: Colors.deepOrangeAccent,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 10),
                            ...items.entries.map((entry) =>
                                buildOrderItemRow(entry.key, entry.value)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(restaurant.translate('close'),
                  style: const TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // 结账确认弹窗
  // ----------------------------------------------------------------------
  void _requestBill(BuildContext context, Restaurant restaurant) {
    final List<Map<String, dynamic>> history = restaurant.getOrderHistory();
    final bool hasItemsInCart = restaurant.getUniqueCartItems().isNotEmpty;

    // 计算历史总金额
    double grandTotal = 0.0;
    for (var order in history) {
      grandTotal += double.tryParse(order['totalPrice']!) ?? 0.0;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.amber, width: 2),
        ),
        title: Text(
          "${restaurant.translate('request_bill')} // ${restaurant.translate('request_bill')}",
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasItemsInCart)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    const Icon(Icons.warning,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(restaurant.translate('warning_unordered'),
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            Text(restaurant.translate('total_payment'),
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '¥${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    shadows: [BoxShadow(color: Colors.amber, blurRadius: 20)]),
              ),
            ),
            const SizedBox(height: 20),
            Text(restaurant.translate('call_staff_prompt'),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(restaurant.translate('cancel'),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: Colors.amber,
                content: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.black),
                    const SizedBox(width: 10),
                    Text(restaurant.translate('staff_notified'),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier')),
                  ],
                ),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text(restaurant.translate('call_staff'),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 下单逻辑
  void _placeOrder(BuildContext context, Restaurant restaurant) {
    if (restaurant.getUniqueCartItems().isEmpty) {
      // 略... (保持原有逻辑)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(restaurant.translate('order_empty'),
              style: const TextStyle(color: Colors.black)),
          content: Text(restaurant.translate('select_items'),
              style: const TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(restaurant.translate('confirm'),
                  style: const TextStyle(color: Colors.deepOrange)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final uniqueItems = restaurant.getUniqueCartItems();
        final totalPrice = restaurant.getTotalPrice();

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Colors.deepOrange, width: 2),
          ),
          title: Text(restaurant.translate('confirm_order'),
              style: const TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: uniqueItems.length,
                    itemBuilder: (context, index) {
                      final food = uniqueItems[index];
                      final quantity = restaurant.getFoodQuantity(food);
                      final itemSubtotal =
                          (double.tryParse(food.price) ?? 0.0) * quantity;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(food.name,
                                style: const TextStyle(color: Colors.white70)),
                            Text('x$quantity',
                                style:
                                    const TextStyle(color: Colors.blueAccent)),
                            Text('¥${itemSubtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.deepOrangeAccent)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(restaurant.translate('total'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("¥$totalPrice",
                        style: const TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(restaurant.translate('cancel'),
                  style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                restaurant.placeOrder();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(restaurant.translate('order_transmitted'),
                        style: const TextStyle(fontFamily: 'Courier')),
                    backgroundColor: Colors.deepOrangeAccent,
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: Text(restaurant.translate('confirm'),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 购物车侧边栏组件
  Widget _buildCartSidePanel(
    BuildContext context,
    Restaurant restaurant, {
    bool compact = false,
  }) {
    final uniqueItems = restaurant.getUniqueCartItems();
    final totalPrice = restaurant.getTotalPrice();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: compact
            ? const Border(top: BorderSide(color: Colors.deepOrange, width: 2))
            : const Border(
                left: BorderSide(color: Colors.deepOrange, width: 2),
              ),
      ),
      padding: const EdgeInsets.all(12), // Padding reduced to save space
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.translate('order_cart'),
            style: const TextStyle(
              color: Colors.deepOrangeAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const Divider(color: Colors.white10),

          Expanded(
            child: uniqueItems.isEmpty
                ? Center(
                    child: Text(
                      restaurant.translate('cart_empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Courier',
                          fontSize: 14), // Slightly smaller text
                    ),
                  )
                : ListView.builder(
                    itemCount: uniqueItems.length,
                    itemBuilder: (context, index) {
                      final food = uniqueItems[index];
                      final quantity = restaurant.getFoodQuantity(food);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(food.name,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => restaurant.removeFromCart(food),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.red.withValues(alpha: 0.2),
                                    child: const Icon(Icons.remove,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text('$quantity',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                                GestureDetector(
                                  onTap: () => restaurant.addToCart(food),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.green.withValues(alpha: 0.2),
                                    child: const Icon(Icons.add,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(color: Colors.white10),

          // ------------------------------------------------------------------
          // 底部控制区：按钮和总价 (修正布局)
          // ------------------------------------------------------------------
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧：图标按钮 (使用 Tooltip 代替文本以节省空间)
                  Row(
                    children: [
                      // 1. 历史记录按钮
                      Tooltip(
                        message: restaurant.translate('history_log'),
                        child: GestureDetector(
                          onTap: () => _showHistoryLog(context, restaurant),
                          child: Container(
                            padding:
                                const EdgeInsets.all(8), // Padding optimized
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.blueAccent, width: 1.5),
                            ),
                            child: const Icon(Icons.history,
                                color: Colors.blueAccent, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 2. 结账按钮 (文字追加)
                      Tooltip(
                        message: restaurant.translate('request_bill'),
                        child: GestureDetector(
                          onTap: () => _requestBill(context, restaurant),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border:
                                  Border.all(color: Colors.amber, width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.receipt_long,
                                    color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.translate('request_bill'),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 右侧：总金额 (FittedBox で縮小)
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${restaurant.translate('total')}:",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                        FittedBox(
                          // Ensure price fits
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "¥$totalPrice",
                            style: const TextStyle(
                              color: Colors.deepOrangeAccent,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 3. 下单按钮
              GestureDetector(
                onTap: uniqueItems.isEmpty
                    ? null
                    : () => _placeOrder(context, restaurant),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                      color: uniqueItems.isEmpty
                          ? Colors.grey[700]
                          : Colors.deepOrange,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: uniqueItems.isEmpty
                          ? null
                          : [
                              BoxShadow(
                                  color:
                                      Colors.deepOrange.withValues(alpha: 0.5),
                                  blurRadius: 8)
                            ]),
                  child: Center(
                    child: Text(
                      uniqueItems.isEmpty
                          ? restaurant.translate('select_items')
                          : restaurant.translate('transmit_order'),
                      style: TextStyle(
                          color: uniqueItems.isEmpty
                              ? Colors.white54
                              : Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  int _menuColumnCount(double width) {
    if (width >= 900) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  Widget _buildMainCategoryButton(
    Restaurant restaurant,
    Map<String, String> category,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _onMainCategoryTap(category['id']!),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepOrange.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              restaurant.translate(category['key']!),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.deepOrangeAccent : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
                fontSize: 13,
                letterSpacing: 1.0,
                shadows: isSelected
                    ? [
                        const Shadow(
                          color: Colors.deepOrange,
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.deepOrangeAccent,
                  boxShadow: const [
                    BoxShadow(color: Colors.deepOrange, blurRadius: 5)
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildMenuArea(
    Restaurant restaurant,
    List<Food> currentMenu,
    List<Map<String, String>> currentSubCategories,
    double width,
  ) {
    final columnCount = _menuColumnCount(width);
    final useScrollableCategories = width < 720;

    return Column(
      children: [
        Container(
          height: 70,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(
              bottom: BorderSide(color: Colors.deepOrange, width: 2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepOrangeAccent,
                blurRadius: 10,
                offset: Offset(0, 1),
              )
            ],
          ),
          child: useScrollableCategories
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories.map((cat) {
                    final isSelected = cat['id'] == _selectedCategory;
                    return SizedBox(
                      width: 104,
                      child:
                          _buildMainCategoryButton(restaurant, cat, isSelected),
                    );
                  }).toList(),
                )
              : Row(
                  children: _categories.map((cat) {
                    final isSelected = cat['id'] == _selectedCategory;
                    return Expanded(
                      child:
                          _buildMainCategoryButton(restaurant, cat, isSelected),
                    );
                  }).toList(),
                ),
        ),
        Container(
          height: currentSubCategories.isEmpty ? 0 : 60,
          width: double.infinity,
          color: const Color(0xFF121212),
          alignment: Alignment.centerLeft,
          child: currentSubCategories.isEmpty
              ? Container()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: currentSubCategories.length,
                  itemBuilder: (context, index) {
                    final subCat = currentSubCategories[index];
                    final subCatId = subCat['id']!;
                    final isMainCategorySelected =
                        subCatId == _selectedCategory &&
                            _selectedSubCategoryTag.isEmpty;
                    final isSubTagSelected =
                        subCatId == _selectedSubCategoryTag;
                    final isSelected =
                        isMainCategorySelected || isSubTagSelected;

                    return GestureDetector(
                      onTap: () => _onSubCategoryTap(subCatId),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepOrange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? Colors.deepOrange
                                : Colors.grey[800]!,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          restaurant.translate(subCat['key']!),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.grey[500],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFF0A0A0A)),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentMenu.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                return FoodTile(food: currentMenu[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final String activeFilterTag = _selectedSubCategoryTag.isNotEmpty
            ? _selectedSubCategoryTag
            : _selectedCategory;

        List<Food> currentMenu = restaurant.getMenuByTag(activeFilterTag);

        final List<Map<String, String>> currentSubCategories =
            _subCategoryMap[_selectedCategory] ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: LayoutBuilder(
                        builder: (context, menuConstraints) {
                          return _buildMenuArea(
                            restaurant,
                            currentMenu,
                            currentSubCategories,
                            menuConstraints.maxWidth,
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: _buildCartSidePanel(context, restaurant),
                    ),
                  ],
                );
              }

              final cartHeight =
                  (constraints.maxHeight * 0.38).clamp(260.0, 360.0).toDouble();

              return Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, menuConstraints) {
                        return _buildMenuArea(
                          restaurant,
                          currentMenu,
                          currentSubCategories,
                          menuConstraints.maxWidth,
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    height: cartHeight,
                    child: _buildCartSidePanel(
                      context,
                      restaurant,
                      compact: true,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
