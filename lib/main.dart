import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html; // ბრაუზერის მეხსიერებისთვის

void main() => runApp(const SchoolFocusApp());

class SchoolFocusApp extends StatelessWidget {
  const SchoolFocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF0A0E21),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- LOGIN (მეხსიერებით) ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  String _selectedClass = 'მე-9 კლასი';

  @override
  void initState() {
    super.initState();
    // თუ სახელი უკვე შენახულია, პირდაპირ გადავიდეს მთავარ გვერდზე
    String? savedName = html.window.localStorage['user_name'];
    if (savedName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToMain(savedName, html.window.localStorage['user_class'] ?? 'მე-9 კლასი');
      });
    }
  }

  void _navigateToMain(String name, String group) {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (c) => MainNavigation(name: name, classGroup: group)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.save, size: 60, color: Colors.cyanAccent),
              const SizedBox(height: 20),
              const Text("მონაცემები ინახება ლოკალურად", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "შენი სახელი", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    // ვინახავთ მონაცემებს მეხსიერებაში
                    html.window.localStorage['user_name'] = _nameController.text;
                    html.window.localStorage['user_class'] = _selectedClass;
                    _navigateToMain(_nameController.text, _selectedClass);
                  }
                },
                child: const Text("შესვლა და დამახსოვრება"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- NAVIGATION (ქულების შენახვით) ---
class MainNavigation extends StatefulWidget {
  final String name;
  final String classGroup;
  const MainNavigation({super.key, required this.name, required this.classGroup});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late int _points;

  @override
  void initState() {
    super.initState();
    // ქულების ჩატვირთვა მეხსიერებიდან
    String? savedPoints = html.window.localStorage['user_points'];
    _points = savedPoints != null ? int.parse(savedPoints) : 150;
  }

  void _updatePoints(int amount) {
    setState(() {
      _points += amount;
      // ყოველი ცვლილებისას ვინახავთ ქულებს
      html.window.localStorage['user_points'] = _points.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack( // IndexedStack ინახავს გვერდების მდგომარეობას
        index: _currentIndex,
        children: [
          FocusPage(points: _points, onAdd: _updatePoints),
          const Center(child: Text("რეიტინგი (მალე განახლდება)")),
          const Center(child: Text("მაღაზია (მალე განახლდება)")),
          ProfilePage(name: widget.name, classGroup: widget.classGroup, points: _points, onTeacherUpdate: _updatePoints),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.cyanAccent,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "ფოკუსი"),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "რეიტინგი"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "მაღაზია"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "პროფილი"),
        ],
      ),
    );
  }
}

// --- სხვა გვერდები (მოკლედ) ---
class FocusPage extends StatefulWidget {
  final int points; final Function(int) onAdd;
  const FocusPage({super.key, required this.points, required this.onAdd});
  @override _FocusPageState createState() => _FocusPageState();
}
class _FocusPageState extends State<FocusPage> {
  int _s = 0; Timer? _t; bool _a = false;
  void _go() {
    if (_a) { _t?.cancel(); widget.onAdd(_s ~/ 10); setState(() { _s = 0; _a = false; }); }
    else { setState(() => _a = true); _t = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => _s++)); }
  }
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text("${widget.points} ⭐", style: const TextStyle(fontSize: 40)),
    Text("${(_s ~/ 60)}:${(_s % 60).toString().padLeft(2,'0')}", style: const TextStyle(fontSize: 30)),
    ElevatedButton(onPressed: _go, child: Text(_a ? "STOP" : "START")),
  ]));
}

class ProfilePage extends StatelessWidget {
  final String name; final String classGroup; final int points; final Function(int) onTeacherUpdate;
  const ProfilePage({super.key, required this.name, required this.classGroup, required this.points, required this.onTeacherUpdate});

  @override Widget build(BuildContext context) => Column(children: [
    const SizedBox(height: 50),
    Text(name, style: const TextStyle(fontSize: 24)),
    Text("ბალანსი: $points ⭐"),
    const Spacer(),
    TextButton(onPressed: () {
      html.window.localStorage.clear(); // მეხსიერების გასუფთავება (Reset)
      html.window.location.reload(); 
    }, child: const Text("მონაცემების წაშლა და გამოსვლა", style: TextStyle(color: Colors.red))),
    const SizedBox(height: 20),
  ]);
}
