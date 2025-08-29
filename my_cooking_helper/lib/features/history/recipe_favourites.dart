import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '/models/recipe_history.dart' show RecipeHistoryEntry, UnifiedHistoryItem, RecipeSource;
import '/widgets/recipe/recipe_tracker_widgets.dart';
import '/services/recipe_tracker_service.dart';
import '/services/cravings_recipe_service.dart';
import '/theme/app_theme.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';

/// Existing normal favourites stream (Spoonacular-backed)
final favouriteRecipesProvider = StreamProvider<List<RecipeHistoryEntry>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return RecipeTrackerService.favouriteRecipesStream(userId);
});

/// AI favourites stream: users/{uid}/userTrackers where isFavourite == true
final aiFavouriteProvider = StreamProvider<List<UnifiedHistoryItem>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  final q = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('userTrackers')
      .where('isFavourite', isEqualTo: true);

  return q.snapshots().map((snap) {
    return snap.docs.map((d) => UnifiedHistoryItem.fromAi(d.id, d.data())).toList();
  });
});

class RecipeFavouritesPage extends ConsumerWidget {
  const RecipeFavouritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalAsync = ref.watch(favouriteRecipesProvider);
    final aiAsync = ref.watch(aiFavouriteProvider);

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "Favourites",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
        themeToggleWidget: ThemeToggleButton(),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 85.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your Favourite Recipes",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor(context),
              ),
            ),
            SizedBox(height: 12.h),

            Expanded(
              child: Builder(builder: (_) {
                if (normalAsync.isLoading || aiAsync.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (normalAsync.hasError) {
                  return Center(child: Text("Error: ${normalAsync.error}"));
                }
                if (aiAsync.hasError) {
                  return Center(child: Text("Error: ${aiAsync.error}"));
                }

                final uid = FirebaseAuth.instance.currentUser?.uid;

                // Normal favourites -> Unified
                final normalUnified =
                    (normalAsync.value ?? const <RecipeHistoryEntry>[])
                        .map((r) => UnifiedHistoryItem(
                              id: r.recipeId,
                              source: RecipeSource.normal,
                              title: r.recipeTitle,
                              isFavourite: true,
                              timesCooked: r.timesCooked,
                              lastCookedAt: r.lastCookedAt,
                              imageUrl: r.imageUrl,
                            ))
                        .toList();

                // AI favourites (already Unified)
                final aiUnified = aiAsync.value ?? const <UnifiedHistoryItem>[];

                // Merge and sort (prefer most recently cooked; nulls last; then title)
                int ts(UnifiedHistoryItem x) =>
                    x.lastCookedAt?.millisecondsSinceEpoch ?? 0;
                final favs = <UnifiedHistoryItem>[...normalUnified, ...aiUnified]
                  ..sort((a, b) {
                    final t = ts(b).compareTo(ts(a));
                    if (t != 0) return t;
                    return (a.title).toLowerCase().compareTo((b.title).toLowerCase());
                  });

                if (favs.isEmpty) {
                  return Center(
                    child: Text(
                      "No favourites yet.",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor(context).withOpacity(0.7),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  cacheExtent: MediaQuery.of(context).size.height,
                  padding: EdgeInsets.only(bottom: 24.h),
                  itemCount: favs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final it = favs[index];

                    // Re-use the shared card by adapting to RecipeHistoryEntry
                    final entry = RecipeHistoryEntry(
                      recipeId: it.id,                  // normal: numeric/string id; AI: ai:<hash>
                      recipeTitle: it.title,
                      isFavourite: true,
                      lastCookedAt: it.lastCookedAt,
                      timesCooked: it.timesCooked,
                      imageUrl: it.imageUrl,
                      markFavOn: null,
                    );

                    return CookedRecipeCard(
                      recipe: entry,
                      imageUrl: it.imageUrl,
                      isAi: it.source == RecipeSource.ai,
                      onTap: () async {
                        if (uid == null) return;

                        // loader
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );

                        // Normal favourites -> open RecipePage
                        if (it.source == RecipeSource.normal) {
                          final detail = await RecipeTrackerService.fetchFullRecipeDetail(it.id);
                          Navigator.of(context, rootNavigator: true).pop();
                          if (detail != null) {
                            context.push('/recipePage', extra: {
                              'recipe': detail,
                              'fromHistory': true,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recipe details not found.')),
                            );
                          }
                          return;
                        }

                        // AI favourites -> open CravingRecipePage
                        final found = await CravingsRecipeService.fetchCravingByRecipeKey(
                          uid: uid,
                          recipeKey: it.id, // ai:<hash>
                        );

                        Navigator.of(context, rootNavigator: true).pop();

                        if (found == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI recipe not found.')),
                          );
                          return;
                        }

                        context.push('/cravingRecipe', extra: {
                          'recipe': found.recipe,
                          'fromHistory': true,
                          'recipeKey': it.id,
                          'sessionId': found.sessionId, // optional
                          'trackerId': found.trackerId, // optional
                        });
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
