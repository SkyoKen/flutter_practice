import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/pages/menu_page.dart';
import 'package:test_app/models/restaurant.dart';
import 'package:test_app/models/food.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart'; // 确保已添加 qr_flutter 依赖

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _tableId =
      "T-0" + Random().nextInt(100).toString().padLeft(2, '0');

  static const String _appVersion = "1.3.0";
  static const String _buildNumber = "20250524";

  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ----------------------------------------------------------------------
  // 登录弹窗逻辑
  // ----------------------------------------------------------------------
  void _showLoginDialog(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) {
        _memberIdController.clear();
        _passwordController.clear();

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.deepOrangeAccent, width: 2),
          ),
          title: Text(
              "${restaurant.translate('member_login')} // ${restaurant.translate('login')}",
              style: const TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _memberIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: restaurant.translate('member_id'),
                    labelStyle: TextStyle(
                        color: Colors.deepOrangeAccent.withOpacity(0.8),
                        fontFamily: 'Courier'),
                    hintText: 'e.g. 123456',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.person, color: Colors.deepOrange),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrangeAccent),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.blueAccent, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: restaurant.translate('password'),
                    labelStyle: TextStyle(
                        color: Colors.deepOrangeAccent.withOpacity(0.8),
                        fontFamily: 'Courier'),
                    hintText: '******',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    prefixIcon:
                        const Icon(Icons.lock, color: Colors.deepOrange),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrangeAccent),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.deepOrangeAccent, width: 2),
                    ),
                  ),
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
            TextButton(
              onPressed: () {
                final memberId = _memberIdController.text.trim().isEmpty
                    ? "GC-${Random().nextInt(9999).toString().padLeft(4, '0')}"
                    : _memberIdController.text.trim();
                final userName = "User-$memberId";

                if (memberId.isNotEmpty) {
                  Provider.of<Restaurant>(context, listen: false)
                      .login(memberId, userName);

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.deepOrange,
                    content: Text(
                        "${restaurant.translate('access_granted')}: $userName",
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    duration: const Duration(seconds: 1),
                  ));

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(restaurant.translate('login_failed')),
                    duration: const Duration(seconds: 1),
                  ));
                }
              },
              child: Text(restaurant.translate('login'),
                  style: const TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontWeight: FontWeight.bold)),
            ),
          ],
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
        final qrData = "https://app.tableorder.com/table/$_tableId";

        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          title: Text(restaurant.translate('mobile_order'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${restaurant.translate('scan_to_order')}\nTable ID: $_tableId",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 15),
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (cxt, err) {
                        return const Center(
                          child: Text(
                            "QR Error",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Data Stream: $qrData",
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontFamily: 'Courier'),
                ),
              ],
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

  // 呼叫服务员逻辑
  void _callWaiter(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.blueGrey,
      content: Row(
        children: [
          const Icon(Icons.ring_volume, color: Colors.black),
          const SizedBox(width: 10),
          Text("${restaurant.translate('waiter_called')} $_tableId.",
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
        ],
      ),
      duration: const Duration(seconds: 2),
    ));
  }

  // ----------------------------------------------------------------------
  // 系统设置弹窗
  // ----------------------------------------------------------------------
  void _showSettingsDialog(BuildContext context) {
    final restaurant = Provider.of<Restaurant>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.grey, width: 1),
        ),
        title: Text(restaurant.translate('system_config'),
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Language",
                      style: TextStyle(color: Colors.white70)),
                  Row(
                    children: [
                      _buildLanguageButton(context, "EN", "en", restaurant),
                      const SizedBox(width: 8),
                      _buildLanguageButton(context, "中文", "zh", restaurant),
                      const SizedBox(width: 8),
                      _buildLanguageButton(context, "日本語", "ja", restaurant),
                    ],
                  ),
                ],
              ),
            ),
            _buildSettingItem("Theme", "Cyberpunk Dark"),
            _buildSettingItem("Notifications", "Enabled"),
            const Divider(color: Colors.white24, height: 30),
            const Text("ABOUT APP",
                style: TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontSize: 12,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Version", style: TextStyle(color: Colors.grey)),
                Text("v$_appVersion",
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Courier')),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Build Number",
                    style: TextStyle(color: Colors.grey)),
                Text(_buildNumber,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Courier')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(restaurant.translate('close'),
                style: const TextStyle(color: Colors.deepOrangeAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(
      BuildContext context, String label, String code, Restaurant restaurant) {
    final isSelected = restaurant.languageCode == code;
    return GestureDetector(
      onTap: () {
        restaurant.setLanguage(code);
        Navigator.pop(context);
        _showSettingsDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _buildSettingItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Text(value,
              style: const TextStyle(
                  color: Colors.blueAccent,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 历史记录行构建 (修复：使用 FittedBox 强制不换行)
  // ----------------------------------------------------------------------
  Widget _buildOrderItemRow(Food food, int quantity) {
    double itemPrice = (double.tryParse(food.price) ?? 0.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 菜品名称
          Expanded(
            child: Text(
              food.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Courier',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 2. 数量
          SizedBox(
            width: 40,
            child: Text('x$quantity',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier')),
          ),

          // 3. 金额 (修复核心：使用 FittedBox)
          SizedBox(
            width: 100, // 给定固定宽度
            child: FittedBox(
              fit: BoxFit.scaleDown, // 核心：内容太长时自动缩小，绝不换行
              alignment: Alignment.centerRight, // 保持右对齐
              child: Text(
                '¥${(itemPrice * quantity).toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13, // 初始字体大小
                    fontFamily: 'Courier'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // 历史记录弹窗 (小票样式)
  // ----------------------------------------------------------------------
  void _showHistoryLog(BuildContext context, Restaurant restaurant) {
    final List<Map<String, dynamic>> history = restaurant.getOrderHistory();
    double grandTotal = 0.0;
    for (var order in history) {
      grandTotal += double.tryParse(order['totalPrice']!) ?? 0.0;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: Colors.white24, width: 1),
          ),
          title: Column(
            children: [
              Text(restaurant.translate('history_log'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                    letterSpacing: 2.0,
                  )),
              const SizedBox(height: 5),
              Text("TABLE: $_tableId",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'Courier',
                  )),
              const Divider(color: Colors.white24, thickness: 1),
            ],
          ),
          content: SizedBox(
            width: 380,
            height: 500,
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
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '#${history.length - index}  $formattedTime',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Courier')),
                                Text(
                                    '${restaurant.translate('sub')}: ¥$totalPrice',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        fontFamily: 'Courier')),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "-----------------------------------------",
                              style: TextStyle(
                                  color: Colors.white12, fontFamily: 'Courier'),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                            ...items.entries
                                .map((entry) =>
                                    _buildOrderItemRow(entry.key, entry.value))
                                .toList(),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            Column(
              children: [
                const Divider(color: Colors.white, thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        restaurant.translate('total'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Courier',
                        ),
                      ),
                      Text(
                        '¥${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                    child: Text(restaurant.translate('close'),
                        style: const TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  // 会员信息弹窗
  void _buildMemberProfileDialog(BuildContext context, Restaurant restaurant) {
    Widget _buildInfoRow(
        IconData icon, String label, String value, Color color) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontFamily: 'Courier')),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier')),
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
            side: const BorderSide(color: Colors.deepOrangeAccent, width: 2),
          ),
          title: Text(
              "${restaurant.translate('member_profile')} // ${restaurant.translate('member_profile')}", // Duplicated for style
              style: const TextStyle(
                  color: Colors.deepOrangeAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                    Icons.person_pin,
                    restaurant.translate('nickname'),
                    restaurant.getUserName.toUpperCase(),
                    Colors.deepOrange),
                _buildInfoRow(
                    Icons.credit_card,
                    restaurant.translate('member_id'),
                    restaurant.getMemberId,
                    Colors.deepOrangeAccent),
                const Divider(color: Colors.white10, height: 30),
                Text(
                  restaurant.translate('coupons'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Courier'),
                ),
                const SizedBox(height: 10),
                ...restaurant.getCoupons
                    .map((coupon) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.deepOrange.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(coupon,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Courier')),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(restaurant.translate('use'),
                                      style: const TextStyle(
                                          color: Colors.deepOrangeAccent,
                                          fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                restaurant.logout();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  backgroundColor: Colors.blueGrey,
                  content: Text("Logged out successfully.",
                      style: TextStyle(color: Colors.black)),
                  duration: Duration(seconds: 1),
                ));
              },
              child: Text(restaurant.translate('logout'),
                  style: const TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(restaurant.translate('close'),
                  style: const TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Restaurant>(
      builder: (context, restaurant, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_2,
                    color: Colors.deepOrangeAccent, size: 20),
                const SizedBox(width: 8),
                Text("ACCESS ID: $_tableId",
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 4,
            shadowColor: Colors.deepOrange.withOpacity(0.5),
            leading: Builder(
              builder: (context) => IconButton(
                icon:
                    const Icon(Icons.menu_book, color: Colors.deepOrangeAccent),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: restaurant.translate('system_menu'),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => _showQrCodeDialog(context),
                icon: const Icon(Icons.qr_code_scanner,
                    color: Colors.blueAccent, size: 20),
                label: Text(restaurant.translate('mobile_qr'),
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              TextButton.icon(
                onPressed: () => _callWaiter(context),
                icon: const Icon(
                  Icons.notifications_active,
                  color: Colors.amberAccent,
                  size: 20,
                ),
                label: Text(restaurant.translate('help'),
                    style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: IconButton(
                  onPressed: restaurant.getIsLoggedIn
                      ? () => _buildMemberProfileDialog(context, restaurant)
                      : () => _showLoginDialog(context),
                  icon: const Icon(
                    Icons.person_pin,
                    color: Colors.deepOrangeAccent,
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
            backgroundColor: const Color(0xFF1E1E1E),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.deepOrange.withOpacity(0.5),
                                width: 1.0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            restaurant.getIsLoggedIn
                                ? Icons.verified_user
                                : Icons.no_accounts,
                            size: 40,
                            color: restaurant.getIsLoggedIn
                                ? Colors.deepOrangeAccent
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant.getIsLoggedIn
                                    ? restaurant.translate('status_online')
                                    : restaurant.translate('status_offline'),
                                style: TextStyle(
                                  color: restaurant.getIsLoggedIn
                                      ? Colors.deepOrange
                                      : Colors.grey[700],
                                  fontSize: 12,
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Text(
                                restaurant.getIsLoggedIn
                                    ? "${restaurant.translate('user')}: ${restaurant.getUserName}"
                                    : restaurant.translate('guest_mode'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.white),
                      title: Text(restaurant.translate('history_log'),
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _showHistoryLog(context, restaurant);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: Icon(Icons.person_pin,
                          color: restaurant.getIsLoggedIn
                              ? Colors.deepOrangeAccent
                              : Colors.white54),
                      title: Text(
                          restaurant.getIsLoggedIn
                              ? restaurant.translate('member_profile')
                              : restaurant.translate('member_login'),
                          style: TextStyle(
                              color: restaurant.getIsLoggedIn
                                  ? Colors.deepOrangeAccent
                                  : Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        if (restaurant.getIsLoggedIn) {
                          _buildMemberProfileDialog(context, restaurant);
                        } else {
                          _showLoginDialog(context);
                        }
                      },
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: Text(restaurant.translate('system_config'),
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _showSettingsDialog(context);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 25.0, bottom: 25.0, right: 25.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _callWaiter(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          restaurant.translate('call_staff'),
                          style: const TextStyle(
                            color: Colors.black,
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
          body: const MenuPage(),
        );
      },
    );
  }
}
