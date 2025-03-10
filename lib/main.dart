import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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

class _PlanManagerScreenState extends State<PlanManagerScreen>
    with SingleTickerProviderStateMixin {
  final List<Plan> _plans = [];
  late TabController _tabController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Plan>> _events = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption & Travel Planner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List View'),
            Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListView(),
          _buildCalendarView(),
        ],
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

  Widget _buildListView() {
    return _plans.isEmpty
        ? const Center(
            child: Text('No plans yet. Create a plan to get started!'),
          )
        : ReorderableListView.builder(
            itemCount: _plans.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _plans.removeAt(oldIndex);
                _plans.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final plan = _plans[index];
              return _buildPlanTile(plan, index);
            },
          );
  }

  Widget _buildCalendarView() {
    _updateEventMap();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: (day) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            return _events[normalizedDay] ?? [];
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: const CalendarStyle(
            markersMaxCount: 3,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildSelectedDayPlans(),
        ),
        _buildDragTarget(),
      ],
    );
  }

  Widget _buildSelectedDayPlans() {
    if (_selectedDay == null) return Container();

    final normalizedDay =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayPlans = _events[normalizedDay] ?? [];

    return dayPlans.isEmpty
        ? const Center(
            child: Text('No plans for this day'),
          )
        : ListView.builder(
            itemCount: dayPlans.length,
            itemBuilder: (context, index) {
              final plan = dayPlans[index];
              final planIndex = _plans.indexOf(plan);
              return _buildPlanTile(plan, planIndex);
            },
          );
  }

  Widget _buildDragTarget() {
    return DragTarget<Plan>(
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 80,
          color: candidateData.isNotEmpty
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          child: Center(
            child: Text(
              candidateData.isNotEmpty
                  ? 'Drop to assign to ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}'
                  : 'Drag a plan here to assign to ${_selectedDay != null ? DateFormat('MMM dd, yyyy').format(_selectedDay!) : 'selected date'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
      onAccept: (plan) {
        final planIndex = _plans.indexOf(plan);
        if (planIndex != -1 && _selectedDay != null) {
          setState(() {
            _plans[planIndex].date = _selectedDay!;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${plan.name} assigned to ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}'),
              duration: const Duration(seconds: 2),
            ),
          );
          _updateEventMap();
        }
      },
    );
  }

  void _updateEventMap() {
    _events = {};
    for (final plan in _plans) {
      final normalizedDay =
          DateTime(plan.date.year, plan.date.month, plan.date.day);
      if (_events[normalizedDay] == null) {
        _events[normalizedDay] = [];
      }
      _events[normalizedDay]!.add(plan);
    }
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
      child: LongPressDraggable<Plan>(
        data: plan,
        feedback: Material(
          elevation: 4,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(16),
            color: tileColor,
            child: Text(plan.name, style: const TextStyle(fontSize: 16)),
          ),
        ),
        childWhenDragging: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.grey.shade200,
          child: ListTile(
            title: Text(
              plan.name,
              style: TextStyle(
                decoration: plan.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            subtitle: Text('Dragging...'),
          ),
        ),
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
      ),
    );
  }

  void _showAddPlanDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();
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
      _updateEventMap();
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
      _updateEventMap();
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
      _updateEventMap();
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
