import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

class FoodTile extends StatelessWidget {
  final Food food;

  const FoodTile({super.key, required this.food});

  IconData get _foodIcon {
    if (food.tags.contains('fish') || food.tags.contains('tuna')) {
      return Icons.set_meal;
    }
    if (food.tags.contains('meat') || food.tags.contains('beef')) {
      return Icons.dinner_dining;
    }
    if (food.tags.contains('beer')) return Icons.local_drink;
    if (food.tags.contains('bento')) return Icons.rice_bowl;
    if (food.tags.contains('side')) return Icons.eco;
    return Icons.ramen_dining;
  }

  Color _accentColor(AppThemeTokens theme) {
    if (food.tags.contains('fish') || food.tags.contains('tuna')) {
      return theme.cyan;
    }
    if (food.tags.contains('beer')) return theme.amber;
    return theme.accentSoft;
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color foregroundColor,
    required Color backgroundColor,
    required AppThemeTokens theme,
    required VoidCallback onTap,
  }) {
    return SizedBox.square(
      dimension: 34,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(theme.radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(theme.radius),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.border, width: 2),
              borderRadius: BorderRadius.circular(theme.radius),
            ),
            child: Icon(icon, color: foregroundColor, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualHeader(AppThemeTokens theme) {
    final accentColor = _accentColor(theme);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(theme.radius)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: accentColor,
          border: Border(
            bottom: BorderSide(
              color: theme.border,
              width: theme.strongBorderWidth,
            ),
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.radius),
                  border: Border.all(
                    color: theme.border,
                    width: theme.strongBorderWidth,
                  ),
                  boxShadow: theme.hardShadow(
                    offset: const Offset(3, 3),
                  ),
                ),
                child: Icon(
                  _foodIcon,
                  size: 34,
                  color: theme.useHardShadow ? theme.ink : accentColor,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.radius),
                  border: Border.all(color: theme.border, width: 2),
                ),
                child: Text(
                  '¥${food.price}',
                  style: TextStyle(
                    color: theme.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTile(
    Restaurant restaurant,
    AppThemeTokens theme,
    int quantity,
    bool isInCart,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border(
          left: BorderSide(color: theme.accent, width: 5),
          top: BorderSide(color: theme.border, width: 1.2),
          right: BorderSide(color: theme.border, width: 1.2),
          bottom: BorderSide(color: theme.border, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.surfaceHigh,
                  border: Border.all(color: theme.border),
                ),
                child: Icon(_foodIcon, color: theme.ink, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      food.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.ink.withValues(alpha: 0.66),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '¥${food.price}',
                style: TextStyle(
                  color: theme.ink,
                  fontFamily: 'Courier',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: theme.border.withValues(alpha: 0.2),
          ),
          Row(
            children: [
              Text(
                'RATING ${food.rating}',
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.72),
                  fontFamily: 'Courier',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isInCart) ...[
                _buildControlButton(
                  icon: Icons.remove,
                  foregroundColor: theme.ink,
                  backgroundColor: theme.surfaceHigh,
                  theme: theme,
                  onTap: () => restaurant.removeFromCart(food),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              _buildControlButton(
                icon: isInCart ? Icons.add : Icons.add_shopping_cart,
                foregroundColor: Colors.white,
                backgroundColor: theme.accent,
                theme: theme,
                onTap: () => restaurant.addToCart(food),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetroTile(
    Restaurant restaurant,
    AppThemeTokens theme,
    int quantity,
    bool isInCart,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.border, width: 2),
        boxShadow: theme.hardShadow(offset: const Offset(3, 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 30,
            color: theme.accent,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    food.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '¥${food.price}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Icon(_foodIcon, color: theme.ink, size: 44),
                  const SizedBox(height: 10),
                  Text(
                    food.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.ink,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.amber,
                          border: Border.all(color: theme.border),
                        ),
                        child: Text(
                          '★ ${food.rating}',
                          style: TextStyle(
                            color: theme.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isInCart) ...[
                        _buildControlButton(
                          icon: Icons.remove,
                          foregroundColor: theme.ink,
                          backgroundColor: theme.surfaceHigh,
                          theme: theme,
                          onTap: () => restaurant.removeFromCart(food),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '$quantity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      _buildControlButton(
                        icon: isInCart ? Icons.add : Icons.add_shopping_cart,
                        foregroundColor: Colors.white,
                        backgroundColor: theme.accentSoft,
                        theme: theme,
                        onTap: () => restaurant.addToCart(food),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalTile(
    Restaurant restaurant,
    AppThemeTokens theme,
    int quantity,
    bool isInCart,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.cyan.withValues(alpha: 0.7), width: 1),
        boxShadow: theme.softGlow(theme.cyan),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_foodIcon, color: theme.cyan, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ITEM://${food.id.toString().padLeft(3, '0')}',
                  style: TextStyle(
                    color: theme.cyan,
                    fontFamily: 'Courier',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '¥${food.price}',
                style: TextStyle(
                  color: theme.accentSoft,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            food.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.ink,
              fontWeight: FontWeight.w900,
              fontSize: 17,
              fontFamily: 'Courier',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            food.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.ink.withValues(alpha: 0.62),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                '> RATE ${food.rating}',
                style: TextStyle(
                  color: theme.amber,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (isInCart) ...[
                _buildControlButton(
                  icon: Icons.remove,
                  foregroundColor: theme.ink,
                  backgroundColor: theme.surfaceHigh,
                  theme: theme,
                  onTap: () => restaurant.removeFromCart(food),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              _buildControlButton(
                icon: isInCart ? Icons.add : Icons.add_shopping_cart,
                foregroundColor: Colors.black,
                backgroundColor: theme.cyan,
                theme: theme,
                onTap: () => restaurant.addToCart(food),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听 Restaurant 状态的变化，并获取当前菜品的数量
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final theme = AppTheme.of(context);
        final accentColor = _accentColor(theme);
        final int quantity = restaurant.getFoodQuantity(food);
        final bool isInCart = quantity > 0;

        switch (AppTheme.activeMode) {
          case AppThemeMode.neonTerminal:
            return _buildTerminalTile(restaurant, theme, quantity, isInCart);
          case AppThemeMode.paperReceipt:
            return _buildReceiptTile(restaurant, theme, quantity, isInCart);
          case AppThemeMode.retroOS:
            return _buildRetroTile(restaurant, theme, quantity, isInCart);
          case AppThemeMode.neoBrutalism:
            break;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(theme.radius),
            border: Border.all(
              color: theme.border,
              width: isInCart
                  ? theme.strongBorderWidth + 1
                  : theme.strongBorderWidth,
            ),
            boxShadow: theme.useHardShadow
                ? theme.hardShadow()
                : theme.softGlow(accentColor),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(theme.radius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildVisualHeader(theme)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        food.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: theme.ink,
                          fontFamily: 'Courier',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        food.description,
                        style: TextStyle(
                          color: theme.ink.withValues(alpha: 0.68),
                          fontSize: 12,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.amber,
                              borderRadius: BorderRadius.circular(theme.radius),
                              border: Border.all(color: theme.border, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: theme.ink, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  food.rating.toString(),
                                  style: TextStyle(
                                    color: theme.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (isInCart) ...[
                            _buildControlButton(
                              icon: Icons.remove,
                              foregroundColor: theme.ink,
                              backgroundColor: theme.surfaceHigh,
                              theme: theme,
                              onTap: () => restaurant.removeFromCart(food),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                quantity.toString(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          _buildControlButton(
                            icon:
                                isInCart ? Icons.add : Icons.add_shopping_cart,
                            foregroundColor:
                                theme.useHardShadow ? theme.ink : Colors.black,
                            backgroundColor:
                                isInCart ? theme.accent : accentColor,
                            theme: theme,
                            onTap: () => restaurant.addToCart(food),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
