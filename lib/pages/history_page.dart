import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // 辅助方法：格式化订单中的单个菜品行
  Widget _buildOrderItemRow(Food food, int quantity) {
    double itemPrice = (double.tryParse(food.price) ?? 0.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 菜名和数量
          Expanded(
            child: Text(
              food.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 数量和单价
          Row(
            children: [
              Text('x$quantity',
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 15),
              // 小计
              SizedBox(
                width: 60,
                child: Text(
                  '¥${(itemPrice * quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final List<Map<String, dynamic>> history = restaurant.getOrderHistory();

        // 计算所有历史订单的总消费金额
        double grandTotal = 0.0;
        for (var order in history) {
          grandTotal += double.tryParse(order['totalPrice']!) ?? 0.0;
        }

        return Container(
          color: const Color(0xFF121212), // 科幻主题背景
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              const Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 10),
                child: Text(
                  'HISTORY LOG // 历史记录',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: 'Courier',
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.blueAccent, blurRadius: 5)
                      ]),
                ),
              ),

              // 底部总计面板 (总消费)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.deepOrangeAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL SPENT // 总消费',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'Courier'),
                    ),
                    Text(
                      '¥${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.deepOrangeAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        shadows: [
                          Shadow(color: Colors.deepOrange, blurRadius: 8)
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 列表
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text("// NO HISTORY FOUND\n请先完成订单",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                                fontFamily: 'Courier')))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final order = history[index];
                          final DateTime timestamp = order['timestamp'];

                          final String formattedTime =
                              DateFormat('HH:mm:ss').format(timestamp);
                          final Map<Food, int> items = order['items'];
                          final String totalPrice = order['totalPrice'];
                          final int itemCount = order['itemCount'];

                          // 历史订单卡片 (不再是 ExpansionTile，而是直接展示内容)
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color:
                                      Colors.blueAccent.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.blueAccent
                                        .withValues(alpha: 0.1),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ---- 订单头部摘要 ----
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 订单序号 & 时间
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('ORDER #${history.length - index}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Courier',
                                                fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('TIME: $formattedTime',
                                            style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 11,
                                                fontFamily: 'Courier')),
                                      ],
                                    ),

                                    // 总价 & 数量
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('¥$totalPrice',
                                            style: const TextStyle(
                                                color: Colors.deepOrangeAccent,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        Text('$itemCount ITEMS',
                                            style: TextStyle(
                                                color: Colors.blueAccent,
                                                fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),

                                const Divider(
                                    color: Colors.white10, height: 20),

                                // ---- 菜品详情 (默认展开) ----
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 5.0, right: 5.0),
                                  child: Column(
                                    children: items.entries.map((entry) {
                                      return _buildOrderItemRow(
                                          entry.key, entry.value);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
