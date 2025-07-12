import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

import 'emoji_animation.dart';

class PreferenceOption {
  final String label;
  final List<String> emojis; // fallback static only
  final List<dynamic> emojiMix; // can be AnimatedEmojiData or String

  PreferenceOption(this.label, this.emojis, [this.emojiMix = const []]);
}

class SmartPreferenceEmojiRow extends StatelessWidget {
  final PreferenceOption option;
  final double size;
  final bool repeat;
  const SmartPreferenceEmojiRow({
    Key? key,
    required this.option,
    this.size = 24,
    this.repeat = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use emojiMix if not empty; otherwise, use emojis
    final List<dynamic> toDisplay = option.emojiMix.isNotEmpty ? option.emojiMix : option.emojis;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: toDisplay.map<Widget>((e) {
        if (e is AnimatedEmojiData) {
          return AnimatedEmoji(e, size: size, repeat: repeat);
        } else if (e is Map && e.containsKey("name")) {
          // Map for custom asset-based emoji
          return EmojiAnimation(
            name: e["name"],
            size: (e["size"] ?? size).toDouble(),
            repeat: e["repeat"] ?? true,
            key: e["key"], // nullable is fine
          );
        } else if (e is String) {
          return Text(e, style: TextStyle(fontSize: size));
        } else {
          return const SizedBox.shrink();
        }
      }).toList(),
    );
  }
}

class PreferenceUtils {
  
  static final genders = [
    PreferenceOption("Male", ["👨‍🍳"],),
    PreferenceOption("Female", ["👩‍🍳"],),
    PreferenceOption("Non-binary", ["🧑‍🍳"],),
    PreferenceOption("Prefer not to say", ["🤫"], [{"name": "shushingFace"}]),
    PreferenceOption("Other", ["❓"], [{"name": "question"}]),
  ];

  static final cookingTimes = [
    PreferenceOption("Super Fast (<20 min)", ["⚡🍜"], [{"name": "electricity"}, {"name": "steamingBowl"}]),
    PreferenceOption("Chill Cook (20-45 min)", ["⏰😎"], [{"name": "alarmClock"}, {"name": "sunglassesFace"}]),
    PreferenceOption("Epic Feast (>45 min)", ["🕰️🍽️"], [{"name": "anatomicalHeart"}, "🍽️"]),
    PreferenceOption("Surprise Me!", ["🎲"], [{"name": "die"}]),
    PreferenceOption("Meal Prep Pro", ["📅💪"], ["📅", {"name": "muscle"}]),
    PreferenceOption("Batch Boss", ["📦👑"]),
    PreferenceOption("Whatever works!", ["🤷‍♂️"], [{"name": "rollingEyes"}, "🤷‍♂️"]),

  ];

  static final allergies = [
    PreferenceOption("Dairy", ["🥛"]),
    PreferenceOption("Gluten", ["🌾"]),
    PreferenceOption("Grain", ["🌽"]),
    PreferenceOption("Tree Nut", ["🌰"]),
    PreferenceOption("Wheat", ["🍞"]),
    PreferenceOption("Nuts", ["🥜"]),
    PreferenceOption("Soy", ["🌱"]),
    PreferenceOption("Shellfish", ["🦐"]),
    PreferenceOption("Egg", ["🥚"]),
    PreferenceOption("Seafood", ["🐟"], [{"name": "fish"}]),
    PreferenceOption("Sesame", ["🌻"]),
    PreferenceOption("Sulphites", ["💨"]),
    // PreferenceOption("Corn", ["🌽"]), //omit
    // PreferenceOption("Lactose intolerance", ["🚫🥛"]), //omit
    // PreferenceOption("Crustaceans", ["🦀"], [{"name": "crab"}]), //omit
    // PreferenceOption("Molluscs", ["🦪"]), //omit
    // PreferenceOption("Mustard", ["🌿"]), //omit
    // PreferenceOption("Celery", ["🥬"]), //omit
    // PreferenceOption("MSG", ["🍜"], [{"name": "steamingBowl"}]), //omit
    // PreferenceOption("Red Meat", ["🥩"]), //omit
    PreferenceOption("Other", ["❓"], [{"name": "question"}]),
    PreferenceOption("None", ["👍"], [{"name": "thumbsUp"}]),
  ];

  static final diets = [
    PreferenceOption("Vegan", ["🌱"], [{"name": "plant"}]),
    PreferenceOption("Vegetarian (Lacto)", ["🥛"]),
    PreferenceOption("Vegetarian (Ovo)", ["🥚"]),
    PreferenceOption("Vegetarian", ["🍠"], [{"name": "rootVegetable"}]),
    PreferenceOption("Pescatarian", ["🐟"], [{"name": "fish"}]),
    PreferenceOption("Paleo", ["🥩"]),
    PreferenceOption("Whole30", ["🧘"]),    
    PreferenceOption("Gluten-free", ["🚫🌾"]),
    PreferenceOption("Low FODMAP", ["🦠"], [{"name": "microbe"}]),
    PreferenceOption("Ketogenic", ["🥓"]), //omit
    PreferenceOption("Low-carb", ["🥗"]), //omit
    PreferenceOption("High Protein", ["🍗"]), //omit
    PreferenceOption("Intermittent Fasting", ["⏳"]), //omit
    PreferenceOption("Halal", ["☪️"]), //omit
    PreferenceOption("Diabetic-friendly", ["🍏"]), //omit
    PreferenceOption("DASH", ["💪"], [{"name": "muscle"}]), //omit
    PreferenceOption("None / Open to all", ["👌"], [{"name": "ok"}]),
    PreferenceOption("Other", ["❓"], [{"name": "question"}]),
  ];

  static final  cuisines = [
    PreferenceOption("Italian", ["🍝"]),
    // PreferenceOption("African", ["🪘"]),
    PreferenceOption("Asian", ["🥢"]),
    // PreferenceOption("Cajun", ["🌶️"]),
    PreferenceOption("Caribbean", ["🍍"]),
    PreferenceOption("Eastern European", ["🥟"]),
    PreferenceOption("European", ["🍽️"]),
    PreferenceOption("Irish", ["🍀"]),
    // PreferenceOption("Jewish", ["🕎"]),
    PreferenceOption("Latin American", ["🌯"]),
    // PreferenceOption("Nordic", ["🧊"]),
    // PreferenceOption("Southern", ["🍗"]),
    PreferenceOption("Chinese", ["🥡"]),
    PreferenceOption("Mexican", ["🌮"]),
    PreferenceOption("Indian", ["🍛"]),
    PreferenceOption("Japanese", ["🍣"]),
    PreferenceOption("Thai", ["🍜"]),
    PreferenceOption("Korean", ["🍲"]),
    PreferenceOption("Vietnamese", ["🥢"]),
    PreferenceOption("Spanish", ["🥘"]),
    PreferenceOption("French", ["🥖"]),
    PreferenceOption("Middle Eastern", ["🥙"]),
    PreferenceOption("Mediterranean", ["🥗"]),
    PreferenceOption("American", ["🍔"]),
    PreferenceOption("British", ["🥧"]),
    PreferenceOption("Greek", ["🥙"]),
    PreferenceOption("German", ["🥨"]),
    PreferenceOption("Mauritian", ["🍲"]), // omit mauritian cuisine
    PreferenceOption("Other", ["🌍"], [{"name": "globeShowingEuropeAfrica"}]),
  ];

  static final spiceLevels = [
    PreferenceOption("No Spice (Plain Jane)", ["😐🥛"], [{"name": "neutralFace"}, "🥛", {"name": "happyCry"}]),
    PreferenceOption("Gentle Warmth (Mild)", ["🙂🌶️"], [{"name": "slightlyHappy"}, {"name": "fire"}]),
    PreferenceOption("Balanced Kick (Medium)", ["😋🌶️🌶️"], [{"name": "yum"}, {"name": "fire"}, {"name": "fire"}]),
    PreferenceOption("Bring the Heat (Spicy)", ["🔥🌶️🌶️🌶️"], [{"name": "collision"}, {"name": "fire"}, {"name": "fire"}, {"name": "fire"}]),
    PreferenceOption("RIP (Super Spicy!)", ["🥵🔥🔥"], [{"name": "hotFace"}, {"name": "fire"}, {"name": "cursing"}, {"name": "impFrown"}]),
    PreferenceOption("Mystery Heat (Surprise me!)", ["🎲🌶️"], [{"name": "die"}, {"name": "shakingFace"}]),
    PreferenceOption("Spice? I'm Open!", ["❔"], [{"name": "nerdFace"}, {"name": "smirk"}, {"name": "impSmile"}]),
  ];

  static final barriers = [
    PreferenceOption("No time!", ["⏳🍴"]),
    PreferenceOption("What's for dinner?", ["🎲🍳"], [{"name": "die"}, {"name": "cooking"}]),
    PreferenceOption("Missing stuff", ["🛒❌🔌"]),
    PreferenceOption("Busy AF", ["🤹‍♂️💼"]),
    PreferenceOption("Chef? Not me", ["😬👩‍🍳"], [{"name": "grimacing"}, "👩‍🍳"]),
    PreferenceOption("Hate cleaning", ["🧽😩"], ["🧽", {"name": "exhale"}]),
    // PreferenceOption("Solo & sad", ["🧑‍🦽🍽️"]),
    PreferenceOption("Kids = picky", ["🧒😝"], [{"name": "stuckOutTongue"}, {"name": "nerdFace"}]),
    // PreferenceOption("No gadgets", ["🔌🍴"]),
    PreferenceOption("Groceries = \$\$\$", ["💸🥦"], [{"name": "moneyFace"}, {"name": "moneyWithWings"}]),
    PreferenceOption("Health probs", ["🩺🥗"], ["🩺", {"name": "microbe"}, {"name": "vomit"}]),
    PreferenceOption("Takeout wins", ["📱🍔"], [{"name": "whiteFlag"}, {"name": "checkMark"}]),
    PreferenceOption("Recipes = scary", ["📖😵"], ["📖",{"name": "eyes"}, {"name": "xEyes"}]),
    PreferenceOption("Zero motivation", ["😴🥄"], [{"name": "tired"}, {"name": "sleep"}, "🥄"]),
    PreferenceOption("No clue!", ["🦄❓"], [{"name": "question"}, "🦄", {"name": "flyingSaucer"}]),
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