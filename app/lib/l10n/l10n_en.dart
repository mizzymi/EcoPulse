// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EcoPulse';

  @override
  String get myAccounts => 'My accounts';

  @override
  String get createAccount => 'Create an account';

  @override
  String get joinAccountByCode => 'Join an account by code';

  @override
  String createdAccount(String name) {
    return 'Account created: $name';
  }

  @override
  String get logout => 'Log out';

  @override
  String get login => 'Log in';

  @override
  String get loading => 'Loading…';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get myHouseholdsTitle => 'My accounts';

  @override
  String get noHouseholdsMessage => 'You don\'t belong to any account yet.';

  @override
  String currencyLabel(String code) {
    return 'Currency: $code';
  }

  @override
  String get unnamedAccount => 'account';

  @override
  String get errorLoading => 'Error loading';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get joinRequestsTitle => 'Pending requests';

  @override
  String get noJoinRequests => 'There are no requests';

  @override
  String get requestApproved => 'Request approved';

  @override
  String get requestRejected => 'Request rejected';

  @override
  String get networkError => 'Network error';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String get joinByCodeTitle => 'Join an account';

  @override
  String codeFieldLabel(String example) {
    return 'Code (e.g. $example)';
  }

  @override
  String get codeExample => '6YQ9-DA8B';

  @override
  String get codeFieldHint => 'XXXX-XXXX';

  @override
  String get joinAction => 'Join';

  @override
  String statusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String get requestSentTitle => 'Request sent';

  @override
  String get requestSentBody =>
      'It\'s pending validation. We\'ll notify you when it\'s approved.';

  @override
  String get joinedToast => 'Joined the account!';

  @override
  String get codeMustBe8 => 'The code must have 8 characters';

  @override
  String get errorLoadData => 'Error loading data';

  @override
  String get incomeSavedToast => 'Income saved';

  @override
  String get expenseSavedToast => 'Expense saved';

  @override
  String get updatedNameToast => 'Name updated';

  @override
  String get addEntryFab => 'Add';

  @override
  String get noMonthsWithMovements => 'There are no months with movements.';

  @override
  String get monthMovementsTitle => 'Movements of the month';

  @override
  String get deleteFailedToast => 'Could not delete';

  @override
  String get accountGenericLower => 'account';

  @override
  String inviteTitleWithName(String name) {
    return 'Invite to \"$name\"';
  }

  @override
  String get generateInviteTitle => 'Generate invitation code';

  @override
  String get pendingRequestsTooltip => 'Pending requests';

  @override
  String get expiresHoursLabel => 'Expiration (hours)';

  @override
  String get expiresHoursHint => 'e.g. 48';

  @override
  String get expiresHoursEmpty => 'Enter the number of hours';

  @override
  String get expiresHoursRange => 'Between 1 and 720 hours';

  @override
  String get maxUsesLabel => 'Maximum uses';

  @override
  String get maxUsesHint => 'e.g. 10';

  @override
  String get maxUsesEmpty => 'Enter a number';

  @override
  String get maxUsesRange => 'Between 1 and 999';

  @override
  String get requireApprovalTitle => 'Require admin approval';

  @override
  String get requireApprovalSubtitle =>
      'If enabled, joins will remain in PENDING';

  @override
  String get generateCodeButton => 'Generate code';

  @override
  String get codeGeneratedTitle => 'Code generated';

  @override
  String expiresAtLabel(String date) {
    return 'Expires: $date';
  }

  @override
  String get copyCodeButton => 'Copy';

  @override
  String get codeCopiedToast => 'Code copied';

  @override
  String get doneButton => 'Done';

  @override
  String get generateAnotherButton => 'Generate another code';

  @override
  String get errorGenerateCode => 'Error generating code';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get accountNameLabel => 'Account name';

  @override
  String get accountNameHint => 'e.g. Can Crustons';

  @override
  String get nameEmpty => 'Enter a name';

  @override
  String get nameMinChars => 'Minimum 3 characters';

  @override
  String get currencyIsoLabel => 'Currency (ISO-4217)';

  @override
  String get currencyIsoHint => 'EUR, USD, GBP…';

  @override
  String get currencyIsoInvalid => 'Use a 3-letter code (e.g. EUR)';

  @override
  String get createAccountCta => 'Create account';

  @override
  String get accountCreatedToast => 'Account created successfully';

  @override
  String get errorCreateAccount => 'Error creating the account';

  @override
  String summaryTitle(String month) {
    return 'Summary $month';
  }

  @override
  String netOfMonth(String amount) {
    return 'Net of month: $amount';
  }

  @override
  String openingOfMonth(String amount) {
    return 'Opening: $amount';
  }

  @override
  String expensesLabel(String amount) {
    return 'Expenses: $amount';
  }

  @override
  String incomeLabel(String amount) {
    return 'Income: $amount';
  }

  @override
  String get noMovementsThisMonth => 'There are no movements this month.';

  @override
  String get incomeGeneric => 'Income';

  @override
  String get expenseGeneric => 'Expense';

  @override
  String get deleteMovementTitle => 'Delete movement';

  @override
  String get deleteMovementConfirm => 'Are you sure you want to delete it?';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deletedToast => 'Deleted';

  @override
  String get prevMonthTooltip => 'Previous month';

  @override
  String get nextMonthTooltip => 'Next month';

  @override
  String get seeAllMonthsTooltip => 'See all months';

  @override
  String get seeCurrentMonthTooltip => 'See current month';

  @override
  String get allMonthsTitle => 'All months';

  @override
  String get newMovementTitle => 'New movement';

  @override
  String get editMovementTitle => 'Edit movement';

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountHint => 'e.g. 25.50';

  @override
  String get categoryOptionalLabel => 'Category (optional)';

  @override
  String get categoryOptionalHint => 'Food, Transport, Payroll…';

  @override
  String get noteOptionalLabel => 'Note (optional)';

  @override
  String dateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get changeDate => 'Change';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get invalidAmountToast => 'Invalid amount';

  @override
  String get errorSave => 'Error while saving';

  @override
  String get savingsTooltip => 'Savings';

  @override
  String get quickSavingsDepositTooltip => 'Savings deposit';

  @override
  String get generateCodeTooltip => 'Generate code';

  @override
  String get membersTooltip => 'Members';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get movementsChartTooltip => 'Movements chart';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String cumulativeTitle(String name) {
    return 'Cumulative balance $name';
  }

  @override
  String get householdGeneric => 'Household';

  @override
  String get groupByTooltip => 'Group by';

  @override
  String get groupByDay => 'Day';

  @override
  String get groupByWeek => 'Week';

  @override
  String get groupByMonth => 'Month';

  @override
  String get noMovementsToChart => 'There are no movements to chart.';

  @override
  String get legendCumulativeBalance => 'Cumulative balance';

  @override
  String periodsEntriesLabel(int periods, int entries) {
    return 'Periods: $periods   •   Entries: $entries';
  }

  @override
  String balanceLabel(String amount) {
    return 'Balance: $amount';
  }

  @override
  String get loadMovementsFailed => 'Couldn\'t load movements';

  @override
  String get unexpectedError => 'Unexpected error';

  @override
  String get errorLoadingGoals => 'Error loading goals';

  @override
  String get newSavingsGoalTitle => 'New savings goal';

  @override
  String get nameLabel => 'Name';

  @override
  String get targetAmountLabel => 'Target amount';

  @override
  String get noDeadlineLabel => 'No deadline';

  @override
  String deadlineLabel(String date) {
    return 'Deadline: $date';
  }

  @override
  String get chooseDateButton => 'Choose date';

  @override
  String get createAction => 'Create';

  @override
  String get createGoalFailed => 'Couldn\'t create';

  @override
  String get deleteGoalTitle => 'Delete goal';

  @override
  String deleteGoalConfirm(String name) {
    return 'Delete \"$name\" and all its savings movements?';
  }

  @override
  String get deleteGoalForbidden =>
      'You don\'t have permission to delete this goal';

  @override
  String get deleteGoalFailed => 'Couldn\'t delete';

  @override
  String goalDeletedToast(String name) {
    return 'Goal \"$name\" deleted';
  }

  @override
  String get goalDeletedSimple => 'Goal deleted';

  @override
  String savingsTitle(String name) {
    return 'Savings – $name';
  }

  @override
  String get newGoalFab => 'New goal';

  @override
  String get noGoalsEmptyState =>
      'No goals yet. Create the first one with the + button';

  @override
  String get goalGeneric => 'Goal';

  @override
  String progressTriple(String saved, String target, String pct) {
    return '$saved / $target  ($pct%)';
  }

  @override
  String get errorLoadingGoal => 'Error loading goal';

  @override
  String get addDepositTitle => 'Add deposit';

  @override
  String get registerWithdrawalTitle => 'Register withdrawal';

  @override
  String get depositRecordedToast => 'Deposit recorded';

  @override
  String get withdrawalRecordedToast => 'Withdrawal recorded';

  @override
  String savingsGoalTitle(String name) {
    return 'Savings goal: $name';
  }

  @override
  String get depositAction => 'Deposit';

  @override
  String get withdrawalAction => 'Withdrawal';

  @override
  String get savingsMovementsTitle => 'Savings movements';

  @override
  String get noSavingsTransactions => 'There are no transactions yet.';

  @override
  String get errorLoadingMembers => 'Couldn\'t load members';

  @override
  String membersTitle(String name) {
    return 'Members — $name';
  }

  @override
  String get membersTitleSimple => 'Members';

  @override
  String sinceLabel(String date) {
    return 'Since: $date';
  }

  @override
  String get noMembers => 'No members yet';

  @override
  String get userGeneric => 'User';

  @override
  String get noSavingsGoalsTitle => 'No savings goals';

  @override
  String get createGoalFirstMsg => 'Create a goal first to record deposits.';

  @override
  String get quickSavingsDepositTitle => 'Savings deposit';

  @override
  String get goalLabel => 'Goal';

  @override
  String get selectGoalFirst => 'Select a goal';

  @override
  String get depositRegisterFailed => 'Couldn\'t register the deposit';

  @override
  String get renameHouseholdTitle => 'Rename account';

  @override
  String get nameHint => 'e.g. Downtown flat';

  @override
  String get nameEmptyToast => 'The name cannot be empty';

  @override
  String get updateNameFailed => 'Couldn\'t update the name';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get registerTitle => 'Create account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginAction => 'Sign in';

  @override
  String get registerAction => 'Sign up';

  @override
  String get noAccountCta => 'Don\'t have an account? Create one';

  @override
  String get alreadyAccountCta => 'Already have an account? Sign in';

  @override
  String get forgotPasswordCta => 'Forgot your password?';

  @override
  String get haveCodeCta => 'I already have a code';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get minPasswordLen => 'Minimum 6 characters';

  @override
  String get authErrorGeneric => 'Authentication error';

  @override
  String get missingTokenResponse => 'Response without token';

  @override
  String get loginSuccess => 'Signed in';

  @override
  String get registerSuccess => 'Registration completed';

  @override
  String get forgotPasswordTitle => 'Recover password';

  @override
  String get sendResetLink => 'Send link/code';

  @override
  String get forgotPasswordFailed => 'Couldn\'t start recovery';

  @override
  String get forgotPasswordAfterMsg =>
      'If the email exists, we sent you instructions to recover your password.';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get codeTokenLabel => 'Code / Token';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get changeAction => 'Change';

  @override
  String get resetPasswordFailed => 'Couldn\'t reset';

  @override
  String get passwordUpdatedToast => 'Password updated. Sign in.';
}
