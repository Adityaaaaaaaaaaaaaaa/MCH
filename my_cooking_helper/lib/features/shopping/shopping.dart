// lib/features/shopping/shopping.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '/utils/snackbar.dart';
import '/widgets/shopping_widgets.dart';
import '/theme/app_theme.dart';
import '/utils/colors.dart';
import '/widgets/navigation/appbar.dart';
import '/widgets/navigation/drawer.dart';
import '/services/shopping_service.dart';
import '/services/reminder_service.dart';

class ShoppingPage extends ConsumerStatefulWidget {
  const ShoppingPage({super.key});
  @override
  ConsumerState<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends ConsumerState<ShoppingPage> with TickerProviderStateMixin {
  bool _hasReminder = false;
  DateTime? _targetWhen;

  @override
  void initState() {
    super.initState();
    ReminderService().init();
    _refreshReminderState();
  }

  Future<void> _refreshReminderState() async {
    final svc = ReminderService();
    final has = await svc.hasUpcomingReminder();
    final when = await svc.getTargetWhen();
    if (!mounted) return;
    setState(() {
      _hasReminder = has;
      _targetWhen = when;
    });
  }

  Future<void> _onBellPressed() async {
    if (_hasReminder) {
      // Offer cancel
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Cancel reminder?'),
          content: Text(
            _targetWhen == null
              ? 'Cancel the upcoming reminder?'
              : 'Cancel the reminder scheduled for $_targetWhen ?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Cancel')),
          ],
        ),
      );
      if (ok == true) {
        await ReminderService().cancelLastReminder();
        if (!mounted) return;
        SnackbarUtils.show(
          context, 
          "Reminder Cancelled",
          duration: 1000, 
          behavior: SnackBarBehavior.floating,
          icon: Icons.calendar_month_outlined,
          iconColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900
          ),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          backgroundColor: Colors.grey,
          width: 250.w,
        );

        _refreshReminderState();
      }
      return;
    }

    // Not set → open sheet to pick future date/time + pre-alert
    final res = await showReminderSheet(context);
    if (res == null) return;

    // Blue log
    // ignore: avoid_print
    print('\x1B[34m[SHOP UI] scheduling reminder for ${res.when} (preAlert=${res.preAlert})\x1B[0m');

    try {
      await ReminderService().addCalendarAndNotify(
        when: res.when,
        preAlert: res.preAlert,
        title: 'Buy groceries',
        description: 'Check your Shopping List',
      );
      if (!mounted) return;
      SnackbarUtils.show(
        context, 
        "Reminder set for ${TimeOfDay.fromDateTime(res.when).format(context)}",
        duration: 1000, 
        behavior: SnackBarBehavior.floating,
        icon: Icons.calendar_month_outlined,
        iconColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900
        ),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        backgroundColor: Colors.grey,
        width: 250.w,
      );

      _refreshReminderState();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not set reminder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(shoppingServiceProvider);
    final svc = ref.read(shoppingServiceProvider.notifier);

    return Scaffold(
      backgroundColor: bgColor(context),
      drawer: const CustomDrawer(),
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: CustomAppBar(
        title: "Shopping List",
        showMenu: false,
        themeToggleWidget: ThemeToggleButton(),
        // green bell when a reminder is scheduled
        trailingWidget: Icon(
          _hasReminder ? Icons.notifications_active : Icons.notifications_none_outlined,
          size: 22.sp,
          color: _hasReminder ? Colors.green : textColor(context),
        ),
        onTrailingIconTap: _onBellPressed,
        height: 70.h,
        borderRadius: 26.r,
        topPadding: 40.h,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
          child: ShoppingReceipt(
            items: items,
            onAdd: ({required String name, required double need, required String unit}) {
              svc.addOrUpdate(name: name, need: need, unit: unit);
            },
            onChange: (updated) => svc.addOrUpdate(
              name: updated.name,
              need: updated.need,
              unit: updated.unit,
              have: updated.have,
              tag: updated.tag,
            ),
            onDelete: (name) => svc.remove(name),
            trailing: ClearListButton(
              itemCount: items.length,
              onClear: () async {
                if (items.isEmpty) return;
                await svc.clearAll();
              },
            ),
          ),
        ),
      ),
    );
  }
}
