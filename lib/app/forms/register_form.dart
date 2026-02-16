import 'package:nylo_framework/nylo_framework.dart';

/* Register Form
|--------------------------------------------------------------------------
| Usage: Learn with Agrisiti/6.x/forms#how-it-works
| Casts: Learn with Agrisiti/6.x/forms#form-casts
| Validation Rules: Learn with Agrisiti/6.x/validation#validation-rules
|-------------------------------------------------------------------------- */

class RegisterForm extends NyFormData {
  RegisterForm({String? name}) : super(name ?? "register");

  @override
  fields() => [
        Field.text("Name",
            autofocus: true,
            validate: FormValidator.notEmpty(),
            style: "compact"),
        Field.email("Email", validate: FormValidator.email(), style: "compact"),
        Field.password("Password",
            validate: FormValidator.password(strength: 1), style: "compact"),
      ];
}
