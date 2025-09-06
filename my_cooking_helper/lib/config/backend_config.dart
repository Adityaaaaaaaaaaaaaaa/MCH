import 'package:flutter_dotenv/flutter_dotenv.dart';

final String ip = dotenv.env['IP'] ?? '';
//final String ip = "10.61.114.52";
final String port = dotenv.env['PORT'] ?? '';
final String serverUrl = dotenv.env['SERVER_URL'] ?? '';

//to be uncommented based on use 
String get backendApiUrl => serverUrl;
//String get backendApiUrl => "http://$ip:$port";

//Gemini API endpoints
String get geminiScanReceipt => "$backendApiUrl/receipt/scanReceipt";
String get geminiScanFood => "$backendApiUrl/food/scanFood";
String get spoonacularRecipeSearch => "$backendApiUrl/recipes/find/searchByIngredients";
String get spoonacularRecipeVideos => "$backendApiUrl/recipes/search/searchVideosAndSummary";
String get spoonacularMealplanner => "$backendApiUrl/mealPlanner/week/weekPlanner";
String get spoonacularChangeDay => "$backendApiUrl/mealPlanner/day/changeDay";
String get spoonacularPing => "$backendApiUrl/mealPlanner/ping";
String get deleteMealPlan => "$backendApiUrl/mealPlanner/userPlan/deletePlan";
String get aiRecipe => "$backendApiUrl/recipes/gemini/aiRecipe";
String get aiRecipeInvCal => "$backendApiUrl/recipes/gemini/InvDeduct";
