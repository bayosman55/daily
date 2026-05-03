import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planlama ve Finans',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SharedPreferences _prefs;
  int _currentIndex = 0;

  final List<Goal> _goals = [];
  final List<PlanItem> _plans = [];
  final List<FinanceItem> _financeItems = [];

  static const String _keyGoals = 'saved_goals';
  static const String _keyPlans = 'saved_plans';
  static const String _keyFinance = 'saved_finance';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedData();
  }

  void _loadSavedData() {
    final String? goalsJson = _prefs.getString(_keyGoals);
    final String? plansJson = _prefs.getString(_keyPlans);
    final String? financeJson = _prefs.getString(_keyFinance);

    if (goalsJson != null) {
      final List<dynamic> data = jsonDecode(goalsJson);
      _goals
        ..clear()
        ..addAll(
          data.map((item) => Goal.fromJson(item as Map<String, dynamic>)),
        );
    }
    if (plansJson != null) {
      final List<dynamic> data = jsonDecode(plansJson);
      _plans
        ..clear()
        ..addAll(
          data.map((item) => PlanItem.fromJson(item as Map<String, dynamic>)),
        );
    }
    if (financeJson != null) {
      final List<dynamic> data = jsonDecode(financeJson);
      _financeItems
        ..clear()
        ..addAll(
          data.map(
            (item) => FinanceItem.fromJson(item as Map<String, dynamic>),
          ),
        );
    }
    setState(() {});
  }

  Future<void> _saveAll() async {
    await _prefs.setString(
      _keyGoals,
      jsonEncode(_goals.map((item) => item.toJson()).toList()),
    );
    await _prefs.setString(
      _keyPlans,
      jsonEncode(_plans.map((item) => item.toJson()).toList()),
    );
    await _prefs.setString(
      _keyFinance,
      jsonEncode(_financeItems.map((item) => item.toJson()).toList()),
    );
  }

  String _generateAiSummary() {
    final int goalCount = _goals.length;
    final int dailyGoals = _goals
        .where((goal) => goal.frequency == GoalFrequency.daily)
        .length;
    final int weeklyGoals = _goals
        .where((goal) => goal.frequency == GoalFrequency.weekly)
        .length;
    final int planCount = _plans.length;
    final double totalDebt = _financeItems
        .where((item) => item.isDebt)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double totalIncome = _financeItems
        .where((item) => !item.isDebt)
        .fold(0.0, (sum, item) => sum + item.amount);
    final double balance = totalIncome - totalDebt;

    if (goalCount == 0 && planCount == 0 && _financeItems.isEmpty) {
      return 'Henüz veri yok. Yapay zeka önerisi almak için hedef, plan veya finans kaydı ekleyebilirsin.';
    }

    final buffer = StringBuffer();
    buffer.writeln('Yapay Zeka Önerisi:');
    buffer.writeln(
      '• Toplam hedef: $goalCount (Günlük: $dailyGoals, Haftalık: $weeklyGoals)',
    );
    buffer.writeln('• Toplam plan: $planCount');
    buffer.writeln('• Gider tutarı: ₺${totalDebt.toStringAsFixed(2)}');
    buffer.writeln('• Gelir tutarı: ₺${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('• Net bakiye: ₺${balance.toStringAsFixed(2)}');

    if (balance < 0) {
      buffer.writeln(
        'Bütçeni dengelemek için harcamalarını gözden geçir. Gereksiz harcamaları azalt.',
      );
    } else {
      buffer.writeln(
        'Güncel finans durumun olumlu. Bu dengenin devamını sağlamak için izlemeye devam et.',
      );
    }

    if (goalCount == 0) {
      buffer.writeln(
        'Hedef ekle; bu, motivasyon ve öncelik yönetimine yardımcı olur.',
      );
    }
    if (planCount == 0) {
      buffer.writeln(
        'Plan ekleyerek günlük işlerini daha düzenli takip edebilirsin.',
      );
    }
    if (_financeItems.isEmpty) {
      buffer.writeln(
        'Finans kaydı eklemek, gelir/giderleri takip etmeni sağlar.',
      );
    }

    return buffer.toString();
  }

  void _showAiAssistant() {
    final String summary = _generateAiSummary();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yapay Zeka Yardımcısı'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _addGoal() {
    final titleController = TextEditingController();
    GoalFrequency frequency = GoalFrequency.daily;
    bool reminderEnabled = true;
    TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);
    int reminderWeekday = DateTime.monday;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Yeni Hedef Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Hedef başlığı',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GoalFrequency>(
                      initialValue: frequency,
                      decoration: const InputDecoration(labelText: 'Frekans'),
                      items: const [
                        DropdownMenuItem(
                          value: GoalFrequency.daily,
                          child: Text('Günlük'),
                        ),
                        DropdownMenuItem(
                          value: GoalFrequency.weekly,
                          child: Text('Haftalık'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          dialogSetState(() {
                            frequency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Bildirim hatırlatması ekle'),
                      value: reminderEnabled,
                      onChanged: (value) {
                        dialogSetState(() {
                          reminderEnabled = value;
                        });
                      },
                    ),
                    if (reminderEnabled) ...[
                      ListTile(
                        title: const Text('Hatırlatma saati'),
                        subtitle: Text(reminderTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final newTime = await showTimePicker(
                            context: context,
                            initialTime: reminderTime,
                          );
                          if (newTime != null) {
                            dialogSetState(() {
                              reminderTime = newTime;
                            });
                          }
                        },
                      ),
                      if (frequency == GoalFrequency.weekly)
                        DropdownButtonFormField<int>(
                          initialValue: reminderWeekday,
                          decoration: const InputDecoration(
                            labelText: 'Haftanın günü',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: DateTime.monday,
                              child: Text('Pazartesi'),
                            ),
                            DropdownMenuItem(
                              value: DateTime.tuesday,
                              child: Text('Salı'),
                            ),
                            DropdownMenuItem(
                              value: DateTime.wednesday,
                              child: Text('Çarşamba'),
                            ),
                            DropdownMenuItem(
                              value: DateTime.thursday,
                              child: Text('Perşembe'),
                            ),
                            DropdownMenuItem(
                              value: DateTime.friday,
                              child: Text('Cuma'),
                            ),
                            DropdownMenuItem(
                              value: DateTime.saturday,
                              child: Text('Cumartesi'),
                            ),
                            DropdownMenuItem(
                              value: DateTime.sunday,
                              child: Text('Pazar'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              dialogSetState(() {
                                reminderWeekday = value;
                              });
                            }
                          },
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final goal = Goal(
                      title: title,
                      frequency: frequency,
                      reminderEnabled: reminderEnabled,
                      reminderHour: reminderTime.hour,
                      reminderMinute: reminderTime.minute,
                      reminderWeekday: reminderWeekday,
                    );
                    setState(() {
                      _goals.add(goal);
                    });
                    Navigator.of(context).pop();
                    await _saveAll();
                    if (!mounted) return;
                    if (goal.reminderEnabled) {
                      // Hatırlatma kaydedildi, ancak lokal bildirimler şimdilik devre dışı.
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addPlanItem() {
    final titleController = TextEditingController();
    bool reminderEnabled = false;
    TimeOfDay reminderTime = const TimeOfDay(hour: 20, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Yeni Plan Madde Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Plan başlığı',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Hatırlatma ekle'),
                      value: reminderEnabled,
                      onChanged: (value) =>
                          dialogSetState(() => reminderEnabled = value),
                    ),
                    if (reminderEnabled)
                      ListTile(
                        title: const Text('Hatırlatma saati'),
                        subtitle: Text(reminderTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () async {
                          final newTime = await showTimePicker(
                            context: context,
                            initialTime: reminderTime,
                          );
                          if (newTime != null) {
                            dialogSetState(() {
                              reminderTime = newTime;
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String title = titleController.text.trim();
                    if (title.isEmpty) return;
                    final plan = PlanItem(
                      title: title,
                      reminderEnabled: reminderEnabled,
                      reminderHour: reminderTime.hour,
                      reminderMinute: reminderTime.minute,
                    );
                    setState(() {
                      _plans.add(plan);
                    });
                    Navigator.of(context).pop();
                    await _saveAll();
                    if (!mounted) return;
                    if (plan.reminderEnabled) {
                      // Hatırlatma kaydedildi, ancak lokal bildirimler şimdilik devre dışı.
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addFinanceItem() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;
    String category = 'Diğer';
    const categories = ['Kira', 'Fatura', 'Market', 'Ulaşım', 'Diğer'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('Gelir/Gider Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Tutar',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories
                          .map(
                            (name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          dialogSetState(() {
                            category = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            value: true,
                            groupValue: isExpense,
                            title: const Text('Gider'),
                            secondary: const Icon(
                              Icons.arrow_downward,
                              color: Colors.redAccent,
                            ),
                            onChanged: (value) {
                              dialogSetState(() {
                                isExpense = value ?? true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            value: false,
                            groupValue: isExpense,
                            title: const Text('Gelir'),
                            secondary: const Icon(
                              Icons.arrow_upward,
                              color: Colors.green,
                            ),
                            onChanged: (value) {
                              dialogSetState(() {
                                isExpense = value ?? false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final String title = titleController.text.trim();
                    final double? amount = double.tryParse(
                      amountController.text.replaceAll(',', '.'),
                    );
                    if (title.isEmpty || amount == null || amount <= 0) return;
                    setState(() {
                      _financeItems.add(
                        FinanceItem(
                          title: title,
                          amount: amount,
                          isDebt: isExpense,
                          category: category,
                        ),
                      );
                    });
                    _saveAll();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsTab() {
    final dailyGoals = _goals
        .where((goal) => goal.frequency == GoalFrequency.daily)
        .toList();
    final weeklyGoals = _goals
        .where((goal) => goal.frequency == GoalFrequency.weekly)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Günlük Hedefler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (dailyGoals.isEmpty)
          const Text('Henüz günlük hedef yok. + ile ekleyebilirsiniz.'),
        ...dailyGoals.map(
          (goal) => CheckboxListTile(
            title: Text(goal.title),
            subtitle: goal.reminderEnabled
                ? Text('Hatırlatma: ${goal.reminderTimeLabel()}')
                : null,
            value: goal.done,
            onChanged: (value) {
              setState(() {
                goal.done = value ?? false;
              });
              _saveAll();
            },
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Haftalık Hedefler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (weeklyGoals.isEmpty)
          const Text('Henüz haftalık hedef yok. + ile ekleyebilirsiniz.'),
        ...weeklyGoals.map(
          (goal) => CheckboxListTile(
            title: Text(goal.title),
            subtitle: goal.reminderEnabled
                ? Text(
                    'Hatırlatma: ${goal.reminderTimeLabel()} ${goal.weekdayLabel()}',
                  )
                : null,
            value: goal.done,
            onChanged: (value) {
              setState(() {
                goal.done = value ?? false;
              });
              _saveAll();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlansTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Planlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_plans.isEmpty)
          const Text('Henüz plan yok. + ile ekleyip takip edebilirsiniz.'),
        ..._plans.map(
          (plan) => Dismissible(
            key: ValueKey(plan.id),
            background: Container(
              color: Colors.redAccent,
              child: const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
            onDismissed: (_) {
              setState(() {
                _plans.remove(plan);
              });
              _saveAll();
            },
            child: CheckboxListTile(
              title: Text(plan.title),
              subtitle: plan.reminderEnabled
                  ? Text('Hatırlatma: ${plan.reminderTimeLabel()}')
                  : null,
              value: plan.done,
              onChanged: (value) {
                setState(() {
                  plan.done = value ?? false;
                });
                _saveAll();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceTab() {
    final expenses = _financeItems.where((item) => item.isDebt).toList();
    final incomes = _financeItems.where((item) => !item.isDebt).toList();
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalIncomes = incomes.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final net = totalIncomes - totalExpenses;
    final netColor = net >= 0 ? Colors.green : Colors.redAccent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finans Özeti',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gider',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₺${totalExpenses.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gelir',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₺${totalIncomes.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: netColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Bakiye',
                      style: TextStyle(color: Colors.black54),
                    ),
                    Text(
                      '₺${net.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Giderler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (expenses.isEmpty) const Text('Henüz gider kaydı yok.'),
        ...expenses.map((item) => _buildFinanceTile(item)),
        const SizedBox(height: 24),
        const Text(
          'Gelirler',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (incomes.isEmpty) const Text('Henüz gelir kaydı yok.'),
        ...incomes.map((item) => _buildFinanceTile(item)),
      ],
    );
  }

  Widget _buildFinanceTile(FinanceItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      background: Container(
        color: Colors.redAccent,
        child: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.delete, color: Colors.white),
          ),
        ),
      ),
      onDismissed: (_) {
        setState(() {
          _financeItems.remove(item);
        });
        _saveAll();
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isDebt
              ? Colors.redAccent.withOpacity(0.12)
              : Colors.green.withOpacity(0.12),
          child: Icon(
            item.isDebt ? Icons.arrow_downward : Icons.arrow_upward,
            color: item.isDebt ? Colors.redAccent : Colors.green,
            size: 20,
          ),
        ),
        title: Text(item.title),
        subtitle: Text(
          '${item.category} • ₺${item.amount.toStringAsFixed(2)} • ${item.isDebt ? 'Gider' : 'Gelir'}',
        ),
        trailing: Checkbox(
          value: item.paid,
          onChanged: (value) {
            setState(() {
              item.paid = value ?? false;
            });
            _saveAll();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_buildGoalsTab(), _buildPlansTab(), _buildFinanceTab()];
    final titles = ['Hedefler', 'Plan', 'Finans'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: 'Yapay Zeka',
            onPressed: _showAiAssistant,
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentIndex == 0) {
            _addGoal();
          } else if (_currentIndex == 1) {
            _addPlanItem();
          } else {
            _addFinanceItem();
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.flag), label: 'Hedefler'),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finans',
          ),
        ],
      ),
    );
  }
}

enum GoalFrequency { daily, weekly }

class Goal {
  final String title;
  final GoalFrequency frequency;
  bool done;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int reminderWeekday;
  final int notificationId;

  Goal({
    required this.title,
    required this.frequency,
    this.done = false,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.reminderWeekday = DateTime.monday,
    int? notificationId,
  }) : notificationId =
           notificationId ??
           DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 1;

  String reminderTimeLabel() =>
      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}';

  String weekdayLabel() {
    switch (reminderWeekday) {
      case DateTime.monday:
        return 'Pazartesi';
      case DateTime.tuesday:
        return 'Salı';
      case DateTime.wednesday:
        return 'Çarşamba';
      case DateTime.thursday:
        return 'Perşembe';
      case DateTime.friday:
        return 'Cuma';
      case DateTime.saturday:
        return 'Cumartesi';
      case DateTime.sunday:
        return 'Pazar';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'frequency': frequency.name,
    'done': done,
    'reminderEnabled': reminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'reminderWeekday': reminderWeekday,
    'notificationId': notificationId,
  };

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      title: json['title'] as String,
      frequency: GoalFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
      ),
      done: json['done'] as bool? ?? false,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      reminderWeekday: json['reminderWeekday'] as int? ?? DateTime.monday,
      notificationId: json['notificationId'] as int?,
    );
  }
}

class PlanItem {
  final String id;
  final String title;
  bool done;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
  final int notificationId;

  PlanItem({
    required this.title,
    this.done = false,
    this.reminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    int? notificationId,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       notificationId =
           notificationId ??
           DateTime.now().millisecondsSinceEpoch.remainder(1000000) + 1;

  String reminderTimeLabel() =>
      '${reminderHour.toString().padLeft(2, '0')}:${reminderMinute.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'reminderEnabled': reminderEnabled,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
    'notificationId': notificationId,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      title: json['title'] as String,
      done: json['done'] as bool? ?? false,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderHour: json['reminderHour'] as int? ?? 20,
      reminderMinute: json['reminderMinute'] as int? ?? 0,
      notificationId: json['notificationId'] as int?,
      id: json['id'] as String?,
    );
  }
}

class FinanceItem {
  final String id;
  final String title;
  final double amount;
  final bool isDebt;
  final String category;
  bool paid;

  FinanceItem({
    required this.title,
    required this.amount,
    required this.isDebt,
    this.category = 'Diğer',
    this.paid = false,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'isDebt': isDebt,
    'category': category,
    'paid': paid,
  };

  factory FinanceItem.fromJson(Map<String, dynamic> json) {
    return FinanceItem(
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      isDebt: json['isDebt'] as bool,
      category: json['category'] as String? ?? 'Diğer',
      paid: json['paid'] as bool? ?? false,
      id: json['id'] as String?,
    );
  }
}
