class BranchEntity {
  final String  id;
  final String  name;
  final String  address;
  final String  city;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final bool    isOpen;
  final String  openTime;
  final String  closeTime;

  const BranchEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceKm,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  factory BranchEntity.fromJson(Map<String, dynamic> j) => BranchEntity(
    id:          j['_id']        as String,
    name:        j['name']       as String,
    address:     j['address']    as String,
    city:        j['city']       as String,
    phone:       j['phone']      as String?,
    latitude:    (j['latitude']  as num?)?.toDouble(),
    longitude:   (j['longitude'] as num?)?.toDouble(),
    distanceKm:  (j['distanceKm'] as num?)?.toDouble(),
    isOpen:      j['isOpen']     as bool? ?? false,
    openTime:    j['openTime']   as String? ?? '09:00',
    closeTime:   j['closeTime']  as String? ?? '22:00',
  );

  String get distanceLabel {
    if (distanceKm != null && distanceKm! > 0) {
      return '${distanceKm!.toStringAsFixed(1)} km';
    }
    return city;
  }
}