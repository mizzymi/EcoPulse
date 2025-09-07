// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Galician (`gl`).
class SGl extends S {
  SGl([String locale = 'gl']) : super(locale);

  @override
  String get appTitle => 'EcoPulse';

  @override
  String get myAccounts => 'As miñas contas';

  @override
  String get createAccount => 'Crear unha conta';

  @override
  String get joinAccountByCode => 'Unirse a unha conta por código';

  @override
  String createdAccount(String name) {
    return 'Conta creada: $name';
  }

  @override
  String get logout => 'Pechar sesión';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get loading => 'Cargando…';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Gardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get settings => 'Axustes';

  @override
  String get myHouseholdsTitle => 'As miñas contas';

  @override
  String get noHouseholdsMessage => 'Aínda non pertences a ningunha cuenta.';

  @override
  String currencyLabel(String code) {
    return 'Moeda: $code';
  }

  @override
  String get unnamedAccount => 'conta';

  @override
  String get errorLoading => 'Erro ao cargar';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Membro';

  @override
  String get joinRequestsTitle => 'Solicitudes pendentes';

  @override
  String get noJoinRequests => 'Non hai solicitudes';

  @override
  String get requestApproved => 'Solicitude aprobada';

  @override
  String get requestRejected => 'Solicitude rexeitada';

  @override
  String get networkError => 'Erro de rede';

  @override
  String errorWithMessage(String message) {
    return 'Erro: $message';
  }

  @override
  String get reject => 'RexeitAR';

  @override
  String get approve => 'Aprobar';

  @override
  String get joinByCodeTitle => 'Unirse a unha conta';

  @override
  String codeFieldLabel(String example) {
    return 'Código (ex. $example)';
  }

  @override
  String get codeExample => '6YQ9-DA8B';

  @override
  String get codeFieldHint => 'XXXX-XXXX';

  @override
  String get joinAction => 'Unirme';

  @override
  String statusLabel(String status) {
    return 'Estado: $status';
  }

  @override
  String get requestSentTitle => 'Solicitude enviada';

  @override
  String get requestSentBody =>
      'Queda pendente de validación. Avisarémoste cando se aprobe.';

  @override
  String get joinedToast => '¡Unido á conta!';

  @override
  String get codeMustBe8 => 'O código debe ter 8 caracteres.';

  @override
  String get errorLoadData => 'Erro ao cargar datos';

  @override
  String get incomeSavedToast => 'Ingreso gardado';

  @override
  String get expenseSavedToast => 'Gasto gardado';

  @override
  String get updatedNameToast => 'Nome actualizado';

  @override
  String get addEntryFab => 'Engadir';

  @override
  String get noMonthsWithMovements => 'Non hai meses con movementos.';

  @override
  String get monthMovementsTitle => 'Movementos do mes';

  @override
  String get deleteFailedToast => 'Non se puido eliminar';

  @override
  String get accountGenericLower => 'conta';

  @override
  String inviteTitleWithName(String name) {
    return 'Invitar a \"$name\"';
  }

  @override
  String get generateInviteTitle => 'Xerar código de invitación';

  @override
  String get pendingRequestsTooltip => 'Solicitudes pendentes';

  @override
  String get expiresHoursLabel => 'Caducidade (horas)';

  @override
  String get expiresHoursHint => 'Ex. 48';

  @override
  String get expiresHoursEmpty => 'Escribe as horas';

  @override
  String get expiresHoursRange => 'Entre 1 e 720 horas';

  @override
  String get maxUsesLabel => 'Usos máximos';

  @override
  String get maxUsesHint => 'Ex. 10';

  @override
  String get maxUsesEmpty => 'Escribe un número';

  @override
  String get maxUsesRange => 'Entre 1 e 999';

  @override
  String get requireApprovalTitle => 'Require aprobación do administrador';

  @override
  String get requireApprovalSubtitle =>
      'Se está activo, as unións quedarán en PENDING';

  @override
  String get generateCodeButton => 'Xerar código';

  @override
  String get codeGeneratedTitle => 'Código xerado';

  @override
  String expiresAtLabel(String date) {
    return 'Caduca: $date';
  }

  @override
  String get copyCodeButton => 'Copiar';

  @override
  String get codeCopiedToast => 'Código copiado';

  @override
  String get doneButton => 'Listo';

  @override
  String get generateAnotherButton => 'Xerar outro código';

  @override
  String get errorGenerateCode => 'Erro ao xerar o código';

  @override
  String get createAccountTitle => 'Crear conta';

  @override
  String get accountNameLabel => 'Nome da conta';

  @override
  String get accountNameHint => 'Ex. Can Crustons';

  @override
  String get nameEmpty => 'Escribe un nome';

  @override
  String get nameMinChars => 'Mínimo 3 caracteres';

  @override
  String get currencyIsoLabel => 'Moeda (ISO-4217)';

  @override
  String get currencyIsoHint => 'EUR, USD, GBP…';

  @override
  String get currencyIsoInvalid => 'Usa un código de 3 letras (ex. EUR)';

  @override
  String get createAccountCta => 'Crear conta';

  @override
  String get accountCreatedToast => 'Conta creada correctamente';

  @override
  String get errorCreateAccount => 'Erro ao crear a conta';

  @override
  String summaryTitle(String month) {
    return 'Resumo $month';
  }

  @override
  String netOfMonth(String amount) {
    return 'Neto do mes: $amount';
  }

  @override
  String openingOfMonth(String amount) {
    return 'Inicio de mes: $amount';
  }

  @override
  String expensesLabel(String amount) {
    return 'Gastos: $amount';
  }

  @override
  String incomeLabel(String amount) {
    return 'Ingresos: $amount';
  }

  @override
  String get noMovementsThisMonth => 'Non hai movementos este mes.';

  @override
  String get incomeGeneric => 'Ingreso';

  @override
  String get expenseGeneric => 'Gasto';

  @override
  String get deleteMovementTitle => 'Eliminar movemento';

  @override
  String get deleteMovementConfirm => 'Seguro que queres eliminalo?';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get deletedToast => 'Eliminado';

  @override
  String get prevMonthTooltip => 'Mes anterior';

  @override
  String get nextMonthTooltip => 'Mes seguinte';

  @override
  String get seeAllMonthsTooltip => 'Ver todos os meses';

  @override
  String get seeCurrentMonthTooltip => 'Ver mes actual';

  @override
  String get allMonthsTitle => 'Todos os meses';

  @override
  String get newMovementTitle => 'Novo movemento';

  @override
  String get editMovementTitle => 'Editar movemento';

  @override
  String get amountLabel => 'Importe';

  @override
  String get amountHint => 'Ex. 25.50';

  @override
  String get categoryOptionalLabel => 'Categoría (opcional)';

  @override
  String get categoryOptionalHint => 'Comida, Transporte, Nómina…';

  @override
  String get noteOptionalLabel => 'Nota (opcional)';

  @override
  String dateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String get changeDate => 'Cambiar';

  @override
  String get saveChanges => 'Gardar cambios';

  @override
  String get invalidAmountToast => 'Importe non válido';

  @override
  String get errorSave => 'Erro ao gardar';

  @override
  String get savingsTooltip => 'Aforro';

  @override
  String get quickSavingsDepositTooltip => 'Ingreso en aforro';

  @override
  String get generateCodeTooltip => 'Xerar código';

  @override
  String get membersTooltip => 'Membros';

  @override
  String get settingsTooltip => 'Configurar';

  @override
  String get movementsChartTooltip => 'Gráfica de movementos';

  @override
  String get refreshTooltip => 'Actualizar';

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
  String get errorLoadingGoals => 'Erro ao cargar obxectivos';

  @override
  String get newSavingsGoalTitle => 'Nova meta de aforro';

  @override
  String get nameLabel => 'Nome';

  @override
  String get targetAmountLabel => 'Obxectivo';

  @override
  String get noDeadlineLabel => 'Sen data límite';

  @override
  String deadlineLabel(String date) {
    return 'Límite: $date';
  }

  @override
  String get chooseDateButton => 'Escoller data';

  @override
  String get createAction => 'Crear';

  @override
  String get createGoalFailed => 'Non se puido crear';

  @override
  String get deleteGoalTitle => 'Eliminar meta';

  @override
  String deleteGoalConfirm(String name) {
    return 'Eliminar «$name» e todos os seus movementos de aforro?';
  }

  @override
  String get deleteGoalForbidden => 'Non tes permisos para eliminar esta meta';

  @override
  String get deleteGoalFailed => 'Non se puido eliminar';

  @override
  String goalDeletedToast(String name) {
    return 'Meta «$name» eliminada';
  }

  @override
  String get goalDeletedSimple => 'Meta eliminada';

  @override
  String savingsTitle(String name) {
    return 'Aforro – $name';
  }

  @override
  String get newGoalFab => 'Nova meta';

  @override
  String get noGoalsEmptyState => 'Sen metas. Crea a primeira co botón +';

  @override
  String get goalGeneric => 'Meta';

  @override
  String progressTriple(String saved, String target, String pct) {
    return '$saved / $target  ($pct%)';
  }

  @override
  String get errorLoadingGoal => 'Erro ao cargar a meta';

  @override
  String get addDepositTitle => 'Engadir depósito';

  @override
  String get registerWithdrawalTitle => 'Rexistrar retirada';

  @override
  String get depositRecordedToast => 'Depósito rexistrado';

  @override
  String get withdrawalRecordedToast => 'Retirada rexistrada';

  @override
  String savingsGoalTitle(String name) {
    return 'Aforro: $name';
  }

  @override
  String get depositAction => 'Depósito';

  @override
  String get withdrawalAction => 'Retirada';

  @override
  String get savingsMovementsTitle => 'Movementos de aforro';

  @override
  String get noSavingsTransactions => 'Aínda non hai transaccións.';

  @override
  String get errorLoadingMembers => 'Non se puideron cargar os membros';

  @override
  String membersTitle(String name) {
    return 'Membros — $name';
  }

  @override
  String get membersTitleSimple => 'Membros';

  @override
  String sinceLabel(String date) {
    return 'Desde: $date';
  }

  @override
  String get noMembers => 'Aínda non hai membros';

  @override
  String get userGeneric => 'Usuario';

  @override
  String get noSavingsGoalsTitle => 'Sen metas de aforro';

  @override
  String get createGoalFirstMsg =>
      'Crea primeiro unha meta para poder rexistrar depósitos.';

  @override
  String get quickSavingsDepositTitle => 'Ingreso en aforro';

  @override
  String get goalLabel => 'Meta';

  @override
  String get selectGoalFirst => 'Selecciona unha meta';

  @override
  String get depositRegisterFailed => 'Non se puido rexistrar o depósito';

  @override
  String get renameHouseholdTitle => 'Cambiar o nome da conta';

  @override
  String get nameHint => 'Ex. Piso Centro';

  @override
  String get nameEmptyToast => 'O nome non pode estar baleiro';

  @override
  String get updateNameFailed => 'Non se puido actualizar o nome';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get registerTitle => 'Crear conta';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Contrasinal';

  @override
  String get loginAction => 'Entrar';

  @override
  String get registerAction => 'Rexistrarme';

  @override
  String get noAccountCta => 'Non tes conta? Crea unha';

  @override
  String get alreadyAccountCta => 'Xa tes conta? Inicia sesión';

  @override
  String get forgotPasswordCta => 'Esqueciches o contrasinal?';

  @override
  String get haveCodeCta => 'Xa teño un código';

  @override
  String get enterYourEmail => 'Introduce o teu email';

  @override
  String get invalidEmail => 'Email non válido';

  @override
  String get minPasswordLen => 'Mínimo 6 caracteres';

  @override
  String get authErrorGeneric => 'Erro de autenticación';

  @override
  String get missingTokenResponse => 'Resposta sen token';

  @override
  String get loginSuccess => 'Sesión iniciada';

  @override
  String get registerSuccess => 'Rexistro completado';

  @override
  String get forgotPasswordTitle => 'Recuperar contrasinal';

  @override
  String get sendResetLink => 'Enviar ligazón/código';

  @override
  String get forgotPasswordFailed => 'Non se puido iniciar a recuperación';

  @override
  String get forgotPasswordAfterMsg =>
      'Se o email existe, enviámosche instrucións para recuperar o contrasinal.';

  @override
  String get resetPasswordTitle => 'Restablecer contrasinal';

  @override
  String get codeTokenLabel => 'Código / Token';

  @override
  String get newPasswordLabel => 'Novo contrasinal';

  @override
  String get changeAction => 'Cambiar';

  @override
  String get resetPasswordFailed => 'Non se puido restablecer';

  @override
  String get passwordUpdatedToast => 'Contrasinal actualizado. Inicia sesión.';
}
