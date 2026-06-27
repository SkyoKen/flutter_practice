import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';

class FoodTile extends StatelessWidget {
  final Food food;

  // 移除了 onTap，所有交互都在内部处理

  const FoodTile({super.key, required this.food});

  // 封装加购/减购按钮的样式
  Widget _buildControlButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听 Restaurant 状态的变化，并获取当前菜品的数量
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final int quantity = restaurant.getFoodQuantity(food);
        final bool isInCart = quantity > 0;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // 深色背景
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isInCart ? Colors.deepOrangeAccent : Colors.grey[800]!,
              width: isInCart ? 2 : 1,
            ),
            boxShadow: isInCart
                ? [
                    BoxShadow(
                        color: Colors.deepOrange.withValues(alpha: 0.2),
                        blurRadius: 10)
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 菜品图片区 (占位图)
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black, // 更深的背景色
                    child: Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.deepOrange[300]!.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // 描述/信息区
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Courier',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${food.price}',
                      style: const TextStyle(
                        color: Colors.deepOrangeAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 数量控制区域
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 评分
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          food.rating.toString(),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),

                    // 数量控制
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isInCart)
                          // 1. 减少按钮
                          _buildControlButton(
                            icon: Icons.remove,
                            color: Colors.grey[700]!,
                            onTap: () => restaurant.removeFromCart(food),
                          ),

                        if (isInCart)
                          // 2. 数量显示
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              quantity.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        // 3. 增加/加购按钮
                        _buildControlButton(
                            icon:
                                isInCart ? Icons.add : Icons.add_shopping_cart,
                            color: isInCart
                                ? Colors.deepOrange
                                : Colors.deepOrangeAccent,
                            onTap: () {
                              // 增加菜品数量
                              restaurant.addToCart(food);
                              // 触发系统提示
                              // ScaffoldMessenger.of(context)
                              //     .removeCurrentSnackBar();
                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(
                              //     content: Row(
                              //       children: [
                              //         const Icon(Icons.check_circle_outline,
                              //             color: Colors.black, size: 20),
                              //         const SizedBox(width: 10),
                              //         Text(
                              //             "ITEM ADDED/UPDATED [${food.name}] QTY: ${quantity + 1}",
                              //             style: const TextStyle(
                              //                 color: Colors.black,
                              //                 fontFamily: 'Courier',
                              //                 fontWeight: FontWeight.bold)),
                              //       ],
                              //     ),
                              //     duration: const Duration(milliseconds: 1000),
                              //     backgroundColor: Colors.deepOrangeAccent,
                              //     behavior: SnackBarBehavior.floating,
                              //     shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(4)),
                              //     // 向上移动，避免被底部导航栏遮挡
                              //     margin: const EdgeInsets.only(
                              //         bottom: 80, left: 10, right: 10),
                              // ),
                              // );
                            }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
