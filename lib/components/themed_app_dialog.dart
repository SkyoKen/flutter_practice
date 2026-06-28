import 'package:flutter/material.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_tokens.dart';

class ThemedAppDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsetsGeometry contentPadding;

  const ThemedAppDialog({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.actions = const [],
    this.maxWidth = 430,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 8, 18, 16),
  });

  BoxDecoration _decoration(AppThemeTokens theme) {
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

  Widget _buildHeader(AppThemeTokens theme) {
    final mode = AppTheme.activeMode;

    if (mode == AppThemeMode.retroOS) {
      return Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: theme.accent,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
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
            Icon(icon, color: theme.ink, size: 20),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.ink,
                fontFamily: 'Courier',
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: theme.ink.withValues(alpha: 0.28)),
          ],
        ),
      );
    }

    final isTerminal = mode == AppThemeMode.neonTerminal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Row(
        children: [
          Icon(
            isTerminal ? Icons.terminal : icon,
            color: isTerminal ? theme.cyan : theme.ink,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final dialogMaxHeight = MediaQuery.sizeOf(context).height - 48;
    final actionBackground =
        mode == AppThemeMode.retroOS ? theme.surfaceHigh : theme.surface;
    final actionBorderColor = mode == AppThemeMode.neonTerminal
        ? theme.cyan.withValues(alpha: 0.34)
        : theme.border.withValues(alpha: 0.24);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: dialogMaxHeight,
        ),
        child: Container(
          decoration: _decoration(theme),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              Flexible(
                child: SingleChildScrollView(
                  padding: contentPadding,
                  child: child,
                ),
              ),
              if (actions.isNotEmpty)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: actionBackground,
                    border: Border(top: BorderSide(color: actionBorderColor)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                    child: Row(
                      children: [
                        for (var index = 0;
                            index < actions.length;
                            index++) ...[
                          if (index > 0) const SizedBox(width: 10),
                          Expanded(child: actions[index]),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemedDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool primary;
  final bool destructive;

  const ThemedDialogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final isRetro = mode == AppThemeMode.retroOS;
    final borderColor = destructive
        ? theme.danger
        : isTerminal
            ? theme.cyan
            : theme.border;
    final foregroundColor = destructive
        ? theme.danger
        : primary && isTerminal
            ? Colors.black
            : theme.ink;
    final backgroundColor = primary
        ? isTerminal
            ? theme.cyan
            : isPaper
                ? theme.surface
                : isRetro
                    ? theme.surfaceHigh
                    : theme.accent
        : Colors.transparent;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
              fontFamily: isTerminal || isPaper ? 'Courier' : null,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: theme.surfaceHigh,
          disabledForegroundColor: theme.ink.withValues(alpha: 0.45),
          elevation: 0,
          side: BorderSide(
            color: borderColor,
            width: mode == AppThemeMode.neoBrutalism ? 3 : 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class ThemedOptionTile extends StatelessWidget {
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;
  final double minWidth;
  final EdgeInsetsGeometry padding;

  const ThemedOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.minWidth = 118,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final isPaper = mode == AppThemeMode.paperReceipt;
    final isRetro = mode == AppThemeMode.retroOS;
    final foregroundColor = selected && isTerminal ? theme.cyan : theme.ink;
    final backgroundColor = selected
        ? isTerminal
            ? theme.cyan.withValues(alpha: 0.14)
            : isPaper
                ? theme.surface
                : isRetro
                    ? theme.accentSoft
                    : theme.accent
        : isTerminal
            ? Colors.transparent
            : theme.surfaceHigh;
    final borderColor = selected
        ? isTerminal
            ? theme.cyan
            : theme.border
        : isTerminal
            ? theme.cyan.withValues(alpha: 0.42)
            : theme.border.withValues(alpha: 0.72);
    final borderWidth = selected
        ? mode == AppThemeMode.neoBrutalism
            ? 3.0
            : 2.0
        : 1.5;

    final border = isRetro
        ? Border(
            top: BorderSide(color: Colors.white, width: selected ? 2 : 1),
            left: BorderSide(color: Colors.white, width: selected ? 2 : 1),
            right: BorderSide(color: theme.ink, width: selected ? 2 : 1),
            bottom: BorderSide(color: theme.ink, width: selected ? 2 : 1),
          )
        : Border.all(color: borderColor, width: borderWidth);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minWidth: minWidth),
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(
              mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
            ),
            border: border,
            boxShadow: selected && mode == AppThemeMode.neoBrutalism
                ? theme.hardShadow(offset: const Offset(3, 3))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTerminal && selected ? '> $label' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foregroundColor,
                  fontFamily: isTerminal || isPaper ? 'Courier' : null,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 3),
                Text(
                  description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor.withValues(alpha: 0.62),
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
