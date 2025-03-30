import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un container che assomiglia a una pagina di diario
class PaperCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final bool showTexture;
  final VoidCallback? onTap;

  const PaperCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.elevation = 2.0,
    this.showTexture = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: ThemeConstants.cardColor,
          borderRadius: ThemeConstants.paperRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: elevation * 2,
              spreadRadius: elevation * 0.2,
              offset: Offset(elevation * 0.5, elevation * 0.8),
            ),
          ],
          border: ThemeConstants.paperBorder,
          image: showTexture ? ThemeConstants.paperBackgroundTexture : null,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Titolo in stile diario con sottolineatura ornamentale
class DiaryTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final bool showDivider;
  final Color? dividerColor;

  const DiaryTitle({
    Key? key,
    required this.title,
    this.style,
    this.showDivider = true,
    this.dividerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: style ?? ThemeConstants.headingStyle,
        ),
        if (showDivider) 
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 16),
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  dividerColor ?? ThemeConstants.primaryColor,
                  dividerColor?.withOpacity(0.3) ?? ThemeConstants.primaryColor.withOpacity(0.3),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
      ],
    );
  }
}

/// Entry di un diario con data e contenuto
class DiaryEntry extends StatelessWidget {
  final String date;
  final String title;
  final String content;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DiaryEntry({
    Key? key,
    required this.date,
    required this.title,
    required this.content,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      onTap: onTap,
      padding: EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ThemeConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: GoogleFonts.caveat(
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.secondaryColor,
                    fontSize: 18,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ThemeConstants.subheadingStyle,
                ),
                SizedBox(height: 8),
                Text(
                  content,
                  style: ThemeConstants.handwrittenNotes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottone stilizzato come un'etichetta di diario
class DiaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  const DiaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? ThemeConstants.primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: GoogleFonts.caveat(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: color?.withOpacity(0.5) ?? ThemeConstants.secondaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon),
            SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// Stile lista per gli elementi tipo arnie/apiari
class DiaryListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const DiaryListItem({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ThemeConstants.subheadingStyle.copyWith(fontSize: 22),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: ThemeConstants.handwrittenNotes,
                    ),
                ],
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
          ],
        ),
      ),
    );
  }
}