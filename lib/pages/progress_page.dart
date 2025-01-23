import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/user_provider.dart';
import '../utils/storage_helper.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  ProgressPageState createState() => ProgressPageState();
}

class ProgressPageState extends State<ProgressPage>
    with WidgetsBindingObserver {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final StorageHelper _storage = StorageHelper();
  Map<String, dynamic> _stats = {'completed': 0, 'pending': 0};
  List<Map<String, dynamic>> _recentTodos = [];
  List<int> _weeklyStats = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusedDay = DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  // 暴露给外部的刷新方法
  void refresh() {
    _loadData();
  }

  Future<void> _loadData() async {
    final userId =
        Provider.of<UserProvider>(context, listen: false).user?['id'];
    if (userId == null) return;

    try {
      final stats = await _storage.getTodoStats(userId);
      final todos = await _storage.getTodos(userId);

      // 计算每周统计数据
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      List<int> weeklyStats = List.filled(7, 0);

      for (var todo in todos) {
        final createdAt = DateTime.parse(todo['created_at']);
        if (createdAt.isAfter(startOfWeek)) {
          final dayIndex = createdAt.weekday - 1;
          weeklyStats[dayIndex]++;
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentTodos = todos.take(3).toList();
          _weeklyStats = weeklyStats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载数据失败，请重试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目进度'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TableCalendar(
                firstDay:
                    DateTime(DateTime.now().year, DateTime.now().month - 3, 1),
                lastDay:
                    DateTime(DateTime.now().year, DateTime.now().month + 3, 0),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '任务完成情况',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: _stats['completed']!.toDouble(),
                        title: '已完成',
                        color: Colors.green,
                        radius: 100,
                      ),
                      PieChartSectionData(
                        value: _stats['pending']!.toDouble(),
                        title: '待完成',
                        color: Colors.orange,
                        radius: 100,
                      ),
                    ],
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '每周任务统计',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _weeklyStats
                            .reduce((curr, next) => curr > next ? curr : next)
                            .toDouble() +
                        5,
                    barGroups: List.generate(7, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                              toY: _weeklyStats[index].toDouble(),
                              color: Colors.blue),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const titles = ['一', '二', '三', '四', '五', '六', '日'];
                            return Text(titles[value.toInt()]);
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '最近任务',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              RecentTasksList(todos: _recentTodos),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentTasksList extends StatelessWidget {
  final List<Map<String, dynamic>> todos;

  const RecentTasksList({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return const Center(
        child: Text('暂无任务'),
      );
    }

    return Column(
      children: todos.map((todo) {
        final progress = todo['completed'] == 1 ? 1.0 : 0.0;
        final createdAt = DateTime.parse(todo['created_at']);
        final formattedDate = DateFormat('MM-dd HH:mm').format(createdAt);
        return _buildTaskItem(todo['title'], formattedDate, progress);
      }).toList(),
    );
  }

  Widget _buildTaskItem(String title, String deadline, double progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  deadline,
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
            ),
          ],
        ),
      ),
    );
  }
}
