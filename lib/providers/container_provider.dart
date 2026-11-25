import 'package:flutter/foundation.dart';
import '../database/container_dao.dart';
import '../models/container.dart';

class ContainerProvider with ChangeNotifier {
  final ContainerDao _dao = ContainerDao();
  List<WaterContainer> _containers = [];
  bool _loading = true;

  List<WaterContainer> get containers => _containers;
  bool get loading => _loading;
  WaterContainer? get primary =>
      _containers.isNotEmpty ? _containers.first : null;

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _containers = await _dao.getAll();
    if (_containers.isEmpty) {
      await _dao.insert(
          WaterContainer(name: 'Glass', volumeMl: 250, icon: 'local_drink'));
      await _dao.insert(
          WaterContainer(name: 'Mug', volumeMl: 350, icon: 'coffee'));
      await _dao.insert(
          WaterContainer(name: 'Bottle', volumeMl: 500, icon: 'water_drop'));
      _containers = await _dao.getAll();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add(WaterContainer c) async {
    await _dao.insert(c);
    _containers = await _dao.getAll();
    notifyListeners();
  }

  Future<void> update(WaterContainer c) async {
    await _dao.update(c);
    _containers = await _dao.getAll();
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _dao.delete(id);
    _containers = await _dao.getAll();
    notifyListeners();
  }
}
