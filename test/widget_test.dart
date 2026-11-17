import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misoles_social_media/demo_auth.dart';
import 'package:misoles_social_media/login_screen.dart';
import 'package:misoles_social_media/main.dart';
import 'package:misoles_social_media/social_media/create_post_sheet.dart';

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(_MockHttpClientRequest());
    }
    return null;
  }
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    return null;
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #headers) {
      return _MockHttpHeaders();
    }
    return null;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDown(() {
    DemoAuth.logout();
    DemoAuth.registeredUsername = null;
    DemoAuth.registeredPassword = null;
  });

  testWidgets('Full flow testing for Step 11', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. App starts at LoginScreen
    await tester.pumpWidget(const StudentApp());
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);

    // 2. Log in using default admin account -> MainScreen opens
    final usernameFields = find.byType(TextFormField);
    await tester.enterText(usernameFields.at(0), 'admin');
    await tester.enterText(usernameFields.at(1), 'admin123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Student!'), findsOneWidget);

    // 3. Open Social Media -> Sample posts appear
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Social Media'), findsWidgets);
    expect(find.text('JohnDoe'), findsOneWidget);
    expect(find.text('JaneSmith'), findsOneWidget);
    expect(find.text('Enjoying the sunny weather!'), findsOneWidget);
    expect(find.text('Just finished a great book!'), findsOneWidget);

    // 4. Tap the + button to open Create Post sheet
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsOneWidget);

    // 5. Submit a post with empty fields -> Validation message appears
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pump();
    expect(find.text('Complete both fields before submitting!'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(CreatePostSheet))).clearSnackBars();
    await tester.pumpAndSettle();

    // 6. Submit a post with invalid URL -> URL validation message appears
    final captionField = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    ).at(0);
    final imageField = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    ).at(1);

    await tester.enterText(captionField, 'My caption');
    await tester.enterText(imageField, 'not-a-valid-url');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pump();
    expect(find.text('Enter a valid HTTP or HTTPS image URL.'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(CreatePostSheet))).clearSnackBars();
    await tester.pumpAndSettle();

    // 7. Submit a valid post (Step 10 test case)
    await tester.enterText(captionField, 'My first Flutter social media post!');
    await tester.enterText(imageField, 'https://picsum.photos/id/20/600/400');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    // Confirm post appears at top with logged-in username 'admin'
    expect(find.text('My first Flutter social media post!'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);

    // 8. Tap Like twice -> changes to Liked, then back to Like
    final likeButtons = find.widgetWithText(TextButton, 'Like');
    expect(likeButtons, findsWidgets);
    await tester.tap(likeButtons.first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Liked'), findsOneWidget);

    // Tap Liked again to unlike
    await tester.tap(find.widgetWithText(TextButton, 'Liked'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Liked'), findsNothing);

    // Tap Like once more so it stays liked for Step 10
    await tester.tap(likeButtons.first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Liked'), findsOneWidget);

    // 9. Submit a blank comment -> No comment is added
    final commentFields = find.widgetWithText(TextField, 'Add a comment...');
    final sendButtons = find.byIcon(Icons.send);

    await tester.enterText(commentFields.first, '   ');
    await tester.tap(sendButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('0 Comments'), findsWidgets);

    // 10. Add a nonempty comment -> Comment appears and count increases
    await tester.enterText(commentFields.first, 'Awesome first post!');
    await tester.tap(sendButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('1 Comments'), findsOneWidget);
    expect(find.text('Awesome first post!'), findsOneWidget);

    // 11. Like a sample post, then create another post -> original post keeps its liked state
    final remainingLikeButtons = find.widgetWithText(TextButton, 'Like');
    await tester.tap(remainingLikeButtons.first);
    await tester.pumpAndSettle();
    // Now there are 2 Liked posts (admin and JohnDoe)
    expect(find.widgetWithText(TextButton, 'Liked'), findsNWidgets(2));

    // Create another post
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final newFields = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(newFields.at(0), 'Second post test');
    await tester.enterText(newFields.at(1), 'https://picsum.photos/id/21/600/400');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    // Verify original posts still have their Liked state
    expect(find.widgetWithText(TextButton, 'Liked'), findsNWidgets(2));

    // 12. Switch to Home and return -> Posts, likes, and comments remain
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Student!'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Second post test'), findsOneWidget);
    expect(find.text('My first Flutter social media post!'), findsOneWidget);
    expect(find.text('Awesome first post!'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Liked'), findsNWidgets(2));

    // 13. Log out, register, and log in with a new account -> New posts use registered username
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsOneWidget);

    // Logout
    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsWidgets);

    // Register a new account
    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();
    expect(find.text('Create an Account'), findsOneWidget);

    final regFields = find.byType(TextFormField);
    await tester.enterText(regFields.at(0), 'juan_delacruz');
    await tester.enterText(regFields.at(1), 'password123');
    await tester.enterText(regFields.at(2), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    // Back to Login
    expect(find.text('Login'), findsWidgets);
    ScaffoldMessenger.of(tester.element(find.byType(LoginScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    // Log in with new account
    final loginFields = find.byType(TextFormField);
    await tester.enterText(loginFields.at(0), 'juan_delacruz');
    await tester.enterText(loginFields.at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    // Go to Social Media
    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();

    // Create a new post with juan_delacruz
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final juanFields = find.descendant(
      of: find.byType(CreatePostSheet),
      matching: find.byType(TextField),
    );
    await tester.enterText(juanFields.at(0), 'Hello from Juan!');
    await tester.enterText(juanFields.at(1), 'https://picsum.photos/id/22/600/400');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Post'));
    await tester.pumpAndSettle();

    expect(find.text('Hello from Juan!'), findsOneWidget);
    expect(find.text('juan_delacruz'), findsOneWidget);
  });
}
