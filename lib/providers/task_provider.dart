import 'package:flutter/foundation.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/data/services/supabase_service.dart';

class TaskProvider extends ChangeNotifier{
  TaskProvider(this._svc);
  final TaskService _svc;


  bool _loading = false;
  List<TaskItem> _today = [];

  bool get isLoading => _loading;
  List<TaskItem> get today => List.unmodifiable(_today);

  Future<void> refreshToday() async {
    _loading  = true; notifyListeners();

    try {
      _today = await _svc.getTodayTasks();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> addQuickTask(String title) async {
    final tmp = TaskItem(
      id: 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      points: 10,
      isDone: false,
      dueDate: DateTime.now(),
      orderHint: (_today.isEmpty ? 1000 : _today.last.orderHint + 1000),
    
    );

    //optimistic
    _today = [..._today, tmp]; notifyListeners();

    try {
      final newId = await _svc.createTask(tmp);
      _today = _today
          .map((t) => t.id == tmp.id
              ? TaskItem(
                  id: newId,
                  title: t.title,
                  points: t.points,
                  isDone: t.isDone,
                  notes: t.notes,
                  startDate: t.startDate,
                  dueDate: t.dueDate,
                  priority: t.priority,
                  orderHint: t.orderHint,
                )
              : t)
          .toList();
      await refreshToday();
    } catch (e) {
      //rollingback
      _today = _today.where((t) => t.id != tmp.id).toList(); notifyListeners();
      rethrow;
    }
  }

  Future<void> toggle(String id, bool done) async {
    final idx = _today.indexWhere((t) => t.id == id);

    if (idx < 0) return;

    final before = _today[idx];

    _today[idx] = before.copyWith(isDone: done); notifyListeners();

    try {
      await _svc.toggleDone(id, done);

    } catch(e) {
      _today[idx] = before; notifyListeners();
      rethrow;
    }
  }

  

  
}
