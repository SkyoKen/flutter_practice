import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

class OrderHistoryDialog extends StatelessWidget {
  final Restaurant restaurant;
  final String? tableId;

  const OrderHistoryDialog({
    super.key,
    required this.restaurant,
    this.tableId,
  });

  double _grandTotal(List<Map<String, dynamic>> history) {
    return history.fold<double>(
      0,
      (sum, order) => sum + (double.tryParse('${order['totalPrice']}') ?? 0),
    );
  }

  String _titleForMode() {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return 'HISTORY::LOG';
      case AppThemeMode.paperReceipt:
        return 'ORDER HISTORY';
      case AppThemeMode.retroOS:
        return 'HISTORY.LOG';
      case AppThemeMode.neoBrutalism:
        return restaurant.translate('history_log');
    }
  }

  BoxDecoration _dialogDecoration(AppThemeTokens theme) {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.radius),
          border: Border.all(color: theme.cyan, width: 1.5),
          boxShadow: theme.softGlow(theme.cyan),
        );
      case AppThemeMode.paperReceipt:
        return BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.radius),
          border: Border.all(color: theme.border.withValues(alpha: 0.55)),
        );
      case AppThemeMode.retroOS:
        return BoxDecoration(
          color: theme.surfaceHigh,
          border: Border(
            top: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
            right: BorderSide(color: theme.ink, width: 2),
            bottom: BorderSide(color: theme.ink, width: 2),
          ),
        );
      case AppThemeMode.neoBrutalism:
        return BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(theme.radius),
          border: Border.all(
            color: theme.border,
            width: theme.strongBorderWidth,
          ),
          boxShadow: theme.hardShadow(offset: const Offset(5, 5)),
        );
    }
  }

  Widget _buildHeader(
    BuildContext context,
    AppThemeTokens theme,
    List<Map<String, dynamic>> history,
    double grandTotal,
  ) {
    final mode = AppTheme.activeMode;
    final tableLine = tableId == null ? null : 'TABLE: $tableId';

    if (mode == AppThemeMode.retroOS) {
      return Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: theme.accent,
        child: Row(
          children: [
            const Icon(Icons.article, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _titleForMode(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              tableId == null ? '${history.length} records' : '$tableId',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (mode == AppThemeMode.paperReceipt) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _titleForMode(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.ink,
                fontFamily: 'Courier',
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (tableLine != null) ...[
              const SizedBox(height: 4),
              Text(
                tableLine,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.62),
                  fontFamily: 'Courier',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(height: 1, color: theme.ink.withValues(alpha: 0.28)),
          ],
        ),
      );
    }

    final isTerminal = mode == AppThemeMode.neonTerminal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isTerminal ? Icons.terminal : Icons.history,
                color: isTerminal ? theme.cyan : theme.ink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _titleForMode(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    fontSize: isTerminal ? 14 : 18,
                  ),
                ),
              ),
              Text(
                isTerminal
                    ? 'TTL ¥${grandTotal.toStringAsFixed(2)}'
                    : '¥${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isTerminal ? theme.amber : theme.ink,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                  fontSize: isTerminal ? 13 : 17,
                ),
              ),
            ],
          ),
          if (tableLine != null) ...[
            const SizedBox(height: 6),
            Text(
              tableLine,
              style: TextStyle(
                color: theme.ink.withValues(alpha: isTerminal ? 0.62 : 0.56),
                fontFamily: 'Courier',
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemRow(Food food, int quantity, AppThemeTokens theme) {
    final itemPrice = (double.tryParse(food.price) ?? 0) * quantity;
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isPaper ? 5 : 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTerminal ? '> ${food.name}' : food.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: theme.ink.withValues(alpha: isTerminal ? 0.9 : 0.76),
                fontFamily: isTerminal || isPaper ? 'Courier' : null,
                fontSize: 12,
                fontWeight: isTerminal ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'x$quantity',
            style: TextStyle(
              color: isTerminal ? theme.cyan : theme.ink.withValues(alpha: 0.7),
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 72,
            child: Text(
              '¥${itemPrice.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isTerminal ? theme.accentSoft : theme.ink,
                fontFamily: 'Courier',
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(
    Map<String, dynamic> order,
    int displayNumber,
    AppThemeTokens theme,
  ) {
    final timestamp =
        order['timestamp'] is DateTime ? order['timestamp'] as DateTime : null;
    final formattedTime = timestamp == null
        ? '--:--:--'
        : DateFormat('HH:mm:ss').format(timestamp);
    final items = Map<Food, int>.from(order['items'] as Map);
    final totalPrice = '${order['totalPrice']}';
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final isRetro = mode == AppThemeMode.retroOS;

    final header = Row(
      children: [
        Expanded(
          child: Text(
            isTerminal
                ? 'LOG[$displayNumber] $formattedTime'
                : '#$displayNumber  $formattedTime',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isTerminal ? theme.cyan : theme.ink,
              fontFamily: 'Courier',
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${restaurant.translate('sub')}: ¥$totalPrice',
          style: TextStyle(
            color: isTerminal ? theme.amber : theme.ink,
            fontFamily: 'Courier',
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(height: isPaper ? 7 : 8),
        if (isPaper)
          Container(height: 1, color: theme.ink.withValues(alpha: 0.18))
        else
          Divider(
            color: isTerminal
                ? theme.cyan.withValues(alpha: 0.18)
                : theme.ink.withValues(alpha: 0.18),
            height: 1,
          ),
        SizedBox(height: isPaper ? 6 : 8),
        ...items.entries.map((entry) => _buildItemRow(
              entry.key,
              entry.value,
              theme,
            )),
      ],
    );

    if (isPaper) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: body,
      );
    }

    if (isTerminal) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.background.withValues(alpha: 0.42),
          border: Border.all(color: theme.cyan.withValues(alpha: 0.46)),
        ),
        child: body,
      );
    }

    if (isRetro) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.surface,
          border: Border(
            top: BorderSide(color: Colors.white, width: 2),
            left: BorderSide(color: Colors.white, width: 2),
            right: BorderSide(color: theme.ink, width: 2),
            bottom: BorderSide(color: theme.ink, width: 2),
          ),
        ),
        child: body,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(theme.radius),
        border: Border.all(color: theme.border, width: 2),
        boxShadow: theme.hardShadow(offset: const Offset(3, 3)),
      ),
      child: body,
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppThemeTokens theme,
    double grandTotal,
  ) {
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final isRetro = mode == AppThemeMode.retroOS;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, isRetro ? 10 : 8, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            color: isTerminal
                ? theme.cyan.withValues(alpha: 0.32)
                : theme.ink.withValues(alpha: isPaper ? 0.34 : 0.18),
            thickness: isPaper || mode == AppThemeMode.neoBrutalism ? 2 : 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  isTerminal ? 'TOTAL::' : restaurant.translate('total'),
                  style: TextStyle(
                    color: isTerminal ? theme.cyan : theme.ink,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w900,
                    fontSize: isPaper ? 16 : 14,
                  ),
                ),
              ),
              Text(
                '¥${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isTerminal ? theme.amber : theme.ink,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w900,
                  fontSize: isPaper ? 22 : 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: isTerminal
                    ? theme.cyan
                    : isPaper
                        ? theme.surface
                        : isRetro
                            ? theme.surfaceHigh
                            : theme.accent,
                foregroundColor: isTerminal ? Colors.black : theme.ink,
                side: BorderSide(
                  color: isTerminal ? theme.cyan : theme.border,
                  width: mode == AppThemeMode.neoBrutalism ? 3 : 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                isTerminal ? 'CLOSE_LOG' : restaurant.translate('close'),
                style: TextStyle(
                  fontFamily: isTerminal || isPaper ? 'Courier' : null,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppThemeTokens theme) {
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;
    return Center(
      child: Text(
        isTerminal ? 'NO HISTORY FOUND' : restaurant.translate('no_history'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: theme.ink.withValues(alpha: 0.58),
          fontFamily: 'Courier',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final history = restaurant.getOrderHistory();
    final grandTotal = _grandTotal(history);
    final maxHeight = (MediaQuery.sizeOf(context).height - 48).clamp(
      280.0,
      620.0,
    );
    final mode = AppTheme.activeMode;
    final contentPadding = switch (mode) {
      AppThemeMode.paperReceipt => const EdgeInsets.symmetric(horizontal: 22),
      AppThemeMode.retroOS => const EdgeInsets.fromLTRB(10, 10, 10, 0),
      AppThemeMode.neonTerminal => const EdgeInsets.fromLTRB(18, 8, 18, 0),
      AppThemeMode.neoBrutalism => const EdgeInsets.fromLTRB(18, 8, 18, 0),
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 540, maxHeight: maxHeight),
        child: Container(
          decoration: _dialogDecoration(theme),
          child: Column(
            children: [
              _buildHeader(context, theme, history, grandTotal),
              Expanded(
                child: Padding(
                  padding: contentPadding,
                  child: history.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            return _buildOrderTile(
                              history[index],
                              history.length - index,
                              theme,
                            );
                          },
                        ),
                ),
              ),
              _buildFooter(context, theme, grandTotal),
            ],
          ),
        ),
      ),
    );
  }
}
