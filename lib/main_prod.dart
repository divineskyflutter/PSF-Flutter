import 'app/config/app_flavor.dart';
import 'main.dart';

void main() {
  AppFlavor.setFlavor(Flavor.prod);
  startApp(/*DefaultFirebaseOptionsProd.currentPlatform*/);
}
