// 📱 CUSTOMER APP
// lib/features/home/data/models/menu_item_model.dart

import '../../domain/entities/menu_item.dart';

class MenuItemModel extends MenuItem {
  const MenuItemModel({
    required super.id,
    required super.restaurantId,
    required super.name,
    required super.description,
    required super.price,
    super.discountedPrice,
    super.discountType,
    super.discountValue,
    super.imageUrl,
    super.isVeg,
    super.preparationTime,
    super.categoryName,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json, String restaurantId) {
    final price           = (json['price']           as num).toDouble();
    final discountedPrice = (json['discountedPrice'] as num?)?.toDouble();

    return MenuItemModel(
      id:             json['_id']             as String,
      restaurantId:   restaurantId,
      name:           json['name']            as String,
      description:    json['description']     as String? ?? '',
      price:          price,
      discountedPrice: discountedPrice,
      discountType:   json['discountType']    as String?,
      discountValue:  (json['discountValue']  as num?)?.toDouble(),
      imageUrl:       json['imageUrl']        as String?,
      isVeg:          json['isVeg']           as bool? ?? false,
      preparationTime: (json['preparationTime'] as num?)?.toInt(),
      categoryName:   json['categoryName']    as String?,
    );
  }
}