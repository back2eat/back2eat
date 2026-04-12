class Restaurant {
  final String       id;
  final String       name;
  final double       rating;
  final double       distanceKm;
  final bool         isOpen;
  final int          prepTimeMins;
  final List<String> categories;
  final String?      logoUrl;
  final String?      coverUrl;
  final String?      description;
  final String?      city;
  final double?      latitude;
  final double?      longitude;

  // ── Service flags — what order types the partner has enabled ──────────────
  final bool dineInEnabled;
  final bool takeawayEnabled;
  final bool tableBookingEnabled;

  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.isOpen,
    required this.prepTimeMins,
    required this.categories,
    this.logoUrl,
    this.coverUrl,
    this.description,
    this.city,
    this.latitude,
    this.longitude,
    this.dineInEnabled       = true,
    this.takeawayEnabled     = true,
    this.tableBookingEnabled = false,
  });
}