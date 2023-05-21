import 'package:objectbox/objectbox.dart';

@Entity()
class AllergensData {
  int id = 0;

  bool? isChecked;

  AllergensData({this.id = 0, required this.isChecked});
}
