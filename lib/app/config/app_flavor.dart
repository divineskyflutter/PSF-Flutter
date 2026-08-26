enum Flavor { dev, prod }

class AppFlavor {
  static late Flavor flavor;

  static void setFlavor(Flavor f) {
    flavor = f;
  }

  static bool get isDev => flavor == Flavor.dev;
  static bool get isProd => flavor == Flavor.prod;

  static String get name => flavor.toString().split('.').last;
}
