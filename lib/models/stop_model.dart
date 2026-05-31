class Stop {
  final String address;
  final String complement;
  final String? note;
  final String? time;
  final int? priority;   // 1 = urgente, 2 = normal, 3 = pode esperar
  final bool feasible;   // false = IA considerou inviável no contexto atual

  Stop({
    required this.address,
    required this.complement,
    this.note,
    this.time,
    this.priority,
    this.feasible = true,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        address: json['address'] as String? ?? '',
        complement: json['complement'] as String? ?? '',
        note: json['note'] as String?,
        time: json['time'] as String?,
        priority: json['priority'] as int?,
        feasible: json['feasible'] as bool? ?? true,
      );
}
