import 'package:flutter/material.dart';

/// Single source of truth for product card grid and list layout tokens.
/// All screens displaying ProductCard MUST use these constants
/// to maintain a consistent "museum gallery" cadence.
class ProductGridConstants {
  ProductGridConstants._();

  // ──────────────────────────────────────────────────
  // GRID LAYOUT (2-column vertical grids)
  // ──────────────────────────────────────────────────
  static const int crossAxisCount = 2;

  /// The canonical aspect ratio for a ProductCard in a 2-column grid.
  /// Calculated to perfectly fit the 1:1 image + 12px gap + 2-line title + price row
  /// inside the card's 12px padding envelope.
  static const double childAspectRatio = 0.68;

  /// Spacing between cards — matches Apple's "tight but breathable" grid rhythm.
  static const double crossAxisSpacing = 12.0;
  static const double mainAxisSpacing = 12.0;

  /// Standard grid padding from screen edges.
  static const EdgeInsets gridPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// Grid padding that accounts for bottom safe-area inset.
  static EdgeInsets gridPaddingWithBottom(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + bottomPadding);
  }

  /// The standard SliverGridDelegate used by every 2-column product grid.
  static const SliverGridDelegateWithFixedCrossAxisCount gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    childAspectRatio: childAspectRatio,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
  );

  // ──────────────────────────────────────────────────
  // HORIZONTAL LIST LAYOUT (scrollable product strips)
  // ──────────────────────────────────────────────────

  /// Fixed width for each card in a horizontal scroll list.
  static const double horizontalCardWidth = 165.0;

  /// Fixed height for the horizontal list container.
  /// Must accommodate: 165 / 0.68 ≈ 243px card height.
  static const double horizontalListHeight = 260.0;

  /// Spacing between cards in horizontal lists.
  static const double horizontalCardSpacing = 12.0;

  /// Standard horizontal padding for scrollable lists.
  static const EdgeInsets horizontalListPadding = EdgeInsets.symmetric(horizontal: 16);
}
