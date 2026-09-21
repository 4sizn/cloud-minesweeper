// Run on a simulator; integration tests must not replace a user's device app.
import 'app_test.dart' as app;
import 'photo_test.dart' as photo;
import 'sky_motion_test.dart' as sky;

void main() {
  photo.main();
  sky.main();
  app.main();
}
