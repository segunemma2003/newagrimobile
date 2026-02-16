import 'package:nylo_framework/nylo_framework.dart';

/* Login Form
|--------------------------------------------------------------------------
| Usage: Learn with Agrisiti/6.x/forms#how-it-works
| Casts: Learn with Agrisiti/6.x/forms#form-casts
| Validation Rules: Learn with Agrisiti/6.x/validation#validation-rules
|-------------------------------------------------------------------------- */

class LoginForm extends NyFormData {
  LoginForm({String? name}) : super(name ?? "login");

  @override
  fields() => [
        Field.email("Email",
            autofocus: true,
            validate: FormValidator.rule("email"),
            style: "compact"),
        Field.password("Password",
            validate: FormValidator.password(strength: 1), style: "compact"),
      ];
}
