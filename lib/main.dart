import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    PlanType selectedType = PlanType.travel;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Plan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan Name',
                        hintText: 'Enter plan name',
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter plan description',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Date: '),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Plan Type: '),
                        DropdownButton<PlanType>(
                          value: selectedType,
                          onChanged: (PlanType? newValue) {
                            setState(() {
                              selectedType = newValue!;
                            });
                          },
                          items: PlanType.values
                              .map<DropdownMenuItem<PlanType>>(
                                  (PlanType value) {
                            return DropdownMenuItem<PlanType>(
                              value: value,
                              child: Text(value.toString().split('.').last),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      _addPlan(
                        nameController.text,
                        descriptionController.text,
                        selectedDate,
                        selectedType,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addPlan(String name, String description, DateTime date, PlanType type) {
    setState(() {
      _plans.add(
        Plan(
          name: name,
          description: description,
          date: date,
          type: type,
        ),
      );
    });
  }
}

class Plan {
  String name;
  String description;
  DateTime date;
  bool isCompleted;
  PlanType type;

  Plan({
    required this.name,
    required this.description,
    required this.date,
    this.isCompleted = false,
    required this.type,
  });
}

enum PlanType {
  adoption,
  travel,
}
