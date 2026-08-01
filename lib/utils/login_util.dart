import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginUtil {
  Future<UserCredential> signInWithGoogle() async {
    //만약 server client id 에러가 나온다면..
    // await GoogleSignIn.instance.initialize(
    //   serverClientId:
    //       'google-services.json 에서 client_id/oauth_client (type=3) 를 가져와서 넣어주면 됨',
    // );

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
