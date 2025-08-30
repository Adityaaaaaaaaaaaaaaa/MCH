import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/services/recipe_save_service.dart';
import '/widgets/recipe/recipe_common_widgets.dart';
import '/theme/app_theme.dart';
import '/models/recipe_detail.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/services/recipe_search_service.dart';
import '/widgets/recipe/recipe_page_widgets.dart';
import '/widgets/shimmer/recipe_page_skeleton.dart';

// Rebuilds on sign-in, sign-out, and user switches
final authUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.userChanges(),
);

final recipeSearchServiceProvider = Provider<RecipeSearchService>((ref) {
  return RecipeSearchService();
});

// AFTER (auto-updates on userChanges)
final favouriteStatusProvider = StreamProvider.autoDispose.family<bool, String>((ref, recipeId) {
  final user = ref.watch(authUserProvider).value;   // 👈 watch, not read
  final uid = user?.uid;
  if (uid == null) return Stream<bool>.value(false);

  final doc = FirebaseFirestore.instance
      .collection('users').doc(uid)
      .collection('recipeHistory').doc(recipeId);

  return doc.snapshots().map(
    (s) => s.exists && (s.data()?['isFavourite'] == true),
  );
});

final recipeVideosProvider = FutureProvider.family<Map<String, dynamic>, RecipeDetail>((ref, recipe) async {
  final service = ref.read(recipeSearchServiceProvider);
  return await service.fetchRecipeVideosAndSummary(
    title: recipe.title ?? '',
    summary: recipe.summary ?? '',
  );
});

final cookedSuccessProvider = StateProvider.autoDispose.family<bool, String>((ref, recipeId) => false);

String extractSummaryText(Map<String, dynamic>? summaryData) {
  if (summaryData == null) return '';
  if (summaryData['summary'] is String) return summaryData['summary'];
  if (summaryData['summary'] is Map && summaryData['summary']['text'] != null) return summaryData['summary']['text'];
  if (summaryData['text'] is String) return summaryData['text'];
  return summaryData.toString();
}

List<RecipeYoutubeVideo> normalizeVideoList(dynamic videosRaw) {
  if (videosRaw == null) return [];
  if (videosRaw is List<RecipeYoutubeVideo>) return videosRaw;
  if (videosRaw is List) {
    return videosRaw.map((e) {
      if (e is RecipeYoutubeVideo) return e;
      if (e is Map<String, dynamic>) return RecipeYoutubeVideo.fromJson(e);
      if (e is RecipeVideo) {
        // Convert RecipeVideo to Map and then to RecipeYoutubeVideo if possible
        try {
          // Assumes RecipeVideo has a toJson() method compatible with RecipeYoutubeVideo.fromJson
          return RecipeYoutubeVideo.fromJson(e.toJson());
        } catch (_) {
          // fallback or skip
          return null;
        }
      }
      return null; // skip unconvertible entries
    }).whereType<RecipeYoutubeVideo>().toList();
  }
  return [];
}


class RecipePage extends ConsumerWidget {
  final RecipeDetail recipe;
  final bool fromHistory;
  const RecipePage({Key? key, required this.recipe, this.fromHistory = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final imageUrl = recipe.image ?? '';
    final title = recipe.title ?? 'No Title';
    final summary = recipe.summary ?? '';
    final website = recipe.sourceUrl ?? '';
    final dishTypes = recipe.dishTypes;
    final servings = recipe.servings ?? 0;

    final AsyncValue<Map<String, dynamic>> videosAndSummaryAsync = fromHistory
    ? AsyncValue.data({
        'summary': recipe.geminiSummary ?? recipe.summary,
        'videos': recipe.videos ?? [],
      })
    : ref.watch(recipeVideosProvider(recipe));

    Map<String, dynamic>? geminiSummaryData;
    if (videosAndSummaryAsync.hasValue && videosAndSummaryAsync.value != null) {
      final summaryData = videosAndSummaryAsync.value!['summary'];
      if (summaryData is Map) {
        geminiSummaryData = summaryData as Map<String, dynamic>;
      }
    }

    final recipeId = recipe.id ?? "default";
    final userId = ref.read(authUserProvider).value?.uid;

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBody: true,
      extendBodyBehindAppBar: true,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "~ Recipe ~",
        showMenu: false,
        themeToggleWidget: ThemeToggleButton(),
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: videosAndSummaryAsync.when(
        data: (_) {
          return Stack(
            children: [
              if (imageUrl.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 70.h),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.all(10.w),
                          child: RecipeImageCard(imageUrl: imageUrl, isDark: isDark),
                        ),
                  
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RecipeTitle(title: title),
                            SizedBox(height: 6.h),

                            if (summary.isNotEmpty)
                              RecipeSummaryText(
                                geminiSummary: geminiSummaryData,
                                originalHtmlSummary: summary,
                              ),
                            SizedBox(height: 10.h),

                            if (recipe.healthScore != null)
                              HealthScoreCard(healthScore: recipe.healthScore),
                            SizedBox(height: 10.h),

                            if (recipe.nutrition?.caloricBreakdown != null)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                child: CaloricBreakdownWidget(
                                  breakdown: recipe.nutrition?.caloricBreakdown,
                                  glutenFree: recipe.glutenFree,
                                  dairyFree: recipe.dairyFree,
                                  weightPerServing: recipe.nutrition?.toJson()['weightPerServing'],
                                  isDark: isDark,
                                ),
                              ),
                            SizedBox(height: 10.h),
                        
                            if (dishTypes.isNotEmpty)
                              Center(
                                child: InfoChip(
                                  icon: Icons.restaurant_rounded,
                                  text: dishTypes.join(', ').replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase()),
                                  isDark: isDark,
                                ),
                              ),
                            SizedBox(height: 7.h),

                            if (servings > 0)
                              Center(
                                child: InfoChip(
                                  icon: Icons.people_rounded,
                                  text: 'Serves $servings',
                                  isDark: isDark,
                                ),
                              ),
                            SizedBox(height: 10.h),

                            // INGREDIENTS
                            if (recipe.extendedIngredients.isNotEmpty) ...[
                              SectionHeader(title: 'Ingredients', icon: Icons.list_alt_rounded, isDark: isDark),
                              SizedBox(height: 10.h),
                              Column(
                                children: recipe.extendedIngredients
                                    .map((ingredient) => ExtendedIngredientCard(ingredient: ingredient, isDark: isDark))
                                    .toList(),
                              ),
                            ],
                            SizedBox(height: 25.h),

                            // INSTRUCTIONS
                            if (recipe.analyzedInstructions.isNotEmpty) ...[
                              SectionHeader(title: 'Instructions', icon: Icons.format_list_numbered_rounded, isDark: isDark),
                              SizedBox(height: 10.h),
                              InstructionsList(
                                instructions: recipe.analyzedInstructions.expand((instr) => instr.steps).toList(),
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 22.h),

                            // EQUIPMENT
                            if (recipe.analyzedInstructions.isNotEmpty) ...[
                              SectionHeader(title: 'Equipment', icon: Icons.kitchen_rounded, isDark: isDark),
                              SizedBox(height: 10.h),
                              EquipmentChips(
                                equipment: recipe.analyzedInstructions
                                    .expand((instr) => instr.steps)
                                    .expand((step) => step.equipment
                                        .map((e) => e['name'])
                                        .whereType<String>())
                                    .toSet()
                                    .toList(),
                                isDark: isDark,
                              ),
                            ],
                            SizedBox(height: 25.h),

                            // NUTRITION
                            if (recipe.nutrition != null) ...[
                              NutritionSection(
                                nutrition: recipe.nutrition!.toJson(),
                              ),
                            ],
                            SizedBox(height: 25.h),

                            // WEBSITE LINK
                            if (website.isNotEmpty) ...[
                              WebsiteLinkCard(
                                url: website,
                                isDark: isDark,
                                onTap: (url) => showRecipeWebView(context, url),
                              ),
                              if (website.startsWith('http://'))
                                HttpWarningCard(isDark: isDark),
                            ],
                            SizedBox(height: 25.h),

                            if (videosAndSummaryAsync.hasValue && videosAndSummaryAsync.value!.isNotEmpty) ...[
                              SectionHeader(title: 'Youtube Videos', icon: Icons.video_collection, isDark: isDark),
                              SizedBox(height: 10.h),
                              RecipeVideosSection(
                                videos: (() {
                                  final videosRaw = videosAndSummaryAsync.value!['videos'];
                                  return normalizeVideoList(videosRaw);
                                })(),
                              ),
                            ],
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),               
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 15,
                child: Consumer(
                  builder: (context, ref, _) {
                    final favAsync = ref.watch(favouriteStatusProvider(recipeId));
                    final cookedSuccess = ref.watch(cookedSuccessProvider(recipeId));

                    return favAsync.when(
                      data: (isFavourite) => DualActionButton(
                        isFavourited: isFavourite,
                        cookedSuccess: cookedSuccess,
                        onFavourite: () async {
                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Please log in to use Favourites."),
                                backgroundColor: Colors.red[600],
                              ),
                            );
                            return;
                          }
                          // Toggle favourite, and Firestore will trigger the stream update!
                          await RecipeSaveService.updateFavouriteStatus(
                            recipeId: recipeId,
                            userId: userId,
                            isFavourite: !isFavourite,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !isFavourite ? "Added to Favourites!" : "Removed from Favourites.",
                              ),
                              backgroundColor: !isFavourite ? Colors.pink[400] : Colors.grey[600],
                            ),
                          );
                        },
                        onMarkCooked: () async {
                          if (userId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Please log in to mark as cooked."),
                                backgroundColor: Colors.red[600],
                              ),
                            );
                            return;
                          }
                          // add ai summary and yt videos 
                          final aiSummary = extractSummaryText(geminiSummaryData);
                          final dynamic rawVideos = videosAndSummaryAsync.value?['videos'];
                          final List<RecipeVideo> videos =
                              rawVideos is List<RecipeVideo> ? rawVideos
                            : rawVideos is List
                                ? rawVideos.map((e) {
                                    if (e is RecipeVideo) return e;
                                    if (e is Map<String, dynamic>) return RecipeVideo.fromJson(e);
                                    if (e is Map) {
                                      // tolerate Map<Object,Object>
                                      final m = e.map((k, v) => MapEntry(k.toString(), v));
                                      return RecipeVideo.fromJson(m);
                                    }
                                    // If something like RecipeYoutubeVideo sneaks in and has toJson()
                                    try {
                                      final toJson = (e as dynamic).toJson;
                                      if (toJson != null) {
                                        final m = (e as dynamic).toJson() as Map;
                                        return RecipeVideo.fromJson(
                                          m.map((k, v) => MapEntry(k.toString(), v)),
                                        );
                                      }
                                    } catch (_) {/* ignore */}
                                    return null;
                                  }).whereType<RecipeVideo>().toList()
                                : <RecipeVideo>[];

                          final enrichedRecipe = recipe.copyWith(
                            geminiSummary: geminiSummaryData,
                            aiSummary: aiSummary,
                            videos: videos,
                          );

                          await RecipeSaveService.markRecipeAsCooked(
                            context: context,
                            recipe: enrichedRecipe,
                            userId: userId,
                            isFavourite: isFavourite,
                          );

                          ref.read(cookedSuccessProvider(recipeId).notifier).state = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Marked as cooked!"),
                              backgroundColor: Colors.green[600],
                            ),
                          );
                        },
                      ),
                      loading: () => DualActionButton(
                        isFavourited: false,
                        cookedSuccess: cookedSuccess,
                        onFavourite: () {}, //does nothing 
                        onMarkCooked: () {},
                      ),
                      error: (err, stack) => Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const RecipePageSkeleton(),
        error: (err, stack) => Center(
          child: Text("Error loading recipe videos/summary: $err"),
        ),
      ),
    );
  }
}

// --- Helper ---
String formatTime(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  if (hours > 0) {
    return mins > 0 ? '$hours hr $mins min' : '$hours hr';
  } else {
    return '$mins min';
  }
}
