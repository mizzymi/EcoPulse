// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class SCa extends S {
  SCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'EcoPulse';

  @override
  String get myAccounts => 'Els meus comptes';

  @override
  String get createAccount => 'Crear un compte';

  @override
  String get joinAccountByCode => 'Unir-se a un compte amb codi';

  @override
  String createdAccount(String name) {
    return 'Compte creat: $name';
  }

  @override
  String get logout => 'Tanca sessió';

  @override
  String get login => 'Log in';

  @override
  String get loading => 'Carregant…';

  @override
  String get cancel => 'Cancel·lar';

  @override
  String get save => 'Desar';

  @override
  String get delete => 'Eliminar';

  @override
  String get settings => 'Ajustos';

  @override
  String get myHouseholdsTitle => 'Els meus comptes';

  @override
  String get noHouseholdsMessage => 'Encara no pertanys a cap compte.';

  @override
  String currencyLabel(String code) {
    return 'Moneda: $code';
  }

  @override
  String get unnamedAccount => 'compte';

  @override
  String get errorLoading => 'Error en carregar';

  @override
  String get roleOwner => 'Propietari';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Membre';

  @override
  String get joinRequestsTitle => 'Sol·licituds pendents';

  @override
  String get noJoinRequests => 'No hi ha sol·licituds';

  @override
  String get requestApproved => 'Sol·licitud aprovada';

  @override
  String get requestRejected => 'Sol·licitud rebutjada';

  @override
  String get networkError => 'Error de xarxa';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get reject => 'Rebutjar';

  @override
  String get approve => 'Aprovar';

  @override
  String get joinByCodeTitle => 'Unir-se a un compte';

  @override
  String codeFieldLabel(String example) {
    return 'Codi (ex. $example)';
  }

  @override
  String get codeExample => '6YQ9-DA8B';

  @override
  String get codeFieldHint => 'XXXX-XXXX';

  @override
  String get joinAction => 'Unir-me';

  @override
  String statusLabel(String status) {
    return 'Estat: $status';
  }

  @override
  String get requestSentTitle => 'Sol·licitud enviada';

  @override
  String get requestSentBody =>
      'Ha quedat pendent de validació. T\'avisarem quan s\'aprovi.';

  @override
  String get joinedToast => 'Unit al compte!';

  @override
  String get codeMustBe8 => 'El codi ha de tenir 8 caràcters.';

  @override
  String get errorLoadData => 'Error en carregar dades';

  @override
  String get incomeSavedToast => 'Ingrés desat';

  @override
  String get expenseSavedToast => 'Despesa desada';

  @override
  String get updatedNameToast => 'Nom actualitzat';

  @override
  String get addEntryFab => 'Afegir';

  @override
  String get noMonthsWithMovements => 'No hi ha mesos amb moviments.';

  @override
  String get monthMovementsTitle => 'Moviments del mes';

  @override
  String get deleteFailedToast => 'No s\'ha pogut eliminar';

  @override
  String get accountGenericLower => 'compte';

  @override
  String inviteTitleWithName(String name) {
    return 'Convidar a \"$name\"';
  }

  @override
  String get generateInviteTitle => 'Generar codi d\'invitació';

  @override
  String get pendingRequestsTooltip => 'Sol·licituds pendents';

  @override
  String get expiresHoursLabel => 'Caducitat (hores)';

  @override
  String get expiresHoursHint => 'Ex. 48';

  @override
  String get expiresHoursEmpty => 'Escriu les hores';

  @override
  String get expiresHoursRange => 'Entre 1 i 720 hores';

  @override
  String get maxUsesLabel => 'Usos màxims';

  @override
  String get maxUsesHint => 'Ex. 10';

  @override
  String get maxUsesEmpty => 'Escriu un número';

  @override
  String get maxUsesRange => 'Entre 1 i 999';

  @override
  String get requireApprovalTitle => 'Requereix aprovació de l\'administrador';

  @override
  String get requireApprovalSubtitle =>
      'Si està actiu, les unions quedaran en PENDING';

  @override
  String get generateCodeButton => 'Generar codi';

  @override
  String get codeGeneratedTitle => 'Codi generat';

  @override
  String expiresAtLabel(String date) {
    return 'Caduca: $date';
  }

  @override
  String get copyCodeButton => 'Copiar';

  @override
  String get codeCopiedToast => 'Codi copiat';

  @override
  String get doneButton => 'Fet';

  @override
  String get generateAnotherButton => 'Generar un altre codi';

  @override
  String get errorGenerateCode => 'Error en generar el codi';

  @override
  String get createAccountTitle => 'Crear compte';

  @override
  String get accountNameLabel => 'Nom del compte';

  @override
  String get accountNameHint => 'Ex. Can Crustons';

  @override
  String get nameEmpty => 'Escriu un nom';

  @override
  String get nameMinChars => 'Mínim 3 caràcters';

  @override
  String get currencyIsoLabel => 'Moneda (ISO-4217)';

  @override
  String get currencyIsoHint => 'EUR, USD, GBP…';

  @override
  String get currencyIsoInvalid => 'Fes servir un codi de 3 lletres (ex. EUR)';

  @override
  String get createAccountCta => 'Crear compte';

  @override
  String get accountCreatedToast => 'Compte creat correctament';

  @override
  String get errorCreateAccount => 'Error en crear el compte';

  @override
  String summaryTitle(String month) {
    return 'Resum $month';
  }

  @override
  String netOfMonth(String amount) {
    return 'Nete del mes: $amount';
  }

  @override
  String openingOfMonth(String amount) {
    return 'Inici de mes: $amount';
  }

  @override
  String expensesLabel(String amount) {
    return 'Despeses: $amount';
  }

  @override
  String incomeLabel(String amount) {
    return 'Ingressos: $amount';
  }

  @override
  String get noMovementsThisMonth => 'No hi ha moviments aquest mes.';

  @override
  String get incomeGeneric => 'Ingrés';

  @override
  String get expenseGeneric => 'Despesa';

  @override
  String get deleteMovementTitle => 'Eliminar moviment';

  @override
  String get deleteMovementConfirm => 'Segur que vols eliminar-lo?';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get deletedToast => 'Eliminat';

  @override
  String get prevMonthTooltip => 'Mes anterior';

  @override
  String get nextMonthTooltip => 'Mes següent';

  @override
  String get seeAllMonthsTooltip => 'Veure tots els mesos';

  @override
  String get seeCurrentMonthTooltip => 'Veure mes actual';

  @override
  String get allMonthsTitle => 'Tots els mesos';

  @override
  String get newMovementTitle => 'Nou moviment';

  @override
  String get editMovementTitle => 'Editar moviment';

  @override
  String get amountLabel => 'Import';

  @override
  String get amountHint => 'Ex. 25.50';

  @override
  String get categoryOptionalLabel => 'Categoria (opcional)';

  @override
  String get categoryOptionalHint => 'Menjar, Transport, Nòmina…';

  @override
  String get noteOptionalLabel => 'Nota (opcional)';

  @override
  String dateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String get changeDate => 'Canviar';

  @override
  String get saveChanges => 'Desar canvis';

  @override
  String get invalidAmountToast => 'Import no vàlid';

  @override
  String get errorSave => 'Error en desar';

  @override
  String get savingsTooltip => 'Estalvi';

  @override
  String get quickSavingsDepositTooltip => 'Ingrés a l\'estalvi';

  @override
  String get generateCodeTooltip => 'Generar codi';

  @override
  String get membersTooltip => 'Membres';

  @override
  String get settingsTooltip => 'Configurar';

  @override
  String get movementsChartTooltip => 'Gràfica de moviments';

  @override
  String get refreshTooltip => 'Actualitzar';

  @override
  String cumulativeTitle(String name) {
    return 'Saldo acumulat $name';
  }

  @override
  String get householdGeneric => 'Casa';

  @override
  String get groupByTooltip => 'Agrupar per';

  @override
  String get groupByDay => 'Dia';

  @override
  String get groupByWeek => 'Setmana';

  @override
  String get groupByMonth => 'Mes';

  @override
  String get noMovementsToChart => 'No hi ha moviments per representar.';

  @override
  String get legendCumulativeBalance => 'Saldo acumulat';

  @override
  String periodsEntriesLabel(int periods, int entries) {
    return 'Períodes: $periods   •   Entrades: $entries';
  }

  @override
  String balanceLabel(String amount) {
    return 'Saldo: $amount';
  }

  @override
  String get loadMovementsFailed => 'No s\'han pogut carregar els moviments';

  @override
  String get unexpectedError => 'Error inesperat';

  @override
  String get errorLoadingGoals => 'Error en carregar objectius';

  @override
  String get newSavingsGoalTitle => 'Nova meta d\'estalvi';

  @override
  String get nameLabel => 'Nom';

  @override
  String get targetAmountLabel => 'Objectiu';

  @override
  String get noDeadlineLabel => 'Sense data límit';

  @override
  String deadlineLabel(String date) {
    return 'Límit: $date';
  }

  @override
  String get chooseDateButton => 'Triar data';

  @override
  String get createAction => 'Crear';

  @override
  String get createGoalFailed => 'No s\'ha pogut crear';

  @override
  String get deleteGoalTitle => 'Eliminar meta';

  @override
  String deleteGoalConfirm(String name) {
    return 'Eliminar «$name» i tots els seus moviments d\'estalvi?';
  }

  @override
  String get deleteGoalForbidden =>
      'No tens permisos per eliminar aquesta meta';

  @override
  String get deleteGoalFailed => 'No s\'ha pogut eliminar';

  @override
  String goalDeletedToast(String name) {
    return 'Meta «$name» eliminada';
  }

  @override
  String get goalDeletedSimple => 'Meta eliminada';

  @override
  String savingsTitle(String name) {
    return 'Estalvi – $name';
  }

  @override
  String get newGoalFab => 'Nova meta';

  @override
  String get noGoalsEmptyState => 'Sense metes. Crea la primera amb el botó +';

  @override
  String get goalGeneric => 'Meta';

  @override
  String progressTriple(String saved, String target, String pct) {
    return '$saved / $target  ($pct%)';
  }

  @override
  String get errorLoadingGoal => 'Error en carregar la meta';

  @override
  String get addDepositTitle => 'Afegir dipòsit';

  @override
  String get registerWithdrawalTitle => 'Registrar retirada';

  @override
  String get depositRecordedToast => 'Dipòsit registrat';

  @override
  String get withdrawalRecordedToast => 'Retirada registrada';

  @override
  String savingsGoalTitle(String name) {
    return 'Estalvi: $name';
  }

  @override
  String get depositAction => 'Dipòsit';

  @override
  String get withdrawalAction => 'Retirada';

  @override
  String get savingsMovementsTitle => 'Moviments d\'estalvi';

  @override
  String get noSavingsTransactions => 'Encara no hi ha transaccions.';

  @override
  String get errorLoadingMembers => 'No s\'han pogut carregar els membres';

  @override
  String membersTitle(String name) {
    return 'Membres — $name';
  }

  @override
  String get membersTitleSimple => 'Membres';

  @override
  String sinceLabel(String date) {
    return 'Des de: $date';
  }

  @override
  String get noMembers => 'Encara no hi ha membres';

  @override
  String get userGeneric => 'Usuari';

  @override
  String get noSavingsGoalsTitle => 'Sense metes d\'estalvi';

  @override
  String get createGoalFirstMsg =>
      'Crea primer una meta per poder registrar dipòsits.';

  @override
  String get quickSavingsDepositTitle => 'Ingrés a l\'estalvi';

  @override
  String get goalLabel => 'Meta';

  @override
  String get selectGoalFirst => 'Selecciona una meta';

  @override
  String get depositRegisterFailed => 'No s\'ha pogut registrar el dipòsit';

  @override
  String get renameHouseholdTitle => 'Canviar el nom del compte';

  @override
  String get nameHint => 'Ex. Pis Centre';

  @override
  String get nameEmptyToast => 'El nom no pot estar buit';

  @override
  String get updateNameFailed => 'No s\'ha pogut actualitzar el nom';

  @override
  String get loginTitle => 'Inicia sessió';

  @override
  String get registerTitle => 'Crear compte';

  @override
  String get emailLabel => 'Correu';

  @override
  String get passwordLabel => 'Contrasenya';

  @override
  String get loginAction => 'Entrar';

  @override
  String get registerAction => 'Registrar-me';

  @override
  String get noAccountCta => 'No tens compte? Crea\'n un';

  @override
  String get alreadyAccountCta => 'Ja tens compte? Inicia sessió';

  @override
  String get forgotPasswordCta => 'Has oblidat la contrasenya?';

  @override
  String get haveCodeCta => 'Ja tinc un codi';

  @override
  String get enterYourEmail => 'Introdueix el teu correu';

  @override
  String get invalidEmail => 'Correu no vàlid';

  @override
  String get minPasswordLen => 'Mínim 6 caràcters';

  @override
  String get authErrorGeneric => 'Error d\'autenticació';

  @override
  String get missingTokenResponse => 'Resposta sense testimoni';

  @override
  String get loginSuccess => 'Sessió iniciada';

  @override
  String get registerSuccess => 'Registre completat';

  @override
  String get forgotPasswordTitle => 'Recuperar contrasenya';

  @override
  String get sendResetLink => 'Enviar enllaç/codi';

  @override
  String get forgotPasswordFailed => 'No s\'ha pogut iniciar la recuperació';

  @override
  String get forgotPasswordAfterMsg =>
      'Si el correu existeix, t\'hem enviat instruccions per recuperar la contrasenya.';

  @override
  String get resetPasswordTitle => 'Restablir contrasenya';

  @override
  String get codeTokenLabel => 'Codi / Testimoni';

  @override
  String get newPasswordLabel => 'Nova contrasenya';

  @override
  String get changeAction => 'Canviar';

  @override
  String get resetPasswordFailed => 'No s\'ha pogut restablir';

  @override
  String get passwordUpdatedToast => 'Contrasenya actualitzada. Inicia sessió.';
}
