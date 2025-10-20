import 'package:flutter/foundation.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/data/services/task_service.dart';

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
      is_done: false,
      due_date: DateTime.now(),
      order_hint: (_today.isEmpty ? 1000 : _today.last.order_hint + 1000),
    
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
                  is_done: t.is_done,
                  notes: t.notes,
                  start_date: t.start_date,
                  due_date: t.due_date,
                  priority: t.priority,
                  order_hint: t.order_hint,
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
