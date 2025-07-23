// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart';
// import 'package:glass/glass.dart';
// import '/utils/recipe_webview_dialog.dart';
import '/models/recipe.dart';
// import '/models/recipe_detail.dart';
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
