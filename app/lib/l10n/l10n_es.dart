// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'EcoPulse';

  @override
  String get myAccounts => 'Mis cuentas';

  @override
  String get createAccount => 'Crear una cuenta';

  @override
  String get joinAccountByCode => 'Unirse a una cuenta por código';

  @override
  String createdAccount(String name) {
    return 'Cuenta creada: $name';
  }

  @override
  String get openHousehold => 'Abrir';

  @override
  String get householdCarouselError => 'Error al cargar cuentas';

  @override
  String get householdCarouselEmpty =>
      'Aún no tienes cuentas. Crea o únete a una.';

  @override
  String householdMembersCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get loading => 'Cargando…';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Borrar';

  @override
  String get settings => 'Ajustes';

  @override
  String get myHouseholdsTitle => 'Mis cuentas';

  @override
  String get noHouseholdsMessage => 'Aún no perteneces a ninguna cuenta.';

  @override
  String currencyLabel(String code) {
    return 'Moneda: $code';
  }

  @override
  String get unnamedAccount => 'cuenta';

  @override
  String get errorLoading => 'Error al cargar';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Miembro';

  @override
  String get joinRequestsTitle => 'Solicitudes pendientes';

  @override
  String get noJoinRequests => 'No hay solicitudes';

  @override
  String get requestApproved => 'Solicitud aprobada';

  @override
  String get requestRejected => 'Solicitud rechazada';

  @override
  String get networkError => 'Error de red';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get reject => 'Rechazar';

  @override
  String get approve => 'Aprobar';

  @override
  String get joinByCodeTitle => 'Unirse a una cuenta';

  @override
  String codeFieldLabel(String example) {
    return 'Código (ej. $example)';
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
  String get requestSentTitle => 'Solicitud enviada';

  @override
  String get requestSentBody =>
      'Quedó pendiente de validación. Te avisaremos al aprobarla.';

  @override
  String get joinedToast => '¡Unido a la cuenta!';

  @override
  String get codeMustBe8 => 'El código debe tener 8 caracteres.';

  @override
  String get errorLoadData => 'Error al cargar datos';

  @override
  String get incomeSavedToast => 'Ingreso guardado';

  @override
  String get expenseSavedToast => 'Gasto guardado';

  @override
  String get updatedNameToast => 'Nombre actualizado';

  @override
  String get addEntryFab => 'Añadir';

  @override
  String get noMonthsWithMovements => 'No hay meses con movimientos.';

  @override
  String get monthMovementsTitle => 'Movimientos del mes';

  @override
  String get deleteFailedToast => 'No se pudo borrar la cuenta';

  @override
  String get accountGenericLower => 'cuenta';

  @override
  String inviteTitleWithName(String name) {
    return 'Invitar a \"$name\"';
  }

  @override
  String get generateInviteTitle => 'Generar código de invitación';

  @override
  String get pendingRequestsTooltip => 'Solicitudes pendientes';

  @override
  String get expiresHoursLabel => 'Caducidad (horas)';

  @override
  String get expiresHoursHint => 'Ej. 48';

  @override
  String get expiresHoursEmpty => 'Escribe las horas';

  @override
  String get expiresHoursRange => 'Entre 1 y 720 horas';

  @override
  String get maxUsesLabel => 'Usos máximos';

  @override
  String get maxUsesHint => 'Ej. 10';

  @override
  String get maxUsesEmpty => 'Escribe un número';

  @override
  String get maxUsesRange => 'Entre 1 y 999';

  @override
  String get requireApprovalTitle => 'Requiere aprobación del admin';

  @override
  String get requireApprovalSubtitle =>
      'Si está activo, las uniones quedarán en PENDING';

  @override
  String get generateCodeButton => 'Generar código';

  @override
  String get codeGeneratedTitle => 'Código generado';

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
  String get generateAnotherButton => 'Generar otro código';

  @override
  String get errorGenerateCode => 'Error al generar el código';

  @override
  String get createAccountTitle => 'Crear cuenta';

  @override
  String get accountNameLabel => 'Nombre de la cuenta';

  @override
  String get accountNameHint => 'Ej. Can Crustons';

  @override
  String get nameEmpty => 'Escribe un nombre';

  @override
  String get nameMinChars => 'Mínimo 3 caracteres';

  @override
  String get currencyIsoLabel => 'Moneda (ISO-4217)';

  @override
  String get currencyIsoHint => 'EUR, USD, GBP…';

  @override
  String get currencyIsoInvalid => 'Usa un código de 3 letras (ej. EUR)';

  @override
  String get createAccountCta => 'Crear cuenta';

  @override
  String get accountCreatedToast => 'Cuenta creada correctamente';

  @override
  String get errorCreateAccount => 'Error al crear la cuenta';

  @override
  String summaryTitle(String month) {
    return 'Resumen $month';
  }

  @override
  String netOfMonth(String amount) {
    return 'Neto del mes: $amount';
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
  String get noMovementsThisMonth => 'No hay movimientos en este mes.';

  @override
  String get incomeGeneric => 'Ingreso';

  @override
  String get expenseGeneric => 'Gasto';

  @override
  String get deleteMovementTitle => 'Eliminar movimiento';

  @override
  String get deleteMovementConfirm => '¿Seguro que quieres eliminarlo?';

  @override
  String get deleteAction => 'Eliminar';

  @override
  String get deletedToast => 'Eliminado';

  @override
  String get prevMonthTooltip => 'Mes anterior';

  @override
  String get nextMonthTooltip => 'Mes siguiente';

  @override
  String get seeAllMonthsTooltip => 'Ver todos los meses';

  @override
  String get seeCurrentMonthTooltip => 'Ver mes actual';

  @override
  String get allMonthsTitle => 'Todos los meses';

  @override
  String get newMovementTitle => 'Nuevo movimiento';

  @override
  String get editMovementTitle => 'Editar movimiento';

  @override
  String get amountLabel => 'Importe';

  @override
  String get amountHint => 'Ej. 25.50';

  @override
  String get categoryOptionalLabel => 'Categoría (opcional)';

  @override
  String get categoryOptionalHint => 'Comida, Transporte, Nómina…';

  @override
  String get noteOptionalLabel => 'Nota (opcional)';

  @override
  String dateLabel(String date) {
    return 'Fecha: $date';
  }

  @override
  String get changeDate => 'Cambiar';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get invalidAmountToast => 'Importe inválido';

  @override
  String get errorSave => 'Error al guardar';

  @override
  String get savingsTooltip => 'Ahorro';

  @override
  String get quickSavingsDepositTooltip => 'Ingreso a ahorro';

  @override
  String get generateCodeTooltip => 'Generar código';

  @override
  String get membersTooltip => 'Miembros';

  @override
  String get settingsTooltip => 'Configurar';

  @override
  String get movementsChartTooltip => 'Gráfica de movimientos';

  @override
  String get refreshTooltip => 'Refrescar';

  @override
  String cumulativeTitle(String name) {
    return 'Saldo acumulado $name';
  }

  @override
  String get householdGeneric => 'Casa';

  @override
  String get groupByTooltip => 'Agrupar por';

  @override
  String get groupByDay => 'Día';

  @override
  String get groupByWeek => 'Semana';

  @override
  String get groupByMonth => 'Mes';

  @override
  String get noMovementsToChart => 'No hay movimientos para graficar.';

  @override
  String get legendCumulativeBalance => 'Saldo acumulado';

  @override
  String periodsEntriesLabel(int periods, int entries) {
    return 'Períodos: $periods   •   Entradas: $entries';
  }

  @override
  String balanceLabel(String amount) {
    return 'Saldo: $amount';
  }

  @override
  String get loadMovementsFailed => 'No se pudieron cargar los movimientos';

  @override
  String get unexpectedError => 'Error inesperado';

  @override
  String get errorLoadingGoals => 'Error al cargar objetivos';

  @override
  String get newSavingsGoalTitle => 'Nueva meta de ahorro';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get targetAmountLabel => 'Objetivo';

  @override
  String get noDeadlineLabel => 'Sin fecha límite';

  @override
  String deadlineLabel(String date) {
    return 'Límite: $date';
  }

  @override
  String get chooseDateButton => 'Elegir fecha';

  @override
  String get createAction => 'Crear';

  @override
  String get createGoalFailed => 'No se pudo crear';

  @override
  String get deleteGoalTitle => 'Eliminar meta';

  @override
  String deleteGoalConfirm(String name) {
    return '¿Eliminar \"$name\" y todos sus movimientos de ahorro?';
  }

  @override
  String get deleteGoalForbidden =>
      'No tienes permisos para eliminar esta meta';

  @override
  String get deleteGoalFailed => 'No se pudo eliminar';

  @override
  String goalDeletedToast(String name) {
    return 'Meta \"$name\" eliminada';
  }

  @override
  String get goalDeletedSimple => 'Meta eliminada';

  @override
  String savingsTitle(String name) {
    return 'Ahorro – $name';
  }

  @override
  String get newGoalFab => 'Nueva meta';

  @override
  String get noGoalsEmptyState => 'Sin metas. Crea la primera con el botón +';

  @override
  String get goalGeneric => 'Meta';

  @override
  String progressTriple(String saved, String target, String pct) {
    return '$saved / $target  ($pct%)';
  }

  @override
  String get errorLoadingGoal => 'Error al cargar meta';

  @override
  String get addDepositTitle => 'Añadir depósito';

  @override
  String get registerWithdrawalTitle => 'Registrar retiro';

  @override
  String get depositRecordedToast => 'Depósito registrado';

  @override
  String get withdrawalRecordedToast => 'Retiro registrado';

  @override
  String savingsGoalTitle(String name) {
    return 'Ahorro: $name';
  }

  @override
  String get depositAction => 'Depósito';

  @override
  String get withdrawalAction => 'Retiro';

  @override
  String get savingsMovementsTitle => 'Movimientos de ahorro';

  @override
  String get noSavingsTransactions => 'Aún no hay transacciones.';

  @override
  String get errorLoadingMembers => 'No se pudieron cargar los miembros';

  @override
  String membersTitle(String name) {
    return 'Miembros — $name';
  }

  @override
  String get membersTitleSimple => 'Miembros';

  @override
  String sinceLabel(String date) {
    return 'Desde: $date';
  }

  @override
  String get noMembers => 'Aún no hay miembros';

  @override
  String get userGeneric => 'Usuario';

  @override
  String get noSavingsGoalsTitle => 'Sin metas de ahorro';

  @override
  String get createGoalFirstMsg =>
      'Crea primero una meta para poder registrar depósitos.';

  @override
  String get quickSavingsDepositTitle => 'Ingreso a ahorro';

  @override
  String get goalLabel => 'Meta';

  @override
  String get selectGoalFirst => 'Selecciona una meta';

  @override
  String get depositRegisterFailed => 'No se pudo registrar el depósito';

  @override
  String get renameHouseholdTitle => 'Cambiar nombre de la cuenta';

  @override
  String get nameHint => 'Ej. Piso Centro';

  @override
  String get nameEmptyToast => 'El nombre no puede estar vacío';

  @override
  String get updateNameFailed => 'No se pudo actualizar el nombre';

  @override
  String get loginTitle => 'Iniciar sesión';

  @override
  String get registerTitle => 'Crear cuenta';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get loginAction => 'Entrar';

  @override
  String get registerAction => 'Registrarme';

  @override
  String get noAccountCta => '¿No tienes cuenta? Crea una';

  @override
  String get alreadyAccountCta => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get forgotPasswordCta => '¿Olvidaste tu contraseña?';

  @override
  String get haveCodeCta => 'Ya tengo un código';

  @override
  String get enterYourEmail => 'Introduce tu email';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get minPasswordLen => 'Mínimo 6 caracteres';

  @override
  String get authErrorGeneric => 'Error de autenticación';

  @override
  String get missingTokenResponse => 'Respuesta sin token';

  @override
  String get loginSuccess => 'Sesión iniciada';

  @override
  String get registerSuccess => 'Registro completado';

  @override
  String get forgotPasswordTitle => 'Recuperar contraseña';

  @override
  String get sendResetLink => 'Enviar enlace/código';

  @override
  String get forgotPasswordFailed => 'No se pudo iniciar la recuperación';

  @override
  String get forgotPasswordAfterMsg =>
      'Si el email existe, te enviamos instrucciones para recuperar tu contraseña.';

  @override
  String get resetPasswordTitle => 'Restablecer contraseña';

  @override
  String get codeTokenLabel => 'Código / Token';

  @override
  String get newPasswordLabel => 'Nueva contraseña';

  @override
  String get changeAction => 'Cambiar';

  @override
  String get resetPasswordFailed => 'No se pudo restablecer';

  @override
  String get passwordUpdatedToast => 'Contraseña actualizada. Inicia sesión.';

  @override
  String get createOrJoinTitle => 'Añadir cuenta';

  @override
  String get createOrJoinSubtitle => 'Crea una casa o únete por código';

  @override
  String get openCta => 'Abrir';

  @override
  String get deleteHouseholdTitle => 'Borrar cuenta';

  @override
  String get deleteHouseholdBody =>
      '¿Seguro que quieres borrar esta cuenta y todos sus datos? Esta acción no se puede deshacer.';

  @override
  String get deleteHouseholdTooltip => 'Borrar cuenta';

  @override
  String get deletedOkToast => 'Cuenta borrada';
}
