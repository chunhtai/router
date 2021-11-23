import 'package:flutter/material.dart';

import 'routing.dart';

void main() {
  runApp(const MyApp());
}

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       routes: <String, WidgetBuilder>{
//         '/': (_) => const HomeScreen(),
//         '/second': (_) => const SecondScreen(),
//       },
//       onGenerateRoute: (RouteSettings settings) {
//         final RegExpMatch? match = RegExp('/second/(?<id>.+)').firstMatch(settings.name!);
//         if (match != null) {
//           return MaterialPageRoute(settings: settings, builder: (_) => MessageScreen(message: match.namedGroup('id')!));
//         }
//       },
//     );
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routeInformationParser: SimpleRouteInformationParser(),
      routerDelegate: SimpleRouterDelegate(
        pages: <String, PageBuilder>{
          '/': (_, __) => const MaterialPage(child: HomeScreen()),
          '/second': (_, __) => const MaterialPage(child: SecondScreen()),
        },
        onGeneratePage: (Uri uri) {
          final RegExpMatch? match = RegExp('/second/(?<id>.+)').firstMatch(uri.path);
          if (match != null) {
            return MaterialPage(child: MessageScreen(message: match.namedGroup('id')!));
          }
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('home'),
            ElevatedButton(onPressed: () {
              Navigator.pushNamed(context, '/second');
            }, child: const Text('Go To Second Screen'))
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Second')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Second'),
            ElevatedButton(onPressed: () {
              Navigator.pushNamed(context, '/second/123');
            }, child: const Text('Go To Message Screen')),
          ],
        ),
      ),
    );
  }
}

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key, required this.message}) : super(key: key);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Message')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Message: $message'),
          ],
        ),
      ),
    );
  }
}
