import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/services/profile_service.dart';

class ProfileState {
  final double? monthlyIncome;
  final bool isLoading;
  final String? userId;

  const ProfileState({this.monthlyIncome, this.isLoading = false, this.userId});

  ProfileState copyWith({
    Object? monthlyIncome = _sentinel,
    Object? userId = _sentinel,
    bool? isLoading,
  }) {
    return ProfileState(
      monthlyIncome: monthlyIncome == _sentinel
          ? this.monthlyIncome
          : monthlyIncome as double?,
      isLoading: isLoading ?? this.isLoading,
      userId: userId == _sentinel ? this.userId : userId as String?,
    );
  }
}

const Object _sentinel = Object();

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._service)
    : super(const ProfileState(isLoading: true)) {
    _load();
  }

  final ProfileService _service;

  String? _currentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _load([String? uid]) async {
    final resolvedUid = uid ?? _currentUid();
    final income = await _service.getMonthlyIncome(resolvedUid);
    state = ProfileState(
      monthlyIncome: income,
      isLoading: false,
      userId: resolvedUid,
    );
  }

  Future<void> updateMonthlyIncome(double income) async {
    final uid = _currentUid();
    state = state.copyWith(isLoading: true, userId: uid);
    await _service.setMonthlyIncome(uid, income);
    state = state.copyWith(monthlyIncome: income, isLoading: false);
  }

  Future<void> reloadForUser(String? uid) async {
    state = state.copyWith(isLoading: true, userId: uid);
    await _load(uid);
  }
}

final profileServiceProvider = Provider<ProfileService>(
  (ref) => ProfileService(),
);

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
      (ref) => ProfileController(ref.read(profileServiceProvider)),
    );
