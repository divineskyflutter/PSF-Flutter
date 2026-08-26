import 'package:flutter/material.dart';
import 'package:psf_application/features/language/presentation/controllers/language_selection_controller.dart';

class LanguageOptionCard extends StatelessWidget {
  const LanguageOptionCard({
    required this.language,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final LanguageOption language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final softColor = Color.lerp(language.color, Colors.white, .94)!;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '${language.englishName} language',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 80,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: language.color, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(language.color, Colors.white, .2)!,
                          language.color,
                        ],
                      ),
                    ),
                    child: Text(
                      language.letter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language.nativeName,
                          style: const TextStyle(
                            color: Color(0xFF17232A),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          language.englishName,
                          style: const TextStyle(
                            color: Color(0xFF586069),
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SelectionIndicator(
                    color: language.color,
                    isSelected: isSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.color, required this.isSelected});

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
      ),
      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
    );
  }
}
