class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isVeg;
  final int? preparationTime;
  final String? categoryName;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isVeg = false,
    this.preparationTime,
    this.categoryName,
  });
}