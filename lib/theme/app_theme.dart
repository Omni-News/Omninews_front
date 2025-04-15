import 'package:flutter/material.dart';

class AppTheme {
  // 라이트(화이트) 테마
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF2979FF),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    cardColor: Colors.white,
    shadowColor: Colors.black.withOpacity(0.1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Colors.white,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[200],
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF2979FF),
      unselectedItemColor: Colors.grey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2979FF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    textTheme: TextTheme(
      // 뉴스 제목
      titleLarge: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      // 뉴스 본문
      bodyLarge: TextStyle(
        color: Colors.black87,
        fontSize: 17,
        height: 1.6,
        letterSpacing: 0.3,
      ),
      // 뉴스 요약
      bodyMedium: TextStyle(
        color: Colors.grey[700],
        fontSize: 14,
        height: 1.2,
      ),
      // 날짜, 출처 등 작은 텍스트
      bodySmall: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
      // 탭 라벨
      labelLarge: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
      labelMedium: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
      // 앱 바 제목
      headlineMedium: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: const Color(0xFF2979FF),
      secondary: const Color(0xFF546E7A),
      surface: Colors.white,
      background: const Color(0xFFFAFAFA),
      error: Colors.red[700],
      // 출처 태그 배경색
      primaryContainer: Colors.blue.shade50,
      // 출처 태그 텍스트 색상
      onPrimaryContainer: Colors.blue.shade700,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(color: Colors.grey[800], fontSize: 12),
    ),
    // 확장 테마 데이터 (앱 전용 속성)
    extensions: [
      NewsCardStyleExtension(
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          height: 1.3,
        ),
        descriptionStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.2,
        ),
        sourceStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue[700],
        ),
        dateStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
        bookmarkActiveColor: Colors.blue,
        bookmarkInactiveColor: Colors.grey,
        thumbnailPlaceholderColor: Colors.grey[200]!,
        thumbnailBorderRadius: 4.0,
        cardPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        dividerColor: Colors.grey[200]!,
      ),
      RssThemeExtension(
        channelCardBackground: Colors.white,
        subscribeButtonActiveBackground: Colors.blue.shade50,
        subscribeButtonActiveText: Colors.blue[700]!,
        subscribeButtonInactiveBackground: Colors.grey.shade200,
        subscribeButtonInactiveText: Colors.grey[700]!,
        channelImageGradientColors: [Colors.blue[400]!, Colors.blue[700]!],
        channelImageBorderRadius: 10.0,
        linkColor: Colors.blue[700]!, // 추가된 속성
        channelIconColor: Colors.orange[300]!, // 추가된 속성
      ),
      // 검색 결과 태그 스타일
      SearchStyleExtension(
        channelTagBackground: Colors.green[50]!,
        channelTagBorder: Colors.green[200]!,
        channelTagText: Colors.green[700]!,
        rssTagBackground: Colors.orange[50]!,
        rssTagBorder: Colors.orange[200]!,
        rssTagText: Colors.orange[700]!,
        channelIconColor: Colors.orange[300]!,
        channelIconBackground: Colors.orange[50]!,
      ),
      // 구독 뷰 스타일
      SubscribeViewStyleExtension(
        dateHeaderBackground: Colors.white,
        dateTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.5,
          color: Colors.indigo[700]!,
        ),
        countTextStyle: TextStyle(
          color: Colors.grey[600]!,
          fontSize: 14,
          letterSpacing: -0.3,
        ),
        dotColor: Colors.grey[400]!,
        channelCardBorder: Colors.grey[100]!,
        expandButtonBackground: Colors.grey[50]!,
        expandButtonTextColor: const Color(0xFF2979FF),
        collapseButtonTextColor: Colors.grey[600]!,
        sectionDividerColor: Colors.grey[100]!,
        errorIconColor: Colors.grey[300]!,
        emptyIconColor: Colors.grey[300]!,
        emptyTextColor: Colors.grey[600]!,
        hintBoxBackground: Colors.grey[50]!,
        hintBoxBorder: Colors.grey[100]!,
        hintTextColor: Colors.grey[600]!,
        dateHeaderColor: Colors.indigo[700]!, // 추가된 속성
      ),
    ],
  );

  // 블루 테마
  static final ThemeData blueTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1565C0),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    cardColor: Colors.white,
    shadowColor: Colors.black.withOpacity(0.1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1565C0),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFFE3F2FD),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.blue[100],
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF1565C0),
      unselectedItemColor: Colors.blueGrey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
    textTheme: TextTheme(
      // 뉴스 제목
      titleLarge: const TextStyle(
        color: Color(0xFF0D47A1),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      // 뉴스 본문
      bodyLarge: TextStyle(
        color: Colors.black87,
        fontSize: 17,
        height: 1.6,
        letterSpacing: 0.3,
      ),
      // 뉴스 요약
      bodyMedium: TextStyle(
        color: Colors.grey[800],
        fontSize: 14,
        height: 1.2,
      ),
      // 날짜, 출처 등 작은 텍스트
      bodySmall: TextStyle(
        color: Colors.grey[700],
        fontSize: 12,
      ),
      // 탭 라벨
      labelLarge: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
      labelMedium: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
      // 앱 바 제목
      headlineMedium: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: const Color(0xFF1565C0),
      secondary: const Color(0xFF42A5F5),
      surface: Colors.white,
      background: const Color(0xFFE3F2FD),
      error: Colors.red[700],
      // 출처 태그 배경색
      primaryContainer: Colors.blue.shade100,
      // 출처 태그 텍스트 색상
      onPrimaryContainer: Colors.blue.shade800,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: Colors.blue[800], fontSize: 12),
    ),
    // 확장 테마 데이터 (앱 전용 속성)
    extensions: [
      NewsCardStyleExtension(
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D47A1),
          height: 1.3,
        ),
        descriptionStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.2,
        ),
        sourceStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue[800],
        ),
        dateStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
        ),
        bookmarkActiveColor: Colors.blue[700]!,
        bookmarkInactiveColor: Colors.blueGrey[300]!,
        thumbnailPlaceholderColor: Colors.blue[50]!,
        thumbnailBorderRadius: 4.0,
        cardPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        dividerColor: Colors.blue[100]!,
      ),
      RssThemeExtension(
        channelCardBackground: Colors.white,
        subscribeButtonActiveBackground: Colors.blue.shade100,
        subscribeButtonActiveText: Colors.blue[800]!,
        subscribeButtonInactiveBackground: Colors.blue.shade50,
        subscribeButtonInactiveText: Colors.blue[800]!,
        channelImageGradientColors: [Colors.blue[300]!, Colors.blue[600]!],
        channelImageBorderRadius: 10.0,
        linkColor: Colors.blue[800]!, // 추가된 속성
        channelIconColor: Colors.blue[300]!, // 추가된 속성
      ),
      // 검색 결과 태그 스타일
      SearchStyleExtension(
        channelTagBackground: Colors.teal[50]!,
        channelTagBorder: Colors.teal[200]!,
        channelTagText: Colors.teal[700]!,
        rssTagBackground: Colors.blue[50]!,
        rssTagBorder: Colors.blue[200]!,
        rssTagText: Colors.blue[700]!,
        channelIconColor: Colors.blue[300]!,
        channelIconBackground: Colors.blue[50]!,
      ),
      // 구독 뷰 스타일
      SubscribeViewStyleExtension(
        dateHeaderBackground: Colors.white,
        dateTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.5,
          color: Colors.blue[900]!,
        ),
        countTextStyle: TextStyle(
          color: Colors.blue[800]!,
          fontSize: 14,
          letterSpacing: -0.3,
        ),
        dotColor: Colors.blue[200]!,
        channelCardBorder: Colors.blue[50]!,
        expandButtonBackground: Colors.blue[50]!,
        expandButtonTextColor: const Color(0xFF1565C0),
        collapseButtonTextColor: Colors.blue[700]!,
        sectionDividerColor: Colors.blue[50]!,
        errorIconColor: Colors.blue[100]!,
        emptyIconColor: Colors.blue[100]!,
        emptyTextColor: Colors.blue[800]!,
        hintBoxBackground: Colors.blue[50]!,
        hintBoxBorder: Colors.blue[100]!,
        hintTextColor: Colors.blue[700]!,
        dateHeaderColor: Colors.blue[900]!, // 추가된 속성
      ),
    ],
  );

  // 다크(블랙) 테마
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF90CAF9),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    shadowColor: Colors.black.withOpacity(0.3),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFF1F1F1F),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey[800],
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1F1F1F),
      selectedItemColor: Color(0xFF90CAF9),
      unselectedItemColor: Colors.grey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    ),
    textTheme: const TextTheme(
      // 뉴스 제목
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      // 뉴스 본문
      bodyLarge: TextStyle(
        color: Colors.white70,
        fontSize: 17,
        height: 1.6,
        letterSpacing: 0.3,
      ),
      // 뉴스 요약
      bodyMedium: TextStyle(
        color: Color(0xFFBBBBBB),
        fontSize: 14,
        height: 1.2,
      ),
      // 날짜, 출처 등 작은 텍스트
      bodySmall: TextStyle(
        color: Color(0xFFAAAAAA),
        fontSize: 12,
      ),
      // 탭 라벨
      labelLarge: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 17,
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
      // 앱 바 제목
      headlineMedium: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    colorScheme: const ColorScheme.dark().copyWith(
      primary: const Color(0xFF90CAF9),
      secondary: const Color(0xFF64B5F6),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      error: const Color(0xFFCF6679),
      // 출처 태그 배경색
      primaryContainer: Colors.blue.shade900,
      // 출처 태그 텍스트 색상
      onPrimaryContainer: Colors.blue.shade100,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      labelStyle: TextStyle(color: Colors.grey[300], fontSize: 12),
    ),
    // 확장 테마 데이터 (앱 전용 속성)
    extensions: [
      NewsCardStyleExtension(
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.3,
        ),
        descriptionStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFBBBBBB),
          height: 1.2,
        ),
        sourceStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue[300],
        ),
        dateStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFFAAAAAA),
        ),
        bookmarkActiveColor: Colors.blue[300]!,
        bookmarkInactiveColor: Colors.grey,
        thumbnailPlaceholderColor: Colors.grey[800]!,
        thumbnailBorderRadius: 4.0,
        cardPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        dividerColor: Colors.grey[800]!,
      ),
      RssThemeExtension(
        channelCardBackground: const Color(0xFF1E1E1E),
        subscribeButtonActiveBackground: Colors.blue.shade900,
        subscribeButtonActiveText: Colors.blue[200]!,
        subscribeButtonInactiveBackground: Colors.grey[800]!,
        subscribeButtonInactiveText: Colors.grey[400]!,
        channelImageGradientColors: [Colors.blue[700]!, Colors.blue[900]!],
        channelImageBorderRadius: 10.0,
        linkColor: Colors.blue[300]!, // 추가된 속성
        channelIconColor: Colors.blue[300]!, // 추가된 속성
      ),
      // 검색 결과 태그 스타일
      SearchStyleExtension(
        channelTagBackground: const Color(0xFF1F3B2B),
        channelTagBorder: Colors.green[900]!,
        channelTagText: Colors.green[300]!,
        rssTagBackground: const Color(0xFF253247),
        rssTagBorder: Colors.blue[900]!,
        rssTagText: Colors.blue[300]!,
        channelIconColor: Colors.blue[300]!,
        channelIconBackground: const Color(0xFF253247),
      ),
      // 구독 뷰 스타일
      SubscribeViewStyleExtension(
        dateHeaderBackground: const Color(0xFF1E1E1E),
        dateTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          letterSpacing: -0.5,
          color: Colors.blue[300]!,
        ),
        countTextStyle: TextStyle(
          color: Colors.grey[400]!,
          fontSize: 14,
          letterSpacing: -0.3,
        ),
        dotColor: Colors.grey[700]!,
        channelCardBorder: Colors.grey[800]!,
        expandButtonBackground: const Color(0xFF2A2A2A),
        expandButtonTextColor: Colors.blue[300]!,
        collapseButtonTextColor: Colors.grey[500]!,
        sectionDividerColor: Colors.grey[850]!,
        errorIconColor: Colors.grey[700]!,
        emptyIconColor: Colors.grey[700]!,
        emptyTextColor: Colors.grey[400]!,
        hintBoxBackground: const Color(0xFF1A1A1A),
        hintBoxBorder: Colors.grey[800]!,
        hintTextColor: Colors.grey[400]!,
        dateHeaderColor: Colors.blue[300]!, // 추가된 속성
      ),
    ],
  );

// 종이질감 서정적 테마 추가
  static final ThemeData paperTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF8D6E63), // 따뜻한 브라운
    scaffoldBackgroundColor: const Color(0xFFF8F3E9), // 페이퍼 베이지색
    cardColor: const Color(0xFFFCF7F0), // 따뜻한 화이트
    shadowColor: Colors.brown.withOpacity(0.1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8F3E9),
      foregroundColor: Color(0xFF3E2723),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF5D4037)),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: Color(0xFFF8F3E9),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0D6C8),
      thickness: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF8F3E9),
      selectedItemColor: Color(0xFF8D6E63),
      unselectedItemColor: Color(0xFFBCAA9C),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8D6E63),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textTheme: TextTheme(
      // 뉴스 제목
      titleLarge: const TextStyle(
        color: Color(0xFF3E2723),
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        fontFamily: 'Serif',
      ),
      // 뉴스 본문
      bodyLarge: const TextStyle(
        color: Color(0xFF4E342E),
        fontSize: 17,
        height: 1.7,
        letterSpacing: 0.3,
        fontFamily: 'Serif',
      ),
      // 뉴스 요약
      bodyMedium: TextStyle(
        color: Colors.brown[700],
        fontSize: 15,
        height: 1.4,
        fontFamily: 'Serif',
      ),
      // 날짜, 출처 등 작은 텍스트
      bodySmall: const TextStyle(
        color: Color(0xFF6D4C41),
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
      // 탭 라벨
      labelLarge: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: Color(0xFF5D4037),
        letterSpacing: -0.3,
      ),
      labelMedium: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 15,
        color: Color(0xFF8D6E63),
      ),
      // 앱 바 제목
      headlineMedium: const TextStyle(
        color: Color(0xFF3E2723),
        fontWeight: FontWeight.w600,
        fontSize: 20,
        letterSpacing: -0.5,
        fontFamily: 'Serif',
      ),
    ),
    colorScheme: const ColorScheme.light().copyWith(
      primary: const Color(0xFF8D6E63),
      secondary: const Color(0xFFBCAAA4),
      surface: const Color(0xFFFCF7F0),
      background: const Color(0xFFF8F3E9),
      error: const Color(0xFFB71C1C),
      // 출처 태그 배경색
      primaryContainer: const Color(0xFFEFE5DC),
      // 출처 태그 텍스트 색상
      onPrimaryContainer: const Color(0xFF5D4037),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEFE5DC),
      labelStyle: TextStyle(color: Colors.brown[700], fontSize: 12),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFD7CCC8)),
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    // 확장 테마 데이터 (앱 전용 속성)
    extensions: [
      NewsCardStyleExtension(
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3E2723),
          height: 1.3,
          fontFamily: 'Serif',
        ),
        descriptionStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF5D4037),
          height: 1.5,
          fontFamily: 'Serif',
        ),
        sourceStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF795548),
          fontStyle: FontStyle.italic,
        ),
        dateStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8D6E63),
          fontStyle: FontStyle.italic,
        ),
        bookmarkActiveColor: const Color(0xFF795548),
        bookmarkInactiveColor: const Color(0xFFBCAAA4),
        thumbnailPlaceholderColor: const Color(0xFFEFE5DC),
        thumbnailBorderRadius: 6.0,
        cardPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        dividerColor: const Color(0xFFE0D6C8),
      ),
      RssThemeExtension(
        channelCardBackground: const Color(0xFFFCF7F0),
        subscribeButtonActiveBackground: const Color(0xFFECE2D8),
        subscribeButtonActiveText: const Color(0xFF5D4037),
        subscribeButtonInactiveBackground: const Color(0xFFEFE5DC),
        subscribeButtonInactiveText: const Color(0xFF8D6E63),
        channelImageGradientColors: const [
          Color(0xFF8D6E63),
          Color(0xFF5D4037)
        ],
        channelImageBorderRadius: 10.0,
        linkColor: const Color(0xFF795548),
        channelIconColor: const Color(0xFFA1887F),
      ),
      // 검색 결과 태그 스타일
      SearchStyleExtension(
        channelTagBackground: const Color(0xFFEDE2D8),
        channelTagBorder: const Color(0xFFD7CCC8),
        channelTagText: const Color(0xFF6D4C41),
        rssTagBackground: const Color(0xFFE8E0D8),
        rssTagBorder: const Color(0xFFD7CCC8),
        rssTagText: const Color(0xFF795548),
        channelIconColor: const Color(0xFFBCAAA4),
        channelIconBackground: const Color(0xFFEFE5DC),
      ),
      // 구독 뷰 스타일
      SubscribeViewStyleExtension(
        dateHeaderBackground: const Color(0xFFF5EFE6),
        dateTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.5,
          color: Color(0xFF5D4037),
          fontFamily: 'Serif',
        ),
        countTextStyle: const TextStyle(
          color: Color(0xFF8D6E63),
          fontSize: 14,
          letterSpacing: -0.3,
          fontStyle: FontStyle.italic,
        ),
        dotColor: const Color(0xFFBCAAA4),
        channelCardBorder: const Color(0xFFE0D6C8),
        expandButtonBackground: const Color(0xFFEFE5DC),
        expandButtonTextColor: const Color(0xFF795548),
        collapseButtonTextColor: const Color(0xFFBCAAA4),
        sectionDividerColor: const Color(0xFFE8E0D8),
        errorIconColor: const Color(0xFFD7CCC8),
        emptyIconColor: const Color(0xFFD7CCC8),
        emptyTextColor: const Color(0xFF8D6E63),
        hintBoxBackground: const Color(0xFFEFE5DC),
        hintBoxBorder: const Color(0xFFE0D6C8),
        hintTextColor: const Color(0xFF8D6E63),
        dateHeaderColor: const Color(0xFF5D4037),
      ),
    ],
  );

  // 테마별 이름과 테마 데이터를 매핑
  static final Map<String, ThemeData> themeData = {
    "light": lightTheme,
    "blue": blueTheme,
    "dark": darkTheme,
    "paper": paperTheme,
  };

  // 테마별 표시 이름
  static final Map<String, String> themeNames = {
    "light": "White Theme",
    "blue": "Blue Theme",
    "dark": "Black Theme",
    "paper": "Paper Theme",
  };

  // 테마별 색상 미리보기
  static final Map<String, Color> themeColors = {
    "light": Colors.white,
    "blue": const Color(0xFF1565C0),
    "dark": const Color(0xFF121212),
    "paper": const Color(0xFFF8F3E9),
  };

  // 헬퍼 메서드: 뉴스 상세화면 전용 스타일
  static ThemeData getNewsDetailStyle(ThemeData baseTheme) {
    if (baseTheme.brightness == Brightness.dark) {
      // 다크 테마 스타일 조정
      return baseTheme.copyWith(
        // 버튼 색상 등 특정 스타일 오버라이드
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64B5F6),
            foregroundColor: Colors.black,
          ),
        ),
      );
    } else {
      // 라이트 테마는 기본 스타일 유지
      return baseTheme;
    }
  }

  // 주어진 ThemeData에서 NewsCardStyleExtension을 가져오는 헬퍼 메서드
  static NewsCardStyleExtension newsCardStyleOf(BuildContext context) {
    return Theme.of(context).extension<NewsCardStyleExtension>() ??
        NewsCardStyleExtension.fallback();
  }

  // 주어진 ThemeData에서 RssThemeExtension을 가져오는 헬퍼 메서드
  static RssThemeExtension rssThemeOf(BuildContext context) {
    return Theme.of(context).extension<RssThemeExtension>() ??
        RssThemeExtension.fallback();
  }

  // 검색 스타일 확장 가져오기
  static SearchStyleExtension searchStyleOf(BuildContext context) {
    return Theme.of(context).extension<SearchStyleExtension>() ??
        SearchStyleExtension.fallback();
  }

  // 구독 뷰 스타일 확장 가져오기
  static SubscribeViewStyleExtension subscribeViewStyleOf(
      BuildContext context) {
    return Theme.of(context).extension<SubscribeViewStyleExtension>() ??
        SubscribeViewStyleExtension.fallback();
  }
}

// 뉴스 카드 스타일을 위한 확장 테마 클래스
class NewsCardStyleExtension extends ThemeExtension<NewsCardStyleExtension> {
  final TextStyle titleStyle;
  final TextStyle descriptionStyle;
  final TextStyle sourceStyle;
  final TextStyle dateStyle;
  final Color bookmarkActiveColor;
  final Color bookmarkInactiveColor;
  final Color thumbnailPlaceholderColor;
  final double thumbnailBorderRadius;
  final EdgeInsets cardPadding;
  final Color dividerColor;

  NewsCardStyleExtension({
    required this.titleStyle,
    required this.descriptionStyle,
    required this.sourceStyle,
    required this.dateStyle,
    required this.bookmarkActiveColor,
    required this.bookmarkInactiveColor,
    required this.thumbnailPlaceholderColor,
    required this.thumbnailBorderRadius,
    required this.cardPadding,
    required this.dividerColor,
  });

  @override
  ThemeExtension<NewsCardStyleExtension> copyWith({
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    TextStyle? sourceStyle,
    TextStyle? dateStyle,
    Color? bookmarkActiveColor,
    Color? bookmarkInactiveColor,
    Color? thumbnailPlaceholderColor,
    double? thumbnailBorderRadius,
    EdgeInsets? cardPadding,
    Color? dividerColor,
  }) {
    return NewsCardStyleExtension(
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      sourceStyle: sourceStyle ?? this.sourceStyle,
      dateStyle: dateStyle ?? this.dateStyle,
      bookmarkActiveColor: bookmarkActiveColor ?? this.bookmarkActiveColor,
      bookmarkInactiveColor:
          bookmarkInactiveColor ?? this.bookmarkInactiveColor,
      thumbnailPlaceholderColor:
          thumbnailPlaceholderColor ?? this.thumbnailPlaceholderColor,
      thumbnailBorderRadius:
          thumbnailBorderRadius ?? this.thumbnailBorderRadius,
      cardPadding: cardPadding ?? this.cardPadding,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }

  @override
  ThemeExtension<NewsCardStyleExtension> lerp(
      covariant ThemeExtension<NewsCardStyleExtension>? other, double t) {
    if (other is! NewsCardStyleExtension) {
      return this;
    }

    return NewsCardStyleExtension(
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t)!,
      descriptionStyle:
          TextStyle.lerp(descriptionStyle, other.descriptionStyle, t)!,
      sourceStyle: TextStyle.lerp(sourceStyle, other.sourceStyle, t)!,
      dateStyle: TextStyle.lerp(dateStyle, other.dateStyle, t)!,
      bookmarkActiveColor:
          Color.lerp(bookmarkActiveColor, other.bookmarkActiveColor, t)!,
      bookmarkInactiveColor:
          Color.lerp(bookmarkInactiveColor, other.bookmarkInactiveColor, t)!,
      thumbnailPlaceholderColor: Color.lerp(
          thumbnailPlaceholderColor, other.thumbnailPlaceholderColor, t)!,
      thumbnailBorderRadius:
          lerpDouble(thumbnailBorderRadius, other.thumbnailBorderRadius, t),
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
    );
  }

  // 기본값을 제공하는 팩토리 메서드
  factory NewsCardStyleExtension.fallback() {
    return NewsCardStyleExtension(
      titleStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 1.3,
      ),
      descriptionStyle: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
        height: 1.2,
      ),
      sourceStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.blue,
      ),
      dateStyle: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
      bookmarkActiveColor: Colors.blue,
      bookmarkInactiveColor: Colors.grey,
      thumbnailPlaceholderColor: Colors.grey.shade200,
      thumbnailBorderRadius: 4.0,
      cardPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      dividerColor: Colors.grey.shade200,
    );
  }

  // lerpDouble 함수 구현
  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

// RSS 관련 테마 확장 클래스
class RssThemeExtension extends ThemeExtension<RssThemeExtension> {
  final Color channelCardBackground;
  final Color subscribeButtonActiveBackground;
  final Color subscribeButtonActiveText;
  final Color subscribeButtonInactiveBackground;
  final Color subscribeButtonInactiveText;
  final List<Color> channelImageGradientColors;
  final double channelImageBorderRadius;
  final Color linkColor; // 추가된 속성
  final Color channelIconColor; // 추가된 속성

  RssThemeExtension({
    required this.channelCardBackground,
    required this.subscribeButtonActiveBackground,
    required this.subscribeButtonActiveText,
    required this.subscribeButtonInactiveBackground,
    required this.subscribeButtonInactiveText,
    required this.channelImageGradientColors,
    required this.channelImageBorderRadius,
    required this.linkColor,
    required this.channelIconColor,
  });

  @override
  ThemeExtension<RssThemeExtension> copyWith({
    Color? channelCardBackground,
    Color? subscribeButtonActiveBackground,
    Color? subscribeButtonActiveText,
    Color? subscribeButtonInactiveBackground,
    Color? subscribeButtonInactiveText,
    List<Color>? channelImageGradientColors,
    double? channelImageBorderRadius,
    Color? linkColor,
    Color? channelIconColor,
  }) {
    return RssThemeExtension(
      channelCardBackground:
          channelCardBackground ?? this.channelCardBackground,
      subscribeButtonActiveBackground: subscribeButtonActiveBackground ??
          this.subscribeButtonActiveBackground,
      subscribeButtonActiveText:
          subscribeButtonActiveText ?? this.subscribeButtonActiveText,
      subscribeButtonInactiveBackground: subscribeButtonInactiveBackground ??
          this.subscribeButtonInactiveBackground,
      subscribeButtonInactiveText:
          subscribeButtonInactiveText ?? this.subscribeButtonInactiveText,
      channelImageGradientColors:
          channelImageGradientColors ?? this.channelImageGradientColors,
      channelImageBorderRadius:
          channelImageBorderRadius ?? this.channelImageBorderRadius,
      linkColor: linkColor ?? this.linkColor,
      channelIconColor: channelIconColor ?? this.channelIconColor,
    );
  }

  @override
  ThemeExtension<RssThemeExtension> lerp(
      covariant ThemeExtension<RssThemeExtension>? other, double t) {
    if (other is! RssThemeExtension) {
      return this;
    }

    return RssThemeExtension(
      channelCardBackground:
          Color.lerp(channelCardBackground, other.channelCardBackground, t)!,
      subscribeButtonActiveBackground: Color.lerp(
          subscribeButtonActiveBackground,
          other.subscribeButtonActiveBackground,
          t)!,
      subscribeButtonActiveText: Color.lerp(
          subscribeButtonActiveText, other.subscribeButtonActiveText, t)!,
      subscribeButtonInactiveBackground: Color.lerp(
          subscribeButtonInactiveBackground,
          other.subscribeButtonInactiveBackground,
          t)!,
      subscribeButtonInactiveText: Color.lerp(
          subscribeButtonInactiveText, other.subscribeButtonInactiveText, t)!,
      channelImageGradientColors: [
        Color.lerp(channelImageGradientColors[0],
            other.channelImageGradientColors[0], t)!,
        Color.lerp(channelImageGradientColors[1],
            other.channelImageGradientColors[1], t)!,
      ],
      channelImageBorderRadius: lerpDouble(
          channelImageBorderRadius, other.channelImageBorderRadius, t),
      linkColor: Color.lerp(linkColor, other.linkColor, t)!,
      channelIconColor:
          Color.lerp(channelIconColor, other.channelIconColor, t)!,
    );
  }

  // 기본값을 제공하는 팩토리 메서드
  factory RssThemeExtension.fallback() {
    return RssThemeExtension(
      channelCardBackground: Colors.white,
      subscribeButtonActiveBackground: Colors.blue.shade50,
      subscribeButtonActiveText: Colors.blue,
      subscribeButtonInactiveBackground: Colors.grey.shade200,
      subscribeButtonInactiveText: Colors.grey.shade700,
      channelImageGradientColors: [Colors.blue.shade400, Colors.blue.shade700],
      channelImageBorderRadius: 10.0,
      linkColor: Colors.blue.shade700,
      channelIconColor: Colors.orange.shade300,
    );
  }

  // lerpDouble 함수 구현
  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

// 검색 결과 스타일 테마 확장 클래스
class SearchStyleExtension extends ThemeExtension<SearchStyleExtension> {
  // 채널 태그 스타일
  final Color channelTagBackground;
  final Color channelTagBorder;
  final Color channelTagText;

  // RSS 태그 스타일
  final Color rssTagBackground;
  final Color rssTagBorder;
  final Color rssTagText;

  // 채널 아이콘 스타일
  final Color channelIconColor;
  final Color channelIconBackground;

  SearchStyleExtension({
    required this.channelTagBackground,
    required this.channelTagBorder,
    required this.channelTagText,
    required this.rssTagBackground,
    required this.rssTagBorder,
    required this.rssTagText,
    required this.channelIconColor,
    required this.channelIconBackground,
  });

  @override
  ThemeExtension<SearchStyleExtension> copyWith({
    Color? channelTagBackground,
    Color? channelTagBorder,
    Color? channelTagText,
    Color? rssTagBackground,
    Color? rssTagBorder,
    Color? rssTagText,
    Color? channelIconColor,
    Color? channelIconBackground,
  }) {
    return SearchStyleExtension(
      channelTagBackground: channelTagBackground ?? this.channelTagBackground,
      channelTagBorder: channelTagBorder ?? this.channelTagBorder,
      channelTagText: channelTagText ?? this.channelTagText,
      rssTagBackground: rssTagBackground ?? this.rssTagBackground,
      rssTagBorder: rssTagBorder ?? this.rssTagBorder,
      rssTagText: rssTagText ?? this.rssTagText,
      channelIconColor: channelIconColor ?? this.channelIconColor,
      channelIconBackground:
          channelIconBackground ?? this.channelIconBackground,
    );
  }

  @override
  ThemeExtension<SearchStyleExtension> lerp(
      covariant ThemeExtension<SearchStyleExtension>? other, double t) {
    if (other is! SearchStyleExtension) {
      return this;
    }

    return SearchStyleExtension(
      channelTagBackground:
          Color.lerp(channelTagBackground, other.channelTagBackground, t)!,
      channelTagBorder:
          Color.lerp(channelTagBorder, other.channelTagBorder, t)!,
      channelTagText: Color.lerp(channelTagText, other.channelTagText, t)!,
      rssTagBackground:
          Color.lerp(rssTagBackground, other.rssTagBackground, t)!,
      rssTagBorder: Color.lerp(rssTagBorder, other.rssTagBorder, t)!,
      rssTagText: Color.lerp(rssTagText, other.rssTagText, t)!,
      channelIconColor:
          Color.lerp(channelIconColor, other.channelIconColor, t)!,
      channelIconBackground:
          Color.lerp(channelIconBackground, other.channelIconBackground, t)!,
    );
  }

  // 기본값을 제공하는 팩토리 메서드
  factory SearchStyleExtension.fallback() {
    return SearchStyleExtension(
      channelTagBackground: Colors.green.shade50,
      channelTagBorder: Colors.green.shade200,
      channelTagText: Colors.green.shade700,
      rssTagBackground: Colors.orange.shade50,
      rssTagBorder: Colors.orange.shade200,
      rssTagText: Colors.orange.shade700,
      channelIconColor: Colors.orange.shade300,
      channelIconBackground: Colors.orange.shade50,
    );
  }
}

// 구독 화면 스타일 테마 확장 클래스
class SubscribeViewStyleExtension
    extends ThemeExtension<SubscribeViewStyleExtension> {
  // 날짜 헤더 스타일
  final Color dateHeaderBackground;
  final TextStyle dateTextStyle;
  final TextStyle countTextStyle;
  final Color dotColor;
  final Color dateHeaderColor; // 추가된 속성

  // 채널 카드 스타일
  final Color channelCardBorder;
  final Color expandButtonBackground;
  final Color expandButtonTextColor;
  final Color collapseButtonTextColor;
  final Color sectionDividerColor;

  // 오류 및 빈 상태 스타일
  final Color errorIconColor;
  final Color emptyIconColor;
  final Color emptyTextColor;
  final Color hintBoxBackground;
  final Color hintBoxBorder;
  final Color hintTextColor;

  SubscribeViewStyleExtension({
    required this.dateHeaderBackground,
    required this.dateTextStyle,
    required this.countTextStyle,
    required this.dotColor,
    required this.channelCardBorder,
    required this.expandButtonBackground,
    required this.expandButtonTextColor,
    required this.collapseButtonTextColor,
    required this.sectionDividerColor,
    required this.errorIconColor,
    required this.emptyIconColor,
    required this.emptyTextColor,
    required this.hintBoxBackground,
    required this.hintBoxBorder,
    required this.hintTextColor,
    required this.dateHeaderColor, // 추가된 속성
  });

  @override
  ThemeExtension<SubscribeViewStyleExtension> copyWith({
    Color? dateHeaderBackground,
    TextStyle? dateTextStyle,
    TextStyle? countTextStyle,
    Color? dotColor,
    Color? channelCardBorder,
    Color? expandButtonBackground,
    Color? expandButtonTextColor,
    Color? collapseButtonTextColor,
    Color? sectionDividerColor,
    Color? errorIconColor,
    Color? emptyIconColor,
    Color? emptyTextColor,
    Color? hintBoxBackground,
    Color? hintBoxBorder,
    Color? hintTextColor,
    Color? dateHeaderColor, // 추가된 속성
  }) {
    return SubscribeViewStyleExtension(
      dateHeaderBackground: dateHeaderBackground ?? this.dateHeaderBackground,
      dateTextStyle: dateTextStyle ?? this.dateTextStyle,
      countTextStyle: countTextStyle ?? this.countTextStyle,
      dotColor: dotColor ?? this.dotColor,
      channelCardBorder: channelCardBorder ?? this.channelCardBorder,
      expandButtonBackground:
          expandButtonBackground ?? this.expandButtonBackground,
      expandButtonTextColor:
          expandButtonTextColor ?? this.expandButtonTextColor,
      collapseButtonTextColor:
          collapseButtonTextColor ?? this.collapseButtonTextColor,
      sectionDividerColor: sectionDividerColor ?? this.sectionDividerColor,
      errorIconColor: errorIconColor ?? this.errorIconColor,
      emptyIconColor: emptyIconColor ?? this.emptyIconColor,
      emptyTextColor: emptyTextColor ?? this.emptyTextColor,
      hintBoxBackground: hintBoxBackground ?? this.hintBoxBackground,
      hintBoxBorder: hintBoxBorder ?? this.hintBoxBorder,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      dateHeaderColor: dateHeaderColor ?? this.dateHeaderColor, // 추가된 속성
    );
  }

  @override
  ThemeExtension<SubscribeViewStyleExtension> lerp(
      covariant ThemeExtension<SubscribeViewStyleExtension>? other, double t) {
    if (other is! SubscribeViewStyleExtension) {
      return this;
    }

    return SubscribeViewStyleExtension(
      dateHeaderBackground:
          Color.lerp(dateHeaderBackground, other.dateHeaderBackground, t)!,
      dateTextStyle: TextStyle.lerp(dateTextStyle, other.dateTextStyle, t)!,
      countTextStyle: TextStyle.lerp(countTextStyle, other.countTextStyle, t)!,
      dotColor: Color.lerp(dotColor, other.dotColor, t)!,
      channelCardBorder:
          Color.lerp(channelCardBorder, other.channelCardBorder, t)!,
      expandButtonBackground:
          Color.lerp(expandButtonBackground, other.expandButtonBackground, t)!,
      expandButtonTextColor:
          Color.lerp(expandButtonTextColor, other.expandButtonTextColor, t)!,
      collapseButtonTextColor: Color.lerp(
          collapseButtonTextColor, other.collapseButtonTextColor, t)!,
      sectionDividerColor:
          Color.lerp(sectionDividerColor, other.sectionDividerColor, t)!,
      errorIconColor: Color.lerp(errorIconColor, other.errorIconColor, t)!,
      emptyIconColor: Color.lerp(emptyIconColor, other.emptyIconColor, t)!,
      emptyTextColor: Color.lerp(emptyTextColor, other.emptyTextColor, t)!,
      hintBoxBackground:
          Color.lerp(hintBoxBackground, other.hintBoxBackground, t)!,
      hintBoxBorder: Color.lerp(hintBoxBorder, other.hintBoxBorder, t)!,
      hintTextColor: Color.lerp(hintTextColor, other.hintTextColor, t)!,
      dateHeaderColor:
          Color.lerp(dateHeaderColor, other.dateHeaderColor, t)!, // 추가된 속성
    );
  }

  // 기본값을 제공하는 팩토리 메서드
  factory SubscribeViewStyleExtension.fallback() {
    return SubscribeViewStyleExtension(
      dateHeaderBackground: Colors.white,
      dateTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 17,
        letterSpacing: -0.5,
        color: Colors.indigo[700]!,
      ),
      countTextStyle: TextStyle(
        color: Colors.grey[600]!,
        fontSize: 14,
        letterSpacing: -0.3,
      ),
      dotColor: Colors.grey[400]!,
      channelCardBorder: Colors.grey[100]!,
      expandButtonBackground: Colors.grey[50]!,
      expandButtonTextColor: Colors.blue,
      collapseButtonTextColor: Colors.grey[600]!,
      sectionDividerColor: Colors.grey[100]!,
      errorIconColor: Colors.grey[300]!,
      emptyIconColor: Colors.grey[300]!,
      emptyTextColor: Colors.grey[600]!,
      hintBoxBackground: Colors.grey[50]!,
      hintBoxBorder: Colors.grey[100]!,
      hintTextColor: Colors.grey[600]!,
      dateHeaderColor: Colors.indigo[700]!, // 추가된 기본값
    );
  }
}
