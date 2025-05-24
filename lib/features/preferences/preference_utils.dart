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
    PreferenceOption("Quick (< 20 min)", "⚡"),
    PreferenceOption("Moderate (20 - 45 min)", "⏰"),
    PreferenceOption("Extended (> 45 min)", "🕰️"),
    PreferenceOption("Varies day to day", "🔄"),
    PreferenceOption("Meal Prep for the Week", "📅"),
    PreferenceOption("Batch Cooking", "📦"),
    PreferenceOption("No preference", "❔"),

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
    PreferenceOption("None", "👍"),
    PreferenceOption("Other", "❓"),
    PreferenceOption("Tree Nuts", "🌰"),
    PreferenceOption("Crustaceans", "🦀"),
    PreferenceOption("Molluscs", "🦪"),
    PreferenceOption("Mustard", "🌿"),
    PreferenceOption("Celery", "🥬"),
    PreferenceOption("MSG", "🍜"),
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
    PreferenceOption("Carnivore", "🍖"),
    PreferenceOption("Raw Food", "🥒"),
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
    PreferenceOption("Mauritian/Creole", "🍲"),
    PreferenceOption("Caribbean", "🏝️"),
    PreferenceOption("Brazilian", "🥥"),
    PreferenceOption("French", "🥖"),
    PreferenceOption("Middle Eastern", "🥙"),
    PreferenceOption("African", "🍲"),
    PreferenceOption("Scandinavian", "🥔"),
    PreferenceOption("Russian", "🍲"),
    PreferenceOption("Mediterranean", "🥗"),
    PreferenceOption("American", "🍔"),
    PreferenceOption("British", "🥧"),
    PreferenceOption("Other", "❓"),
  ];

  static const spiceLevels = [
    PreferenceOption("No Spice", "😐"),
    PreferenceOption("Mild", "🌶️"),
    PreferenceOption("Medium", "🌶️🌶️"),
    PreferenceOption("Spicy", "🌶️🌶️🌶️"),
    PreferenceOption("Super Spicy!", "🔥"),
    PreferenceOption("Surprise me!", "🎲"),
    PreferenceOption("No preference", "❔"),
  ];

  static const barriers = [
    PreferenceOption("Cooking takes too much time", "⏳"),
    PreferenceOption("Don't know what to cook", "🤔"),
    PreferenceOption("Lack of ingredients", "🛒"),
    PreferenceOption("Work/Busy schedule", "💼"),
    PreferenceOption("Lack of confidence/skills", "🙈"),
    PreferenceOption("Cleaning up is difficult", "🧹"),
    PreferenceOption("Cooking for one is not fun", "👤"),
    PreferenceOption("Kids are picky", "🧒"),
    PreferenceOption("Limited kitchen tools", "🔪"),
    PreferenceOption("Too expensive", "💸"),
    PreferenceOption("Health issues", "💊"),
    PreferenceOption("Eating out is easier", "🍽️"),
    PreferenceOption("Other", "❓"),
  ];
}
