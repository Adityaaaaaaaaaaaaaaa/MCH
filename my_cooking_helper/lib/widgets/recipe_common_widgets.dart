// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:glass/glass.dart';
import '/utils/recipe_webview_dialog.dart';
import '/models/recipe.dart';
import '/models/recipe_detail.dart';
import '/utils/colors.dart';

// Recipe Image Card
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

/// Title Widget, 2 file servi sa
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

// InfoChip for dish type/servings 2 file servi sa
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

// Section Header Widget , shared 2
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
                    ? [Colors.grey[800]!.withOpacity(0.5), Colors.grey[700]!.withOpacity(0.3)]
                    : [Colors.grey[100]!, Colors.grey[50]!],
              ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHighlighted
              ? (isDark ? Colors.deepPurple[400]! : Colors.deepPurple[300]!)
              : (isDark ? Colors.grey[600]!.withOpacity(0.3) : Colors.grey[500]!),
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

        // --- Enhanced type detection ---
        String stepText = '';
        int? number;
        List<dynamic> ingredients = [];
        List<dynamic> equipment = [];
        Map<String, dynamic>? length;

        if (step is Map && step.containsKey('step')) {
          // Map from API
          stepText = step['step'] ?? '';
          number = step['number'];
          ingredients = step['ingredients'] ?? [];
          equipment = step['equipment'] ?? [];
          length = step['length'] is Map ? step['length'] : null;
        } else if (step.runtimeType.toString().contains('InstructionStep')) {
          // Likely a model object, use reflection-like access
          try {
            stepText = step.step ?? '';
            number = step.number;
            ingredients = step.ingredients ?? [];
            equipment = step.equipment ?? [];
            length = step.length as Map<String, dynamic>?;
          } catch (_) {
            stepText = step.toString();
          }
        } else if (step is String) {
          stepText = step;
        } else {
          // Fallback
          stepText = step.toString();
        }

        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + idx * 70),
          curve: Curves.easeOutBack,
          margin: EdgeInsets.only(bottom: 14),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? Colors.deepPurple[800]?.withOpacity(0.15)
                : Colors.deepPurple.withOpacity(0.07),
            border: Border.all(
              color: isDark
                  ? Colors.deepPurple[300]!.withOpacity(0.7)
                  : Colors.deepPurple.withOpacity(0.18),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? Colors.deepPurple[400] : Colors.deepPurple[200],
                    radius: 18,
                    child: Text(
                      (number ?? idx + 1).toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      stepText,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (ingredients.isNotEmpty) ...[
                SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  children: ingredients.map<Widget>((ing) {
                    final name = ing['name'] ?? ing.name ?? '';
                    final imgUrl = ing['image'] != null
                        ? (ing['image'] is String && ing['image'].startsWith('http')
                            ? ing['image']
                            : 'https://spoonacular.com/cdn/ingredients_100x100/${ing['image']}')
                        : null;
                    return Chip(
                      avatar: imgUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(imgUrl),
                              backgroundColor: Colors.transparent,
                            )
                          : null,
                      label: Text(name),
                      backgroundColor: isDark
                          ? Colors.deepPurple[900]?.withOpacity(0.18)
                          : Colors.deepPurple.withOpacity(0.11),
                    );
                  }).toList(),
                ),
              ],
              if (equipment.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: equipment.map<Widget>((eq) {
                    final name = eq['name'] ?? eq.name ?? '';
                    final imgUrl = eq['image'] != null
                        ? (eq['image'] is String && eq['image'].startsWith('http')
                            ? eq['image']
                            : 'https://spoonacular.com/cdn/equipment_100x100/${eq['image']}')
                        : null;
                    return Chip(
                      avatar: imgUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(imgUrl),
                              backgroundColor: Colors.transparent,
                            )
                          : null,
                      label: Text(name),
                      backgroundColor: isDark
                          ? Colors.blueGrey[900]?.withOpacity(0.18)
                          : Colors.blueGrey.withOpacity(0.13),
                    );
                  }).toList(),
                ),
              ],
              if (length != null && (length['number'] != null && length['unit'] != null))
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(Icons.timer_rounded, size: 18, color: isDark ? Colors.orange[300] : Colors.orange[700]),
                      SizedBox(width: 6),
                      Text(
                        '${length['number']} ${length['unit']}',
                        style: TextStyle(
                          color: isDark ? Colors.orange[200] : Colors.orange[800],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
class NutritionSection extends StatefulWidget {
  final Map<String, dynamic> nutrition;

  const NutritionSection({
    Key? key,
    required this.nutrition,
  }) : super(key: key);

  @override
  State<NutritionSection> createState() => _NutritionSectionState();
}

class _NutritionSectionState extends State<NutritionSection> {
  bool expanded = false; // Always start collapsed

  @override
  Widget build(BuildContext context) {
    final nutrients = widget.nutrition['nutrients'] as List<dynamic>? ?? [];
    if (nutrients.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final important = [
      'Calories', 'Protein', 'Carbohydrates', 'Fat', 'Saturated Fat', 'Fiber', 'Sugar', 'Sodium'
    ];
    final displayNutrientsDefault = nutrients.where((n) => important.contains(n['name'])).toList();
    final displayNutrients = expanded ? nutrients : displayNutrientsDefault;

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
                      ? [Colors.orange.shade600, Colors.orange.shade700]
                      : [Colors.orange.shade600, Colors.orange.shade700],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.local_dining_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 15.w),
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
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850]?.withOpacity(0.47) : Colors.orange[50],
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.orange[700]!.withOpacity(0.27) : Colors.orange[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              ...displayNutrients.asMap().entries.map((entry) {
                final index = entry.key;
                final nutrient = entry.value;
                return Container(
                  margin: EdgeInsets.only(
                    bottom: index < displayNutrients.length - 1 ? 10.h : 0,
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
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${_safeAmount(nutrient['amount'])} ${nutrient['unit'] ?? ''}',
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
              }),
              if (nutrients.length > displayNutrientsDefault.length)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    child: Center(
                      child: Text(
                        expanded ? 'Show Less' : 'Show More',
                        style: TextStyle(
                          color: isDark ? Colors.orange[300] : Colors.orange[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _safeAmount(dynamic amount) {
    if (amount == null) return '';
    if (amount is num) return amount.toStringAsFixed(0);
    return amount.toString();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final healthColor = isDark ? Colors.green[400] : Colors.green[800];
    final scoreColor = isDark ? Colors.purple[300] : Colors.deepPurple[800];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stat(
          icon: Icons.favorite_rounded,
          label: "Health Score",
          value: healthScore != null ? healthScore!.toStringAsFixed(0) : "-",
          color: healthColor,
          isDark: isDark,
        ),
        /*_stat(
          icon: Icons.monetization_on_rounded,
          label: "Price",
          value: pricePerServing != null ? "${pricePerServing!.toStringAsFixed(0)}¢" : "-",
          color: priceColor,
          isDark: isDark,
        ),*/
        _stat(
          icon: Icons.star_rounded,
          label: "Spoonacular Score",
          value: spoonacularScore != null ? spoonacularScore!.toStringAsFixed(0) : "-",
          color: scoreColor,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _stat({
    required IconData icon,
    required String label,
    required String value,
    required Color? color,
    required bool isDark,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [color!.withOpacity(0.1), Colors.grey[900]!]
              : [color!.withOpacity(0.1), Colors.blueGrey[200]!],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.4 : 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class HtmlSummaryText extends StatelessWidget {
  final String html;
  const HtmlSummaryText({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.deepPurple[900]?.withOpacity(0.12) : Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.deepPurple[300]!.withOpacity(0.2) : Colors.deepPurple.withOpacity(0.08),
        ),
      ),
      child: HtmlWidget(
        html,
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
