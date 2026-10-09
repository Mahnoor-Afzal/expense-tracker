import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 2)
class Debt extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  bool isIOweThem; // True: Maine unka dena hai, False: Unho ne mera dena hai

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isSettled;

  Debt({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isIOweThem,
    required this.date,
    this.isSettled = false,
  });
}
