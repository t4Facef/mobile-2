class Stop {
  final String address;
  final String complement;
  final String? note;
  final String? time;
  final int? priority;
  final bool feasible;
  final DateTime? estimatedArrival; // calculado pelo RouteService após otimização

  Stop({
    required this.address,
    required this.complement,
    this.note,
    this.time,
    this.priority,
    this.feasible = true,
    this.estimatedArrival,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        address: json['address'] as String? ?? '',
        complement: json['complement'] as String? ?? '',
        note: json['note'] as String?,
        time: json['time'] as String?,
        priority: json['priority'] as int?,
        feasible: json['feasible'] as bool? ?? true,
      );

  Stop withArrival(DateTime arrival) => Stop(
        address: address,
        complement: complement,
        note: note,
        time: time,
        priority: priority,
        feasible: feasible,
        estimatedArrival: arrival,
      );
}
