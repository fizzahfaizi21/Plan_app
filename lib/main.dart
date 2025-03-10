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
      body: _plans.isEmpty
          ? const Center(
              child: Text('No plans yet. Create a plan to get started!'),
            )
          : ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return _buildPlanTile(plan, index);
              },
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

  Widget _buildPlanTile(Plan plan, int index) {
    // Determine color based on plan type and completion status
    Color tileColor;
    if (plan.isCompleted) {
      tileColor = Colors.green.shade100;
    } else if (plan.type == PlanType.adoption) {
      tileColor = Colors.blue.shade100;
    } else {
      tileColor = Colors.orange.shade100;
    }

    return Dismissible(
      key: Key(plan.name + index.toString()),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.check,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          plan.isCompleted = !plan.isCompleted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(plan.isCompleted
                ? '${plan.name} marked as completed'
                : '${plan.name} marked as pending'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      confirmDismiss: (direction) async {
        setState(() {
          plan.isCompleted = !plan.isCompleted;
        });
        return false; // Don't remove the item from the list
      },
      child: GestureDetector(
        onDoubleTap: () {
          _deletePlan(index);
        },
        onLongPress: () {
          _showEditPlanDialog(plan, index);
        },
        child: Card(
          color: tileColor,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              plan.name,
              style: TextStyle(
                decoration: plan.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.description),
                const SizedBox(height: 4),
                Text(
                  'Date: ${DateFormat('MMM dd, yyyy').format(plan.date)}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Type: ${plan.type.toString().split('.').last}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Status: ${plan.isCompleted ? "Completed" : "Pending"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: plan.isCompleted ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        ),
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

  void _showEditPlanDialog(Plan plan, int index) {
    final nameController = TextEditingController(text: plan.name);
    final descriptionController = TextEditingController(text: plan.description);
    DateTime selectedDate = plan.date;
    PlanType selectedType = plan.type;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Plan'),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Status: '),
                        Switch(
                          value: plan.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              plan.isCompleted = value;
                            });
                          },
                        ),
                        Text(plan.isCompleted ? 'Completed' : 'Pending'),
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
                      _updatePlan(
                        index,
                        nameController.text,
                        descriptionController.text,
                        selectedDate,
                        selectedType,
                        plan.isCompleted,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Update'),
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

  void _updatePlan(int index, String name, String description, DateTime date,
      PlanType type, bool isCompleted) {
    setState(() {
      _plans[index].name = name;
      _plans[index].description = description;
      _plans[index].date = date;
      _plans[index].type = type;
      _plans[index].isCompleted = isCompleted;
    });
  }

  void _deletePlan(int index) {
    setState(() {
      final plan = _plans.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${plan.name} deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
}

//
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
