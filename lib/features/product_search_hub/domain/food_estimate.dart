import 'dart:typed_data';

/// A photo of the food, sent with a food estimate request. `address` is
/// its Storage address when it is stored already, as for a stored AI food.
typedef FoodEstimatePhoto = ({
  String mimeType,
  Uint8List bytes,
  String? address,
});
