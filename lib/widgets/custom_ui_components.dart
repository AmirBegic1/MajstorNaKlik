import 'package:flutter/material.dart';

/// Custom UI komponente za konzistentan dizajn kroz MajstorNaKlik aplikaciju
/// Kreirao: GitHub Copilot
/// Datum: Oktobar 2025

/// Moderna kartica sa shadow efektima
class ModernCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const ModernCard({
    super.key,
    required this.child,
    this.elevation = 3,
    this.padding = const EdgeInsets.all(20.0),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: color ?? Theme.of(context).cardTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: padding!, child: child),
    );
  }
}

/// Status badge sa bojama
class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({super.key, required this.status, this.label});

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Otvoren';
      case 'assigned':
        return 'Dodijeljen';
      case 'in-progress':
        return 'U toku';
      case 'completed':
        return 'Završen';
      case 'cancelled':
        return 'Otkazan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor().withOpacity(0.3), width: 1),
      ),
      child: Text(
        label ?? _getStatusText(),
        style: TextStyle(
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Prioritet badge sa bojama
class PriorityBadge extends StatelessWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText() {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Nizak';
      case 'medium':
        return 'Srednji';
      case 'high':
        return 'Visok';
      case 'urgent':
        return 'Hitno';
      default:
        return priority;
    }
  }

  IconData _getPriorityIcon() {
    switch (priority.toLowerCase()) {
      case 'low':
        return Icons.keyboard_arrow_down;
      case 'high':
        return Icons.keyboard_arrow_up;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.remove;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(), size: 16, color: _getPriorityColor()),
          const SizedBox(width: 4),
          Text(
            _getPriorityText(),
            style: TextStyle(
              color: _getPriorityColor(),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero sekcija sa gradijentom
class HeroSection extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;

  const HeroSection({super.key, required this.child, this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors:
              gradientColors ??
              [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
        ),
      ),
      child: child,
    );
  }
}

/// Moderna sekcija sa iconom i naslovom
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }
}

/// Loading animacija sa tekstom
class LoadingWidget extends StatelessWidget {
  final String? text;

  const LoadingWidget({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error widget sa retry opcijom
class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skill chip za majstore
class SkillChip extends StatelessWidget {
  final String skill;
  final bool isSelected;
  final VoidCallback? onTap;

  const SkillChip({
    super.key,
    required this.skill,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          skill,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Avatar sa camera overlay
class ProfileAvatar extends StatelessWidget {
  final ImageProvider? imageProvider;
  final double radius;
  final VoidCallback? onCameraTap;

  const ProfileAvatar({
    super.key,
    this.imageProvider,
    this.radius = 70,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: radius - 5,
              backgroundImage:
                  imageProvider ?? const AssetImage('assets/avatar.jpg'),
            ),
          ),
        ),
        if (onCameraTap != null)
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
