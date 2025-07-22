// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:glass/glass.dart';
import '/utils/recipe_webview_dialog.dart';
import '/models/recipe_detail.dart';
import '/utils/colors.dart';

class HealthScoreCard extends StatelessWidget {
  final double? healthScore;
  const HealthScoreCard({Key? key, required this.healthScore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final score = (healthScore ?? 0).clamp(0, 100);
    final grade = _getGradeData(score.toDouble());
    final accent = score >= 80
        ? colorScheme.primary
        : score >= 60
            ? colorScheme.secondary
            : colorScheme.error;

    return Container(
      height: 150.h,
      margin: EdgeInsets.all(10.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark
                ? colorScheme.surface.withOpacity(0.83)
                : colorScheme.surface.withOpacity(0.94),
            isDark
                ? colorScheme.background.withOpacity(0.83)
                : colorScheme.background.withOpacity(0.94),
          ],
        ),
        border: Border.all(
          color: accent.withOpacity(0.19),
          width: 1.1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Heart + Score Column, centered vertically and spaced
          Expanded(
            flex: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(7.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withOpacity(0.2),
                  ),
                  child: Icon(Icons.favorite_rounded, size: 30.sp, color: accent),
                ),
                SizedBox(height: 12.h),
                Text(
                  "${score.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  "Grade: ${grade['grade']}",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),

          // Vertical Divider, centered and sized to column
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Container(
              width: 1.5,
              height: 70.h,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.13),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),

          // Main Info Column, spaced evenly and vertically centered
          Expanded(
            flex: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacer(),
                _divLine(context, "Health Score", accent, isDark, weight: FontWeight.w700),
                SizedBox(height: 10.h),
                _divLine(context, "${grade['emoji']} ${grade['label']}", accent, isDark),
                SizedBox(height: 10.h),
                _divLine(context, "Higher scores = more good, less bad nutrients.", accent, isDark)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divLine(
      BuildContext context, String text, Color accent, bool isDark,
      {FontWeight? weight}) {
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14.sp,
        color: isDark
            ? accent.withOpacity(0.89)
            : accent.withOpacity(0.81),
        fontWeight: weight ?? FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  Map<String, dynamic> _getGradeData(double score) {
    if (score >= 95) return {'grade': 'S+', 'emoji': '🌟', 'label': 'Perfect'};
    if (score >= 90) return {'grade': 'S', 'emoji': '🏆', 'label': 'Excellent'};
    if (score >= 85) return {'grade': 'A+', 'emoji': '💎', 'label': 'Outstanding'};
    if (score >= 80) return {'grade': 'A', 'emoji': '🥇', 'label': 'Great'};
    if (score >= 75) return {'grade': 'A-', 'emoji': '⭐', 'label': 'Very Good'};
    if (score >= 70) return {'grade': 'B+', 'emoji': '🌸', 'label': 'Good'};
    if (score >= 65) return {'grade': 'B', 'emoji': '🌼', 'label': 'Fair'};
    if (score >= 60) return {'grade': 'B-', 'emoji': '🌻', 'label': 'Okay'};
    if (score >= 50) return {'grade': 'C', 'emoji': '🌿', 'label': 'Needs Work'};
    if (score >= 30) return {'grade': 'D', 'emoji': '🌱', 'label': 'Poor'};
    return {'grade': 'F', 'emoji': '🍃', 'label': 'Critical'};
  }
}

class RecipeSummaryText extends StatelessWidget {
  final Map<String, dynamic>? geminiSummary;
  final String originalHtmlSummary;

  const RecipeSummaryText({
    Key? key,
    required this.originalHtmlSummary,
    this.geminiSummary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (geminiSummary == null) {
      // Fallback to HTML
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.deepPurple[900]?.withOpacity(0.12)
              : Colors.deepPurple[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.deepPurple[300]!.withOpacity(0.2)
                : Colors.deepPurple.withOpacity(0.08),
          ),
        ),
        child: HtmlWidget(
          originalHtmlSummary,
          textStyle: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            height: 1.6,
          ),
          onTapUrl: (url) {
            showRecipeWebView(context, url);
            print('Tapped URL: $url');
            return true;
          },
        )
      );
    }

    // --- AI Summary Display ---
    final highlights = (geminiSummary?['highlights'] as List?)?.cast<String>() ?? [];
    final time = _extractTimeFromSummary(geminiSummary);
    final nutrition = geminiSummary?['nutrition'] as String?;
    final servings = geminiSummary?['servings'] as String?;
    final title = geminiSummary?['title'] as String?;
    final shortSummary = geminiSummary?['short_summary'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.deepPurple[900]?.withOpacity(0.12)
            : Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.deepPurple[300]!.withOpacity(0.2)
              : Colors.deepPurple.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Enhanced Label Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 20.sp, color: Colors.blue[400]),
              SizedBox(width: 6.w),
              Text(
                "Summary (AI-Enhanced)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.deepPurple[100] : Colors.deepPurple[800],
                ),
              ),
            ],
          ),
          // if (title != null && title.isNotEmpty) ...[
          //   SizedBox(height: 7.h),
          //   Text(
          //     title,
          //     style: TextStyle(
          //       fontWeight: FontWeight.w700,
          //       fontSize: 18.sp,
          //       color: Theme.of(context).colorScheme.primary,
          //     ),
          //   ),
          // ],
          if (shortSummary != null && shortSummary.isNotEmpty) ...[
            SizedBox(height: 7.h),
            Text(
              shortSummary,
              style: TextStyle(
                fontSize: 16.sp,
                height: 1.5,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
          if ((servings != null && servings.isNotEmpty) ||
              (nutrition != null && nutrition.isNotEmpty) ||
              (time != null && time.isNotEmpty)) ...[
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (servings != null && servings.isNotEmpty)
                  _buildInfoChip(context, icon: Icons.people_alt_rounded, label: 'Serves $servings'),
                if (nutrition != null && nutrition.isNotEmpty)
                  _buildInfoChip(context, icon: Icons.local_fire_department, label: nutrition),
                if (time != null && time.isNotEmpty)
                  _buildInfoChip(context, icon: Icons.timer, label: time),
              ],
            ),
          ],
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 9),
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: highlights
                    .map((e) => Chip(
                          label: Text(e, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500)),
                          backgroundColor: Colors.deepPurple[100]?.withOpacity(0.5),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper to extract time info if available in the short summary or nutrition
  String? _extractTimeFromSummary(Map<String, dynamic>? summary) {
    // Try to find time in the short summary (regex for "XX min" or "XX hr YY min")
    final shortSummary = summary?['short_summary'] as String? ?? '';
    final match = RegExp(r'(\d+\s*hr)?\s*(\d+)\s*min').firstMatch(shortSummary);
    if (match != null) {
      return match.group(0)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    return null;
  }

  Widget _buildInfoChip(BuildContext context, {required IconData icon, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Chip(
        avatar: Icon(icon, color: isDark ? Colors.deepPurple[200] : Colors.deepPurple[400], size: 18.sp),
        label: Text(label, style: TextStyle(fontSize: 14.sp)),
        backgroundColor: isDark ? Colors.deepPurple[700]?.withOpacity(0.18) : Colors.deepPurple[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(horizontal: 6.w),
      ),
    );
  }
}

class ExtendedIngredientCard extends StatelessWidget {
  final ExtendedIngredient ingredient;
  final bool isDark;
  const ExtendedIngredientCard({super.key, required this.ingredient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? Colors.deepPurple[900]?.withOpacity(0.08) : Colors.deepPurple.withOpacity(0.03),
      child: ListTile(
        leading: ingredient.image != null
            ? Image.network(
                'https://spoonacular.com/cdn/ingredients_100x100/${ingredient.image}',
                width: 40, errorBuilder: (_, __, ___) => const SizedBox.shrink())
            : null,
        title: Text(ingredient.original ?? ingredient.name ?? ""),
        subtitle: Text(_subtitle(ingredient)),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => GlassIngredientDialog(ingredient: ingredient, isDark: isDark),
          );
        },
      ),
    );
  }

  String _subtitle(ExtendedIngredient i) {
    final a = i.amount != null ? i.amount!.toStringAsFixed(2) : "";
    final u = i.unit ?? "";
    return (a.isNotEmpty || u.isNotEmpty) ? "$a $u" : "";
  }
}

// --- Glass Dialog Widget ---
class GlassIngredientDialog extends StatelessWidget {
  final ExtendedIngredient ingredient;
  final bool isDark;

  const GlassIngredientDialog({
    Key? key,
    required this.ingredient,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textCol = isDark ? Colors.white : Colors.grey[900];
    final titleCol = isDark ? Colors.deepPurple[100] : Colors.deepPurple[800];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 330.w,
        constraints: BoxConstraints(maxHeight: 340.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.12), width: 1.3),
            ),
            child: Stack(
              children: [
                // Glass background
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.deepPurple[200]?.withOpacity(isDark ? 0.14 : 0.22),
                ).asGlass(
                  blurX: 18,
                  blurY: 18,
                  tintColor: isDark ? Colors.deepPurple[900]! : Colors.white,
                  frosted: true,
                  clipBorderRadius: BorderRadius.circular(24.r),
                ),
                // Foreground content
                Padding(
                  padding: EdgeInsets.all(15.0.w),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ingredient image
                        ingredient.image != null
                          ? ClipOval(
                              child: Image.network(
                              'https://spoonacular.com/cdn/ingredients_100x100/${ingredient.image}',
                              fit: BoxFit.contain,
                              width: 70.r,
                              height: 70.r,
                            ),
                          )
                          : Icon(Icons.restaurant, color: titleCol, size: 32.sp),
                        SizedBox(height: 15.h),

                        Text(
                          ingredient.nameClean ?? ingredient.name ?? '',
                          style: TextStyle(
                            fontSize: 23.sp,
                            fontWeight: FontWeight.w700,
                            color: textColor(context),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        if ((ingredient.original ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3, bottom: 8),
                            child: Text(
                              'Quantity: ${ingredient.original}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: textCol?.withOpacity(0.75),
                              ),
                            ),
                          ),
                        Divider(height: 30, thickness: 4, color: Colors.cyan.withOpacity(0.50)),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _amountCol("US", ingredient.measures?.us?.amount, ingredient.measures?.us?.unitShort, textCol),
                            _amountCol("Metric", ingredient.measures?.metric?.amount, ingredient.measures?.metric?.unitShort, textCol),
                          ],
                        ),
                        Divider(height: 30, thickness: 4, color: Colors.cyan.withOpacity(0.50)),

                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          children: [
                            // if (ingredient.aisle != null && ingredient.aisle!.isNotEmpty)
                            //   _infoChip(Icons.store_mall_directory, ingredient.aisle!, textCol),
                            // if (ingredient.consistency != null)
                            //   _infoChip(Icons.layers, ingredient.consistency!.toLowerCase(), textCol),
                            if (ingredient.meta.isNotEmpty)
                              for (final m in ingredient.meta)
                                _infoChip(Icons.label_important_rounded, m, textCol),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Close button
                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountCol(String label, double? amount, String? unit, Color? textCol) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(
          '${amount != null ? amount.toStringAsFixed(2) : '-'} ${unit ?? ''}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, Color? color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color?.withOpacity(0.68)),
      label: Text(label, style: TextStyle(fontSize: 13, color: color)),
      backgroundColor: color?.withOpacity(0.08) ?? Colors.deepPurple.withOpacity(0.09),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}

class CaloricBreakdownWidget extends StatefulWidget {
  final CaloricBreakdown? breakdown;
  final bool? glutenFree;
  final bool? dairyFree;
  final Map<String, dynamic>? weightPerServing;
  final bool? isDark;

  const CaloricBreakdownWidget({
    super.key,
    required this.breakdown,
    this.glutenFree,
    this.dairyFree,
    this.weightPerServing,
    this.isDark,
  });

  @override
  State<CaloricBreakdownWidget> createState() => _CaloricBreakdownWidgetState();
}

class _CaloricBreakdownWidgetState extends State<CaloricBreakdownWidget>
    with SingleTickerProviderStateMixin {
  bool tapped = false;
  bool isHovered = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOutSine,
    ));
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.breakdown == null) return const SizedBox.shrink();

    final themeIsDark = widget.isDark ?? Theme.of(context).brightness == Brightness.dark;
    final accent = themeIsDark ? Colors.amber[300] : Colors.deepOrange[600];
    final cardBg = themeIsDark ? Colors.grey[900]!.withOpacity(0.1) : Colors.white.withOpacity(0.1);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => tapped = true),
        onTapUp: (_) => setState(() => tapped = false),
        onTapCancel: () => setState(() => tapped = false),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(tapped ? 0.97 : (isHovered ? 1.02 : 1.0))
            ..rotateZ(isHovered ? 0.001 : 0.0),
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeIsDark
                      ? [
                          Colors.amber[900]!.withOpacity(0.1),
                          Colors.orange[800]!.withOpacity(0.05),
                          Colors.deepOrange[700]!.withOpacity(0.08),
                        ]
                      : [
                          Colors.orange[50]!.withOpacity(0.8),
                          Colors.amber[50]!.withOpacity(0.6),
                          Colors.deepOrange[50]!.withOpacity(0.7),
                        ],
                ),
                border: Border.all(
                  color: themeIsDark 
                      ? Colors.amber[400]!.withOpacity(isHovered ? 0.6 : 0.3) 
                      : Colors.orange[300]!.withOpacity(isHovered ? 0.8 : 0.4),
                  width: isHovered ? 2.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeIsDark
                        ? Colors.amber[600]!.withOpacity(isHovered ? 0.2 : 0.1)
                        : Colors.deepOrange.withOpacity(isHovered ? 0.25 : 0.12),
                    blurRadius: isHovered ? 30 : 20,
                    offset: Offset(0, isHovered ? 12 : 8),
                    spreadRadius: isHovered ? 2 : 0,
                  ),
                  BoxShadow(
                    color: themeIsDark
                        ? Colors.amber[900]!.withOpacity(0.1)
                        : Colors.orange[200]!.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: Stack(
                  children: [
                    // Subtle shimmer effect
                    if (isHovered)
                      AnimatedBuilder(
                        animation: _shimmerAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: -50,
                            left: _shimmerAnimation.value * MediaQuery.of(context).size.width,
                            child: Transform.rotate(
                              angle: 0.2,
                              child: Container(
                                width: 50,
                                height: 200,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      (themeIsDark ? Colors.amber[200] : Colors.orange[300])!
                                          .withOpacity(0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    // Main content
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 26.h, horizontal: 22.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Heading Row
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accent!.withOpacity(isHovered ? 0.2 : 0.1),
                                      accent.withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.pie_chart_rounded,
                                  color: accent,
                                  size: 28.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Caloric Breakdown",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20.sp,
                                        color: accent,
                                        letterSpacing: -0.5,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "Nutritional Information",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: (themeIsDark ? Colors.grey[400] : Colors.grey[600]),
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // Enhanced Macro Circles
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0, 0.3),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(widget.breakdown),
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _circularStat("Protein", widget.breakdown!.percentProtein, themeIsDark, 
                                      themeIsDark ? Colors.green[400]! : Colors.green[600]!),
                                  _circularStat("Fat", widget.breakdown!.percentFat, themeIsDark, 
                                      themeIsDark ? Colors.red[400]! : Colors.redAccent[700]!),
                                  _circularStat("Carbs", widget.breakdown!.percentCarbs, themeIsDark, 
                                      themeIsDark ? Colors.blue[400]! : Colors.blue[600]!),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 22.h),

                          // Modern divider with gradient
                          Container(
                            height: 1.5.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1.r),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  themeIsDark
                                      ? Colors.amber[400]!.withOpacity(0.3)
                                      : Colors.orange[400]!.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Enhanced Chips
                          Center(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 10.w,
                                runSpacing: 8.h,
                                children: [
                                  if (widget.glutenFree != null)
                                    _tagChip(
                                      icon: widget.glutenFree! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      label: "Gluten-Free",
                                      color: widget.glutenFree! 
                                          ? (themeIsDark ? Colors.green[400]! : Colors.green[600]!)
                                          : (themeIsDark ? Colors.red[400]! : Colors.redAccent[700]!),
                                      themeIsDark: themeIsDark,
                                    ),
                                  if (widget.dairyFree != null)
                                    _tagChip(
                                      icon: widget.dairyFree! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      label: "Dairy-Free",
                                      color: widget.dairyFree! 
                                          ? (themeIsDark ? Colors.green[400]! : Colors.green[600]!)
                                          : (themeIsDark ? Colors.red[400]! : Colors.redAccent[700]!),
                                      themeIsDark: themeIsDark,
                                    ),
                                  if (widget.weightPerServing != null &&
                                      widget.weightPerServing!['amount'] != null &&
                                      widget.weightPerServing!['unit'] != null)
                                    _tagChip(
                                      icon: Icons.restaurant_rounded,
                                      label: "${widget.weightPerServing!['amount']} ${widget.weightPerServing!['unit']}/serving",
                                      color: themeIsDark ? Colors.amber[400]! : Colors.amber[700]!,
                                      themeIsDark: themeIsDark,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).asGlass(
              blurX: 8,
              blurY: 8,
              tintColor: cardBg,
              frosted: true,
              clipBorderRadius: BorderRadius.circular(28.r),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circularStat(String label, double? value, bool isDark, Color color) {
    final val = value ?? 0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: val / 100),
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return MouseRegion(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            child: Column(
              children: [
                Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background circle
                      CircularProgressIndicator(
                        value: 1.0,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(
                          (isDark ? Colors.grey[800] : Colors.grey[200])!.withOpacity(0.3)
                        ),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                      // Progress circle with gradient effect
                      CircularProgressIndicator(
                        value: animValue,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(color),
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                      // Center content
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? Colors.grey[900] : Colors.white)!.withOpacity(0.9),
                            border: Border.all(
                              color: color.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "${(animValue * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp,
                                color: color,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[300] : color.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tagChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool themeIsDark,
  }) {
    return MouseRegion(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          splashColor: color.withOpacity(0.2),
          highlightColor: color.withOpacity(0.1),
          onTap: () {}, // Could open a tooltip or info dialog
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(themeIsDark ? 0.15 : 0.1),
                  color.withOpacity(themeIsDark ? 0.1 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                  child: Icon(icon, color: color, size: 16.sp),
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    color: themeIsDark ? Colors.grey[300] : color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeYoutubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;

  RecipeYoutubeVideo({
    required this.videoId, 
    required this.title, 
    required this.channelTitle
  });

  factory RecipeYoutubeVideo.fromJson(Map<String, dynamic> json) {
    return RecipeYoutubeVideo(
      videoId: json['videoId'] as String,
      title: json['title'] as String,
      channelTitle: json['channelTitle'] as String,
    );
  }
}

class RecipeVideosSection extends StatefulWidget {
  final List<RecipeYoutubeVideo> videos;
  const RecipeVideosSection({Key? key, required this.videos}) : super(key: key);

  @override
  State<RecipeVideosSection> createState() => _RecipeVideosSectionState();
}

class _RecipeVideosSectionState extends State<RecipeVideosSection> {
  bool showAll = false;
  int selected = 0; // Only this index will have a controller
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initController(selected);
  }

  void _initController(int index) {
    _controller?.close();
    final video = widget.videos[index];
    _controller = YoutubePlayerController.fromVideoId(
      videoId: video.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        showControls: true,
        showFullscreenButton: true,
        enableKeyboard: true,
        enableJavaScript: true,
      ),
    );
    // Only one controller/listener needed, so no risk of memory leak or UI lag
  }

  @override
  void didUpdateWidget(covariant RecipeVideosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videos != widget.videos && widget.videos.isNotEmpty) {
      // Reset selected and controller if the list changes
      selected = 0;
      _initController(selected);
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) return const SizedBox.shrink();

    final mainVideo = widget.videos[selected];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main player for the selected video
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              YoutubePlayer(
                controller: _controller!,
                aspectRatio: 16 / 9,
              ),
              const SizedBox(height: 4),
              Text(mainVideo.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(mainVideo.channelTitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        // "Show More" reveals thumbnails and metadata for other videos, but never instantiates more YoutubePlayers
        if (widget.videos.length > 1 && !showAll)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => setState(() => showAll = true),
              child: const Text("Show More Videos"),
            ),
          ),
        if (showAll && widget.videos.length > 1)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.videos.length,
            itemBuilder: (context, i) {
              if (i == selected) return const SizedBox.shrink(); // Skip main video
              final video = widget.videos[i];
              return ListTile(
                leading: Image.network('https://img.youtube.com/vi/${video.videoId}/0.jpg', width: 80.w, fit: BoxFit.cover),
                title: Text(video.title),
                subtitle: Text(video.channelTitle),
                onTap: () {
                  setState(() {
                    selected = i;
                    showAll = false;
                    _initController(selected); // Clean up and re-create only the needed player
                  });
                },
              );
            },
          ),
      ],
    );
  }
}

/// -- In-app WebView Dialog Helper -- ///
void showRecipeWebView(BuildContext context, String url) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.12),
    builder: (context) => RecipeWebViewDialog(url: url),
  );
}
