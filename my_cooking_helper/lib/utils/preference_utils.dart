import 'package:animated_emoji/animated_emoji.dart';
import 'package:flutter/material.dart';

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
        } else if (e is String) {
          return Text(e, style: TextStyle(fontSize: size));
        } else {
          return SizedBox.shrink();
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
    PreferenceOption("Prefer not to say", ["🤫"], [AnimatedEmojis.shushingFace]),
    PreferenceOption("Other", ["❓"], [AnimatedEmojis.question]),
  ];

  static final cookingTimes = [
    PreferenceOption("Super Fast (<20 min)", ["⚡🍜"], [AnimatedEmojis.electricity, AnimatedEmojis.steamingBowl]),
    PreferenceOption("Chill Cook (20-45 min)", ["⏰😎"], [AnimatedEmojis.alarmClock, AnimatedEmojis.sunglassesFace]),
    PreferenceOption("Epic Feast (>45 min)", ["🕰️🍽️"], [AnimatedEmojis.anatomicalHeart, "🍽️"]),
    PreferenceOption("Surprise Me!", ["🎲"], [AnimatedEmojis.die]),
    PreferenceOption("Meal Prep Pro", ["📅💪"], ["📅", AnimatedEmojis.muscle]),
    PreferenceOption("Batch Boss", ["📦👑"]),
    PreferenceOption("Whatever works!", ["🤷‍♂️"], [AnimatedEmojis.rollingEyes, "🤷‍♂️"]),

  ];

  static final allergies = [
    PreferenceOption("Dairy", ["🥛"]),
    PreferenceOption("Gluten", ["🌾"]),
    PreferenceOption("Nuts", ["🥜"]),
    PreferenceOption("Soy", ["🌱"]),
    PreferenceOption("Shellfish", ["🦐"]),
    PreferenceOption("Eggs", ["🥚"]),
    PreferenceOption("Fish", ["🐟"], [AnimatedEmojis.fish]),
    PreferenceOption("Sesame", ["🌻"]),
    PreferenceOption("Corn", ["🌽"]),
    PreferenceOption("Sulphites", ["💨"]),
    PreferenceOption("Lactose intolerance", ["🚫🥛"]),
    PreferenceOption("Crustaceans", ["🦀"], [AnimatedEmojis.crab]),
    PreferenceOption("Molluscs", ["🦪"]),
    PreferenceOption("Mustard", ["🌿"]),
    PreferenceOption("Celery", ["🥬"]),
    PreferenceOption("MSG", ["🍜"], [AnimatedEmojis.steamingBowl]),
    PreferenceOption("Red Meat", ["🥩"]),
    PreferenceOption("Other", ["❓"], [AnimatedEmojis.question]),
    PreferenceOption("None", ["👍"], [AnimatedEmojis.thumbsUp]),
  ];

  static final diets = [
    PreferenceOption("Vegan", ["🌱"], [AnimatedEmojis.plant]),
    PreferenceOption("Vegetarian (Lacto)", ["🥛"]),
    PreferenceOption("Vegetarian (Ovo)", ["🥚"]),
    PreferenceOption("Pescatarian", ["🐟"], [AnimatedEmojis.fish]),
    PreferenceOption("Flexitarian", ["🍽️"]),
    PreferenceOption("Paleo", ["🥩"]),
    PreferenceOption("Keto", ["🥓"]),
    PreferenceOption("Low-carb", ["🥗"]),
    PreferenceOption("High Protein", ["🍗"]),
    // PreferenceOption("Carnivore", "🍖"),
    // PreferenceOption("Raw Food", "🥒"),
    PreferenceOption("Whole30", ["🧘"]),
    PreferenceOption("Intermittent Fasting", ["⏳"]),
    PreferenceOption("Kosher", ["✡️"]),
    PreferenceOption("Halal", ["☪️"]),
    PreferenceOption("Gluten-free", ["🚫🌾"]),
    PreferenceOption("Low FODMAP", ["🦠"], [AnimatedEmojis.microbe]),
    PreferenceOption("Diabetic-friendly", ["🍏"]),
    PreferenceOption("Mediterranean", ["🍅"], [AnimatedEmojis.tomato]),
    PreferenceOption("DASH", ["💪"], [AnimatedEmojis.muscle]),
    PreferenceOption("None / Open to all", ["👌"], [AnimatedEmojis.ok]),
    PreferenceOption("Other", ["❓"], [AnimatedEmojis.question]),
  ];

  static final  cuisines = [
    PreferenceOption("Italian", ["🍝"]),
    PreferenceOption("Chinese", ["🥡"]),
    PreferenceOption("Mexican", ["🌮"]),
    PreferenceOption("Indian", ["🍛"]),
    PreferenceOption("Japanese", ["🍣"]),
    PreferenceOption("Thai", ["🍜"]),
    PreferenceOption("Korean", ["🍲"]),
    PreferenceOption("Vietnamese", ["🥢"]),
    PreferenceOption("Spanish", ["🥘"]),
    PreferenceOption("Brazilian", ["🥥"]),
    PreferenceOption("French", ["🥖"]),
    PreferenceOption("Middle Eastern", ["🥙"]),
    PreferenceOption("Scandinavian", ["🥔"]),
    PreferenceOption("Russian", ["🍲"]),
    PreferenceOption("Mediterranean", ["🥗"]),
    PreferenceOption("South African", ["🍖"]),
    PreferenceOption("American", ["🍔"]),
    PreferenceOption("British", ["🥧"]),
    PreferenceOption("Greek", ["🥙"]),
    PreferenceOption("Turkish", ["🍢"]),
    PreferenceOption("Moroccan", ["🍛"]),
    PreferenceOption("German", ["🥨"]),
    // PreferenceOption("Polish", "🥟"),
    // PreferenceOption("Hungarian", "🍲"),
    // PreferenceOption("Filipino", "🍗"),
    // PreferenceOption("Indonesian", "🍜"),
    // PreferenceOption("Malaysian", "🍛"),
    // PreferenceOption("Australian", "🥧"),
    // PreferenceOption("Peruvian", "🍠"),
    // PreferenceOption("Argentinian", "🥩"),
    PreferenceOption("Mauritian/Creole", ["🍲"]),
    PreferenceOption("Other", ["🌍"], [AnimatedEmojis.globeShowingEuropeAfrica]),
  ];

  static final spiceLevels = [
    PreferenceOption("No Spice (Plain Jane)", ["😐🥛"], [AnimatedEmojis.neutralFace, "🥛", AnimatedEmojis.happyCry]),
    PreferenceOption("Gentle Warmth (Mild)", ["🙂🌶️"], [AnimatedEmojis.slightlyHappy, AnimatedEmojis.fire]),
    PreferenceOption("Balanced Kick (Medium)", ["😋🌶️🌶️"], [AnimatedEmojis.yum, AnimatedEmojis.fire, AnimatedEmojis.fire]),
    PreferenceOption("Bring the Heat (Spicy)", ["🔥🌶️🌶️🌶️"], [AnimatedEmojis.collision, AnimatedEmojis.fire, AnimatedEmojis.fire, AnimatedEmojis.fire]),
    PreferenceOption("Daredevil (Super Spicy!)", ["🥵🔥🔥"], [AnimatedEmojis.hotFace, AnimatedEmojis.fire, AnimatedEmojis.cursing, AnimatedEmojis.impFrown]),
    PreferenceOption("Mystery Heat (Surprise me!)", ["🎲🌶️"], [AnimatedEmojis.die, AnimatedEmojis.shakingFace]),
    PreferenceOption("Spice? I'm Open!", ["❔"], [AnimatedEmojis.nerdFace, AnimatedEmojis.smirk, AnimatedEmojis.impSmile]),
  ];

  static final barriers = [
    PreferenceOption("No time!", ["⏳"]),
    PreferenceOption("What's for dinner?", ["🎲🍳"], [AnimatedEmojis.die, AnimatedEmojis.cooking]),
    PreferenceOption("Missing stuff", ["🛒❌"]),
    PreferenceOption("Busy AF", ["🤹‍♂️💼"]),
    PreferenceOption("Chef? Not me", ["😬👩‍🍳"], [AnimatedEmojis.grimacing, "👩‍🍳"]),
    PreferenceOption("Hate cleaning", ["🧽😩"], ["🧽", AnimatedEmojis.exhale]),
    PreferenceOption("Solo & sad", ["🧑‍🦽🍽️"]),
    PreferenceOption("Kids = picky", ["🧒😝"], [AnimatedEmojis.stuckOutTongue, AnimatedEmojis.nerdFace]),
    PreferenceOption("No gadgets", ["🔌🍴"]),
    PreferenceOption("Groceries = \$\$\$", ["💸🥦"], [AnimatedEmojis.moneyFace, AnimatedEmojis.moneyWithWings]),
    PreferenceOption("Health probs", ["🩺🥗"], ["🩺", AnimatedEmojis.microbe, AnimatedEmojis.vomit]),
    PreferenceOption("Takeout wins", ["📱🍔"]),
    PreferenceOption("Recipes = scary", ["📖😵"], ["📖",AnimatedEmojis.eyes, AnimatedEmojis.xEyes]),
    PreferenceOption("Zero motivation", ["😴🥄"], [AnimatedEmojis.tired, AnimatedEmojis.sleep, "🥄"]),
    PreferenceOption("No clue!", ["🦄❓"], [AnimatedEmojis.question, "🦄", AnimatedEmojis.flyingSaucer]),
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