import 'package:flutter/foundation.dart';

import 'package:designdynamos/core/models/goal.dart';
import 'package:designdynamos/core/models/goal_step.dart';
import 'package:designdynamos/core/models/goal_draft.dart';
import 'package:designdynamos/data/services/goal_service.dart';
import 'package:designdynamos/data/services/goal_step_task_service.dart';

class GoalProvider extends ChangeNotifier {
  GoalProvider(this._goalService, this._goalStepTaskService);

  final GoalService _goalService;
  final GoalStepTaskService _goalStepTaskService;

  bool _loading = false;
  List<Goal> _goals = const [];
  String? _selectedGoalId;

  bool get isLoading => _loading;
  List<Goal> get goals => _goals;
  Goal? get selectedGoal {
    if (_goals.isEmpty) return null;
    if (_selectedGoalId == null) return null;
    try {
      return _goals.firstWhere((goal) => goal.id == _selectedGoalId);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final fetched = await _goalService.fetchGoals();
      _goals = fetched;
      if (_goals.isNotEmpty) {
        _selectedGoalId ??= _goals.first.id;
      } else {
        _selectedGoalId = null;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectGoal(String? goalId) {
    if (_selectedGoalId == goalId) return;
    _selectedGoalId = goalId;
    notifyListeners();
  }

  Future<void> createGoal(GoalDraft draft) async {
    final created = await _goalService.createGoal(draft);
    _goals = [..._goals, created]..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    _selectedGoalId = created.id;
    notifyListeners();
  }

  Future<void> assignTaskToStep(Goal goal, GoalStep step, String taskId) async {
    final link = await _goalStepTaskService.assign(step.id, taskId);
    _updateStep(
      goalId: goal.id,
      stepId: step.id,
      updater: (current) => current.copyWith(
        taskLinks: [
          ...current.taskLinks.where((e) => e.taskId != taskId),
          link,
        ],
      ),
    );
  }

  Future<void> removeTaskFromStep(
    Goal goal,
    GoalStep step,
    String taskId,
  ) async {
    await _goalStepTaskService.remove(step.id, taskId);
    _updateStep(
      goalId: goal.id,
      stepId: step.id,
      updater: (current) => current.copyWith(
        taskLinks: current.taskLinks
            .where((link) => link.taskId != taskId)
            .toList(),
      ),
    );
  }

  Future<void> updateGoalMeta(
    Goal goal, {
    DateTime? startAt,
    DateTime? dueAt,
    int? priority,
  }) async {
    final updated = await _goalService.updateGoal(
      goal.id,
      startAt: startAt,
      dueAt: dueAt,
      priority: priority,
    );
    _goals = _goals.map((g) => g.id == goal.id ? updated : g).toList();
    notifyListeners();
  }

  Future<void> deleteGoal(Goal goal) async {
    await _goalService.deleteGoal(goal.id);
    _goals = _goals.where((g) => g.id != goal.id).toList();
    if (_selectedGoalId == goal.id) {
      _selectedGoalId = _goals.isNotEmpty ? _goals.first.id : null;
    }
    notifyListeners();
  }

  void _updateStep({
    required String goalId,
    required String stepId,
    required GoalStep Function(GoalStep current) updater,
  }) {
    _goals = _goals.map((goal) {
      if (goal.id != goalId) return goal;
      final updatedSteps = goal.steps.map((step) {
        if (step.id != stepId) return step;
        return updater(step);
      }).toList();
      return goal.copyWith(steps: updatedSteps);
    }).toList();
    notifyListeners();
  }
}
