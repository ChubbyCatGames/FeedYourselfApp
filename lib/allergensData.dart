import 'package:objectbox/objectbox.dart';

@Entity()
class AllergensData {
  int id = 0;

  int idAllergy;
  String? name;

  bool? isChecked;

  AllergensData(
      {this.id = 0,
      required this.idAllergy,
      required this.name,
      required this.isChecked});
}
