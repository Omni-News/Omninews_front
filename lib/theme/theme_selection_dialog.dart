import 'package:flutter/material.dart';
import 'package:omninews_test_flutter/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';

class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineMedium?.color,
              ),
            ),
            const SizedBox(height: 20),
            ...AppTheme.themeData.keys.map((themeKey) {
              bool isSelected = themeProvider.currentThemeKey == themeKey;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                      : null,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.themeColors[themeKey],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Center(
                            child: Icon(
                              Icons.check_circle,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    AppTheme.themeNames[themeKey]!,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  onTap: () {
                    themeProvider.setTheme(themeKey);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: const Text('CANCEL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
