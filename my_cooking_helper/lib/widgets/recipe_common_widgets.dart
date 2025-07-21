// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/recipe_webview_dialog.dart';
import '/models/recipe.dart';
import '/models/recipe_detail.dart';
import '/utils/colors.dart';

/// Recipe Hero Image Card
class RecipeImageCard extends StatelessWidget {
  final String imageUrl;
  final bool isDark;
  final double width;
  final double height;
  final double borderRadius;

  const RecipeImageCard({
    super.key,
    required this.imageUrl,
    required this.isDark,
    this.width = double.infinity,
    this.height = 220,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 32.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: Image.network(
          imageUrl,
          width: width,
          height: height.h,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Container(
            width: width,
            height: height.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                      ? [Colors.grey[800]!, Colors.grey[700]!]
                      : [Colors.grey[200]!, Colors.grey[100]!],
              ),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded, 
              size: 64.sp, 
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                        ? [Colors.grey[800]!, Colors.grey[700]!]
                        : [Colors.grey[200]!, Colors.grey[100]!],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.deepPurple[300]! : Colors.deepPurple,
                  ),
                  value: loadingProgress.expectedTotalBytes != null
                       ? loadingProgress.cumulativeBytesLoaded /
                         loadingProgress.expectedTotalBytes!
                        : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Title Widget
class RecipeTitle extends StatelessWidget {
  final String title;
  final double fontSize;
  const RecipeTitle({super.key, required this.title, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: fontSize.sp,
        color: textColor(context),
        height: 1.2,
        letterSpacing: -0.5,
      ),
    );
  }
}

/// InfoChip for dish type/servings
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  final EdgeInsetsGeometry? margin;

  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    required this.isDark,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.deepPurple[800]!.withOpacity(0.34), Colors.deepPurple[700]!.withOpacity(0.2)]
              : [Colors.deepPurple.withOpacity(0.11), Colors.deepPurple.withOpacity(0.07)],
        ),
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: isDark
              ? Colors.deepPurple[400]!.withOpacity(0.26)
              : Colors.deepPurple.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, size: 16.sp, 
            color: isDark ? Colors.cyan[300] : Colors.deepPurple[700]
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.cyan[300] : Colors.deepPurple[700],
              ),
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.deepPurple[400]!, Colors.deepPurple[600]!]
                  : [Colors.deepPurple, Colors.deepPurple[700]!],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: Colors.white, size: 19.sp),
        ),
        SizedBox(width: 16.w),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            color: textColor(context),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Time Row Widget
class TimeRow extends StatelessWidget {
  final Recipe recipe;
  final bool isDark;
  final String Function(int) formatTime;

  const TimeRow({super.key, required this.recipe, required this.isDark, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (recipe.prepTime > 0)
          Expanded(
            child: TimeCard(
              icon: Icons.schedule_rounded,
              label: 'Prep',
              time: '${recipe.prepTime} min',
              isDark: isDark,
            ),
          ),
        if (recipe.prepTime > 0 && recipe.cookTime > 0)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text('|', style: TextStyle(fontSize: 16.sp, color: Colors.grey[500])),
          ),
        if (recipe.cookTime > 0)
          Expanded(
            child: TimeCard(
              icon: Icons.local_fire_department_rounded,
              label: 'Cook',
              time: '${recipe.cookTime} min',
              isDark: isDark,
            ),
          ),
        if ((recipe.cookTime > 0 || recipe.prepTime > 0) && recipe.totalTime > 0)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text('|', style: TextStyle(fontSize: 16.sp, color: Colors.grey[500])),
          ),
        if (recipe.totalTime > 0)
          Expanded(
            child: TimeCard(
              icon: Icons.timer_rounded,
              label: 'Total',
              time: formatTime(recipe.totalTime),
              isDark: isDark,
              isHighlighted: true,
            ),
          ),
      ],
    );
  }
}

/// Time Card Widget
class TimeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final bool isDark;
  final bool isHighlighted;

  const TimeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.time,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: isHighlighted
            ? LinearGradient(
                colors: isDark
                    ? [Colors.deepPurple[600]!, Colors.deepPurple[700]!]
                    : [Colors.deepPurple, Colors.deepPurple[600]!],
              )
            : LinearGradient(
                colors: isDark
                    ? [Colors.grey[800]!.withOpacity(0.5), Colors.grey[750]!.withOpacity(0.3)]
                    : [Colors.grey[100]!, Colors.grey[50]!],
              ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHighlighted
              ? (isDark ? Colors.deepPurple[400]! : Colors.deepPurple[300]!)
              : (isDark ? Colors.grey[600]!.withOpacity(0.3) : Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: isHighlighted
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isHighlighted
                  ? Colors.white.withOpacity(0.9)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            time,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? Colors.white
                  : textColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ingredients List Widget
class IngredientsList extends StatelessWidget {
  final List<dynamic> ingredients;
  final bool isDark;

  const IngredientsList({super.key, required this.ingredients, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark 
             ? Colors.blueGrey.withOpacity(0.25) 
             : Colors.red[50],
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark 
               ? Colors.grey[700]!.withOpacity(0.7) 
               : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        children: ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < ingredients.length - 1 ? 16.h : 0
            ),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.h,
                  margin: EdgeInsets.only(top: 5.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.deepPurple[200] : Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    '${ingredient.name}${ingredient.quantity.isNotEmpty ? " (${ingredient.quantity})" : ""}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: textColor(context),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Instructions List Widget
class InstructionsList extends StatelessWidget {
  final List<dynamic> instructions;
  final bool isDark;

  const InstructionsList({super.key, required this.instructions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: instructions.asMap().entries.map((entry) {
        final idx = entry.key;
        final step = entry.value;
        return AnimatedContainer(
          duration: Duration(milliseconds: 180 + idx * 60),
          curve: Curves.easeOutBack,
          margin: EdgeInsets.only(bottom: 13.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: isDark ? Colors.deepPurple[800]?.withOpacity(0.15) : Colors.deepPurple.withOpacity(0.1),
            border: Border.all(
              color: isDark 
              ? Colors.deepPurple[300]!.withOpacity(0.7) 
              : Colors.deepPurple.withOpacity(0.7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: isDark ? Colors.deepPurple[500] : Colors.deepPurple[300],
                radius: 16.w,
                child: Text("${idx + 1}",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    )),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  step,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: textColor(context),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Equipment Chips Widget
class EquipmentChips extends StatelessWidget {
  final List<String> equipment;
  final bool isDark;

  const EquipmentChips({super.key, required this.equipment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      children: equipment.map((e) => Chip(
        label: Text(
          e, 
          style: TextStyle(
            fontSize: 14.sp, 
            fontWeight: FontWeight.w600
          )
        ),
        backgroundColor: isDark 
          ? Colors.deepPurple[900]?.withOpacity(0.15) 
          : Colors.deepPurple.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      )).toList(),
    );
  }
}

// Nutrition Section (reuse your previous NutritionSection)
class NutritionSection extends StatelessWidget {
  final Map<String, dynamic> nutrition;

  const NutritionSection({Key? key, required this.nutrition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nutrients = nutrition['nutrients'] as List<dynamic>? ?? [];
    if (nutrients.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final important = [
      'Calories', 'Protein', 'Carbohydrates', 'Fat', 'Saturated Fat', 'Fiber', 'Sugar', 'Sodium'
    ];

    final filtered = nutrients.where((n) => important.contains(n['name'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.orange[600]!, Colors.orange[700]!]
                      : [Colors.orange[600]!, Colors.orange[700]!],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.local_dining_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 13.w),
            Text(
              'Nutrition',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21.sp,
                color: textColor(context),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850]?.withOpacity(0.47) : Colors.orange[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.orange[700]!.withOpacity(0.27) : Colors.orange[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: filtered.asMap().entries.map((entry) {
              final index = entry.key;
              final nutrient = entry.value;
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < filtered.length - 1 ? 10.h : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${nutrient['name'] ?? ''}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor(context),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.orange[800]?.withOpacity(0.32) : Colors.orange[100],
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Text(
                        '${nutrient['amount']?.toStringAsFixed(0) ?? ''} ${nutrient['unit'] ?? ''}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.orange[300] : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
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

/// -- Website Link Card Widget -- ///
class WebsiteLinkCard extends StatelessWidget {
  final String url;
  final bool isDark;
  final void Function(String url) onTap;
  final String buttonText;

  const WebsiteLinkCard({
    super.key,
    required this.url,
    required this.isDark,
    required this.onTap,
    this.buttonText = 'Visit Recipe Website',
  });

  @override
  Widget build(BuildContext context) {
    final originalUrl = url;
    final fixedUrl = url.startsWith('http://') ? url.replaceFirst('http://', 'https://') : url;
    print('\x1B[33m[DEBUG] Recipe Website tapped.\n[DEBUG] Original: $originalUrl\n[DEBUG] Modified: $fixedUrl\x1B[0m');
    
    return GestureDetector(
      onTap: () => onTap(fixedUrl),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
                ? [Colors.blue[700]!.withOpacity(0.2), Colors.blue[600]!.withOpacity(0.1)]
                : [Colors.blue.withOpacity(0.08), Colors.blue.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark 
                ? Colors.blue[400]!.withOpacity(0.3)
                : Colors.blue.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.language_rounded, 
              color: isDark ? Colors.blue[300] : Colors.blue[700], 
              size: 20.sp
            ),
            SizedBox(width: 12.w),
            Text(
              buttonText,
              style: TextStyle(
                color: isDark ? Colors.blue[300] : Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -- HTTP Warning Card Widget -- ///
class HttpWarningCard extends StatelessWidget {
  final bool isDark;

  const HttpWarningCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark 
             ? Colors.red[900]!.withOpacity(0.15) 
             : Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark 
               ? Colors.red[400]!.withOpacity(0.3) 
               : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded, 
            color: isDark ? Colors.red[300] : Colors.red[700], 
            size: 30.sp
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This website is not secure (HTTP).',
                  style: TextStyle(
                    color: isDark ? Colors.red[300] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
                Text(
                  'Your connection may not be private.',
                  style: TextStyle(
                    color: isDark ? Colors.red[300] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    height: 1.4,
                  ),
                ),
                Text(
                  'HTTPS version will be used if available.',
                  style: TextStyle(
                    color: isDark ? Colors.green[300] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DietChips extends StatelessWidget {
  final bool? vegetarian, vegan, glutenFree, dairyFree;
  final List<String> diets;
  final bool isDark;

  const DietChips({
    super.key,
    required this.vegetarian,
    required this.vegan,
    required this.glutenFree,
    required this.dairyFree,
    required this.diets,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (vegetarian == true) chips.add(_chip("Vegetarian"));
    if (vegan == true) chips.add(_chip("Vegan"));
    if (glutenFree == true) chips.add(_chip("Gluten Free"));
    if (dairyFree == true) chips.add(_chip("Dairy Free"));
    for (final diet in diets) {
      chips.add(_chip(diet));
    }
    return Wrap(spacing: 8, children: chips);
  }

  Widget _chip(String label) => Chip(
    label: Text(label),
    backgroundColor: isDark ? Colors.green[900] : Colors.green[50],
  );
}

class RecipeStatsRow extends StatelessWidget {
  final double? healthScore, pricePerServing, spoonacularScore;

  const RecipeStatsRow({
    super.key,
    required this.healthScore,
    required this.pricePerServing,
    required this.spoonacularScore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat("Health", healthScore != null ? healthScore!.toStringAsFixed(0) : "-"),
        _stat("Price", pricePerServing != null ? "${pricePerServing!.toStringAsFixed(0)}¢" : "-"),
        _stat("Score", spoonacularScore != null ? spoonacularScore!.toStringAsFixed(0) : "-"),
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class HtmlSummaryText extends StatelessWidget {
  final String html;
  const HtmlSummaryText({super.key, required this.html});
  @override
  Widget build(BuildContext context) {
    return Text(html.replaceAll(RegExp(r'<[^>]+>'), ''));
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
            builder: (_) => SimpleDialog(
              title: Text(ingredient.nameClean ?? ingredient.name ?? "Ingredient"),
              children: [
                if (ingredient.aisle != null) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('Aisle: ${ingredient.aisle}'),
                ),
                if (ingredient.meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('Meta: ${ingredient.meta.join(", ")}'),
                  ),
                if (ingredient.measures?.us != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('US: ${ingredient.measures?.us?.amount} ${ingredient.measures?.us?.unitShort}'),
                  ),
                if (ingredient.measures?.metric != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text('Metric: ${ingredient.measures?.metric?.amount} ${ingredient.measures?.metric?.unitShort}'),
                  ),
              ],
            ),
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

class CaloricBreakdownWidget extends StatelessWidget {
  final CaloricBreakdown? breakdown;
  const CaloricBreakdownWidget({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat("Protein", breakdown!.percentProtein),
        _stat("Fat", breakdown!.percentFat),
        _stat("Carbs", breakdown!.percentCarbs),
      ],
    );
  }

  Widget _stat(String label, double? value) {
    final v = value != null ? "${value.toStringAsFixed(1)}%" : "-";
    return Column(
      children: [
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

