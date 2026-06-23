import 'package:flutter_riverpod/flutter_riverpod.dart';

// Contador que se incrementa cada vez que llega un cambio
// Los providers que dependen de esto se refrescan automáticamente
final realtimeVersionProvider = StateProvider<int>((ref) => 0);

void notificarCambio(ProviderContainer container) {
  final current =
      container.read(realtimeVersionProvider);
  container
      .read(realtimeVersionProvider.notifier)
      .state = current + 1;
}

