import '../../domain/entities/menu_item.dart';

class MenuItemModel extends MenuItem {
  const MenuItemModel({
    required super.id,
    required super.restaurantId,
    required super.name,
    required super.description,
    required super.price,
    super.imageUrl,
    super.isVeg,
    super.preparationTime,
    super.categoryName,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json, String restaurantId) {
    return MenuItemModel(
      id: json['_id'] as String,
      restaurantId: restaurantId,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      isVeg: json['isVeg'] as bool? ?? false,
      preparationTime: (json['preparationTime'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
    );
  }
}