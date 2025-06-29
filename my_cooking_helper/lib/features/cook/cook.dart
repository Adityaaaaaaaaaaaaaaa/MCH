import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass/glass.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/widgets/navigation/nav.dart';

class CookScreen extends ConsumerWidget {
  const CookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<_CookFeatureCardData> features = [
      _CookFeatureCardData(
        'Past Cooked Meals',
        Icons.history_rounded,
        Colors.teal,
        '/history',
      ),
      _CookFeatureCardData(
        'Cook Something New',
        Icons.restaurant_menu_rounded,
        Colors.deepOrangeAccent,
        '/cook-now',
      ),
      _CookFeatureCardData(
        'My Favourite Recipes',
        Icons.favorite_rounded,
        Colors.pink,
        '/favourites',
      ),
    ];

    // Card sizing
    double cardWidth = 170.w;
    double cardHeight = 110.h;

    return Scaffold(
      backgroundColor: bgColor(context),
      extendBodyBehindAppBar: true,
      extendBody: true,
      drawer: CustomDrawer(),
      //bottomNavigationBar: CustomNavBar(currentIndex: 4),
      appBar: CustomAppBar(
        title: "Cook",
        showMenu: false,
        height: 70.h,
        borderRadius: 26.r,
        topPadding:40.h,
      ),
      body: Stack(
        children: [
          // --- BACKGROUND IMAGES (for aesthetics) ---
          Positioned(
            top: 35,
            right: 80,
            child: Transform.rotate(
              angle: -0.5,
              child: Image.asset(
                'assets/images/home/salad.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 170,
            left: 30,
            child: Transform.rotate(
              angle: 0.7,
              child: Image.asset(
                'assets/images/home/curry.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.0.w, vertical: 24.0.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 110.h),
                Text(
                  'Welcome to Cooking!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor(context),
                      ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Choose what you want to do:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor(context).withOpacity(0.7),
                      ),
                ),
                SizedBox(height: 35.h),
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 26.h,
                      crossAxisSpacing: 0,
                      childAspectRatio: cardWidth / cardHeight,
                    ),
                    itemCount: features.length,
                    itemBuilder: (context, index) {
                      final feature = features[index];
                      return Center(
                        child: CookFeatureCard(
                          icon: feature.icon,
                          title: feature.title,
                          color: feature.color,
                          width: cardWidth,
                          height: cardHeight,
                          onTap: () => context.push(feature.route),
                        ).asGlass(
                          blurX: 14,
                          blurY: 14,
                          tintColor: Colors.black,
                          clipBorderRadius: BorderRadius.circular(14.r),
                          frosted: true,
                        ),
                      );
                    },
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

class CookFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final double width;
  final double height;
  final VoidCallback onTap;
  const CookFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(20.r),
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(22.r),
        splashColor: color.withOpacity(0.18),
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: height,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(12.w),
                child: Icon(icon, size: 32.sp, color: color),
              ),
              SizedBox(width: 18.w),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.10,
                    fontSize: 17.sp,
                    color: textColor(context),
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class for feature card metadata
class _CookFeatureCardData {
  final String title;
  final IconData icon;
  final Color color;
  final String route;
  const _CookFeatureCardData(this.title, this.icon, this.color, this.route);
}