import 'package:objectbox/objectbox.dart';

@Entity()
class productObject {
  @Id()
  int id = 0;

  String? name;

  @Property(type: PropertyType.date)
  DateTime? date;
}
