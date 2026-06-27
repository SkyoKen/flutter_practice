import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cyber_table_order/components/order_history_dialog.dart';
import 'package:cyber_table_order/components/themed_app_dialog.dart';
import 'package:cyber_table_order/pages/menu_page.dart';
import 'package:cyber_table_order/models/restaurant.dart';
import 'package:cyber_table_order/theme/app_theme.dart';
import 'package:cyber_table_order/theme/app_theme_mode.dart';
import 'package:cyber_table_order/theme/theme_controller.dart';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart'; // 确保已添加 qr_flutter 依赖

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _tableId =
      "T-0${Random().nextInt(100).toString().padLeft(2, '0')}";

  static final String _appVersion = "1.3.0";
  static final String _buildNumber = "20250524";

  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _memberIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------------
  // 登录弹窗逻辑
  // ----------------------------------------------------------------------
  void _showLoginDialog(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final isTerminal = mode == AppThemeMode.neonTerminal;
        _memberIdController.clear();
        _passwordController.clear();

        InputDecoration loginInputDecoration({
          required String label,
          required String hint,
          required IconData icon,
        }) {
          return InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon),
            fillColor: theme.surfaceHigh,
            labelStyle: TextStyle(
              color: theme.ink.withValues(alpha: 0.72),
              fontFamily: 'Courier',
            ),
            hintStyle: TextStyle(color: theme.ink.withValues(alpha: 0.36)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
              ),
              borderSide: BorderSide(
                color: isTerminal
                    ? theme.cyan.withValues(alpha: 0.55)
                    : theme.border,
                width: isTerminal ? 1 : 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
              ),
              borderSide: BorderSide(
                color: isTerminal ? theme.cyan : theme.accent,
                width: mode == AppThemeMode.neoBrutalism ? 3 : 2,
              ),
            ),
          );
        }

        final title = switch (mode) {
          AppThemeMode.neonTerminal => 'LOGIN::MEMBER',
          AppThemeMode.paperReceipt => restaurant.translate('member_login'),
          AppThemeMode.retroOS => 'LOGIN.EXE',
          AppThemeMode.neoBrutalism => restaurant.translate('member_login'),
        };

        return ThemedAppDialog(
          title: title,
          icon: Icons.person_pin,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ThemedDialogButton(
              label: restaurant.translate('login'),
              icon: Icons.login,
              primary: true,
              onPressed: () {
                final memberId = _memberIdController.text.trim().isEmpty
                    ? "GC-${Random().nextInt(9999).toString().padLeft(4, '0')}"
                    : _memberIdController.text.trim();
                final userName = "User-$memberId";

                if (memberId.isNotEmpty) {
                  Provider.of<Restaurant>(context, listen: false)
                      .login(memberId, userName);

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: isTerminal ? theme.cyan : theme.accent,
                    content: Text(
                      "${restaurant.translate('access_granted')}: $userName",
                      style: TextStyle(
                        color: isTerminal ? Colors.black : theme.ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    duration: Duration(seconds: 1),
                  ));

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: theme.danger,
                    content: Text(
                      restaurant.translate('login_failed'),
                      style: TextStyle(
                        color: mode == AppThemeMode.neonTerminal
                            ? Colors.black
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    duration: Duration(seconds: 1),
                  ));
                }
              },
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _memberIdController,
                style: TextStyle(color: theme.ink, fontFamily: 'Courier'),
                decoration: loginInputDecoration(
                  label: restaurant.translate('member_id'),
                  hint: 'e.g. 123456',
                  icon: Icons.person,
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: TextStyle(color: theme.ink, fontFamily: 'Courier'),
                decoration: loginInputDecoration(
                  label: restaurant.translate('password'),
                  hint: '******',
                  icon: Icons.lock,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------------
  // QR Code 弹窗逻辑
  // ----------------------------------------------------------------------
  void _showQrCodeDialog(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final qrData = "https://app.tableorder.com/table/$_tableId";
        final title = switch (mode) {
          AppThemeMode.neonTerminal => 'QR::MOBILE_ORDER',
          AppThemeMode.paperReceipt => restaurant.translate('mobile_order'),
          AppThemeMode.retroOS => 'QR_VIEW.EXE',
          AppThemeMode.neoBrutalism => restaurant.translate('mobile_order'),
        };

        return ThemedAppDialog(
          title: title,
          icon: Icons.qr_code_2,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${restaurant.translate('scan_to_order')}\nTable ID: $_tableId",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.72),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 15),
              Container(
                width: 220,
                height: 220,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                  ),
                  border: Border.all(
                    color: mode == AppThemeMode.neonTerminal
                        ? theme.cyan
                        : theme.border,
                    width: mode == AppThemeMode.neoBrutalism ? 3 : 2,
                  ),
                ),
                child: Center(
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (cxt, err) {
                      return Center(
                        child: Text(
                          "QR Error",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: theme.danger),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 15),
              Text(
                mode == AppThemeMode.neonTerminal
                    ? "STREAM $qrData"
                    : "Data Stream: $qrData",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.ink.withValues(alpha: 0.54),
                  fontSize: 10,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 呼叫服务员逻辑
  void _callWaiter(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    final theme = AppTheme.of(context);
    final isTerminal = AppTheme.activeMode == AppThemeMode.neonTerminal;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isTerminal ? theme.cyan : theme.amber,
      content: Row(
        children: [
          Icon(Icons.ring_volume, color: isTerminal ? Colors.black : theme.ink),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "${restaurant.translate('waiter_called')} $_tableId.",
              style: TextStyle(
                color: isTerminal ? Colors.black : theme.ink,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          ),
        ],
      ),
      duration: Duration(seconds: 2),
    ));
  }

  // ----------------------------------------------------------------------
  // 系统设置弹窗
  // ----------------------------------------------------------------------
  void _showSettingsDialog(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        final theme = AppTheme.of(context);
        final mode = AppTheme.activeMode;
        final title = switch (mode) {
          AppThemeMode.neonTerminal => 'CONFIG::SYSTEM',
          AppThemeMode.paperReceipt => restaurant.translate('system_config'),
          AppThemeMode.retroOS => 'CONFIG.EXE',
          AppThemeMode.neoBrutalism => restaurant.translate('system_config'),
        };

        return ThemedAppDialog(
          title: title,
          icon: Icons.settings,
          maxWidth: 560,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('close'),
              primary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingSectionLabel(context, "Language"),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildLanguageOption(context, "EN", "en", restaurant),
                  _buildLanguageOption(context, "中文", "zh", restaurant),
                  _buildLanguageOption(context, "日本語", "ja", restaurant),
                ],
              ),
              SizedBox(height: 18),
              Consumer<ThemeController>(
                builder: (context, themeController, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSettingSectionLabel(context, "Theme"),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: AppThemeMode.values
                            .map((mode) => _buildThemeOption(
                                  context,
                                  mode,
                                  themeController,
                                ))
                            .toList(),
                      ),
                    ],
                  );
                },
              ),
              _buildSettingItem(context, "Notifications", "Enabled"),
              Divider(color: theme.ink.withValues(alpha: 0.2), height: 30),
              Text("ABOUT APP",
                  style: TextStyle(
                      color: theme.accent,
                      fontSize: 12,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Version",
                      style:
                          TextStyle(color: theme.ink.withValues(alpha: 0.64))),
                  Text("v$_appVersion",
                      style:
                          TextStyle(color: theme.ink, fontFamily: 'Courier')),
                ],
              ),
              SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Build Number",
                      style:
                          TextStyle(color: theme.ink.withValues(alpha: 0.64))),
                  Text(_buildNumber,
                      style:
                          TextStyle(color: theme.ink, fontFamily: 'Courier')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingSectionLabel(BuildContext context, String label) {
    final theme = AppTheme.of(context);
    return Text(
      label,
      style: TextStyle(
        color: theme.ink.withValues(alpha: 0.72),
        fontWeight: FontWeight.w800,
        fontFamily: 'Courier',
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String label,
    String code,
    Restaurant restaurant,
  ) {
    return ThemedOptionTile(
      label: label,
      selected: restaurant.languageCode == code,
      minWidth: 72,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onTap: () {
        restaurant.setLanguage(code);
        Navigator.pop(context);
        _showSettingsDialog(context);
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode mode,
    ThemeController controller,
  ) {
    return ThemedOptionTile(
      label: mode.label,
      description: mode.description,
      selected: controller.mode == mode,
      minWidth: 132,
      onTap: () => controller.setMode(mode),
    );
  }

  Widget _buildSettingItem(BuildContext context, String title, String value) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(color: theme.ink.withValues(alpha: 0.72))),
          Text(value,
              style: TextStyle(
                  color: theme.cyan,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 历史记录弹窗 (小票样式)
  // ----------------------------------------------------------------------
  void _showHistoryLog(BuildContext context, Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => OrderHistoryDialog(
        restaurant: restaurant,
        tableId: _tableId,
      ),
    );
  }

  // 会员信息弹窗
  void _buildMemberProfileDialog(BuildContext context, Restaurant restaurant) {
    final theme = AppTheme.of(context);
    final mode = AppTheme.activeMode;
    final isTerminal = mode == AppThemeMode.neonTerminal;
    final title = switch (mode) {
      AppThemeMode.neonTerminal => 'MEMBER::PROFILE',
      AppThemeMode.paperReceipt => restaurant.translate('member_profile'),
      AppThemeMode.retroOS => 'PROFILE.EXE',
      AppThemeMode.neoBrutalism => restaurant.translate('member_profile'),
    };

    Widget buildInfoRow(
        IconData icon, String label, String value, Color color) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: theme.ink.withValues(alpha: 0.62),
                    fontSize: 14,
                    fontFamily: 'Courier')),
            Spacer(),
            Text(value,
                style: TextStyle(
                    color: theme.ink,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier')),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return ThemedAppDialog(
          title: title,
          icon: Icons.person_pin,
          maxWidth: 460,
          actions: [
            ThemedDialogButton(
              label: restaurant.translate('logout'),
              destructive: true,
              onPressed: () {
                restaurant.logout();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: theme.surfaceHigh,
                  content: Text(
                    "Logged out successfully.",
                    style: TextStyle(
                      color: theme.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  duration: Duration(seconds: 1),
                ));
              },
            ),
            ThemedDialogButton(
              label: restaurant.translate('close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInfoRow(Icons.person_pin, restaurant.translate('nickname'),
                  restaurant.getUserName.toUpperCase(), theme.accent),
              buildInfoRow(
                Icons.credit_card,
                restaurant.translate('member_id'),
                restaurant.getMemberId,
                isTerminal ? theme.cyan : theme.accentSoft,
              ),
              Divider(color: theme.ink.withValues(alpha: 0.18), height: 30),
              Text(
                restaurant.translate('coupons'),
                style: TextStyle(
                  color: theme.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Courier',
                ),
              ),
              SizedBox(height: 10),
              ...restaurant.getCoupons.map((coupon) => Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: mode == AppThemeMode.neonTerminal
                            ? theme.background.withValues(alpha: 0.36)
                            : theme.surfaceHigh,
                        borderRadius: BorderRadius.circular(
                          mode == AppThemeMode.neoBrutalism ? theme.radius : 0,
                        ),
                        border: Border.all(
                          color: isTerminal
                              ? theme.cyan.withValues(alpha: 0.5)
                              : theme.border,
                          width: mode == AppThemeMode.neoBrutalism ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.star, color: theme.amber, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              coupon,
                              style: TextStyle(
                                color: theme.ink,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(restaurant.translate('use'),
                                style: TextStyle(
                                    color:
                                        isTerminal ? theme.cyan : theme.accent,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Color _appBarBackgroundColor() {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return AppTheme.surface;
      case AppThemeMode.paperReceipt:
        return AppTheme.surface;
      case AppThemeMode.retroOS:
        return AppTheme.accent;
      case AppThemeMode.neoBrutalism:
        return AppTheme.amber;
    }
  }

  Color _appBarForegroundColor() {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return AppTheme.cyan;
      case AppThemeMode.retroOS:
        return Colors.white;
      case AppThemeMode.paperReceipt:
      case AppThemeMode.neoBrutalism:
        return AppTheme.ink;
    }
  }

  String _appBarTitleText(bool compact) {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return compact ? _tableId : 'TERMINAL // $_tableId';
      case AppThemeMode.paperReceipt:
        return compact ? 'TABLE $_tableId' : 'ORDER SLIP // TABLE $_tableId';
      case AppThemeMode.retroOS:
        return compact ? _tableId : 'Cyber Table Order - $_tableId';
      case AppThemeMode.neoBrutalism:
        return compact ? _tableId : 'ACCESS ID: $_tableId';
    }
  }

  IconData _appBarTitleIcon() {
    switch (AppTheme.activeMode) {
      case AppThemeMode.neonTerminal:
        return Icons.terminal;
      case AppThemeMode.paperReceipt:
        return Icons.receipt_long;
      case AppThemeMode.retroOS:
        return Icons.window;
      case AppThemeMode.neoBrutalism:
        return Icons.qr_code_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        final compactAppBar = MediaQuery.sizeOf(context).width < 700;
        final mode = AppTheme.activeMode;
        final appBarForeground = _appBarForegroundColor();
        final appBarBorderColor =
            mode == AppThemeMode.neonTerminal ? AppTheme.cyan : AppTheme.ink;
        final appBarBorderWidth = switch (mode) {
          AppThemeMode.neonTerminal => 1.0,
          AppThemeMode.paperReceipt => 1.0,
          AppThemeMode.retroOS => 2.0,
          AppThemeMode.neoBrutalism => 3.0,
        };
        final drawerHeaderBackground = _appBarBackgroundColor();
        final drawerHeaderForeground = _appBarForegroundColor();

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: compactAppBar
                ? Text(_appBarTitleText(true),
                    style: TextStyle(
                        color: appBarForeground,
                        fontFamily: 'Courier',
                        fontSize: 13,
                        fontWeight: FontWeight.w900))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _appBarTitleIcon(),
                        color: appBarForeground,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(_appBarTitleText(false),
                          style: TextStyle(
                              color: appBarForeground,
                              fontFamily: 'Courier',
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
            centerTitle: true,
            backgroundColor: _appBarBackgroundColor(),
            elevation: 0,
            shape: Border(
              bottom: BorderSide(
                color: appBarBorderColor,
                width: appBarBorderWidth,
              ),
            ),
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu_book, color: appBarForeground),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: restaurant.translate('system_menu'),
              ),
            ),
            actions: [
              if (compactAppBar)
                IconButton(
                  onPressed: () => _showQrCodeDialog(context),
                  icon: Icon(Icons.qr_code_scanner,
                      color: appBarForeground, size: 20),
                  tooltip: restaurant.translate('mobile_qr'),
                )
              else
                TextButton.icon(
                  onPressed: () => _showQrCodeDialog(context),
                  icon: Icon(Icons.qr_code_scanner,
                      color: appBarForeground, size: 20),
                  label: Text(restaurant.translate('mobile_qr'),
                      style: TextStyle(
                          color: appBarForeground,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              if (compactAppBar)
                IconButton(
                  onPressed: () => _callWaiter(context),
                  icon: Icon(
                    Icons.notifications_active,
                    color: appBarForeground,
                    size: 20,
                  ),
                  tooltip: restaurant.translate('help'),
                )
              else
                TextButton.icon(
                  onPressed: () => _callWaiter(context),
                  icon: Icon(
                    Icons.notifications_active,
                    color: appBarForeground,
                    size: 20,
                  ),
                  label: Text(restaurant.translate('help'),
                      style: TextStyle(
                          color: appBarForeground,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(right: compactAppBar ? 4.0 : 15.0),
                child: IconButton(
                  onPressed: restaurant.getIsLoggedIn
                      ? () => _buildMemberProfileDialog(context, restaurant)
                      : () => _showLoginDialog(context),
                  icon: Icon(
                    Icons.person_pin,
                    color: appBarForeground,
                    size: 28,
                  ),
                  tooltip: restaurant.getIsLoggedIn
                      ? restaurant.translate('member_tooltip_profile')
                      : restaurant.translate('member_tooltip_login'),
                ),
              )
            ],
          ),
          drawer: Drawer(
            backgroundColor: AppTheme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24.0),
                      decoration: BoxDecoration(
                        color: drawerHeaderBackground,
                        border: Border(
                          bottom: BorderSide(
                            color: appBarBorderColor,
                            width: appBarBorderWidth,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            restaurant.getIsLoggedIn
                                ? Icons.verified_user
                                : Icons.no_accounts,
                            size: 40,
                            color: restaurant.getIsLoggedIn
                                ? drawerHeaderForeground
                                : drawerHeaderForeground.withValues(
                                    alpha: 0.58),
                          ),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.getIsLoggedIn
                                    ? restaurant.translate('status_online')
                                    : restaurant.translate('status_offline'),
                                style: TextStyle(
                                  color: restaurant.getIsLoggedIn
                                      ? drawerHeaderForeground
                                      : drawerHeaderForeground.withValues(
                                          alpha: 0.64,
                                        ),
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Text(
                                restaurant.getIsLoggedIn
                                    ? "${restaurant.translate('user')}: ${restaurant.getUserName}"
                                    : restaurant.translate('guest_mode'),
                                style: TextStyle(
                                  color: drawerHeaderForeground,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              if (restaurant.getIsLoggedIn)
                                Text(
                                  "${restaurant.translate('id')}: ${restaurant.getMemberId}",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontFamily: 'Courier',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      leading: Icon(Icons.history, color: AppTheme.ink),
                      title: Text(restaurant.translate('history_log'),
                          style: TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800)),
                      onTap: () {
                        Navigator.pop(context);
                        _showHistoryLog(context, restaurant);
                      },
                    ),
                    Divider(color: Colors.white10),
                    ListTile(
                      leading: Icon(Icons.person_pin,
                          color: restaurant.getIsLoggedIn
                              ? AppTheme.ink
                              : AppTheme.ink.withValues(alpha: 0.62)),
                      title: Text(
                          restaurant.getIsLoggedIn
                              ? restaurant.translate('member_profile')
                              : restaurant.translate('member_login'),
                          style: TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800)),
                      onTap: () {
                        Navigator.pop(context);
                        if (restaurant.getIsLoggedIn) {
                          _buildMemberProfileDialog(context, restaurant);
                        } else {
                          _showLoginDialog(context);
                        }
                      },
                    ),
                    Divider(color: Colors.white10),
                    ListTile(
                      leading: Icon(Icons.settings, color: AppTheme.ink),
                      title: Text(restaurant.translate('system_config'),
                          style: TextStyle(
                              color: AppTheme.ink,
                              fontWeight: FontWeight.w800)),
                      onTap: () {
                        Navigator.pop(context);
                        _showSettingsDialog(context);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding:
                      EdgeInsets.only(left: 25.0, bottom: 25.0, right: 25.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _callWaiter(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: mode == AppThemeMode.neonTerminal
                            ? AppTheme.cyan
                            : mode == AppThemeMode.paperReceipt
                                ? AppTheme.surface
                                : AppTheme.amber,
                        borderRadius: BorderRadius.circular(
                          mode == AppThemeMode.neoBrutalism ? 4 : 0,
                        ),
                        border: Border.all(
                          color: mode == AppThemeMode.neonTerminal
                              ? AppTheme.cyan
                              : AppTheme.ink,
                          width: mode == AppThemeMode.neoBrutalism ? 3 : 2,
                        ),
                        boxShadow: mode == AppThemeMode.neoBrutalism
                            ? AppTheme.brutalShadow()
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          restaurant.translate('call_staff'),
                          style: TextStyle(
                            color: mode == AppThemeMode.paperReceipt
                                ? AppTheme.ink
                                : Colors.black,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Courier',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: MenuPage(),
        );
      },
    );
  }
}
