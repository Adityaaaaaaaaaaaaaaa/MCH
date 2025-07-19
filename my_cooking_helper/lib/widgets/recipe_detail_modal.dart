// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/models/recipe.dart';
import '/utils/colors.dart';

class RecipeDetailModal extends StatelessWidget {
  final Recipe recipe;
  final String Function(int) formatTime;
  final void Function(String url) openWebView;

  const RecipeDetailModal({
    Key? key,
    required this.recipe,
    required this.formatTime,
    required this.openWebView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark 
        ? const Color(0xFF1A1A1A).withOpacity(0.98)
        : Colors.white.withOpacity(0.98);

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      maxChildSize: 0.98,
      minChildSize: 0.60,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          child: Container(
            color: backgroundColor,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      margin: EdgeInsets.only(bottom: 24.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                  // IMAGE
                  if (recipe.imageUrl.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 32.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Stack(
                          children: [
                            Image.network(
                              recipe.imageUrl,
                              width: double.infinity,
                              height: 220.h,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => Container(
                                width: double.infinity,
                                height: 220.h,
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
                                  color: isDark ? Colors.grey[500] : Colors.grey[400]
                                ),
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: double.infinity,
                                  height: 220.h,
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
                          ],
                        ),
                      ),
                    ),
                  // TITLE
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 32.sp,
                      color: textColor(context),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 15.h),

                  // DISH TYPE (one line)
                  if (recipe.dishTypes.isNotEmpty)
                    _buildInfoChip(
                      context,
                      icon: Icons.restaurant_rounded,
                      text: recipe.dishTypes.join(', ').replaceFirstMapped(
                        RegExp(r'^\w'),
                        (m) => m.group(0)!.toUpperCase(),
                      ),
                      isDark: isDark,
                    ),
                  SizedBox(height: 7.h),

                  // SERVINGS (separate line)
                  if (recipe.servings > 0)
                    _buildInfoChip(
                      context,
                      icon: Icons.people_rounded,
                      text: 'Serves ${recipe.servings}',
                      isDark: isDark,
                    ),
                  SizedBox(height: 10.h),

                  // TIMES: prep/cook/total (horizontal row, centered, with separators)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (recipe.prepTime > 0)
                        Expanded(
                          child: _buildTimeCard(
                            context,
                            icon: Icons.schedule_rounded,
                            label: 'Prep',
                            time: '${recipe.prepTime} min',
                            isDark: isDark,
                          ),
                        ),
                      if (recipe.prepTime > 0 && recipe.cookTime > 0)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Text('|', style: TextStyle(fontSize: 16.sp, color: Colors.grey[500])),
                        ),
                      if (recipe.cookTime > 0)
                        Expanded(
                          child: _buildTimeCard(
                            context,
                            icon: Icons.local_fire_department_rounded,
                            label: 'Cook',
                            time: '${recipe.cookTime} min',
                            isDark: isDark,
                          ),
                        ),
                      if ((recipe.cookTime > 0 || recipe.prepTime > 0) && recipe.totalTime > 0)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: Text('|', style: TextStyle(fontSize: 16.sp, color: Colors.grey[500])),
                        ),
                      if (recipe.totalTime > 0)
                        Expanded(
                          child: _buildTimeCard(
                            context,
                            icon: Icons.timer_rounded,
                            label: 'Total',
                            time: formatTime(recipe.totalTime),
                            isDark: isDark,
                            isHighlighted: true,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 25.h),

                  // INGREDIENTS SECTION
                  if (recipe.ingredients.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Ingredients', Icons.list_alt_rounded, isDark),
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey[850]?.withOpacity(0.5)
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: recipe.ingredients.asMap().entries.map((entry) {
                          final index = entry.key;
                          final ingredient = entry.value;
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: index < recipe.ingredients.length - 1 ? 16.h : 0,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8.w,
                                  height: 8.h,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.deepPurple[300] : Colors.deepPurple,
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
                    ),
                    SizedBox(height: 25.h),
                  ],

                  // INSTRUCTIONS SECTION (as in your style)
                  if (recipe.instructions.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Instructions', Icons.format_list_numbered_rounded, isDark),
                    SizedBox(height: 20.h),
                    ...recipe.instructions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final instruction = entry.value;
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: index < recipe.instructions.length - 1 ? 20.h : 0,
                        ),
                        padding: EdgeInsets.all(15.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[850]?.withOpacity(0.3)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey[700]!.withOpacity(0.3)
                                : Colors.grey[400]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [Colors.deepPurple[400]!, Colors.deepPurple[600]!]
                                      : [Colors.deepPurple, Colors.deepPurple[700]!],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                instruction,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  height: 1.5,
                                  color: textColor(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    SizedBox(height: 25.h),
                  ],

                  // EQUIPMENT SECTION
                  if (recipe.equipment.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Equipment', Icons.kitchen_rounded, isDark),
                    SizedBox(height: 16.h),
                    Wrap(
                      spacing: 10.w,
                      runSpacing: 10.h,
                      children: recipe.equipment.map((equipment) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark 
                                ? [Colors.deepPurple[800]!.withOpacity(0.2), Colors.deepPurple[700]!.withOpacity(0.1)]
                                : [Colors.deepPurple.withOpacity(0.08), Colors.deepPurple.withOpacity(0.04)],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isDark 
                                ? Colors.deepPurple[400]!.withOpacity(0.3)
                                : Colors.deepPurple.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          equipment,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.deepPurple[300] : Colors.deepPurple[700],
                          ),
                        ),
                      )).toList(),
                    ),
                    SizedBox(height: 25.h),
                  ],
                    
                  // Nutrition Section
                  if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty) ...[
                    NutritionSection(nutrition: recipe.nutrition!),
                    SizedBox(height: 35.h),
                  ],
                  
                  // Website Link
                  if (recipe.website.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () {
                        final originalUrl = recipe.website;
                        final fixedUrl = recipe.website.startsWith('http://')
                            ? recipe.website.replaceFirst('http://', 'https://')
                            : recipe.website;

                        print('\x1B[33m[DEBUG] Recipe Website tapped.\n[DEBUG] Original: $originalUrl\n[DEBUG] Modified: $fixedUrl\x1B[0m');
                        openWebView(fixedUrl);
                      },
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
                              'Visit Recipe Website',
                              style: TextStyle(
                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // HTTP Warning
                    if (recipe.website.startsWith('http://'))
                      Container(
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
                      ),
                  ],
                  
                  // Videos Section
                  if (recipe.videos.isNotEmpty) ...[
                    _buildSectionHeader(context, 'Videos', Icons.play_circle_filled_rounded, isDark),
                    SizedBox(height: 16.h),
                    ...recipe.videos.map((video) => Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: GestureDetector(
                        onTap: () => openWebView(video),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark 
                                  ? [Colors.red[800]!.withOpacity(0.2), Colors.red[700]!.withOpacity(0.1)]
                                  : [Colors.red.withOpacity(0.08), Colors.red.withOpacity(0.04)],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.red[400]!.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_circle_fill_rounded, 
                                color: isDark ? Colors.red[300] : Colors.red[700], 
                                size: 24.sp
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  video,
                                  style: TextStyle(
                                    color: isDark ? Colors.red[300] : Colors.red[700],
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, bool isDark) {
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
          child: Icon(
            icon,
            color: Colors.white,
            size: 20.sp,
          ),
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

  Widget _buildInfoChip(BuildContext context, {
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [Colors.deepPurple[800]!.withOpacity(0.3), Colors.deepPurple[700]!.withOpacity(0.2)]
              : [Colors.deepPurple.withOpacity(0.1), Colors.deepPurple.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark 
              ? Colors.deepPurple[400]!.withOpacity(0.3)
              : Colors.deepPurple.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isDark ? Colors.cyan[300] : Colors.deepPurple[700],
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
      )
    );
  }

  Widget _buildTimeCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String time,
    required bool isDark,
    bool isHighlighted = false,
  }) {
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
            offset: const Offset(0, 2),
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
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              'Nutrition',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.sp,
                color: textColor(context),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.grey[850]?.withOpacity(0.5) 
                : Colors.orange[50],
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark 
                  ? Colors.orange[700]!.withOpacity(0.3)
                  : Colors.orange[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: filtered.asMap().entries.map((entry) {
              final index = entry.key;
              final nutrient = entry.value;
              return Container(
                margin: EdgeInsets.only(
                  bottom: index < filtered.length - 1 ? 16.h : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${nutrient['name'] ?? ''}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: textColor(context),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.orange[800]?.withOpacity(0.3)
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${nutrient['amount']?.toStringAsFixed(0) ?? ''} ${nutrient['unit'] ?? ''}',
                        style: TextStyle(
                          fontSize: 14.sp,
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