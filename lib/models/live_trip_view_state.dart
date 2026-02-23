import 'live_trip_location.dart';

class LiveTripViewState {
  const LiveTripViewState({
    this.latestLocation,
    this.history = const <LiveTripLocation>[],
    this.isLoading = false,
    this.isReconnecting = false,
    this.errorMessage,
  });

  final LiveTripLocation? latestLocation;
  final List<LiveTripLocation> history;
  final bool isLoading;
  final bool isReconnecting;
  final String? errorMessage;

  LiveTripViewState copyWith({
    LiveTripLocation? latestLocation,
    List<LiveTripLocation>? history,
    bool? isLoading,
    bool? isReconnecting,
    String? errorMessage,
  }) {
    return LiveTripViewState(
      latestLocation: latestLocation ?? this.latestLocation,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
