import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/dummy_data.dart';
import '../../infrastructure/providers/repositories.dart';

class ProfileController extends StateNotifier<DummyProfile> {
  ProfileController(this._ref)
    : super(_ref.read(profileRepositoryProvider).getProfile());

  final Ref _ref;

  void updateProfile({required String name, required String bio}) {
    _ref.read(profileRepositoryProvider).updateProfile(name: name, bio: bio);
    state = _ref.read(profileRepositoryProvider).getProfile();
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, DummyProfile>((ref) {
      return ProfileController(ref);
    });
