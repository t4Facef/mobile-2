class Stop {
  final String address;
  final String complement;
  final String? note;
  final String? time;

  Stop({
    required this.address,
    required this.complement,
    this.note,
    this.time,
  });

  factory Stop.fromJson(Map<String, dynamic> json) => Stop(
        address: json['address'] as String? ?? '',
        complement: json['complement'] as String? ?? '',
        note: json['note'] as String?,
        time: json['time'] as String?,
      );
}
