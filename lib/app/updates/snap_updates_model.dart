/*
 * Copyright (C) 2022 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

import 'dart:async';

import 'package:safe_change_notifier/safe_change_notifier.dart';
import 'package:snapd/snapd.dart';
import 'package:software/services/snap_service.dart';

class SnapUpdatesModel extends SafeChangeNotifier {
  SnapUpdatesModel(
    this._snapService,
  );

  final SnapService _snapService;
  StreamSubscription<bool>? _snapChangesSub;

  Future<void> init() async {
    _snapChangesSub = _snapService.snapChangesInserted.listen((_) {
      checkingForUpdates = true;
      if (_snapService.snapChanges.isEmpty) {
        loadSnapsWithUpdate().then((_) => checkingForUpdates = false);
      }
    });
  }

  @override
  Future<void> dispose() async {
    await _snapChangesSub?.cancel();

    super.dispose();
  }

  bool _checkingForUpdates = false;
  bool get checkingForUpdates => _checkingForUpdates;
  set checkingForUpdates(bool value) {
    if (value == _checkingForUpdates) return;
    _checkingForUpdates = value;
    notifyListeners();
  }

  Future<void> checkForUpdates() async {
    checkingForUpdates = true;
    await loadSnapsWithUpdate();
    checkingForUpdates = false;
  }

  Future<List<Snap>> loadSnapsWithUpdate() async =>
      await _snapService.loadSnapsWithUpdate();

  Future<void> refreshAll({
    required String doneMessage,
    required List<Snap> snaps,
  }) async {
    for (var snap in snaps) {
      await _snapService.refresh(
        snap: snap,
        message: doneMessage,
        confinement: snap.confinement,
        channel: snap.channel,
      );
      notifyListeners();
    }
  }
}