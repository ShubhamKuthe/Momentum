import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/responsive.dart';
import '../core/theme/typography.dart';

class AccountHeader extends StatelessWidget {
  const AccountHeader({
    super.key,
    required this.title,
    this.onClose,
    this.leadingIcon = Icons.close_rounded,
  });

  final String title;
  final VoidCallback? onClose;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Row(
      children: [
        if (onClose != null)
          _HeaderCircleButton(
            icon: leadingIcon,
            onTap: onClose!,
          )
        else
          SizedBox(
            width: responsive.value(50, min: 44, max: 56),
            height: responsive.value(50, min: 44, max: 56),
          ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        SizedBox(
          width: responsive.value(50, min: 44, max: 56),
          height: responsive.value(50, min: 44, max: 56),
        ),
      ],
    );
  }
}

class ProfileAccountCard extends StatelessWidget {
  const ProfileAccountCard({
    super.key,
    required this.initial,
    required this.name,
    required this.secondaryText,
    this.imageBase64,
    this.onTap,
    this.onAvatarTap,
    this.showChevron = true,
  });

  final String initial;
  final String name;
  final String secondaryText;
  final String? imageBase64;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final responsive = context.responsive;
    final avatar = MomentumProfileAvatar(
      initial: initial,
      imageBase64: imageBase64,
      size: responsive.value(42, min: 40, max: 44),
      backgroundColor: palette.surfaceMuted,
      borderColor: palette.borderSoft.withValues(alpha: isDark ? 0.3 : 0.85),
      textStyle: MomentumTypography.numbers(
        Theme.of(context).textTheme.titleMedium!,
      ),
    );

    return SettingsGroupCard(
      children: [
        PressableSettingsRow(
          title: name,
          subtitle: secondaryText,
          onTap: onTap,
          leading: onAvatarTap == null
              ? avatar
              : GestureDetector(
                  onTap: onAvatarTap,
                  behavior: HitTestBehavior.opaque,
                  child: avatar,
                ),
          minHeight: responsive.value(AppHeights.row, min: 68, max: 84),
          subtitleMaxLines: 1,
          showChevron: showChevron,
          titleStyle: Theme.of(context).textTheme.titleMedium,
          subtitleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: palette.textSoft,
              ),
        ),
      ],
    );
  }
}

class MomentumProfileAvatar extends StatelessWidget {
  const MomentumProfileAvatar({
    super.key,
    required this.initial,
    this.imageBase64,
    required this.size,
    required this.backgroundColor,
    required this.borderColor,
    required this.textStyle,
  });

  final String initial;
  final String? imageBase64;
  final double size;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle textStyle;

  Uint8List? _decodedBytes() {
    final raw = imageBase64?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _decodedBytes();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.2),
        child: ClipOval(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: SizedBox(
            width: size,
            height: size,
            child: bytes == null
                ? Center(child: Text(initial, style: textStyle))
                : Image.memory(
                    bytes,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: palette.textMuted,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.children,
    this.accent = false,
  });

  final List<Widget> children;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(responsive.radius(AppRadii.card)),
        border: Border.all(
          color: isDark
              ? palette.borderSoft.withValues(alpha: accent ? 0.7 : 0.42)
              : palette.border,
        ),
        boxShadow: AppElevations.card(palette.shadow, isDark: isDark),
      ),
      child: Column(children: children),
    );
  }
}

class PressableSettingsRow extends StatefulWidget {
  const PressableSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
    this.leading,
    this.showDivider = false,
    this.accent = false,
    this.minHeight = AppHeights.row,
    this.titleStyle,
    this.subtitleStyle,
    this.subtitleMaxLines = 2,
    this.showChevron = true,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool showDivider;
  final bool accent;
  final double minHeight;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final int subtitleMaxLines;
  final bool showChevron;

  @override
  State<PressableSettingsRow> createState() => _PressableSettingsRowState();
}

class _PressableSettingsRowState extends State<PressableSettingsRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final responsive = context.responsive;
    final isInteractive = widget.onTap != null;
    final showChevron = widget.showChevron && isInteractive;

    return GestureDetector(
      onTapDown: isInteractive ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: isInteractive ? () => setState(() => _pressed = false) : null,
      onTapUp: isInteractive ? (_) => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.press,
        curve: AppEasing.standard,
        child: AnimatedContainer(
          duration: AppDurations.card,
          curve: AppEasing.standard,
          constraints: BoxConstraints(minHeight: widget.minHeight),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.value(AppSpacing.x4, min: 16, max: 18),
            vertical: responsive.value(AppSpacing.x3, min: 12, max: 16),
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? (isDark
                    ? palette.gloss.withValues(alpha: 0.1)
                    : palette.surfaceMuted.withValues(alpha: 0.55))
                : Colors.transparent,
            border: widget.showDivider
                ? Border(
                    top: BorderSide(
                      color: isDark
                          ? palette.borderSoft.withValues(alpha: 0.5)
                          : palette.borderSoft,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                SizedBox(width: responsive.value(AppSpacing.x3, min: 10, max: 14)),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: widget.titleStyle ??
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: widget.accent
                                    ? (isDark ? palette.gold : palette.accent)
                                    : palette.text,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    if (widget.subtitle != null) ...[
                      SizedBox(height: responsive.value(2, min: 2, max: 3)),
                      Text(
                        widget.subtitle!,
                        maxLines: widget.subtitleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        style: widget.subtitleStyle ??
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: palette.textSoft,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron) ...[
                SizedBox(width: responsive.value(AppSpacing.x2, min: 8, max: 10)),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.textSoft.withValues(alpha: 0.5),
                  size: responsive.value(24, min: 22, max: 26),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;
    final platform = Theme.of(context).platform;
    final responsive = context.responsive;

    return Container(
      constraints: BoxConstraints(
        minHeight: responsive.value(AppHeights.row, min: 68, max: 78),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(AppSpacing.x4, min: 16, max: 18),
        vertical: responsive.value(AppSpacing.x3, min: 12, max: 14),
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                top: BorderSide(
                  color: isDark
                      ? palette.borderSoft.withValues(alpha: 0.5)
                      : palette.borderSoft,
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: palette.textSoft,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS)
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: palette.success,
            )
          else
            SizedBox(
              width: responsive.value(48, min: 46, max: 50),
              height: responsive.value(30, min: 28, max: 32),
              child: Center(
                child: Transform.scale(
                  scale: 0.76,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: palette.success,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: isDark
                        ? palette.surfaceMuted
                        : const Color(0xFFD6D8DE),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.momentum;
    final isDark = context.isMomentumDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Ink(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isDark ? palette.surfaceStrong : palette.surfaceStrong,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? palette.borderSoft.withValues(alpha: 0.45)
                : palette.border,
          ),
          boxShadow: isDark ? null : AppElevations.floating(palette.shadow, isDark: false),
        ),
        child: Icon(
          icon,
          color: palette.text,
          size: 24,
        ),
      ),
    );
  }
}
