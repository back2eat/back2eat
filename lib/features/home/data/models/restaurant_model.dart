import '../../domain/entities/restaurant.dart';

class RestaurantModel extends Restaurant {
  const RestaurantModel({
    required super.id,
    required super.name,
    required super.rating,
    required super.distanceKm,
    required super.isOpen,
    required super.prepTimeMins,
    required super.categories,
    super.logoUrl,
    super.coverUrl,
    super.description,
    super.city,
    super.latitude,
    super.longitude,
    super.dineInEnabled,
    super.takeawayEnabled,
    super.tableBookingEnabled,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    final cuisine = (json['cuisine'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ??
        [];

    return RestaurantModel(
      id:                   json['_id']                as String,
      name:                 json['name']               as String,
      rating:               (json['rating']            as num?)?.toDouble()  ?? 0.0,
      distanceKm:           (json['distanceKm']        as num?)?.toDouble()  ?? 0.0,
      isOpen:               json['isOpen']             as bool?              ?? true,
      prepTimeMins:         (json['avgPrepTimeMins']   as num?)?.toInt()     ??
          (json['prepTimeMins']      as num?)?.toInt()     ?? 20,
      categories:           cuisine,
      logoUrl:              json['logoUrl']             as String?,
      coverUrl:             json['coverUrl']            as String?,
      description:          json['description']         as String?,
      city:                 json['city']                as String?,
      latitude:             (json['latitude']           as num?)?.toDouble(),
      longitude:            (json['longitude']          as num?)?.toDouble(),
      // Service flags — default true/false if backend doesn't send them yet
      dineInEnabled:        json['dineInEnabled']       as bool? ?? true,
      takeawayEnabled:      json['takeawayEnabled']     as bool? ?? true,
      tableBookingEnabled:  json['tableBookingEnabled'] as bool? ?? false,
    );
  }
}