import 'package:objectbox/objectbox.dart';

@Entity()
class AllergensData {
  int id = 0;

  String? name;

  bool? isChecked;

  AllergensData({this.id = 0, required this.name, required this.isChecked});
}
