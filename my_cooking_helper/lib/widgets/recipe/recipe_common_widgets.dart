// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/web_check.dart';
import '/models/recipe.dart';
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

        // --- Enhanced type detection (unchanged) ---
        String stepText = '';
        int? number;
        List<dynamic> ingredients = [];
        List<dynamic> equipment = [];
        Map<String, dynamic>? length;

        if (step is Map && step.containsKey('step')) {
          stepText = step['step'] ?? '';
          number = step['number'];
          ingredients = step['ingredients'] ?? [];
          equipment = step['equipment'] ?? [];
          length = step['length'] is Map ? step['length'] : null;
        } else if (step.runtimeType.toString().contains('InstructionStep')) {
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
          stepText = step.toString();
        }

        return _InstructionTileAnimated(
          index: number ?? idx + 1,
          stepText: stepText,
          ingredients: ingredients,
          equipment: equipment,
          length: length,
          isDark: isDark,
          // preserve your existing entrance animation timings
          outerAnimMs: 200 + idx * 70,
        );
      }).toList(),
    );
  }
}

///
/// Private stateful tile that adds:
///  - tap to toggle completion
///  - strike-through on text when done
///  - animated index badge: halo + ring fill + number→check
///
class _InstructionTileAnimated extends StatefulWidget {
  const _InstructionTileAnimated({
    required this.index,
    required this.stepText,
    required this.ingredients,
    required this.equipment,
    required this.length,
    required this.isDark,
    required this.outerAnimMs,
  });

  final int index;
  final String stepText;
  final List<dynamic> ingredients;
  final List<dynamic> equipment;
  final Map<String, dynamic>? length;
  final bool isDark;
  final int outerAnimMs;

  @override
  State<_InstructionTileAnimated> createState() => _InstructionTileAnimatedState();
}

class _InstructionTileAnimatedState extends State<_InstructionTileAnimated>
    with SingleTickerProviderStateMixin {
  bool done = false;

  late final AnimationController _ctrl;
  late final Animation<double> _progress;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleDone() {
    setState(() => done = !done);
    if (done) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // keep your card colors/border as close as possible
    final cardBg = isDark
        ? Colors.deepPurple[800]?.withOpacity(0.15)
        : Colors.deepPurple.withOpacity(0.07);
    final cardBorder = Border.all(
      color: isDark
          ? Colors.deepPurple[300]!.withOpacity(0.7)
          : Colors.deepPurple.withOpacity(0.18),
      width: 1.2,
    );

    // adaptive text colors similar to your previous logic
    final textColor = theme.textTheme.bodyLarge?.color?.withOpacity(done ? 0.75 : 0.95);

    // progress ring track
    final trackCol = isDark ? Colors.white12 : Colors.black12;
    final haloCol = isDark ? primary.withOpacity(0.50) : primary.withOpacity(0.35);

    return AnimatedContainer(
      duration: Duration(milliseconds: widget.outerAnimMs),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cardBg,
        border: cardBorder,
      ),
      child: InkWell(
        onTap: _toggleDone,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: animated badge + body
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // —— Animated index badge (halo + ring + number→check) ——
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Halo
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (_, __) => Opacity(
                            opacity: _glow.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: haloCol,
                                    blurRadius: 16 * _glow.value,
                                    spreadRadius: 1.6 * _glow.value,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Track
                        CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(trackCol),
                          backgroundColor: Colors.transparent,
                        ),

                        // Fill
                        AnimatedBuilder(
                          animation: _progress,
                          builder: (_, __) => CircularProgressIndicator(
                            value: _progress.value,
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(primary),
                            backgroundColor: Colors.transparent,
                          ),
                        ),

                        // Core circle (number → check)
                        Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.85)],
                            ),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeOut,
                              child: done
                                  ? const Icon(Icons.check_rounded,
                                      key: ValueKey('check'), color: Colors.white, size: 18)
                                  : Text(
                                      "${widget.index}",
                                      key: const ValueKey('num'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // —— Body text with strike-through when done ——
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15.5,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
                        decorationThickness: 1,
                        decorationColor: isDark ? Colors.red : Colors.red,
                      ),
                      child: Text(
                        widget.stepText,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                ],
              ),

              // —— Chips and time (unchanged) ——
              if (widget.ingredients.isNotEmpty) ...[
                const SizedBox(height: 10),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 9,
                    children: widget.ingredients.map<Widget>((ing) {
                      final name = ing is Map
                          ? (ing['name'] ?? '')
                          : (ing?.name ?? '');
                      final rawImg = ing is Map ? ing['image'] : ing?.image;
                      final imgUrl = rawImg != null
                          ? (rawImg is String && rawImg.startsWith('http')
                              ? rawImg
                              : 'https://spoonacular.com/cdn/ingredients_100x100/$rawImg')
                          : null;
                      return Chip(
                        avatar: imgUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(imgUrl),
                                backgroundColor: Colors.transparent,
                              )
                            : null,
                        label: Text(name),
                        backgroundColor: widget.isDark
                            ? Colors.blueGrey.withOpacity(0.20)
                            : Colors.deepPurple.withOpacity(0.25),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (widget.equipment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: widget.equipment.map<Widget>((eq) {
                      final name = eq is Map
                          ? (eq['name'] ?? '')
                          : (eq?.name ?? '');
                      final rawImg = eq is Map ? eq['image'] : eq?.image;
                      final imgUrl = rawImg != null
                          ? (rawImg is String && rawImg.startsWith('http')
                              ? rawImg
                              : 'https://spoonacular.com/cdn/equipment_100x100/$rawImg')
                          : null;
                      return Chip(
                        avatar: imgUrl != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(imgUrl),
                                backgroundColor: Colors.transparent,
                              )
                            : null,
                        label: Text(name),
                        backgroundColor: widget.isDark
                            ? Colors.grey.withOpacity(0.20)
                            : Colors.blueGrey.withOpacity(0.25),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (widget.length != null && (widget.length!['number'] != null && widget.length!['unit'] != null))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // keeps icon+text centered together
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 18.sp,
                          color: widget.isDark ? Colors.orange[300] : Colors.orange[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.length!['number']} ${widget.length!['unit']}',
                          style: TextStyle(
                            color: widget.isDark ? Colors.orange[200] : Colors.orange[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
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
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
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
      ),
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
    return FutureBuilder<WebsiteCheckResult>(
      future: WebChecker.check(url),
      builder: (context, snap) {
        final result = snap.data;
        final resolvedUrl = result?.resolvedUrl ?? url;

        // Blue debug prints (your convention)
        // 34m => blue; 0m => reset
        print('\x1B[34m[WEBCHK] url="$url" -> resolved="$resolvedUrl" '
              'wasHttp=${result?.wasHttp} httpsOk=${result?.httpsAvailable} '
              'mobileFriendly=${result?.mobileFriendly}\x1B[0m');

        return GestureDetector(
          onTap: () => onTap(resolvedUrl),
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue[700]!.withOpacity(0.22), Colors.blue[600]!.withOpacity(0.10)]
                    : [Colors.blue.withOpacity(0.10), Colors.blue.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.blue[300]!.withOpacity(0.35)
                    : Colors.blue.withOpacity(0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Main action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.language_rounded,
                        color: isDark ? Colors.blue[200] : Colors.blue[800],
                        size: 20.sp),
                    SizedBox(width: 10.w),
                    Text(
                      buttonText,
                      style: TextStyle(
                        color: isDark ? Colors.blue[200] : Colors.blue[800],
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(Icons.arrow_outward_rounded,
                        size: 18.sp,
                        color: isDark ? Colors.blue[200] : Colors.blue[800]),
                  ],
                ),

                SizedBox(height: 10.h),

                // Status/warning row (sexy + minimal)
                if (snap.connectionState == ConnectionState.waiting) ...[
                  _StatusShimmer(isDark: isDark),
                ] else ...[
                  if (result == null) _StatusChip(
                    isDark: isDark,
                    icon: Icons.warning_amber_rounded,
                    text: 'Could not verify website',
                    danger: true,
                  ) else ...[
                    if (result.warnings.isEmpty) Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      alignment: WrapAlignment.center,
                      children: [
                        _StatusChip(
                          isDark: isDark,
                          icon: Icons.lock_rounded,
                          text: 'Secure',
                        ),
                        _StatusChip(
                          isDark: isDark,
                          icon: Icons.phone_iphone_rounded,
                          text: 'Mobile-friendly',
                        ),
                      ],
                    ) else Column(
                      children: [
                        // Single title: "Warning"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: isDark ? Colors.red[300] : Colors.red[700],
                                size: 18.sp),
                            SizedBox(width: 6.w),
                            Text(
                              'Warning',
                              style: TextStyle(
                                color: isDark ? Colors.red[300] : Colors.red[700],
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        // Specific issues as chips
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 6.h,
                          alignment: WrapAlignment.center,
                          children: result.warnings.map((w) => _StatusChip(
                            isDark: isDark,
                            icon: w.contains('HTTP')
                                ? Icons.lock_open_rounded
                                : Icons.smartphone_rounded,
                            text: w,
                            danger: true,
                          )).toList(),
                        ),
                        if (result.wasHttp && result.httpsAvailable) ...[
                          SizedBox(height: 6.h),
                          Text(
                            'We will open the HTTPS version automatically.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? Colors.green[300] : Colors.green[700],
                              fontWeight: FontWeight.w500,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ],
                    )
                  ]
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String text;
  final bool danger;
  const _StatusChip({
    required this.isDark,
    required this.icon,
    required this.text,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = danger
        ? (isDark ? Colors.red[200]! : Colors.red[800]!)
        : (isDark ? Colors.green[200]! : Colors.green[800]!);
    final bg = danger
        ? (isDark ? Colors.red[900]!.withOpacity(0.18) : Colors.red[50]!)
        : (isDark ? Colors.green[900]!.withOpacity(0.18) : Colors.green[50]!);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      // Cap max width defensively to avoid rare overflows on very long labels
      constraints: BoxConstraints(
        // Use the available screen width; Wrap will still break lines as needed
        maxWidth: MediaQuery.of(context).size.width - 48.w,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: fg),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 11.5.sp,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusShimmer extends StatelessWidget {
  final bool isDark;
  const _StatusShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // very lightweight placeholder without extra deps
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) => Container(
        width: 110.w, height: 22.h,
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(999.r),
        ),
      )),
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
