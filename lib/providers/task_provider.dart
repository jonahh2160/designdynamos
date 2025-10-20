import 'package:flutter/foundation.dart';

import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/data/services/task_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._service);

  final TaskService _service;

  bool _loading = false;
  bool _creating = false;
  List<TaskItem> _today = [];
  String? _selectedTaskId;

  bool get isLoading => _loading;
  bool get isCreating => _creating;
  List<TaskItem> get today => List.unmodifiable(_today);

  TaskItem? get selectedTask {
    if (_selectedTaskId == null) return null;
    for (final task in _today) {
      if (task.id == _selectedTaskId) return task;
    }
    return null;
  }

  Future<void> refreshToday() async {
    _loading = true;
    notifyListeners();

    try {
      final tasks = await _service.getTodayTasks();
      _today = tasks;

      if (_today.isEmpty) {
        _selectedTaskId = null;
      } else if (_selectedTaskId == null ||
          !_today.any((t) => t.id == _selectedTaskId)) {
        _selectedTaskId = _today.first.id;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectTask(String? id) {
    if (_selectedTaskId == id) return;
    _selectedTaskId = id;
    notifyListeners();
  }

  Future<void> createTask(TaskDraft draft) async {
    if (_creating) return;

    final nextOrderHint = _today.isEmpty
        ? 1000
        : (_today.last.orderHint + 1000);
    final tempId = 'tmp-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now();
    final tempTask = draft.toTask(
      id: tempId,
      orderHint: nextOrderHint,
      startDate: now,
    );

    _creating = true;
    _today = [..._today, tempTask];
    _selectedTaskId = tempTask.id;
    notifyListeners();

    try {
      final created = await _service.createTask(tempTask);
      _today = _today
          .map((task) => task.id == tempId ? created : task)
          .toList(growable: false);
      _selectedTaskId = created.id;
    } catch (error) {
      _today = _today
          .where((task) => task.id != tempId)
          .toList(growable: false);
      rethrow;
    } finally {
      _creating = false;
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id, bool done) async {
    final index = _today.indexWhere((task) => task.id == id);
    if (index < 0) return;

    final before = _today[index];
    final updated = before.copyWith(
      isDone: done,
      completedAt: done ? DateTime.now() : null,
    );
    _today[index] = updated;
    notifyListeners();

    try {
      await _service.toggleDone(id, done);
    } catch (error) {
      _today[index] = before;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(
    String id, {
    DateTime? dueDate,
    bool clearDueDate = false,
    int? priority,
    String? iconName,
  }) async {
    final index = _today.indexWhere((task) => task.id == id);
    if (index < 0) return;

    final before = _today[index];
    var updated = before;

    if (iconName != null) {
      updated = updated.copyWith(iconName: iconName);
    }

    if (priority != null) {
      updated = updated.copyWith(priority: priority);
    }

    if (clearDueDate) {
      updated = updated.copyWith(clearDueDate: true);
    } else if (dueDate != null) {
      updated = updated.copyWith(dueDate: dueDate);
    }

    _today[index] = updated;
    notifyListeners();

    try {
      await _service.updateTask(
        id,
        dueDate: dueDate,
        clearDueDate: clearDueDate,
        priority: priority,
        iconName: iconName,
      );
    } catch (error) {
      _today[index] = before;
      notifyListeners();
      rethrow;
    }
  }
}
