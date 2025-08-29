import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '/models/recipe_history.dart';
import '/widgets/recipe/recipe_tracker_widgets.dart';
import '/services/recipe_tracker_service.dart';
import '/theme/app_theme.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';

final favouriteRecipesProvider = StreamProvider<List<RecipeHistoryEntry>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return RecipeTrackerService.favouriteRecipesStream(userId);
});

class RecipeFavouritesPage extends ConsumerWidget {
  const RecipeFavouritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favRecipesAsync = ref.watch(favouriteRecipesProvider);

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
              child: favRecipesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text("Error: $e")),
                data: (favRecipes) {
                  if (favRecipes.isEmpty) {
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
                    padding: EdgeInsets.only(bottom: 24.h),
                    itemCount: favRecipes.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final r = favRecipes[index];
                      return CookedRecipeCard(
                        imageUrl: r.imageUrl,
                        recipe: r,
                        onTap: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => Center(child: CircularProgressIndicator()),
                          );
                          final detail = await RecipeTrackerService.fetchFullRecipeDetail(r.recipeId);
                          Navigator.of(context, rootNavigator: true).pop();
                          if (detail != null) {
                            context.push('/recipePage', extra: {
                              'recipe': detail,
                              'fromHistory': true,
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Recipe details not found.'))
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
