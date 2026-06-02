// 📱 CUSTOMER APP
// lib/features/home/domain/entities/menu_item.dart

class MenuItem {
  final String  id;
  final String  restaurantId;
  final String  name;
  final String  description;
  final double  price;              // original price
  final double? discountedPrice;    // final price after discount (null = no discount)
  final String? discountType;       // 'FLAT' | 'PERCENT' | null
  final double? discountValue;      // discount amount or percent
  final String? imageUrl;
  final bool    isVeg;
  final int?    preparationTime;
  final String? categoryName;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.discountedPrice,
    this.discountType,
    this.discountValue,
    this.imageUrl,
    this.isVeg = false,
    this.preparationTime,
    this.categoryName,
  });

  // The effective price customer pays (discounted if available)
  double get effectivePrice => discountedPrice ?? price;

  // Whether this item has an active discount
  bool get hasDiscount =>
      discountedPrice != null && discountedPrice! < price;

  // Discount label e.g. "20% off" or "₹50 off"
  String get discountLabel {
    if (!hasDiscount) return '';
    if (discountType == 'PERCENT' && discountValue != null) {
      return '${discountValue!.toStringAsFixed(0)}% off';
    }
    if (discountType == 'FLAT' && discountValue != null) {
      return '₹${discountValue!.toStringAsFixed(0)} off';
    }
    return '₹${(price - effectivePrice).toStringAsFixed(0)} off';
  }
}