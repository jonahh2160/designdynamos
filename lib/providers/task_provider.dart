import 'package:flutter/foundation.dart';

import 'package:designdynamos/core/models/task_draft.dart';
import 'package:designdynamos/core/models/task_item.dart';
import 'package:designdynamos/core/models/db_subtask.dart';
import 'package:designdynamos/data/services/task_service.dart';
import 'package:designdynamos/data/services/subtask_service.dart';
import 'package:designdynamos/data/services/label_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider(this._service, {SubtaskService? subtasks, LabelService? labels})
    : _subtaskService = subtasks ?? SubtaskService(_service.client),
      _labelService = labels ?? LabelService(_service.client);

  final TaskService _service;
  final SubtaskService _subtaskService;
  final LabelService _labelService;

  bool _loading = false;
  bool _creating = false;
  List<TaskItem> _today = [];
  String? _selectedTaskId;
  final Map<String, List<DbSubtask>> _subtasksByTask = {};
  final Map<String, String?> _notesByTask = {};
  final Map<String, Set<String>> _labelsByTask = {};

  bool get isLoading => _loading;
  bool get isCreating => _creating;
  List<TaskItem> get today => List.unmodifiable(_today);
  List<DbSubtask> subtasksOf(String taskId) =>
      List.unmodifiable(_subtasksByTask[taskId] ?? const []);
  (int done, int total) subtaskProgress(String taskId) {
    final list = _subtasksByTask[taskId] ?? const [];
    final total = list.length;
    final done = list.where((s) => s.isDone).length;
    return (done, total); //tuple of done and total
  }

  String? noteOf(String taskId) => _notesByTask[taskId];
  Set<String> labelsOf(String taskId) => _labelsByTask[taskId] ?? {};

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
          //.any is a method that checks if any element in the collection satisfies the given condition
          !_today.any((t) => t.id == _selectedTaskId)) {
        _selectedTaskId = _today.first.id;
      }
      //Load details for selected task (subtasks, labels, notes)
      final sel = _selectedTaskId;
      if (sel != null) {
        await _loadDetails(sel);
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
    if (id != null) {
      //Fire and forget detail load
      _loadDetails(id);
    }
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
          .toList();
      _selectedTaskId = created.id;

      //Optional: notes
      if (draft.notes != null && draft.notes!.trim().isNotEmpty) {
        await _service.upsertNote(created.id, draft.notes);
        _notesByTask[created.id] = draft.notes;
      }

      //Optional: subtasks
      if (draft.subtasks.isNotEmpty) {
        int hint = 0;
        final items = <DbSubtask>[];
        for (final title in draft.subtasks) {
          hint += 1000;
          final sub = await _subtaskService.create(
            created.id,
            title,
            orderHint: hint,
          );
          items.add(sub);
        }
        _subtasksByTask[created.id] = items;
      }

      //Optional: labels
      if (draft.labels.isNotEmpty) {
        for (final name in draft.labels) {
          await _labelService.toggleTaskLabel(created.id, name, true);
        }
        _labelsByTask[created.id] = {...draft.labels};
      }
    } catch (error) {
      _today = _today
          .where((task) => task.id != tempId)
          .toList();
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

  Future<void> deleteTask(String id) async {
    final idx = _today.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final removed = _today.removeAt(idx);
    notifyListeners();
    try {
      await _service.deleteTask(id);
      _subtasksByTask.remove(id);
      _labelsByTask.remove(id);
      _notesByTask.remove(id);
      if (_selectedTaskId == id) {
        _selectedTaskId = _today.isEmpty ? null : _today.first.id;
      }
    } catch (e) {
      //rollback
      _today.insert(idx, removed);
      notifyListeners();
      print('Failed to delete task: $e');
      rethrow;
    }
  }

  Future<void> _loadDetails(String taskId) async {
    try {
      final subs = await _subtaskService.fetchForTask(taskId);
      _subtasksByTask[taskId] = subs;
      _labelsByTask[taskId] = await _labelService.getTaskLabelNames(taskId);
      _notesByTask[taskId] = await _service.fetchNote(taskId);
    } catch (_) {
      //ignore detail failures for now
    } finally {
      notifyListeners();
    }
  }

  Future<void> addSubtask(String taskId, String title) async {
    final list = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
    final temp = DbSubtask(
      id: 'tmp-${DateTime.now().microsecondsSinceEpoch}',
      taskId: taskId,
      title: title,
      isDone: false,
    );
    list.add(temp);
    _subtasksByTask[taskId] = list;
    notifyListeners();
    try {
      final created = await _subtaskService.create(
        taskId,
        title,
        orderHint: 1000 * list.length,
      );
      final updated = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
      final idx = updated.indexWhere((s) => s.id == temp.id);
      if (idx >= 0) updated[idx] = created;
      _subtasksByTask[taskId] = updated;
      notifyListeners();
    } catch (e) {
      final updated = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
      updated.removeWhere((s) => s.id == temp.id);
      _subtasksByTask[taskId] = updated;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId, bool done) async {
    final list = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
    final idx = list.indexWhere((s) => s.id == subtaskId);
    if (idx < 0) return;
    final before = list[idx];
    list[idx] = before.copyWith(isDone: done);
    _subtasksByTask[taskId] = list;
    notifyListeners();
    try {
      await _subtaskService.toggleDone(subtaskId, done);
    } catch (e) {
      list[idx] = before;
      _subtasksByTask[taskId] = list;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final list = List<DbSubtask>.from(_subtasksByTask[taskId] ?? const []);
    final idx = list.indexWhere((s) => s.id == subtaskId);
    if (idx < 0) return;
    final removed = list.removeAt(idx);
    _subtasksByTask[taskId] = list;
    notifyListeners();
    try {
      await _subtaskService.delete(subtaskId);
    } catch (e) {
      list.insert(idx, removed);
      _subtasksByTask[taskId] = list;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setNote(String taskId, String? content) async {
    _notesByTask[taskId] = content;
    notifyListeners();
    await _service.upsertNote(taskId, content);
  }

  Future<void> toggleLabel(
    String taskId,
    String labelName,
    bool enabled,
  ) async {
    final set = _labelsByTask.putIfAbsent(taskId, () => <String>{});
    if (enabled) {
      set.add(labelName);
    } else {
      set.remove(labelName);
    }
    _labelsByTask[taskId] = set;
    notifyListeners();
    await _labelService.toggleTaskLabel(taskId, labelName, enabled);
  }
}
