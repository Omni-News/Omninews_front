# Omninews

RSS 피드, 큐레이션된 뉴스, 개인화된 콘텐츠를 한 곳에서 제공하는 Flutter 기반 크로스 플랫폼 뉴스 앱입니다.

**웹**: https://kang1027.com/omninews
**앱 스토어**: https://apps.apple.com/kr/app/omninews/id6746567181?l=en-GB

## 주요 기능

- **RSS 피드 구독**: 좋아하는 RSS 피드를 구독하고 정리
- **뉴스 탐색**: 다양한 소스의 큐레이션된 뉴스 탐색
- **소셜 로그인**: Google, Kakao, Apple 로그인 지원
- **북마크**: 나중에 읽을 기사 저장
- **검색**: 모든 소스에서 기사 검색
- **읽기 기록**: 최근 읽은 기사 추적
- **커스텀 테마**: 개인화된 읽기 경험을 위한 다양한 테마 옵션
- **푸시 알림**: Firebase Cloud Messaging을 통한 업데이트
- **인앱 구매**: 프리미엄 구독 기능
- **크로스 플랫폼**: iOS, Android, Web 지원

## 사전 요구사항

- Flutter SDK ^3.7.2
- Dart SDK
- Xcode (iOS 개발용)
- Android Studio (Android 개발용)
- Firebase 계정
- Google Cloud Console 계정 (Google 로그인용)
- Kakao Developers 계정 (Kakao 로그인용)

## 설정

### 1. 저장소 클론

```bash
git clone <repository-url>
cd Omninews_front
```

### 2. 의존성 설치

```bash
flutter pub get
```

### 3. 환경 변수 설정

루트 디렉토리에 `.env` 파일을 생성합니다:

```bash
cp .env.example .env
```

`.env` 파일을 편집하여 인증 정보를 추가합니다:

```env
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_SERVER_CLIENT_ID=your-google-server-client-id
KAKAO_APP_KEY=your-kakao-app-key
```

**인증 정보 발급 방법:**

- **GOOGLE_CLIENT_ID & GOOGLE_SERVER_CLIENT_ID**:
  1. [Google Cloud Console](https://console.cloud.google.com/)로 이동
  2. 새 프로젝트를 생성하거나 기존 프로젝트 선택
  3. Google Sign-In API 활성화
  4. iOS, Android, Web용 OAuth 2.0 인증 정보 생성
  5. Client ID 복사

- **KAKAO_APP_KEY**:
  1. [Kakao Developers](https://developers.kakao.com/)로 이동
  2. 새 애플리케이션 생성
  3. 앱 키 섹션에서 Native App Key 가져오기

### 4. Firebase 설정

#### iOS
1. [Firebase Console](https://console.firebase.google.com/)로 이동
2. iOS 앱 추가
3. `GoogleService-Info.plist` 다운로드
4. `ios/Runner/` 에 배치

#### Android
1. Firebase Console에서 Android 앱 추가
2. `google-services.json` 다운로드
3. `android/app/` 에 배치

### 5. Android 서명 설정

릴리즈 빌드를 위해 서명을 설정해야 합니다:

#### 키스토어 생성 (없는 경우)

```bash
keytool -genkey -v -keystore android/update-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### key.properties 설정

`android/key.properties` 파일 생성:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=update-keystore.jks
```

**주의**: 이 파일들은 이미 `.gitignore`에 포함되어 있으며 절대 커밋하면 안 됩니다.

## 앱 실행

### 개발 모드

```bash
# 연결된 기기/에뮬레이터에서 실행
flutter run

# 특정 플랫폼에서 실행
flutter run -d chrome    # Web
flutter run -d ios       # iOS
flutter run -d android   # Android
```

### 프로덕션 빌드

#### iOS
```bash
flutter build ios --release
```

#### Android
```bash
flutter build appbundle --release  # Google Play Store용
flutter build apk --release        # APK 직접 배포용
```

#### Web
```bash
flutter build web --release
```

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── news.dart
│   ├── rss_channel.dart
│   ├── rss_item.dart
│   └── ...
├── screens/                  # UI 화면
│   ├── home_screen.dart
│   ├── news_screen.dart
│   ├── rss_screen.dart
│   ├── bookmark_screen.dart
│   ├── search_screen.dart
│   └── ...
├── services/                 # 비즈니스 로직 & API 호출
│   ├── auth_service.dart
│   ├── news_service.dart
│   ├── rss_service.dart
│   └── ...
├── widgets/                  # 재사용 가능한 UI 컴포넌트
├── providers/                # 상태 관리
│   ├── theme_provider.dart
│   ├── settings_provider.dart
│   └── subscription_provider.dart
└── utils/                    # 헬퍼 유틸리티
```

## 주요 의존성

- **firebase_core** & **firebase_auth**: 인증
- **firebase_messaging**: 푸시 알림
- **google_sign_in**: Google OAuth
- **kakao_flutter_sdk**: Kakao OAuth
- **sign_in_with_apple**: Apple Sign In
- **in_app_purchase**: 인앱 구독
- **google_mobile_ads**: 광고 통합
- **flutter_dotenv**: 환경 변수
- **provider**: 상태 관리
- **http**: API 호출
- **shared_preferences**: 로컬 저장소

## 보안 주의사항

**중요**: 다음 파일들은 민감한 정보를 포함하고 있으며 절대 커밋하면 안 됩니다:

- `.env` - API 키 및 시크릿 정보
- `android/key.properties` - 키스토어 인증 정보
- `android/update-keystore.jks` - 릴리즈 서명용 키스토어 파일
- `android/app/google-services.json` - Firebase 설정 파일
- `ios/Runner/GoogleService-Info.plist` - Firebase 설정 파일

이 모든 파일은 이미 `.gitignore`에 포함되어 있습니다.
