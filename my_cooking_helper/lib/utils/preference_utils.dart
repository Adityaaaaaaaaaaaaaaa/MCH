class PreferenceOption {
  final String label;
  final String emoji;
  const PreferenceOption(this.label, this.emoji);
}

class PreferenceUtils {
  
  static const genders = [
    PreferenceOption("Male", "👨‍🍳"),
    PreferenceOption("Female", "👩‍🍳"),
    PreferenceOption("Non-binary", "🧑‍🍳"),
    PreferenceOption("Prefer not to say", "🤫"),
    PreferenceOption("Other", "❓"),
  ];

  static const cookingTimes = [
    PreferenceOption("Super Fast (<20 min)", "⚡🍜"),
    PreferenceOption("Chill Cook (20-45 min)", "⏰😎"),
    PreferenceOption("Epic Feast (>45 min)", "🕰️🍽️"),
    PreferenceOption("Surprise Me!", "🎲"),
    PreferenceOption("Meal Prep Pro", "📅💪"),
    PreferenceOption("Batch Boss", "📦👑"),
    PreferenceOption("Whatever works!", "🤷‍♂️"),

  ];

  static const allergies = [
    PreferenceOption("Dairy", "🥛"),
    PreferenceOption("Gluten", "🌾"),
    PreferenceOption("Nuts", "🥜"),
    PreferenceOption("Soy", "🌱"),
    PreferenceOption("Shellfish", "🦐"),
    PreferenceOption("Eggs", "🥚"),
    PreferenceOption("Fish", "🐟"),
    PreferenceOption("Sesame", "🌻"),
    PreferenceOption("Corn", "🌽"),
    PreferenceOption("Sulphites", "💨"),
    PreferenceOption("Lactose intolerance", "🚫🥛"),
    PreferenceOption("Crustaceans", "🦀"),
    PreferenceOption("Molluscs", "🦪"),
    PreferenceOption("Mustard", "🌿"),
    PreferenceOption("Celery", "🥬"),
    PreferenceOption("MSG", "🍜"),
    PreferenceOption("Red Meat", "🥩"),
    PreferenceOption("Other", "❓"),
    PreferenceOption("None", "👍"),
  ];

  static const diets = [
    PreferenceOption("Vegan", "🌱"),
    PreferenceOption("Vegetarian (Lacto)", "🥛"),
    PreferenceOption("Vegetarian (Ovo)", "🥚"),
    PreferenceOption("Pescatarian", "🐟"),
    PreferenceOption("Flexitarian", "🍽️"),
    PreferenceOption("Paleo", "🥩"),
    PreferenceOption("Keto", "🥓"),
    PreferenceOption("Low-carb", "🥗"),
    PreferenceOption("High Protein", "🍗"),
    // PreferenceOption("Carnivore", "🍖"),
    // PreferenceOption("Raw Food", "🥒"),
    PreferenceOption("Whole30", "🧘"),
    PreferenceOption("Intermittent Fasting", "⏳"),
    PreferenceOption("Kosher", "✡️"),
    PreferenceOption("Halal", "☪️"),
    PreferenceOption("Gluten-free", "🚫🌾"),
    PreferenceOption("Low FODMAP", "🦠"),
    PreferenceOption("Diabetic-friendly", "🍏"),
    PreferenceOption("Mediterranean", "🍅"),
    PreferenceOption("DASH", "💪"),
    PreferenceOption("None / Open to all", "👌"),
    PreferenceOption("Other", "❓"),
  ];

  static const cuisines = [
    PreferenceOption("Italian", "🍝"),
    PreferenceOption("Chinese", "🥡"),
    PreferenceOption("Mexican", "🌮"),
    PreferenceOption("Indian", "🍛"),
    PreferenceOption("Japanese", "🍣"),
    PreferenceOption("Thai", "🍜"),
    PreferenceOption("Korean", "🍲"),
    PreferenceOption("Vietnamese", "🥢"),
    PreferenceOption("Spanish", "🥘"),
    PreferenceOption("Brazilian", "🥥"),
    PreferenceOption("French", "🥖"),
    PreferenceOption("Middle Eastern", "🥙"),
    PreferenceOption("Scandinavian", "🥔"),
    PreferenceOption("Russian", "🍲"),
    PreferenceOption("Mediterranean", "🥗"),
    PreferenceOption("South African", "🍖"),
    PreferenceOption("American", "🍔"),
    PreferenceOption("British", "🥧"),
    PreferenceOption("Greek", "🥙"),
    PreferenceOption("Turkish", "🍢"),
    PreferenceOption("Moroccan", "🍛"),
    PreferenceOption("German", "🥨"),
    // PreferenceOption("Polish", "🥟"),
    // PreferenceOption("Hungarian", "🍲"),
    // PreferenceOption("Filipino", "🍗"),
    // PreferenceOption("Indonesian", "🍜"),
    // PreferenceOption("Malaysian", "🍛"),
    // PreferenceOption("Australian", "🥧"),
    // PreferenceOption("Peruvian", "🍠"),
    // PreferenceOption("Argentinian", "🥩"),
    PreferenceOption("Mauritian/Creole", "🍲"),
    PreferenceOption("Other", "🌍"),
  ];

  static const spiceLevels = [
    PreferenceOption("No Spice (Plain Jane)", "😐🥛"),
    PreferenceOption("Gentle Warmth (Mild)", "🙂🌶️"),
    PreferenceOption("Balanced Kick (Medium)", "😋🌶️🌶️"),
    PreferenceOption("Bring the Heat (Spicy)", "🔥🌶️🌶️🌶️"),
    PreferenceOption("Daredevil (Super Spicy!)", "🥵🔥🔥"),
    PreferenceOption("Mystery Heat (Surprise me!)", "🎲🌶️"),
    PreferenceOption("Spice? I'm Open!", "❔"),
  ];

  static const barriers = [
    PreferenceOption("No time!", "⏳"),
    PreferenceOption("What's for dinner?", "🎲🍳"),
    PreferenceOption("Missing stuff", "🛒❌"),
    PreferenceOption("Busy AF", "🤹‍♂️💼"),
    PreferenceOption("Chef? Not me", "😬👩‍🍳"),
    PreferenceOption("Hate cleaning", "🧽😩"),
    PreferenceOption("Solo & sad", "🧑‍🦽🍽️"),
    PreferenceOption("Kids = picky", "🧒😝"),
    PreferenceOption("No gadgets", "🔌🍴"),
    PreferenceOption("Groceries = \$\$\$", "💸🥦"),
    PreferenceOption("Health probs", "🩺🥗"),
    PreferenceOption("Takeout wins", "📱🍔"),
    PreferenceOption("Recipes = scary", "📖😵"),
    PreferenceOption("Zero motivation", "😴🥄"),
    PreferenceOption("No clue!", "🦄❓"),
  ];
}

class PreferenceKeys {
  static const gender = 'gender';
  static const cookingTime = 'cookingTime';
  static const allergies = 'allergies';
  static const diets = 'diets';
  static const cuisines = 'cuisines';
  static const spiceLevel = 'spiceLevel';
  static const barriers = 'barriers';
}

class UserPreferences {
  String? gender;
  String? cookingTime;
  List<String> allergies = [];
  List<String> diets = [];
  List<String> cuisines = [];
  String? spiceLevel;
  List<String> barriers = [];

  UserPreferences();
  
  Map<String, dynamic> toMap() {
    return {
      'gender': gender,
      'cookingTime': cookingTime,
      'allergies': allergies,
      'diets': diets,
      'cuisines': cuisines,
      'spiceLevel': spiceLevel,
      'barriers': barriers,
    };
  }
}