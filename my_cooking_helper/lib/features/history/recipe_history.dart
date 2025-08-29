import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '/models/recipe_history.dart' show RecipeHistoryEntry, UnifiedHistoryItem, RecipeSource;
import '/services/recipe_tracker_service.dart';
import '/services/cravings_recipe_service.dart';
import '/theme/app_theme.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/utils/colors.dart';
import '/widgets/recipe/recipe_tracker_widgets.dart';

// ===== Existing normal stream (unchanged) =====================================
final cookedRecipesProvider = StreamProvider<List<RecipeHistoryEntry>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return const Stream.empty();
  return RecipeTrackerService.cookedRecipesStream(userId);
});

// ===== AI cooked stream (client-side filter; resilient to missing fields) =====
final cookedAiRawProvider = StreamProvider<List<UnifiedHistoryItem>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  final coll = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('userTrackers');

  return coll.snapshots().map((snap) {
    final out = <UnifiedHistoryItem>[];
    for (final d in snap.docs) {
      final m = d.data();
      final tc = (m['timesCooked'] as int?) ?? 0;
      final lc = m['lastCookedAt']; // Timestamp? may be null
      if (tc > 0 || lc != null) {
        out.add(UnifiedHistoryItem.fromAi(d.id, m));
      }
    }
    return out;
  });
});

// ===== Page ===================================================================
class RecipeHistoryPage extends ConsumerWidget {
  const RecipeHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalAsync = ref.watch(cookedRecipesProvider);
    final aiAsync = ref.watch(cookedAiRawProvider);

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

                // Normal -> Unified
                final normal =
                    (normalAsync.value ?? const <RecipeHistoryEntry>[])
                        .map((r) => UnifiedHistoryItem(
                              id: r.recipeId,
                              source: RecipeSource.normal,
                              title: r.recipeTitle,
                              isFavourite: r.isFavourite,
                              timesCooked: r.timesCooked,
                              lastCookedAt: r.lastCookedAt,
                              imageUrl: r.imageUrl,
                            ))
                        .toList();

                // AI already Unified
                final ai = aiAsync.value ?? const <UnifiedHistoryItem>[];

                // Merge & sort by lastCookedAt desc (nulls last)
                int ts(UnifiedHistoryItem x) =>
                    x.lastCookedAt?.millisecondsSinceEpoch ?? 0;
                final merged = <UnifiedHistoryItem>[...normal, ...ai]
                  ..sort((a, b) => ts(b).compareTo(ts(a)));

                final groups = _groupByRecency(merged);

                if (groups.isEmpty) {
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
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.label,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textColor(context).withOpacity(0.75),
                              ),
                        ),
                        SizedBox(height: 6.h),
                        ...g.items.map((it) {

                          final isAi = it.source == RecipeSource.ai;

                          // ✅ Live favourite for AI items (falls back to list value while loading)
                          bool fav = it.isFavourite;
                          if (isAi) {
                            final favAsync = ref.watch(cravingFavouriteStatusProvider(it.id));
                            fav = favAsync.maybeWhen(
                              data: (v) => v,
                              orElse: () => it.isFavourite,
                            );
                          }

                          // 🔁 Adapt UnifiedHistoryItem -> RecipeHistoryEntry for the shared card
                          final entry = RecipeHistoryEntry(
                            recipeId: it.id,
                            recipeTitle: it.title,
                            isFavourite: fav,                 // 👈 use the live flag
                            lastCookedAt: it.lastCookedAt,
                            timesCooked: it.timesCooked,
                            imageUrl: it.imageUrl,
                            markFavOn: null,
                          );

                          return CookedRecipeCard(
                            key: ValueKey('${isAi ? "ai" : "n"}-${it.id}-${fav ? 1 : 0}'), // 👈 force rebuild when fav changes
                            recipe: entry,
                            imageUrl: it.imageUrl,
                            isAi: isAi,
                            onTap: () async {
                              if (uid == null) return;

                              // loader
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );

                              // ===== normal recipe (unchanged) =====
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

                              // --- AI recipe open (safe, no collectionGroup) ---
                              final found = await CravingsRecipeService.fetchCravingByRecipeKey(
                                uid: uid,
                                recipeKey: it.id, // this is the ai:<hash>
                              );

                              Navigator.of(context, rootNavigator: true).pop();

                              if (found == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('AI recipe not found.')),
                                );
                                return;
                              }

                              // pass pointers too so the page can reflect "from history" state, etc.
                              context.push('/cravingRecipe', extra: {
                                'recipe': found.recipe,
                                'fromHistory': true,
                                'recipeKey': it.id,            // <-- 'ai:<hash>' from the history item
                                'sessionId': found.sessionId,  // optional
                                'trackerId': found.trackerId,  // optional
                              });
                            },
                          );
                        }).toList(),
                      ],
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

  // ==== grouping helpers (Today, Yesterday, Week, Earlier, Unknown) ===========
  List<_Group> _groupByRecency(List<UnifiedHistoryItem> items) {
    final now = DateTime.now();
    final today = <UnifiedHistoryItem>[];
    final yesterday = <UnifiedHistoryItem>[];
    final week = <UnifiedHistoryItem>[];
    final older = <UnifiedHistoryItem>[];
    final unknown = <UnifiedHistoryItem>[];

    for (final r in items) {
      final d = r.lastCookedAt;
      if (d == null) {
        unknown.add(r);
        continue;
      }
      final daysAgo = now.difference(DateTime(d.year, d.month, d.day)).inDays;
      if (daysAgo == 0) {
        today.add(r);
      } else if (daysAgo == 1) {
        yesterday.add(r);
      } else if (daysAgo < 7) {
        week.add(r);
      } else {
        older.add(r);
      }
    }

    final out = <_Group>[];
    if (today.isNotEmpty) out.add(_Group('Today', today));
    if (yesterday.isNotEmpty) out.add(_Group('Yesterday', yesterday));
    if (week.isNotEmpty) out.add(_Group('Earlier this week', week));
    if (older.isNotEmpty) out.add(_Group('Earlier', older));
    if (unknown.isNotEmpty) out.add(_Group('Unknown', unknown));
    return out;
  }
}

class _Group {
  final String label;
  final List<UnifiedHistoryItem> items;
  _Group(this.label, this.items);
}
