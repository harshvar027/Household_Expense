class CategoryUtils {
  static const Set<String> savingsCategories = {
    'Mutual Funds',
    'Investment',
  };

  static bool isSavingsCategory(String category) {
    return savingsCategories.contains(category);
  }
}
