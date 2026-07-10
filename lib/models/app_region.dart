/// Major regions supported at registration (English UI only).
enum AppRegion {
  india,
  unitedStates,
  unitedKingdom,
  europe,
  international;

  String get storageKey => name;

  String get label {
    switch (this) {
      case AppRegion.india:
        return 'India';
      case AppRegion.unitedStates:
        return 'United States';
      case AppRegion.unitedKingdom:
        return 'United Kingdom';
      case AppRegion.europe:
        return 'Europe';
      case AppRegion.international:
        return 'International / Other';
    }
  }

  static AppRegion fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return AppRegion.india;
    for (final region in AppRegion.values) {
      if (region.name == raw || region.storageKey == raw) return region;
    }
    return AppRegion.international;
  }

  static AppRegion inferFromCurrency(String? currency) {
    switch (currency?.toUpperCase()) {
      case 'INR':
        return AppRegion.india;
      case 'USD':
        return AppRegion.unitedStates;
      case 'GBP':
        return AppRegion.unitedKingdom;
      case 'EUR':
        return AppRegion.europe;
      default:
        return AppRegion.international;
    }
  }
}
