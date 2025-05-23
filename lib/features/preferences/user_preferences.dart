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
