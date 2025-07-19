import 'package:flutter/material.dart';
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(26, 18, 26, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  // IMAGE
                  if (recipe.imageUrl.isNotEmpty)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            recipe.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.restaurant_menu, size: 60, color: Colors.grey[400]),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 200,
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
                  const SizedBox(height: 20),
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: textColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Time Info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.deepPurple.withOpacity(0.25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.deepPurple),
                            const SizedBox(width: 7),
                            Text(
                              formatTime(recipe.totalTime),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  // Ingredients
                  if (recipe.ingredients.isNotEmpty) ...[
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.ingredients.map((ingredient) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${ingredient.name}${ingredient.quantity.isNotEmpty ? " (${ingredient.quantity})" : ""}',
                              style: TextStyle(fontSize: 16, color: textColor(context)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 18),
                  ],
                  // Instructions
                  if (recipe.instructions.isNotEmpty) ...[
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.instructions.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
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
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(fontSize: 15, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  // Equipment
                  if (recipe.equipment.isNotEmpty) ...[
                    Text(
                      'Equipment',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: textColor(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recipe.equipment.map((equipment) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          equipment,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
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
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.withOpacity(0.18)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.blue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Visit Recipe Website',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (recipe.website.startsWith('http://')) // Show warning for HTTP
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 0),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This website is not secure (HTTP). Your connection may not be private.',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
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
                    const SizedBox(height: 16),
                    Text(
                      'Videos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...recipe.videos.map((video) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: GestureDetector(
                        onTap: () => openWebView(video),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.withOpacity(0.18)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  video,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
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
