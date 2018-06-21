
import 'package:meta/meta.dart';

class Drink {
  int id;
  String name;
  int volume;
  double strength;
  double unit;
  int consumptionDate;
  String remark;



  Drink({
    this.id,
    @required this.name,
    @required this.volume,
    @required this.strength,
    @required this.unit,
    @required this.consumptionDate,
    this.remark
});

  @override
  String toString() {
    return "Drink(name: ${name}, volume: ${volume},"
        " strength: ${strength}, unit: ${unit}, "
        " consumptionDate: ${new DateTime.fromMillisecondsSinceEpoch(consumptionDate)}"
        " remark: ${remark})";
  }
}