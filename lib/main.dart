import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'services/notification_service.dart';
import 'services/chat_service.dart';
import 'services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'onlyUs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const _SplashRouter(),
    );
  }
}

/// Checks SharedPreferences to resume session if already logged in.
class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _route();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('currentUser');
    if (user != null && user.isNotEmpty) {
      if (state == AppLifecycleState.resumed) {
        PresenceService.updatePresence(user, true);
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
        PresenceService.updatePresence(user, false);
      }
    }
  }

  Future<void> _route() async {
    await NotificationService().init();
    await Future.delayed(const Duration(milliseconds: 5000)); // Time to read the messages
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString('currentUser');
    if (!mounted) return;
    if (user != null && user.isNotEmpty) {
      ChatService().startBackgroundListener(user);
      PresenceService.updatePresence(user, true); // Mark online on startup
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ChatScreen(currentUser: user)));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Splash logo
            const DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Icon(Icons.favorite_rounded,
                    size: 52, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'onlyUs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Not just a ban will keep us from talking ever again ❤️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Никакой бан не заставит нас перестать общаться ❤️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF48CAE4).withOpacity(0.9),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'مش مجرد حظر هيخلينا مش هنتكلم تاني ❤️',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: const Color(0xFF6C63FF).withOpacity(0.9),
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
