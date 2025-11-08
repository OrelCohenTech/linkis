import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groups Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

enum AppView { menu, search, add, categories, signup }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AppView currentView = AppView.menu;

  // Shared state for Search view
  List<String> items = [];
  String query = "";
  bool isLoading = false;

  // Fetch from Flask
  Future<void> fetchItems() async {
    setState(() => isLoading = true);
    try {
      // Change the URL as needed:
      // Android emulator: http://10.0.2.2:5000/groups
      // iOS simulator:   http://127.0.0.1:5000/groups
      // Real device:     http://<your-computer-LAN-IP>:5000/groups
      final res = await http.get(Uri.parse('http://127.0.0.1:5000/groups'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        setState(() {
          items = data.map((e) => e.toString()).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load groups');
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading groups: $e')),
      );
    }
  }

  // Navigate helpers
  void goTo(AppView view) {
    setState(() => currentView = view);
    if (view == AppView.search) {
      // Load data when entering search
      fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (currentView) {
      case AppView.menu:
        return Scaffold(
          appBar: AppBar(title: const Text('Choose an option')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _MenuButton(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () => goTo(AppView.search),
                ),
                _MenuButton(
                  icon: Icons.group_add,
                  label: 'Add Group',
                  onTap: () {
                    goTo(AppView.add);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add Group screen placeholder')),
                    );
                  },
                ),
                _MenuButton(
                  icon: Icons.category,
                  label: 'Categories',
                  onTap: () {
                    goTo(AppView.categories);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categories screen placeholder')),
                    );
                  },
                ),
                _MenuButton(
                  icon: Icons.person_add,
                  label: 'Sign Up',
                  onTap: () {
                    goTo(AppView.signup);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign Up screen placeholder')),
                    );
                  },
                ),
              ],
            ),
          ),
        );

      case AppView.search:
        final filtered = items
            .where((it) => it.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Search Groups'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => goTo(AppView.menu),
              tooltip: 'Back',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isLoading ? null : fetchItems,
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchItems,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => ListTile(
                            title: Text(filtered[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );


  case AppView.add:
  final TextEditingController _addController = TextEditingController();

  Future<void> addGroup() async {
    final name = _addController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('http://127.0.0.1:5000/groups'), // Adjust if needed
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      );

      if (res.statusCode == 201) {
        _addController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group added successfully')),
        );
      } else if (res.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group already exists')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add group: ${res.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Add Group'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => goTo(AppView.menu),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _addController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: addGroup,
            icon: const Icon(Icons.add),
            label: const Text('Add Group'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50), // Full width
            ),
          ),
        ],
      ),
    ),
  );

      case AppView.categories:
      case AppView.signup:
        // Minimal placeholders, you can replace with real UIs later
        return Scaffold(
          appBar: AppBar(
            title: Text(_titleFor(currentView)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => goTo(AppView.menu),
            ),
          ),
          body: Center(child: Text('${_titleFor(currentView)} screen')),
        );
    }
  }

  String _titleFor(AppView v) {
    switch (v) {
      case AppView.add:
        return 'Add Group';
      case AppView.categories:
        return 'Categories';
      case AppView.signup:
        return 'Sign Up';
      default:
        return 'Menu';
    }
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
