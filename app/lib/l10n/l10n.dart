import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_ca.dart';
import 'l10n_en.dart';
import 'l10n_es.dart';
import 'l10n_gl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ca'),
    Locale('en'),
    Locale('es'),
    Locale('gl')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'EcoPulse'**
  String get appTitle;

  /// No description provided for @myAccounts.
  ///
  /// In en, this message translates to:
  /// **'My accounts'**
  String get myAccounts;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @joinAccountByCode.
  ///
  /// In en, this message translates to:
  /// **'Join an account by code'**
  String get joinAccountByCode;

  /// Snackbar message after creating an account
  ///
  /// In en, this message translates to:
  /// **'Account created: {name}'**
  String createdAccount(String name);

  /// No description provided for @openHousehold.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openHousehold;

  /// No description provided for @householdCarouselError.
  ///
  /// In en, this message translates to:
  /// **'Error loading accounts'**
  String get householdCarouselError;

  /// No description provided for @householdCarouselEmpty.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any accounts yet. Create or join one.'**
  String get householdCarouselEmpty;

  /// No description provided for @householdMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {1 member} other {{count} members}}'**
  String householdMembersCount(num count);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @myHouseholdsTitle.
  ///
  /// In en, this message translates to:
  /// **'My accounts'**
  String get myHouseholdsTitle;

  /// No description provided for @noHouseholdsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t belong to any account yet.'**
  String get noHouseholdsMessage;

  /// Subtitle showing the currency code of a household
  ///
  /// In en, this message translates to:
  /// **'Currency: {code}'**
  String currencyLabel(String code);

  /// No description provided for @unnamedAccount.
  ///
  /// In en, this message translates to:
  /// **'account'**
  String get unnamedAccount;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @joinRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get joinRequestsTitle;

  /// No description provided for @noJoinRequests.
  ///
  /// In en, this message translates to:
  /// **'There are no requests'**
  String get noJoinRequests;

  /// No description provided for @requestApproved.
  ///
  /// In en, this message translates to:
  /// **'Request approved'**
  String get requestApproved;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// Generic error with interpolated message
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @joinByCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join an account'**
  String get joinByCodeTitle;

  /// Label for the code input
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. {example})'**
  String codeFieldLabel(String example);

  /// No description provided for @codeExample.
  ///
  /// In en, this message translates to:
  /// **'6YQ9-DA8B'**
  String get codeExample;

  /// No description provided for @codeFieldHint.
  ///
  /// In en, this message translates to:
  /// **'XXXX-XXXX'**
  String get codeFieldHint;

  /// No description provided for @joinAction.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinAction;

  /// Shows the current server status string
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(String status);

  /// No description provided for @requestSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get requestSentTitle;

  /// No description provided for @requestSentBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s pending validation. We\'ll notify you when it\'s approved.'**
  String get requestSentBody;

  /// No description provided for @joinedToast.
  ///
  /// In en, this message translates to:
  /// **'Joined the account!'**
  String get joinedToast;

  /// No description provided for @codeMustBe8.
  ///
  /// In en, this message translates to:
  /// **'The code must have 8 characters'**
  String get codeMustBe8;

  /// No description provided for @errorLoadData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadData;

  /// No description provided for @incomeSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Income saved'**
  String get incomeSavedToast;

  /// No description provided for @expenseSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Expense saved'**
  String get expenseSavedToast;

  /// No description provided for @updatedNameToast.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get updatedNameToast;

  /// No description provided for @addEntryFab.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addEntryFab;

  /// No description provided for @noMonthsWithMovements.
  ///
  /// In en, this message translates to:
  /// **'There are no months with movements.'**
  String get noMonthsWithMovements;

  /// No description provided for @monthMovementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Movements of the month'**
  String get monthMovementsTitle;

  /// No description provided for @deleteFailedToast.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get deleteFailedToast;

  /// No description provided for @accountGenericLower.
  ///
  /// In en, this message translates to:
  /// **'account'**
  String get accountGenericLower;

  /// Title when inviting to a specific household
  ///
  /// In en, this message translates to:
  /// **'Invite to \"{name}\"'**
  String inviteTitleWithName(String name);

  /// No description provided for @generateInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate invitation code'**
  String get generateInviteTitle;

  /// No description provided for @pendingRequestsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequestsTooltip;

  /// No description provided for @expiresHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiration (hours)'**
  String get expiresHoursLabel;

  /// No description provided for @expiresHoursHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 48'**
  String get expiresHoursHint;

  /// No description provided for @expiresHoursEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter the number of hours'**
  String get expiresHoursEmpty;

  /// No description provided for @expiresHoursRange.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 720 hours'**
  String get expiresHoursRange;

  /// No description provided for @maxUsesLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum uses'**
  String get maxUsesLabel;

  /// No description provided for @maxUsesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get maxUsesHint;

  /// No description provided for @maxUsesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get maxUsesEmpty;

  /// No description provided for @maxUsesRange.
  ///
  /// In en, this message translates to:
  /// **'Between 1 and 999'**
  String get maxUsesRange;

  /// No description provided for @requireApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Require admin approval'**
  String get requireApprovalTitle;

  /// No description provided for @requireApprovalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If enabled, joins will remain in PENDING'**
  String get requireApprovalSubtitle;

  /// No description provided for @generateCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get generateCodeButton;

  /// No description provided for @codeGeneratedTitle.
  ///
  /// In en, this message translates to:
  /// **'Code generated'**
  String get codeGeneratedTitle;

  /// Shows the localized expiration date/time
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String expiresAtLabel(String date);

  /// No description provided for @copyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyCodeButton;

  /// No description provided for @codeCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopiedToast;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @generateAnotherButton.
  ///
  /// In en, this message translates to:
  /// **'Generate another code'**
  String get generateAnotherButton;

  /// No description provided for @errorGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Error generating code'**
  String get errorGenerateCode;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountTitle;

  /// No description provided for @accountNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountNameLabel;

  /// No description provided for @accountNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Can Crustons'**
  String get accountNameHint;

  /// No description provided for @nameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameEmpty;

  /// No description provided for @nameMinChars.
  ///
  /// In en, this message translates to:
  /// **'Minimum 3 characters'**
  String get nameMinChars;

  /// No description provided for @currencyIsoLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency (ISO-4217)'**
  String get currencyIsoLabel;

  /// No description provided for @currencyIsoHint.
  ///
  /// In en, this message translates to:
  /// **'EUR, USD, GBP…'**
  String get currencyIsoHint;

  /// No description provided for @currencyIsoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a 3-letter code (e.g. EUR)'**
  String get currencyIsoInvalid;

  /// No description provided for @createAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountCta;

  /// No description provided for @accountCreatedToast.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get accountCreatedToast;

  /// No description provided for @errorCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Error creating the account'**
  String get errorCreateAccount;

  /// Card title for a given month, e.g. 2025-09
  ///
  /// In en, this message translates to:
  /// **'Summary {month}'**
  String summaryTitle(String month);

  /// Net result of the month with sign
  ///
  /// In en, this message translates to:
  /// **'Net of month: {amount}'**
  String netOfMonth(String amount);

  /// Opening balance for the month
  ///
  /// In en, this message translates to:
  /// **'Opening: {amount}'**
  String openingOfMonth(String amount);

  /// Total expenses
  ///
  /// In en, this message translates to:
  /// **'Expenses: {amount}'**
  String expensesLabel(String amount);

  /// Total income
  ///
  /// In en, this message translates to:
  /// **'Income: {amount}'**
  String incomeLabel(String amount);

  /// No description provided for @noMovementsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'There are no movements this month.'**
  String get noMovementsThisMonth;

  /// No description provided for @incomeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeGeneric;

  /// No description provided for @expenseGeneric.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseGeneric;

  /// No description provided for @deleteMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete movement'**
  String get deleteMovementTitle;

  /// No description provided for @deleteMovementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete it?'**
  String get deleteMovementConfirm;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deletedToast.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedToast;

  /// No description provided for @prevMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get prevMonthTooltip;

  /// No description provided for @nextMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonthTooltip;

  /// No description provided for @seeAllMonthsTooltip.
  ///
  /// In en, this message translates to:
  /// **'See all months'**
  String get seeAllMonthsTooltip;

  /// No description provided for @seeCurrentMonthTooltip.
  ///
  /// In en, this message translates to:
  /// **'See current month'**
  String get seeCurrentMonthTooltip;

  /// No description provided for @allMonthsTitle.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get allMonthsTitle;

  /// No description provided for @newMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'New movement'**
  String get newMovementTitle;

  /// No description provided for @editMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit movement'**
  String get editMovementTitle;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 25.50'**
  String get amountHint;

  /// No description provided for @categoryOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get categoryOptionalLabel;

  /// No description provided for @categoryOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Food, Transport, Payroll…'**
  String get categoryOptionalHint;

  /// No description provided for @noteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptionalLabel;

  /// Label for the selected date
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateLabel(String date);

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeDate;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @invalidAmountToast.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmountToast;

  /// No description provided for @errorSave.
  ///
  /// In en, this message translates to:
  /// **'Error while saving'**
  String get errorSave;

  /// No description provided for @savingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savingsTooltip;

  /// No description provided for @quickSavingsDepositTooltip.
  ///
  /// In en, this message translates to:
  /// **'Savings deposit'**
  String get quickSavingsDepositTooltip;

  /// No description provided for @generateCodeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Generate code'**
  String get generateCodeTooltip;

  /// No description provided for @membersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @movementsChartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Movements chart'**
  String get movementsChartTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Chart screen title including household name
  ///
  /// In en, this message translates to:
  /// **'Cumulative balance {name}'**
  String cumulativeTitle(String name);

  /// No description provided for @householdGeneric.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get householdGeneric;

  /// No description provided for @groupByTooltip.
  ///
  /// In en, this message translates to:
  /// **'Group by'**
  String get groupByTooltip;

  /// No description provided for @groupByDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get groupByDay;

  /// No description provided for @groupByWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get groupByWeek;

  /// No description provided for @groupByMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get groupByMonth;

  /// No description provided for @noMovementsToChart.
  ///
  /// In en, this message translates to:
  /// **'There are no movements to chart.'**
  String get noMovementsToChart;

  /// No description provided for @legendCumulativeBalance.
  ///
  /// In en, this message translates to:
  /// **'Cumulative balance'**
  String get legendCumulativeBalance;

  /// No description provided for @periodsEntriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Periods: {periods}   •   Entries: {entries}'**
  String periodsEntriesLabel(int periods, int entries);

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance: {amount}'**
  String balanceLabel(String amount);

  /// No description provided for @loadMovementsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load movements'**
  String get loadMovementsFailed;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get unexpectedError;

  /// No description provided for @errorLoadingGoals.
  ///
  /// In en, this message translates to:
  /// **'Error loading goals'**
  String get errorLoadingGoals;

  /// No description provided for @newSavingsGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'New savings goal'**
  String get newSavingsGoalTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @targetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get targetAmountLabel;

  /// No description provided for @noDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get noDeadlineLabel;

  /// No description provided for @deadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline: {date}'**
  String deadlineLabel(String date);

  /// No description provided for @chooseDateButton.
  ///
  /// In en, this message translates to:
  /// **'Choose date'**
  String get chooseDateButton;

  /// No description provided for @createAction.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAction;

  /// No description provided for @createGoalFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create'**
  String get createGoalFailed;

  /// No description provided for @deleteGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get deleteGoalTitle;

  /// No description provided for @deleteGoalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all its savings movements?'**
  String deleteGoalConfirm(String name);

  /// No description provided for @deleteGoalForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to delete this goal'**
  String get deleteGoalForbidden;

  /// No description provided for @deleteGoalFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete'**
  String get deleteGoalFailed;

  /// No description provided for @goalDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Goal \"{name}\" deleted'**
  String goalDeletedToast(String name);

  /// No description provided for @goalDeletedSimple.
  ///
  /// In en, this message translates to:
  /// **'Goal deleted'**
  String get goalDeletedSimple;

  /// No description provided for @savingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings – {name}'**
  String savingsTitle(String name);

  /// No description provided for @newGoalFab.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get newGoalFab;

  /// No description provided for @noGoalsEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No goals yet. Create the first one with the + button'**
  String get noGoalsEmptyState;

  /// No description provided for @goalGeneric.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalGeneric;

  /// No description provided for @progressTriple.
  ///
  /// In en, this message translates to:
  /// **'{saved} / {target}  ({pct}%)'**
  String progressTriple(String saved, String target, String pct);

  /// No description provided for @errorLoadingGoal.
  ///
  /// In en, this message translates to:
  /// **'Error loading goal'**
  String get errorLoadingGoal;

  /// No description provided for @addDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Add deposit'**
  String get addDepositTitle;

  /// No description provided for @registerWithdrawalTitle.
  ///
  /// In en, this message translates to:
  /// **'Register withdrawal'**
  String get registerWithdrawalTitle;

  /// No description provided for @depositRecordedToast.
  ///
  /// In en, this message translates to:
  /// **'Deposit recorded'**
  String get depositRecordedToast;

  /// No description provided for @withdrawalRecordedToast.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal recorded'**
  String get withdrawalRecordedToast;

  /// No description provided for @savingsGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings goal: {name}'**
  String savingsGoalTitle(String name);

  /// No description provided for @depositAction.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get depositAction;

  /// No description provided for @withdrawalAction.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get withdrawalAction;

  /// No description provided for @savingsMovementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings movements'**
  String get savingsMovementsTitle;

  /// No description provided for @noSavingsTransactions.
  ///
  /// In en, this message translates to:
  /// **'There are no transactions yet.'**
  String get noSavingsTransactions;

  /// No description provided for @errorLoadingMembers.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load members'**
  String get errorLoadingMembers;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members — {name}'**
  String membersTitle(String name);

  /// No description provided for @membersTitleSimple.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitleSimple;

  /// No description provided for @sinceLabel.
  ///
  /// In en, this message translates to:
  /// **'Since: {date}'**
  String sinceLabel(String date);

  /// No description provided for @noMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get noMembers;

  /// No description provided for @userGeneric.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userGeneric;

  /// No description provided for @noSavingsGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'No savings goals'**
  String get noSavingsGoalsTitle;

  /// No description provided for @createGoalFirstMsg.
  ///
  /// In en, this message translates to:
  /// **'Create a goal first to record deposits.'**
  String get createGoalFirstMsg;

  /// No description provided for @quickSavingsDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings deposit'**
  String get quickSavingsDepositTitle;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @selectGoalFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a goal'**
  String get selectGoalFirst;

  /// No description provided for @depositRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t register the deposit'**
  String get depositRegisterFailed;

  /// No description provided for @renameHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename account'**
  String get renameHouseholdTitle;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Downtown flat'**
  String get nameHint;

  /// No description provided for @nameEmptyToast.
  ///
  /// In en, this message translates to:
  /// **'The name cannot be empty'**
  String get nameEmptyToast;

  /// No description provided for @updateNameFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the name'**
  String get updateNameFailed;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginAction;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerAction;

  /// No description provided for @noAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get noAccountCta;

  /// No description provided for @alreadyAccountCta.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyAccountCta;

  /// No description provided for @forgotPasswordCta.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotPasswordCta;

  /// No description provided for @haveCodeCta.
  ///
  /// In en, this message translates to:
  /// **'I already have a code'**
  String get haveCodeCta;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @minPasswordLen.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minPasswordLen;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get authErrorGeneric;

  /// No description provided for @missingTokenResponse.
  ///
  /// In en, this message translates to:
  /// **'Response without token'**
  String get missingTokenResponse;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get loginSuccess;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration completed'**
  String get registerSuccess;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Recover password'**
  String get forgotPasswordTitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send link/code'**
  String get sendResetLink;

  /// No description provided for @forgotPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start recovery'**
  String get forgotPasswordFailed;

  /// No description provided for @forgotPasswordAfterMsg.
  ///
  /// In en, this message translates to:
  /// **'If the email exists, we sent you instructions to recover your password.'**
  String get forgotPasswordAfterMsg;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @codeTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Code / Token'**
  String get codeTokenLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @changeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeAction;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reset'**
  String get resetPasswordFailed;

  /// No description provided for @passwordUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in.'**
  String get passwordUpdatedToast;

  /// No description provided for @createOrJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Add household'**
  String get createOrJoinTitle;

  /// No description provided for @createOrJoinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a household or join with a code'**
  String get createOrJoinSubtitle;

  /// No description provided for @openCta.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openCta;

  /// No description provided for @deleteHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteHouseholdTitle;

  /// No description provided for @deleteHouseholdBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account and all its data? This action cannot be undone.'**
  String get deleteHouseholdBody;

  /// No description provided for @deleteHouseholdTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteHouseholdTooltip;

  /// No description provided for @deletedOkToast.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get deletedOkToast;

  /// No description provided for @changeLanguageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguageTooltip;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account or create a new one'**
  String get welcomeSubtitle;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orLabel;

  /// No description provided for @legalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get legalPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @andLabel.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andLabel;

  /// No description provided for @forecastIncludeLabel.
  ///
  /// In en, this message translates to:
  /// **'Include planned & fixed'**
  String get forecastIncludeLabel;

  /// No description provided for @plannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Planned expenses (month)'**
  String get plannedTitle;

  /// No description provided for @plannedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No planned items'**
  String get plannedEmpty;

  /// No description provided for @plannedAdd.
  ///
  /// In en, this message translates to:
  /// **'Add planned'**
  String get plannedAdd;

  /// No description provided for @plannedSettle.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get plannedSettle;

  /// No description provided for @fixedTitle.
  ///
  /// In en, this message translates to:
  /// **'Fixed expenses'**
  String get fixedTitle;

  /// No description provided for @fixedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fixed items'**
  String get fixedEmpty;

  /// No description provided for @fixedAdd.
  ///
  /// In en, this message translates to:
  /// **'Add fixed expense'**
  String get fixedAdd;

  /// No description provided for @fixedPostInstance.
  ///
  /// In en, this message translates to:
  /// **'Post this month\'s entry'**
  String get fixedPostInstance;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t complete action'**
  String get actionFailed;

  /// No description provided for @editPlannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit planned'**
  String get editPlannedTitle;

  /// No description provided for @addPlannedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add planned'**
  String get addPlannedTitle;

  /// No description provided for @concept.
  ///
  /// In en, this message translates to:
  /// **'Concept'**
  String get concept;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectDate;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @editFixedTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit fixed expense'**
  String get editFixedTitle;

  /// No description provided for @addFixedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add fixed expense'**
  String get addFixedTitle;

  /// No description provided for @recurrence.
  ///
  /// In en, this message translates to:
  /// **'Recurrence'**
  String get recurrence;

  /// No description provided for @monthlyByDay.
  ///
  /// In en, this message translates to:
  /// **'Monthly by day'**
  String get monthlyByDay;

  /// No description provided for @advancedRrule.
  ///
  /// In en, this message translates to:
  /// **'Advanced RRULE'**
  String get advancedRrule;

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day of month'**
  String get dayOfMonth;

  /// No description provided for @rrule.
  ///
  /// In en, this message translates to:
  /// **'RRULE (iCal)'**
  String get rrule;

  /// No description provided for @fixedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete fixed expense'**
  String get fixedDeleteTitle;

  /// No description provided for @fixedDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This action cannot be undone.'**
  String get fixedDeleteBody;

  /// No description provided for @fixedDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete fixed expense'**
  String get fixedDelete;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ca', 'en', 'es', 'gl'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return SCa();
    case 'en':
      return SEn();
    case 'es':
      return SEs();
    case 'gl':
      return SGl();
  }

  throw FlutterError(
      'S.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
