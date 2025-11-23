class Food {
  final int id; // 新增：唯一 ID
  final String name; // 菜名
  final String price; // 价格
  final String imagePath; // 图片路径 (这里我们暂时用 asset 路径字符串，实际中可能用 IconData 或网络图)
  final String description; // 描述
  final double rating; // 评分
  final List<String> tags; // 新增：用于菜单筛选的标签列表

  Food({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.description,
    required this.rating,
    required this.tags, // 添加到构造函数
  });

  // 方便 Map 查找的重载，确保 ID 相同的 Food 视为同一键
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
