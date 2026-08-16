import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions(this.spacingScale);

  final double spacingScale;

  double get spacingXs => 4 * spacingScale;
  double get spacingSm => 8 * spacingScale;
  double get spacingMd => 16 * spacingScale;
  double get spacingLg => 24 * spacingScale;
  double get spacingXl => 32 * spacingScale;

  double call(double value) => value * spacingScale;

  EdgeInsets all(double v) => EdgeInsets.all(v * spacingScale);
  EdgeInsets symmetric({double? h, double? v}) => EdgeInsets.symmetric(
        horizontal: (h ?? 0) * spacingScale,
        vertical: (v ?? 0) * spacingScale,
      );
  EdgeInsets only({
    double? l,
    double? t,
    double? r,
    double? b,
  }) =>
      EdgeInsets.only(
        left: (l ?? 0) * spacingScale,
        top: (t ?? 0) * spacingScale,
        right: (r ?? 0) * spacingScale,
        bottom: (b ?? 0) * spacingScale,
      );
  EdgeInsets fromLTRB(double l, double t, double r, double b) =>
      EdgeInsets.fromLTRB(
        l * spacingScale,
        t * spacingScale,
        r * spacingScale,
        b * spacingScale,
      );

  double icon(double size) => size * spacingScale;
  double get iconXs => 12 * spacingScale;
  double get iconSm => 16 * spacingScale;
  double get iconMd => 20 * spacingScale;
  double get iconLg => 24 * spacingScale;
  double get iconXl => 28 * spacingScale;
}
