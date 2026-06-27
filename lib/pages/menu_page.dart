import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/food_tile.dart';
import 'package:cyber_table_order/components/order_history_dialog.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';

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
    showDialog(
      context: context,
      builder: (context) => OrderHistoryDialog(restaurant: restaurant),
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
      builder: (context) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final isPaper = mode == AppThemeMode.paperReceipt;
        final isRetro = mode == AppThemeMode.retroOS;
        final dialogTitle = switch (mode) {
          AppThemeMode.neonTerminal => 'BILL::REQUEST',
          AppThemeMode.paperReceipt => 'BILL RECEIPT',
          AppThemeMode.retroOS => 'BILL.EXE',
          AppThemeMode.neoBrutalism => restaurant.translate('request_bill'),
        };
        final titleColor = isTerminal
            ? theme.cyan
            : isRetro
                ? Colors.white
                : theme.ink;
        final amountColor = isTerminal ? theme.amber : theme.ink;
        final border = isRetro
            ? Border(
                top: BorderSide(color: Colors.white, width: 2),
                left: BorderSide(color: Colors.white, width: 2),
                right: BorderSide(color: theme.ink, width: 2),
                bottom: BorderSide(color: theme.ink, width: 2),
              )
            : Border.all(
                color: isTerminal ? theme.cyan : theme.border,
                width: mode == AppThemeMode.neoBrutalism
                    ? theme.strongBorderWidth
                    : 1.5,
              );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              decoration: BoxDecoration(
                color: isRetro ? theme.surfaceHigh : theme.surface,
                borderRadius: isRetro
                    ? null
                    : BorderRadius.circular(
                        mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                      ),
                border: border,
                boxShadow: mode == AppThemeMode.neoBrutalism
                    ? theme.hardShadow(offset: const Offset(5, 5))
                    : isTerminal
                        ? theme.softGlow(theme.cyan)
                        : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isRetro ? 8 : 18,
                      vertical: isRetro ? 8 : 16,
                    ),
                    color: isRetro ? theme.accent : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          isTerminal
                              ? Icons.terminal
                              : isPaper
                                  ? Icons.receipt_long
                                  : Icons.payments,
                          color: titleColor,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontFamily:
                                  isTerminal || isPaper ? 'Courier' : null,
                              fontWeight: FontWeight.w900,
                              fontSize: isRetro ? 13 : 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasItemsInCart)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.danger.withValues(alpha: 0.12),
                              border: Border.all(color: theme.danger),
                              borderRadius: BorderRadius.circular(
                                mode == AppThemeMode.neoBrutalism
                                    ? theme.radius
                                    : 0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning,
                                    color: theme.danger, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    restaurant.translate('warning_unordered'),
                                    style: TextStyle(
                                      color: theme.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isPaper)
                          Container(
                            height: 1,
                            margin: const EdgeInsets.only(bottom: 14),
                            color: theme.ink.withValues(alpha: 0.28),
                          ),
                        Text(
                          isTerminal
                              ? 'TOTAL_PAYMENT::'
                              : restaurant.translate('total_payment'),
                          style: TextStyle(
                            color: theme.ink.withValues(alpha: 0.68),
                            fontFamily:
                                isTerminal || isPaper ? 'Courier' : null,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '¥${grandTotal.toStringAsFixed(2)}',
                          textAlign:
                              isPaper ? TextAlign.center : TextAlign.left,
                          style: TextStyle(
                            color: amountColor,
                            fontSize: isPaper ? 34 : 32,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          restaurant.translate('call_staff_prompt'),
                          style: TextStyle(
                            color: theme.ink.withValues(alpha: 0.62),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  restaurant.translate('cancel'),
                                  style: TextStyle(
                                    color: theme.ink.withValues(alpha: 0.66),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: isTerminal
                                          ? theme.cyan
                                          : isPaper
                                              ? theme.surface
                                              : theme.amber,
                                      content: Row(
                                        children: [
                                          Icon(
                                            Icons.notifications_active,
                                            color: isTerminal
                                                ? Colors.black
                                                : theme.ink,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              restaurant.translate(
                                                'staff_notified',
                                              ),
                                              style: TextStyle(
                                                color: isTerminal
                                                    ? Colors.black
                                                    : theme.ink,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Courier',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isTerminal
                                      ? theme.cyan
                                      : isPaper
                                          ? theme.surface
                                          : isRetro
                                              ? theme.surfaceHigh
                                              : theme.amber,
                                  foregroundColor:
                                      isTerminal ? Colors.black : theme.ink,
                                  side: BorderSide(
                                    color: isTerminal ? theme.cyan : theme.ink,
                                    width: mode == AppThemeMode.neoBrutalism
                                        ? 3
                                        : 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      mode == AppThemeMode.neoBrutalism
                                          ? theme.radius
                                          : 0,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  restaurant.translate('call_staff'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color:
                                        isTerminal ? Colors.black : theme.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 下单逻辑
  void _placeOrder(BuildContext context, Restaurant restaurant) {
    if (restaurant.getUniqueCartItems().isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          final theme = AppTheme.of(context);
          final mode = AppTheme.activeMode;
          final title = switch (mode) {
            AppThemeMode.neonTerminal => 'ORDER::EMPTY',
            AppThemeMode.paperReceipt => restaurant.translate('order_empty'),
            AppThemeMode.retroOS => 'EMPTY_ORDER.EXE',
            AppThemeMode.neoBrutalism => restaurant.translate('order_empty'),
          };

          return ThemedAppDialog(
            title: title,
            icon: Icons.info_outline,
            actions: [
              ThemedDialogButton(
                label: restaurant.translate('confirm'),
                primary: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
            child: Text(
              restaurant.translate('select_items'),
              style: TextStyle(
                color: theme.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        final uniqueItems = restaurant.getUniqueCartItems();
        final totalPrice = restaurant.getTotalPrice();
        final title = switch (mode) {
          AppThemeMode.neonTerminal => 'ORDER::CONFIRM',
          AppThemeMode.paperReceipt => restaurant.translate('confirm_order'),
          AppThemeMode.retroOS => 'CONFIRM.EXE',
          AppThemeMode.neoBrutalism => restaurant.translate('confirm_order'),
        };

        Widget buildOrderRow(Food food) {
          final quantity = restaurant.getFoodQuantity(food);
          final itemSubtotal = (double.tryParse(food.price) ?? 0.0) * quantity;

          return Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isTerminal
                      ? theme.cyan.withValues(alpha: 0.18)
                      : theme.ink.withValues(alpha: 0.14),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isTerminal ? '> ${food.name}' : food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.ink,
                      fontFamily:
                          isTerminal || mode == AppThemeMode.paperReceipt
                              ? 'Courier'
                              : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'x$quantity',
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 10),
                SizedBox(
                  width: 76,
                  child: Text(
                    '¥${itemSubtotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isTerminal ? theme.accentSoft : theme.ink,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return ThemedAppDialog(
          title: title,
          icon: Icons.send,
          maxWidth: 520,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ThemedDialogButton(
              label: restaurant.translate('confirm'),
              icon: Icons.send,
              primary: true,
              onPressed: () {
                restaurant.placeOrder();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).removeCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      restaurant.translate('order_transmitted'),
                      style: TextStyle(
                        color: isTerminal ? Colors.black : theme.ink,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: isTerminal ? theme.cyan : theme.accent,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: uniqueItems.length,
                  itemBuilder: (context, index) {
                    return buildOrderRow(uniqueItems[index]);
                  },
                ),
              ),
              Divider(
                color: theme.ink.withValues(alpha: 0.18),
                height: 22,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTerminal ? 'TOTAL::' : restaurant.translate('total'),
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                    ),
                  ),
                  Text(
                    "¥$totalPrice",
                    style: TextStyle(
                      color: isTerminal ? theme.amber : theme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _cartTitle(Restaurant restaurant) {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return 'ORDER_CART::BUFFER';
      case AppThemeMode.paperReceipt:
        return 'RECEIPT';
      case AppThemeMode.retroOS:
        return 'CART.EXE';
      case AppThemeMode.neoBrutalism:
        return restaurant.translate('order_cart');
    }
  }

  Widget _buildCartHeader(Restaurant restaurant, int itemCount) {
    final mode = AppTheme.activeMode;
    final countLabel = switch (mode) {
      AppThemeMode.neonTerminal => 'QTY=$itemCount',
      AppThemeMode.paperReceipt => '#$itemCount',
      AppThemeMode.retroOS => itemCount.toString().padLeft(2, '0'),
      AppThemeMode.neoBrutalism => itemCount.toString(),
    };

    if (mode == AppThemeMode.paperReceipt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              _cartTitle(restaurant),
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Courier',
              ),
            ),
          ),
          SizedBox(height: 4),
          Center(
            child: Text(
              'TABLE ORDER / ITEMS $countLabel',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.62),
                fontSize: 11,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 1,
            color: AppTheme.ink.withValues(alpha: 0.28),
          ),
        ],
      );
    }

    if (mode == AppThemeMode.retroOS) {
      return Container(
        height: 32,
        decoration: BoxDecoration(
          color: AppTheme.accent,
          border: Border(
            top: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
            right: BorderSide(color: AppTheme.ink, width: 2),
            bottom: BorderSide(color: AppTheme.ink, width: 2),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                _cartTitle(restaurant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              color: AppTheme.surface,
              child: Text(
                countLabel,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isTerminal = mode == AppThemeMode.neonTerminal;
    return Row(
      children: [
        Icon(
          isTerminal ? Icons.terminal : Icons.shopping_bag_outlined,
          color: isTerminal ? AppTheme.cyan : AppTheme.ink,
          size: 21,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            _cartTitle(restaurant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isTerminal ? AppTheme.cyan : AppTheme.ink,
              fontSize: isTerminal ? 14 : 19,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
            ),
          ),
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: itemCount == 0 ? AppTheme.surfaceHigh : AppTheme.accentSoft,
            borderRadius: BorderRadius.circular(isTerminal ? 0 : 4),
            border: Border.all(
              color: isTerminal ? AppTheme.cyan : AppTheme.ink,
              width: isTerminal ? 1 : 2,
            ),
          ),
          child: Text(
            countLabel,
            style: TextStyle(
              color: isTerminal ? AppTheme.cyan : AppTheme.ink,
              fontWeight: FontWeight.w900,
              fontFamily: 'Courier',
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItemTile(Restaurant restaurant, Food food) {
    final mode = AppTheme.activeMode;
    final quantity = restaurant.getFoodQuantity(food);
    final itemSubtotal = (double.tryParse(food.price) ?? 0.0) * quantity;

    Widget quantityControls({bool compact = false}) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: mode == AppThemeMode.neonTerminal
              ? Colors.transparent
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(
            mode == AppThemeMode.retroOS || mode == AppThemeMode.paperReceipt
                ? 0
                : 4,
          ),
          border: Border.all(
            color: mode == AppThemeMode.neonTerminal
                ? AppTheme.cyan.withValues(alpha: 0.58)
                : AppTheme.ink,
            width: mode == AppThemeMode.neonTerminal ? 1 : 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CartIconButton(
              icon: Icons.remove,
              tooltip: 'remove',
              onTap: () => restaurant.removeFromCart(food),
            ),
            SizedBox(
              width: compact ? 24 : 28,
              child: Text(
                '$quantity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),
            ),
            _CartIconButton(
              icon: Icons.add,
              tooltip: 'add',
              onTap: () => restaurant.addToCart(food),
            ),
          ],
        ),
      );
    }

    if (mode == AppThemeMode.neonTerminal) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.cyan.withValues(alpha: 0.16)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '> ${food.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Courier',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SUBTOTAL ¥${itemSubtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.cyan.withValues(alpha: 0.82),
                      fontSize: 11,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            quantityControls(compact: true),
          ],
        ),
      );
    }

    if (mode == AppThemeMode.paperReceipt) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.ink.withValues(alpha: 0.16)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                food.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'x$quantity',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.62),
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: Text(
                '¥${itemSubtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 12,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 8),
            quantityControls(compact: true),
          ],
        ),
      );
    }

    if (mode == AppThemeMode.retroOS) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
            right: BorderSide(color: AppTheme.ink, width: 2),
            bottom: BorderSide(color: AppTheme.ink, width: 2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, color: AppTheme.ink, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '¥${itemSubtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            quantityControls(compact: true),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppTheme.ink,
          width: 2,
        ),
        boxShadow: AppTheme.brutalShadow(
          offset: Offset(3, 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '¥${itemSubtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          quantityControls(),
        ],
      ),
    );
  }

  Widget _buildCartSidePanel(
    BuildContext context,
    Restaurant restaurant, {
    bool compact = false,
  }) {
    final uniqueItems = restaurant.getUniqueCartItems();
    final totalPrice = restaurant.getTotalPrice();
    final itemCount = _cartItemCount(restaurant);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final isRetro = mode == AppThemeMode.retroOS;
    final borderColor = isTerminal ? AppTheme.cyan : AppTheme.ink;
    final borderWidth = isTerminal || isPaper ? 1.5 : 3.0;
    final orderLabel = switch (mode) {
      AppThemeMode.neonTerminal =>
        uniqueItems.isEmpty ? 'AWAIT_SELECTION' : 'TRANSMIT_ORDER',
      AppThemeMode.paperReceipt => uniqueItems.isEmpty
          ? restaurant.translate('select_items')
          : 'PRINT ORDER',
      AppThemeMode.retroOS => uniqueItems.isEmpty
          ? restaurant.translate('select_items')
          : 'Send Order',
      AppThemeMode.neoBrutalism => uniqueItems.isEmpty
          ? restaurant.translate('select_items')
          : restaurant.translate('transmit_order'),
    };
    final totalLabel = switch (mode) {
      AppThemeMode.neonTerminal => 'TOTAL_BUFFER',
      AppThemeMode.paperReceipt => 'TOTAL DUE',
      AppThemeMode.retroOS => 'Total:',
      AppThemeMode.neoBrutalism => "${restaurant.translate('total')}:",
    };

    return Container(
      decoration: BoxDecoration(
        color: isRetro ? AppTheme.surfaceHigh : AppTheme.surface,
        border: compact
            ? Border(top: BorderSide(color: borderColor, width: borderWidth))
            : Border(
                left: BorderSide(color: borderColor, width: borderWidth),
              ),
      ),
      padding: EdgeInsets.fromLTRB(
        isPaper ? 18 : 14,
        compact ? 12 : 16,
        isPaper ? 18 : 14,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCartHeader(restaurant, itemCount),
          SizedBox(height: isPaper ? 8 : 10),
          if (!isPaper) Divider(),
          Expanded(
            child: uniqueItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_shopping_cart,
                          color: AppTheme.ink.withValues(alpha: 0.24),
                          size: compact ? 34 : 42,
                        ),
                        SizedBox(height: compact ? 8 : 12),
                        Text(
                          isTerminal
                              ? 'BUFFER EMPTY'
                              : restaurant.translate('cart_empty'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.ink.withValues(
                              alpha: isTerminal ? 0.7 : 0.58,
                            ),
                            fontFamily: 'Courier',
                            fontSize: compact ? 13 : 14,
                            height: compact ? 1.25 : 1.35,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: uniqueItems.length,
                    separatorBuilder: (context, index) => SizedBox(
                      height: isPaper || isTerminal ? 0 : 10,
                    ),
                    itemBuilder: (context, index) {
                      final food = uniqueItems[index];
                      return _buildCartItemTile(restaurant, food);
                    },
                  ),
          ),
          Divider(),
          Row(
            children: [
              Tooltip(
                message: restaurant.translate('history_log'),
                child: _CartActionButton(
                  icon: Icons.history,
                  color: AppTheme.cyan.withValues(alpha: 0.86),
                  onTap: () => _showHistoryLog(context, restaurant),
                ),
              ),
              SizedBox(width: 10),
              Tooltip(
                message: restaurant.translate('request_bill'),
                child: _CartActionButton(
                  icon: Icons.receipt_long,
                  color: AppTheme.amber,
                  onTap: () => _requestBill(context, restaurant),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      totalLabel,
                      style: TextStyle(
                        color: AppTheme.ink.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFamily: isTerminal || isPaper ? 'Courier' : null,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "¥$totalPrice",
                        style: TextStyle(
                          color: AppTheme.ink,
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
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: uniqueItems.isEmpty
                    ? null
                    : AppTheme.brutalShadow(offset: Offset(3, 3)),
              ),
              child: ElevatedButton.icon(
                onPressed: uniqueItems.isEmpty
                    ? null
                    : () => _placeOrder(context, restaurant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: uniqueItems.isEmpty
                      ? AppTheme.surfaceHigh
                      : isTerminal
                          ? AppTheme.cyan
                          : AppTheme.accent,
                  foregroundColor: isTerminal && uniqueItems.isNotEmpty
                      ? Colors.black
                      : AppTheme.ink,
                  disabledBackgroundColor: AppTheme.surfaceHigh,
                  disabledForegroundColor: AppTheme.ink.withValues(alpha: 0.45),
                  side: BorderSide(
                    color: isTerminal ? AppTheme.cyan : AppTheme.ink,
                    width: isTerminal || isPaper || isRetro ? 2 : 3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      isTerminal || isPaper || isRetro ? 0 : 4,
                    ),
                  ),
                ),
                icon: Icon(
                  isTerminal
                      ? Icons.terminal
                      : isPaper
                          ? Icons.receipt_long
                          : Icons.send,
                  size: 18,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    orderLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      fontFamily: isTerminal || isPaper ? 'Courier' : null,
                    ),
                  ),
                ),
              ),
            ),
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

  double _menuCardAspectRatio(double width) {
    switch (AppTheme.activeMode) {
      case AppThemeMode.paperReceipt:
        if (width >= 900) return 1.45;
        if (width >= 560) return 1.35;
        return 1.8;
      case AppThemeMode.neonTerminal:
        if (width >= 900) return 1.05;
        if (width >= 560) return 0.95;
        return 1.55;
      case AppThemeMode.retroOS:
        if (width >= 900) return 0.95;
        if (width >= 560) return 0.9;
        return 1.45;
      case AppThemeMode.neoBrutalism:
        break;
    }
    if (width >= 900) return 0.88;
    if (width >= 560) return 0.82;
    return 1.45;
  }

  int _cartItemCount(Restaurant restaurant) {
    return restaurant
        .getUniqueCartItems()
        .fold(0, (sum, food) => sum + restaurant.getFoodQuantity(food));
  }

  IconData _categoryIcon(String categoryId) {
    switch (categoryId) {
      case 'fish':
        return Icons.set_meal;
      case 'meat':
        return Icons.dinner_dining;
      case 'beer':
        return Icons.local_drink;
      case 'side':
        return Icons.eco;
      case 'bento':
        return Icons.rice_bowl;
      default:
        return Icons.local_fire_department;
    }
  }

  Widget _buildMainCategoryButton(
    Restaurant restaurant,
    Map<String, String> category,
    bool isSelected,
  ) {
    final categoryId = category['id']!;
    final label = restaurant.translate(category['key']!);
    final mode = AppTheme.activeMode;

    if (mode == AppThemeMode.neonTerminal) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        child: InkWell(
          onTap: () => _onMainCategoryTap(categoryId),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.cyan.withValues(alpha: 0.14)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.cyan : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              isSelected ? '> $label' : '[$label]',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? AppTheme.cyan : AppTheme.ink,
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    if (mode == AppThemeMode.paperReceipt) {
      return InkWell(
        onTap: () => _onMainCategoryTap(categoryId),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surface : AppTheme.background,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.accent : AppTheme.border,
                width: isSelected ? 4 : 1,
              ),
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.ink,
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (mode == AppThemeMode.retroOS) {
      return Padding(
        padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: InkWell(
          onTap: () => _onMainCategoryTap(categoryId),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accent : AppTheme.surface,
              border: Border(
                top: BorderSide(color: Colors.white, width: 2),
                left: BorderSide(color: Colors.white, width: 2),
                right: BorderSide(color: AppTheme.ink, width: 2),
                bottom: BorderSide(color: AppTheme.ink, width: 2),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _onMainCategoryTap(categoryId),
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 160),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.amber : AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.ink,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: isSelected
                  ? AppTheme.brutalShadow(offset: Offset(3, 3))
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _categoryIcon(categoryId),
                  color: AppTheme.ink,
                  size: 20,
                ),
                SizedBox(height: 5),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryChip(
    Restaurant restaurant,
    Map<String, String> subCat,
  ) {
    final subCatId = subCat['id']!;
    final isMainCategorySelected =
        subCatId == _selectedCategory && _selectedSubCategoryTag.isEmpty;
    final isSubTagSelected = subCatId == _selectedSubCategoryTag;
    final isSelected = isMainCategorySelected || isSubTagSelected;
    final label = restaurant.translate(subCat['key']!);
    final mode = AppTheme.activeMode;

    if (mode == AppThemeMode.neonTerminal) {
      return Padding(
        padding: EdgeInsets.only(right: 10),
        child: InkWell(
          onTap: () => _onSubCategoryTap(subCatId),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.18)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.accent : AppTheme.border,
              ),
            ),
            child: Text(
              '--${label.toLowerCase().replaceAll(' ', '-')}',
              style: TextStyle(
                color: isSelected ? AppTheme.accentSoft : AppTheme.ink,
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    if (mode == AppThemeMode.paperReceipt) {
      return Padding(
        padding: EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () => _onSubCategoryTap(subCatId),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accent : AppTheme.surface,
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    if (mode == AppThemeMode.retroOS) {
      return Padding(
        padding: EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () => _onSubCategoryTap(subCatId),
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentSoft : AppTheme.surfaceHigh,
              border: Border(
                top: BorderSide(color: Colors.white, width: 2),
                left: BorderSide(color: Colors.white, width: 2),
                right: BorderSide(color: AppTheme.ink, width: 2),
                bottom: BorderSide(color: AppTheme.ink, width: 2),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _onSubCategoryTap(subCatId),
          borderRadius: BorderRadius.circular(4),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.cyan : AppTheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.ink,
                width: 2,
              ),
              boxShadow: isSelected
                  ? AppTheme.brutalShadow(offset: Offset(3, 3))
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.ink,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuModeHeader(int itemCount) {
    final mode = AppTheme.activeMode;
    final activeFilter = (_selectedSubCategoryTag.isNotEmpty
            ? _selectedSubCategoryTag
            : _selectedCategory)
        .toUpperCase();

    if (mode == AppThemeMode.neonTerminal) {
      return Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.background,
          border: Border(
            bottom: BorderSide(color: AppTheme.cyan.withValues(alpha: 0.42)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '> list menu --filter=$activeFilter',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.cyan,
                  fontFamily: 'Courier',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SizedBox(width: 10),
            Text(
              '$itemCount ITEMS',
              style: TextStyle(
                color: AppTheme.amber,
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (mode == AppThemeMode.paperReceipt) {
      return Container(
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: 18),
        color: AppTheme.surface,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "TODAY'S MENU / $itemCount ITEMS",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.ink,
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Container(
              height: 1,
              color: AppTheme.ink.withValues(alpha: 0.28),
            ),
          ],
        ),
      );
    }

    if (mode == AppThemeMode.retroOS) {
      return Container(
        height: 30,
        margin: EdgeInsets.fromLTRB(8, 8, 8, 0),
        decoration: BoxDecoration(
          color: AppTheme.accent,
          border: Border(
            top: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
            right: BorderSide(color: AppTheme.ink, width: 2),
            bottom: BorderSide(color: AppTheme.ink, width: 2),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(Icons.folder_open, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Menu Browser',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '$itemCount files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildMenuArea(
    Restaurant restaurant,
    List<Food> currentMenu,
    List<Map<String, String>> currentSubCategories,
    double width,
  ) {
    final mode = AppTheme.activeMode;
    final columnCount = _menuColumnCount(width);
    final useScrollableCategories = width < 720;
    final gridPadding = switch (mode) {
      AppThemeMode.neonTerminal => width < 560 ? 12.0 : 18.0,
      AppThemeMode.paperReceipt => width < 560 ? 12.0 : 18.0,
      AppThemeMode.retroOS => width < 560 ? 10.0 : 14.0,
      AppThemeMode.neoBrutalism => width < 560 ? 16.0 : 22.0,
    };
    final gridSpacing = switch (mode) {
      AppThemeMode.neonTerminal => width < 560 ? 12.0 : 16.0,
      AppThemeMode.paperReceipt => width < 560 ? 8.0 : 12.0,
      AppThemeMode.retroOS => width < 560 ? 8.0 : 10.0,
      AppThemeMode.neoBrutalism => width < 560 ? 18.0 : 24.0,
    };
    final categoryHeight = switch (mode) {
      AppThemeMode.neonTerminal => 54.0,
      AppThemeMode.paperReceipt => 48.0,
      AppThemeMode.retroOS => 42.0,
      AppThemeMode.neoBrutalism => 76.0,
    };
    final subCategoryHeight = switch (mode) {
      AppThemeMode.neonTerminal => 44.0,
      AppThemeMode.paperReceipt => 44.0,
      AppThemeMode.retroOS => 42.0,
      AppThemeMode.neoBrutalism => 60.0,
    };
    final categoryBackground = switch (mode) {
      AppThemeMode.neonTerminal => AppTheme.surface,
      AppThemeMode.paperReceipt => AppTheme.surface,
      AppThemeMode.retroOS => AppTheme.surfaceHigh,
      AppThemeMode.neoBrutalism => AppTheme.surfaceHigh,
    };
    final categoryBorderColor =
        mode == AppThemeMode.neonTerminal ? AppTheme.cyan : AppTheme.ink;
    final categoryBorderWidth = switch (mode) {
      AppThemeMode.neonTerminal => 1.0,
      AppThemeMode.paperReceipt => 1.0,
      AppThemeMode.retroOS => 2.0,
      AppThemeMode.neoBrutalism => 3.0,
    };

    return Column(
      children: [
        _buildMenuModeHeader(currentMenu.length),
        Container(
          height: categoryHeight,
          decoration: BoxDecoration(
            color: categoryBackground,
            border: Border(
              bottom: BorderSide(
                color: categoryBorderColor,
                width: categoryBorderWidth,
              ),
            ),
          ),
          child: useScrollableCategories
              ? ListView(
                  scrollDirection: Axis.horizontal,
                  children: _categories.map((cat) {
                    final isSelected = cat['id'] == _selectedCategory;
                    return SizedBox(
                      width: 112,
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
          height: currentSubCategories.isEmpty ? 0 : subCategoryHeight,
          width: double.infinity,
          color: mode == AppThemeMode.retroOS
              ? AppTheme.surfaceHigh
              : AppTheme.background,
          alignment: Alignment.centerLeft,
          child: currentSubCategories.isEmpty
              ? Container()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: mode == AppThemeMode.retroOS ? 10 : 16,
                    vertical: mode == AppThemeMode.neoBrutalism ? 12 : 8,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: currentSubCategories.length,
                  itemBuilder: (context, index) {
                    return _buildSubCategoryChip(
                      restaurant,
                      currentSubCategories[index],
                    );
                  },
                ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppTheme.background),
            child: GridView.builder(
              padding: EdgeInsets.all(gridPadding),
              itemCount: currentMenu.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                childAspectRatio: _menuCardAspectRatio(width),
                crossAxisSpacing: gridSpacing,
                mainAxisSpacing: gridSpacing,
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
          backgroundColor: AppTheme.background,
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

class _CartIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CartIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mode = AppTheme.activeMode;
    final radius = mode == AppThemeMode.neoBrutalism ? 4.0 : 0.0;
    final iconColor =
        mode == AppThemeMode.neonTerminal ? AppTheme.cyan : AppTheme.ink;

    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 28,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ),
      ),
    );
  }
}

class _CartActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CartActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mode = AppTheme.activeMode;
    final radius = mode == AppThemeMode.neoBrutalism ? 4.0 : 0.0;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isRetro = mode == AppThemeMode.retroOS;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final backgroundColor = isTerminal
        ? color.withValues(alpha: 0.12)
        : isPaper
            ? AppTheme.surface
            : color;
    final border = isRetro
        ? Border(
            top: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
            right: BorderSide(color: AppTheme.ink, width: 2),
            bottom: BorderSide(color: AppTheme.ink, width: 2),
          )
        : Border.all(
            color: isTerminal ? AppTheme.cyan : AppTheme.ink,
            width: isTerminal || isPaper ? 1.5 : 2,
          );

    return SizedBox.square(
      dimension: 42,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: mode == AppThemeMode.neoBrutalism
              ? AppTheme.brutalShadow(offset: Offset(3, 3))
              : null,
        ),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: border,
              ),
              child: Icon(
                icon,
                color: isTerminal ? AppTheme.cyan : AppTheme.ink,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
