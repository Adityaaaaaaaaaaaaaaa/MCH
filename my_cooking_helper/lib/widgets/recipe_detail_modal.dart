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
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      maxChildSize: 0.98,
      minChildSize: 0.60,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34.r)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34.r)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(26.w, 18.h, 26.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45.w,
                      height: 6.h,
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  // IMAGE
                  if (recipe.imageUrl.isNotEmpty)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.r),
                          child: Image.network(
                            recipe.imageUrl,
                            width: double.infinity,
                            height: 200.h,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: double.infinity,
                              height: 200.h,
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant_menu, size: 60.sp, color: Colors.grey[400]),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 200.h,
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
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
                      ),
                    ),
                  SizedBox(height: 20.h),
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.sp,
                      color: textColor(context),
                    ),
                  ),
                if (recipe.dishTypes.isNotEmpty || recipe.servings > 0)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recipe.dishTypes.isNotEmpty)
                          Text(
                            recipe.dishTypes.join(', ').replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase()),
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                        if (recipe.servings > 0)
                          Row(
                            children: [
                              Icon(Icons.people, size: 16.sp, color: Colors.deepPurple),
                              SizedBox(width: 4.w),
                              Text(
                                'Serves ${recipe.servings}',
                                style: TextStyle(
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Times Row
                  Row(
                    children: [
                      if (recipe.prepTime > 0)
                        Text('Prep: ${recipe.prepTime} min', style: TextStyle(fontSize: 13.sp, color: Colors.grey[800])),
                      if (recipe.prepTime > 0 && recipe.cookTime > 0)
                        const Text('  |  '),
                      if (recipe.cookTime > 0)
                        Text('Cook: ${recipe.cookTime} min', style: TextStyle(fontSize: 13.sp, color: Colors.grey[800])),
                      if ((recipe.prepTime > 0 || recipe.cookTime > 0) && recipe.totalTime > 0)
                        const Text('  |  '),
                      if (recipe.totalTime > 0)
                        Text('Total: ${recipe.totalTime} min', style: TextStyle(fontSize: 13.sp, color: Colors.grey[800])),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  // Time Info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          color: Colors.deepPurple.withOpacity(0.25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16.sp, color: Colors.deepPurple),
                            SizedBox(width: 7.w),
                            Text(
                              formatTime(recipe.totalTime),
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),
                  // Ingredients
                  if (recipe.ingredients.isNotEmpty) ...[
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        color: textColor(context),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...recipe.ingredients.map((ingredient) => Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Row(
                        children: [
                          Container(
                            width: 7.w,
                            height: 7.h,
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              '${ingredient.name}${ingredient.quantity.isNotEmpty ? " (${ingredient.quantity})" : ""}',
                              style: TextStyle(fontSize: 16.sp, color: textColor(context)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    SizedBox(height: 18.h),
                  ],
                  // Instructions
                  if (recipe.instructions.isNotEmpty) ...[
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        color: textColor(context),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...recipe.instructions.asMap().entries.map((entry) => Padding(
                      padding: EdgeInsets.only(bottom: 13.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28.w,
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(fontSize: 15.sp, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    )),
                    SizedBox(height: 16.h),
                  ],
                  // Equipment
                  if (recipe.equipment.isNotEmpty) ...[
                    Text(
                      'Equipment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        color: textColor(context),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.equipment.map((equipment) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Text(
                          equipment,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                          ),
                        ),
                      )).toList(),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  if (recipe.nutrition != null && recipe.nutrition!.isNotEmpty) ...[
                    NutritionSection(nutrition: recipe.nutrition!),
                  ],
                  // Website Link
                  if (recipe.website.isNotEmpty) ...[
                    GestureDetector(
                      //onTap: () => openWebView(recipe.website),
                      onTap: () {
                        final originalUrl = recipe.website;
                        final fixedUrl = recipe.website.startsWith('http://')
                            ? recipe.website.replaceFirst('http://', 'https://')
                            : recipe.website;

                        print('\x1B[33m[DEBUG] Recipe Website tapped.\n[DEBUG] Original: $originalUrl\n[DEBUG] Modified: $fixedUrl\x1B[0m');
                        openWebView(fixedUrl);
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(color: Colors.blue.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.blue, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'Visit Recipe Website',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 15.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (recipe.website.startsWith('http://')) // Show warning for HTTP
                      Padding(
                        padding: EdgeInsets.only(top: 8.0.h, bottom: 0.h),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18.sp),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'This website is not secure (HTTP). Your connection may not be private.',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13.sp,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  // Videos
                  if (recipe.videos.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      'Videos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    ...recipe.videos.map((video) => Padding(
                      padding: EdgeInsets.only(bottom: 7.h),
                      child: GestureDetector(
                        onTap: () => openWebView(video),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Colors.red.withOpacity(0.18)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, color: Colors.red, size: 20.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  video,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
}

class NutritionSection extends StatelessWidget {
  final Map<String, dynamic> nutrition;

  const NutritionSection({Key? key, required this.nutrition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nutrients = nutrition['nutrients'] as List<dynamic>? ?? [];
    if (nutrients.isEmpty) return const SizedBox.shrink();

    final important = [
      'Calories', 'Protein', 'Carbohydrates', 'Fat', 'Saturated Fat', 'Fiber', 'Sugar', 'Sodium'
    ];

    final filtered = nutrients.where((n) => important.contains(n['name'])).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
            color: textColor(context),
          ),
        ),
        SizedBox(height: 10.h),
        ...filtered.map((n) => Row(
          children: [
            Icon(Icons.local_dining, size: 18.sp, color: Colors.orange[700]),
            SizedBox(width: 10.w),
            Text(
              '${n['name'] ?? ''}: ',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: textColor(context)),
            ),
            Text(
              '${n['amount']?.toStringAsFixed(0) ?? ''} ${n['unit'] ?? ''}',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[800]),
            ),
          ],
        )),
        SizedBox(height: 18.h),
      ],
    );
  }
}

