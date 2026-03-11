import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'bootstrap/boot.dart';

void main() async {
  print('═══════════════════════════════════════════');
  print('MAIN: Starting app');
  print('MAIN: WidgetsFlutterBinding.ensureInitialized()');
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORARY: Bypass Nylo entirely to test if Flutter renders
  print('MAIN: Running direct MaterialApp test (bypassing Nylo)');
  print('MAIN: About to call runApp()');

  runApp(Builder(
    builder: (context) {
      print('MAIN: MaterialApp builder called - widget is being built!');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('MAIN: PostFrameCallback - widget should be visible now');
      });

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.orange, // Force orange background
          colorScheme: ColorScheme.light(
            primary: Colors.blue,
            surface: Colors.orange,
            background: Colors.orange,
          ),
        ),
        darkTheme: null, // Disable dark theme
        themeMode: ThemeMode.light, // Force light mode
        home: Builder(
          builder: (context) {
            print('MAIN: Scaffold builder called');
            return Scaffold(
              backgroundColor: Colors.orange, // Very bright color
              body: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 300,
                        height: 300,
                        color: Colors.purple,
                        child: Center(
                          child: Text(
                            'DIRECT TEST\nNO NYLO\nIf you see this,\nFlutter works!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Text(
                        'This bypasses Nylo framework',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  ));

  print('MAIN: runApp() called successfully');
  print('═══════════════════════════════════════════');
  return; // Exit early, don't run Nylo

  /* ORIGINAL CODE (commented for testing):
  try {
    await Nylo.init(
      setup: Boot.nylo,
      setupFinished: Boot.finished,
      showSplashScreen: true,
    );
  } catch (e, stackTrace) {
    print('FATAL ERROR during Learn with Agrisiti initialization: $e');
    print('Stack trace: $stackTrace');

    // Fallback: Run a minimal app to show the error
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.white, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
  */
}
