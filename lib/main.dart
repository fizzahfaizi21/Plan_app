import 'package:flutter/material.dart';

void main() {
  runApp(const AdoptionTravelPlannerApp());
}

class AdoptionTravelPlannerApp extends StatelessWidget {
  const AdoptionTravelPlannerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adoption & Travel Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PlanManagerScreen(),
    );
  }
}

class PlanManagerScreen extends StatefulWidget {
  const PlanManagerScreen({Key? key}) : super(key: key);

  @override
  _PlanManagerScreenState createState() => _PlanManagerScreenState();
}

class _PlanManagerScreenState extends State<PlanManagerScreen> {
  // Plan data model - we'll expand this
  final List<Plan> _plans = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption & Travel Planner'),
      ),
      body: const Center(
        child: Text('Plans will appear here'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPlanDialog();
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Plan',
      ),
    );
  }

  void _showAddPlanDialog() {
    // We'll implement this in the next step
  }
}

// Plan data model
class Plan {
  String name;
  String description;
  DateTime date;
  bool isCompleted;
  PlanType type; // adoption or travel

  Plan({
    required this.name,
    required this.description,
    required this.date,
    this.isCompleted = false,
    required this.type,
  });
}

// Plan type enum
enum PlanType {
  adoption,
  travel,
}
