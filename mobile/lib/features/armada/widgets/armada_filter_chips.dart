import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ArmadaFilterChips extends StatefulWidget {
  final String? initialCategory;
  final Function(String)? onFilterChanged;

  const ArmadaFilterChips({super.key, this.initialCategory, this.onFilterChanged});

  @override
  State<ArmadaFilterChips> createState() => _ArmadaFilterChipsState();
}

class _ArmadaFilterChipsState extends State<ArmadaFilterChips> {
  final List<String> categories = ['Semua', 'Bus', 'Elf', 'Truk'];
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialCategory != null
        ? categories.indexOf(widget.initialCategory!)
        : 0;
    if (selectedIndex == -1) selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedIndex = index;
                });
                if (widget.onFilterChanged != null) {
                  widget.onFilterChanged!(categories[index]);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentLime : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.accentLime : AppColors.borderSoft,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accentLime.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  categories[index],
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryNavy : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
