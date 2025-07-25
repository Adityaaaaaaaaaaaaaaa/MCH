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

final cookedRecipesProvider = StreamProvider<List<RecipeHistoryEntry>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return RecipeTrackerService.cookedRecipesStream(userId);
});

class RecipeHistoryPage extends ConsumerWidget {
  const RecipeHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookedRecipesAsync = ref.watch(cookedRecipesProvider);

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: const CustomDrawer(),
      appBar: CustomAppBar(
        title: "Cook History",
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
              "Your Past Cooked Meals",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor(context),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: cookedRecipesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text("Error: $e")),
                data: (cookedRecipes) {
                  final grouped = groupRecipesByRecency(cookedRecipes);
                  if (grouped.isEmpty) {
                    return Center(
                      child: Text(
                        "No cooked recipes yet.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textColor(context).withOpacity(0.7),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.only(bottom: 24.h),
                    itemCount: grouped.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.label,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: textColor(context).withOpacity(0.75),
                                ),
                          ),
                          SizedBox(height: 6.h),
                          ...group.recipes.map(
                            (r) => CookedRecipeCard(
                              imageUrl: r.imageUrl, 
                              recipe: r,
                              onTap: () async {
                                // 1. Show loader if you want (optional)
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => Center(child: CircularProgressIndicator()),
                                );

                                // 2. Fetch RecipeDetail from Firestore
                                final detail = await RecipeTrackerService.fetchFullRecipeDetail(r.recipeId);

                                // 3. Hide loader
                                Navigator.of(context, rootNavigator: true).pop();

                                // 4. Check and route
                                if (detail != null) {
                                  context.push('/recipePage', extra: {
                                    'recipe': detail,
                                    'fromHistory': true, // Set true when coming from history
                                  });
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Recipe details not found.'))
                                  );
                                }
                              },
                            )
                          ).toList(),
                        ],
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