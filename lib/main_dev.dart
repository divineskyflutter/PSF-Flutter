
import 'app/config/app_flavor.dart';
import 'main.dart';

void main() {
  AppFlavor.flavor = Flavor.dev;
  startApp(/*DefaultFirebaseOptionsDev.currentPlatform*/);
}
