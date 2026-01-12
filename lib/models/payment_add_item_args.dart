import 'package:rt_app_apk/models/tagihan_item.dart';

class PaymentAddItemArgs {
  final List<TagihanItem> tagihanItems;
  final String tagihanName;

  PaymentAddItemArgs({
    required this.tagihanItems,
    required this.tagihanName,
  });
}
