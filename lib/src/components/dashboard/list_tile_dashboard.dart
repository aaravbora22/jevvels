import 'package:flutter/material.dart';

class MyListTile extends StatelessWidget {
  final Widget icon;           // pass Icon(...) from caller
  final String tileTitle;
  final String tileSubtitle;
  final VoidCallback? onTap;

  const MyListTile({
    super.key,
    required this.icon,
    required this.tileTitle,
    required this.tileSubtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors
    const gold = Color(0xFFB99750);
    const bg = Colors.transparent;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          // Ensures everything sits on one line, vertically centered
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minLeadingWidth: 0,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: gold,
              borderRadius: BorderRadius.circular(10),
            ),
            // Center the provided icon inside the gold square
            child: Center(
              child: IconTheme(
                data: const IconThemeData(size: 22, color: Color.fromARGB(255, 39, 36, 36)),
                child: icon,
              ),
            ),
          ),
          title: const SizedBox.shrink(), // we’ll use title+subtitle in a single block below
          subtitle: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tileTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tileSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
          // Tighten vertical space so the row stays compact but centered
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        ),
      ),
    );
  }
}
