import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Widget _buildOrderItemRow(
    Food food,
    int quantity,
    AppThemeTokens theme,
    bool isTerminal,
  ) {
    final itemPrice = (double.tryParse(food.price) ?? 0.0) * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTerminal ? '> ${food.name}' : food.name,
              style: TextStyle(
                color: theme.ink,
                fontSize: 14,
                fontFamily: isTerminal ? 'Courier' : null,
                fontWeight: isTerminal ? FontWeight.w800 : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'x$quantity',
            style: TextStyle(
              color: isTerminal ? theme.cyan : theme.ink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 72,
            child: Text(
              '¥${itemPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: isTerminal ? theme.accentSoft : theme.ink,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Courier',
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _titleForMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.neonTerminal:
        return 'HISTORY::PAGE';
      case AppThemeMode.paperReceipt:
        return 'ORDER HISTORY';
      case AppThemeMode.retroOS:
        return 'HISTORY.LOG';
      case AppThemeMode.neoBrutalism:
        return 'HISTORY LOG';
    }
  }

  BoxDecoration _panelDecoration(AppThemeTokens theme, AppThemeMode mode) {
    final isTerminal = mode == AppThemeMode.neonTerminal;

    return BoxDecoration(
      color: theme.surface,
      borderRadius: BorderRadius.circular(
        mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
      ),
      border: Border.all(
        color: isTerminal ? theme.cyan : theme.border,
        width: mode == AppThemeMode.neoBrutalism ? 3 : 1.5,
      ),
      boxShadow: mode == AppThemeMode.neoBrutalism
          ? theme.hardShadow(offset: const Offset(3, 3))
          : isTerminal
              ? theme.softGlow(theme.cyan)
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final history = restaurant.getOrderHistory();
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final title = _titleForMode(mode);

        var grandTotal = 0.0;
        for (final order in history) {
          grandTotal += double.tryParse(order['totalPrice']!) ?? 0.0;
        }

        return Container(
          color: theme.background,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontFamily: 'Courier',
                    shadows: isTerminal
                        ? [
                            Shadow(
                              color: theme.cyan.withValues(alpha: 0.48),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: _panelDecoration(theme, mode),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTerminal ? 'TOTAL_SPENT::' : 'TOTAL SPENT // 总消费',
                      style: TextStyle(
                        color: theme.ink.withValues(alpha: 0.68),
                        fontSize: 14,
                        fontFamily: 'Courier',
                      ),
                    ),
                    Text(
                      '¥${grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isTerminal ? theme.amber : theme.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          isTerminal
                              ? '// NO HISTORY FOUND'
                              : '// NO HISTORY FOUND\n请先完成订单',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.ink.withValues(alpha: 0.52),
                            fontSize: 16,
                            fontFamily: 'Courier',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final order = history[index];
                          final timestamp = order['timestamp'] as DateTime;
                          final formattedTime =
                              DateFormat('HH:mm:ss').format(timestamp);
                          final items = Map<Food, int>.from(
                            order['items'] as Map,
                          );
                          final totalPrice = order['totalPrice'];
                          final itemCount = order['itemCount'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: _panelDecoration(theme, mode),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isTerminal
                                              ? 'ORDER[${history.length - index}]'
                                              : 'ORDER #${history.length - index}',
                                          style: TextStyle(
                                            color: theme.ink,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Courier',
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'TIME: $formattedTime',
                                          style: TextStyle(
                                            color: theme.ink
                                                .withValues(alpha: 0.58),
                                            fontSize: 11,
                                            fontFamily: 'Courier',
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '¥$totalPrice',
                                          style: TextStyle(
                                            color: isTerminal
                                                ? theme.amber
                                                : theme.ink,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$itemCount ITEMS',
                                          style: TextStyle(
                                            color: isTerminal
                                                ? theme.cyan
                                                : theme.ink
                                                    .withValues(alpha: 0.62),
                                            fontSize: 10,
                                            fontFamily: 'Courier',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Divider(
                                  color: theme.ink.withValues(alpha: 0.16),
                                  height: 20,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                  ),
                                  child: Column(
                                    children: items.entries.map((entry) {
                                      return _buildOrderItemRow(
                                        entry.key,
                                        entry.value,
                                        theme,
                                        isTerminal,
                                      );
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
