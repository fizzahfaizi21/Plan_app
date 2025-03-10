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
    _updateEventMap(); // Initialize event map
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
    return Column(
      children: [
        Expanded(
          child: _plans.isEmpty
              ? Center(
                  child: Text(
                    'No plans yet. Create a plan or use templates below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
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
                ),
        ),
        // Always show templates at the bottom of list view
        _buildTemplatesSection(),
      ],
    );
  }

  Widget _buildTemplatesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Template Plans:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTemplate(
                'Adoption Meeting',
                'Schedule meeting with adoption agency',
                PlanType.adoption,
                Colors.blue.shade100,
              ),
              _buildTemplate(
                'Travel Booking',
                'Book flights and accommodations',
                PlanType.travel,
                Colors.orange.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplate(
      String name, String description, PlanType type, Color color) {
    return DragTarget<Plan>(
      onAccept: (data) {
        // Update an existing plan when dropped on a template
        final index = _plans.indexOf(data);
        if (index != -1) {
          setState(() {
            _plans[index].type = type;
            _plans[index].name = name;
            _plans[index].description = description;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated plan to $name template'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        // This creates the template card that is both draggable and a drop target
        return Draggable<Map<String, dynamic>>(
          data: {
            'name': name,
            'description': description,
            'type': type,
          },
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 150,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(name),
            ),
          ),
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: candidateData.isNotEmpty ? color.withOpacity(0.7) : color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: candidateData.isNotEmpty
                    ? Colors.blue
                    : Colors.grey.shade300,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView() {
    // Make sure events are updated
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
        const Divider(),
        // Display plans for selected day
        Expanded(
          child: _buildSelectedDayPlans(),
        ),
        // Templates for calendar view as well
        _buildCalendarTemplates(),
      ],
    );
  }

  Widget _buildCalendarTemplates() {
    if (_selectedDay == null) return Container();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Add to ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCalendarTemplate(
                'Adoption Meeting',
                'Schedule meeting with adoption agency',
                PlanType.adoption,
                Colors.blue.shade100,
              ),
              _buildCalendarTemplate(
                'Travel Booking',
                'Book flights and accommodations',
                PlanType.travel,
                Colors.orange.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTemplate(
      String name, String description, PlanType type, Color color) {
    return InkWell(
      onTap: () {
        // Add a new plan directly when template is tapped in calendar view
        if (_selectedDay != null) {
          _addPlan(name, description, _selectedDay!, type);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '$name added to ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayPlans() {
    if (_selectedDay == null) return Container();

    final normalizedDay =
        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayPlans = _events[normalizedDay] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Plans for ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Expanded(
          child: dayPlans.isEmpty
              ? DragTarget<Plan>(
                  onAccept: (data) {
                    // Update the date of an existing plan when dropped here
                    final index = _plans.indexOf(data);
                    if (index != -1 && _selectedDay != null) {
                      setState(() {
                        _plans[index].date = _selectedDay!;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${data.name} moved to ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      _updateEventMap();
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: candidateData.isNotEmpty
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.transparent,
                      child: Center(
                        child: Text(
                          candidateData.isNotEmpty
                              ? 'Drop to add here'
                              : 'No plans for this day\nDrag plans here or use templates below',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: dayPlans.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final plan = dayPlans[index];
                    final planIndex = _plans.indexOf(plan);
                    return _buildPlanTile(plan, planIndex);
                  },
                ),
        ),
      ],
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
      key: Key('plan_${plan.name}_$index'),
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
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete when swiped right to left
          return await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Delete Plan'),
                content:
                    Text('Are you sure you want to delete "${plan.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        } else {
          // Toggle completion when swiped left to right
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
          return false; // Don't dismiss
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deletePlan(index);
        }
      },
      child: Draggable<Plan>(
        // Make entire plan draggable, not just on long press
        data: plan,
        feedback: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Card(
              color: tileColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plan.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(plan.description),
                  ],
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey.shade200,
            child: ListTile(
              title: Text(plan.name),
              subtitle: Text('Dragging...'),
            ),
          ),
        ),
        child: GestureDetector(
          onTap: () {
            _showPlanDetails(plan);
          },
          onDoubleTap: () {
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      plan.isCompleted
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: plan.isCompleted ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        plan.isCompleted = !plan.isCompleted;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showEditPlanDialog(plan, index);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPlanDetails(Plan plan) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(plan.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description: ${plan.description}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(plan.date)}'),
              const SizedBox(height: 8),
              Text('Type: ${plan.type.toString().split('.').last}'),
              const SizedBox(height: 8),
              Text('Status: ${plan.isCompleted ? "Completed" : "Pending"}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
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
                              firstDate:
                                  DateTime.now().subtract(Duration(days: 365)),
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
                              firstDate:
                                  DateTime.now().subtract(Duration(days: 365)),
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

  void _updateEventMap() {
    Map<DateTime, List<Plan>> newEvents = {};
    for (final plan in _plans) {
      final normalizedDay =
          DateTime(plan.date.year, plan.date.month, plan.date.day);
      if (newEvents[normalizedDay] == null) {
        newEvents[normalizedDay] = [];
      }
      newEvents[normalizedDay]!.add(plan);
    }
    setState(() {
      _events = newEvents;
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
