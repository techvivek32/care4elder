import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SelectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;
  final int delayMs;
  final String? description;

  const SelectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
    this.delayMs = 0,
    this.description,
  });

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Select ${widget.title}',
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                transform: Matrix4.diagonal3Values(
                  _isHovered ? 1.02 : 1.0,
                  _isHovered ? 1.02 : 1.0,
                  1.0,
                ),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? colorScheme.primary.withOpacity(0.05)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: widget.isSelected || _isHovered
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(
                        _isHovered ? 0.15 : 0.05,
                      ),
                      blurRadius: _isHovered ? 30 : 20,
                      offset: Offset(0, _isHovered ? 15 : 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(
                    22,
                  ), // Slightly less than container to fit inside border
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onTap,
                    onHover: (value) => setState(() => _isHovered = value),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: widget.isSelected || _isHovered
                                  ? colorScheme.primary
                                  : colorScheme.surfaceVariant,
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (_isHovered)
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              size: 40,
                              color: widget.isSelected || _isHovered
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: widget.isSelected || _isHovered
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                          ),
                          if (widget.description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.description!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: widget.delayMs.ms, duration: 600.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                delay: widget.delayMs.ms,
                curve: Curves.easeOutQuad,
              ),
    );
  }
}
