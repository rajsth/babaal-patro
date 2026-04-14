/// Centralized localization strings for Nepali and English.
/// Access via `S.of(isNepali)` or `S.ne` / `S.en` directly.
class S {
  final bool isNepali;
  const S._(this.isNepali);

  static const _ne = S._(true);
  static const _en = S._(false);

  static S of(bool isNepali) => isNepali ? _ne : _en;

  // ─── App Title ──────────────────────────────────────────────────────
  String get appTitle => isNepali ? 'बबाल पात्रो' : 'Babaal patro';

  // ─── Bottom Navigation ──────────────────────────────────────────────
  String get navCalendar => isNepali ? 'पात्रो' : 'Calendar';
  String get navReminders => isNepali ? 'स्मरण' : 'Reminders';
  String get navConverter => isNepali ? 'रूपान्तरण' : 'Converter';
  String get navSettings => isNepali ? 'सेटिङ्स' : 'Settings';

  // ─── Calendar Header ───────────────────────────────────────────────
  String get today => isNepali ? 'आज' : 'Today';
  String get previousMonth => isNepali ? 'अघिल्लो महिना' : 'Previous month';
  String get nextMonth => isNepali ? 'अर्को महिना' : 'Next month';

  // ─── Month Names ───────────────────────────────────────────────────
  List<String> get monthNames => isNepali
      ? const [
          'बैशाख',
          'जेठ',
          'असार',
          'श्रावण',
          'भदौ',
          'असोज',
          'कार्तिक',
          'मंसिर',
          'पौष',
          'माघ',
          'फाल्गुन',
          'चैत्र',
        ]
      : const [
          'Baisakh',
          'Jestha',
          'Asar',
          'Shrawan',
          'Bhadau',
          'Asoj',
          'Kartik',
          'Mangsir',
          'Poush',
          'Magh',
          'Falgun',
          'Chaitra',
        ];

  // ─── Day Names (abbreviated) ──────────────────────────────────────
  List<String> get dayNames => isNepali
      ? const ['आइत', 'सोम', 'मंगल', 'बुध', 'बिहि', 'शुक्र', 'शनि']
      : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // ─── Day Names (full) ─────────────────────────────────────────────
  List<String> get dayFullNames => isNepali
      ? const [
          'आइतबार',
          'सोमबार',
          'मंगलबार',
          'बुधबार',
          'बिहिबार',
          'शुक्रबार',
          'शनिबार',
        ]
      : const [
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
        ];

  // ─── Settings Screen ──────────────────────────────────────────────
  String get settings => isNepali ? 'सेटिङ्स' : 'Settings';
  String get lightMode => isNepali ? 'लाइट मोड' : 'Light mode';
  String get darkMode => isNepali ? 'डार्क मोड' : 'Dark mode';
  String get switchToLight =>
      isNepali ? 'लाइट थिममा स्विच गर्नुहोस्' : 'Switch to light theme';
  String get switchToDark =>
      isNepali ? 'डार्क थिममा स्विच गर्नुहोस्' : 'Switch to dark theme';
  String get showGridBorder =>
      isNepali ? 'ग्रिड बोर्डर देखाउनुहोस्' : 'Show grid border';
  String get hideGridBorder =>
      isNepali ? 'ग्रिड बोर्डर हटाउनुहोस्' : 'Hide grid border';
  String get gridBorderSubtitle => isNepali
      ? 'क्यालेन्डर ग्रिडमा बोर्डर देखाउने/हटाउने'
      : 'Show/hide border on calendar grid';
  String get accentColor => isNepali ? 'एक्सेन्ट रङ' : 'Accent color';
  String get chooseAccentColor =>
      isNepali ? 'एक्सेन्ट रङ छान्नुहोस्' : 'Choose accent color';
  String get accentColorSubtitle =>
      isNepali ? 'एपको मुख्य रङ छान्नुहोस्' : 'Choose the app\'s main color';
  String get language => isNepali ? 'भाषा' : 'Language';
  String get nepali => isNepali ? 'नेपाली' : 'Nepali';
  String get english => isNepali ? 'अंग्रेजी' : 'English';
  String get languageSubtitle =>
      isNepali ? 'एपको भाषा छान्नुहोस्' : 'Choose app language';

  // ─── Auth / Sync ──────────────────────────────────────────────────
  String get noBackup => isNepali ? 'ब्याकअप छैन' : 'No backup';
  String get dataLossWarning => isNepali
      ? 'साइन इन नगरेमा डाटा गुम्न सक्छ'
      : 'Data may be lost without sign in';
  String get signIn => isNepali ? 'साइन इन' : 'Sign in';
  String get signOut => isNepali ? 'साइन आउट' : 'Sign out';
  String get signInFailed => isNepali ? 'साइन इन असफल भयो' : 'Sign in failed';
  String get syncing => isNepali ? 'सिंक भइरहेको छ' : 'Syncing';
  String get user => isNepali ? 'प्रयोगकर्ता' : 'User';

  // ─── Events Screen ────────────────────────────────────────────────
  String get reminders => isNepali ? 'स्मरणहरू' : 'Reminders';
  String get saveReminders =>
      isNepali ? 'स्मरण सुरक्षित गर्नुहोस्!' : 'Save your reminders!';
  String get backupDescription => isNepali
      ? 'अहिले तपाईंका स्मरणहरू यस डिभाइसमा मात्र छन्। फोन बदल्दा वा एप मेटाउँदा सबै डाटा गुम्न सक्छ।\n\nGoogle खाताबाट साइन इन गरेर क्लाउडमा ब्याकअप गर्नुहोस्।'
      : 'Your reminders are only on this device. Data may be lost when changing phones or deleting the app.\n\nSign in with Google to backup to cloud.';
  String get signInWithGoogle =>
      isNepali ? 'Google बाट साइन इन गर्नुहोस्' : 'Sign in with Google';
  String get later => isNepali ? 'पछि गर्छु' : 'Later';
  String get remindersSyncedToCloud => isNepali
      ? 'स्मरणहरू क्लाउडमा सुरक्षित भयो!'
      : 'Reminders saved to cloud!';
  String get allRemindersSyncAuto => isNepali
      ? 'अहिले र भविष्यका सबै स्मरणहरू स्वतः सिंक हुनेछन्।'
      : 'All current and future reminders will auto-sync.';
  String get signInToKeepSafe => isNepali
      ? 'स्मरणहरू सुरक्षित साथ राख्नको लागी साइन इन गर्नुहोस्'
      : 'Sign in to keep your reminders safe';
  String get noCategoryReminders =>
      isNepali ? 'यस श्रेणीमा कुनै स्मरण छैन' : 'No reminders in this category';
  String get noRemindersAdded =>
      isNepali ? 'कुनै स्मरण थपिएको छैन' : 'No reminders added';
  String get chooseDifferentCategory => isNepali
      ? 'अर्को श्रेणी छान्नुहोस् वा फिल्टर हटाउनुहोस्'
      : 'Choose another category or remove filter';
  String get tapPlusToAdd =>
      isNepali ? '+ थिचेर नयाँ स्मरण थप्नुहोस्' : 'Tap + to add a new reminder';

  // ─── Add Reminder Dialog ──────────────────────────────────────────
  String get addNewReminder =>
      isNepali ? 'नयाँ स्मरण थप्नुहोस्' : 'Add new reminder';
  String get title => isNepali ? 'शीर्षक *' : 'Title *';
  String get titleHint =>
      isNepali ? 'के को स्मरण गराउने?' : 'What should I remind of?';
  String get titleRequired =>
      isNepali ? 'स्मरण राख्न भुल्नुभयो' : 'You missed to enter reminder';
  String get bsDate => isNepali ? 'बि.सं. मिति' : 'BS Date';
  String get time => isNepali ? 'समय' : 'Time';
  String get category => isNepali ? 'श्रेणी?' : 'Category';
  String get recurrence => isNepali ? 'कहिले दोहोर्याउने हो?' : 'Recurrence';
  String get alertWhen => isNepali ? 'कहिले सूचना पठाउने?' : 'When to send notification?';
  String get cancel => isNepali ? 'रद्द' : 'Cancel';
  String get save => isNepali ? 'सुरक्षित गर्नुहोस्' : 'Save';
  String get addReminder => isNepali ? 'स्मरण थप्नुहोस्' : 'Add reminder';
  String get moreOptions => isNepali ? 'थप विकल्पहरू' : 'More options';

  // ─── Converter Screen ─────────────────────────────────────────────
  String get dateConversion => isNepali ? 'मिति रूपान्तरण' : 'Date conversion';
  String get selectADDate =>
      isNepali ? 'AD मिति चयन गर्नुहोस्' : 'Select AD date';
  String get enterBSDate =>
      isNepali ? 'बि.सं. मिति प्रविष्ट गर्नुहोस्' : 'Enter BS date';
  String get convert => isNepali ? 'रूपान्तरण गर्नुहोस्' : 'Convert';
  String get invalidDate => isNepali ? 'अमान्य मिति' : 'Invalid date';
  String get bsDateLabel => isNepali ? 'बि.सं. मिति' : 'BS date';
  String get adDateLabel => 'AD date';
  String get year => isNepali ? 'वर्ष' : 'Year';
  String get month => isNepali ? 'महिना' : 'Month';
  String get day => isNepali ? 'गते' : 'Day';

  // ─── Month/Year Picker ────────────────────────────────────────────
  String get selectYearMonth =>
      isNepali ? 'वर्ष र महिना छान्नुहोस्' : 'Select year & month';
  String get go => isNepali ? 'जानुहोस्' : 'Go';

  // ─── Date Detail Card ─────────────────────────────────────────────
  String get panchangam => isNepali ? 'पञ्चाङ्ग' : 'Panchang';
  String get events => isNepali ? 'विशेष दिन' : 'Events';

  // ─── Monthly Holidays ─────────────────────────────────────────────
  String holidaysOf(String monthName) =>
      isNepali ? '$monthNameका बिदाहरू' : 'Holidays in $monthName';
  String gate(String num) => isNepali ? '$num गते' : num;
  String get todayLabel => isNepali ? 'आज' : 'Today';
  String daysAgo(String n) => isNepali ? '$n दिन अगाडि' : '$n days ago';
  String daysLater(String n) => isNepali ? '$n दिन पछि' : 'in $n days';
  String get yesterdayLabel => isNepali ? 'हिजो' : 'Yesterday';
  String get tomorrowLabel => isNepali ? 'भोलि' : 'Tomorrow';

  // ─── Calendar Grid Semantics ──────────────────────────────────────
  String get todaySemantic => isNepali ? 'आज' : 'Today';
  String holidaySemantic(String name) =>
      isNepali ? 'बिदा: $name' : 'Holiday: $name';
  String get hasEventSemantic => isNepali ? 'घटना छ' : 'Has event';

  // ─── Reminder Categories ──────────────────────────────────────────
  String get catPersonal => isNepali ? 'व्यक्तिगत' : 'Personal';
  String get catFinancial => isNepali ? 'आर्थिक' : 'Financial';
  String get catHealthcare => isNepali ? 'स्वास्थ्य' : 'Healthcare';
  String get catCultural => isNepali ? 'सांस्कृतिक' : 'Cultural';
  String get catBirthday => isNepali ? 'जन्मदिन' : 'Birthday';
  String get catAnniversary => isNepali ? 'वार्षिकोत्सव' : 'Anniversary';
  String get catInvitation => isNepali ? 'निमन्त्रणा' : 'Invitation';
  String get catShopping => isNepali ? 'किनमेल' : 'Shopping';
  String get catMedicine => isNepali ? 'औषधि' : 'Medicine';
  String get catSchool => isNepali ? 'विद्यालय' : 'School';

  String categoryLabel(ReminderCategoryKey cat) {
    switch (cat) {
      case ReminderCategoryKey.personal:
        return catPersonal;
      case ReminderCategoryKey.financial:
        return catFinancial;
      case ReminderCategoryKey.healthcare:
        return catHealthcare;
      case ReminderCategoryKey.cultural:
        return catCultural;
      case ReminderCategoryKey.birthday:
        return catBirthday;
      case ReminderCategoryKey.anniversary:
        return catAnniversary;
      case ReminderCategoryKey.invitation:
        return catInvitation;
      case ReminderCategoryKey.shopping:
        return catShopping;
      case ReminderCategoryKey.medicine:
        return catMedicine;
      case ReminderCategoryKey.school:
        return catSchool;
    }
  }

  // ─── Reminder Recurrence ──────────────────────────────────────────
  String get recNone => isNepali ? 'पर्दैन' : 'None';
  String get recDaily => isNepali ? 'दैनिक' : 'Daily';
  String get recWeekly => isNepali ? 'साप्ताहिक' : 'Weekly';
  String get recMonthly => isNepali ? 'मासिक' : 'Monthly';
  String get recYearly => isNepali ? 'वार्षिक' : 'Yearly';
  String get recOnce => isNepali ? 'एक पटक' : 'Once';

  String recurrenceLabel(RecurrenceKey rec) {
    switch (rec) {
      case RecurrenceKey.none:
        return recNone;
      case RecurrenceKey.once:
        return recOnce;
      case RecurrenceKey.daily:
        return recDaily;
      case RecurrenceKey.weekly:
        return recWeekly;
      case RecurrenceKey.monthly:
        return recMonthly;
      case RecurrenceKey.yearly:
        return recYearly;
    }
  }

  // ─── Alert Offsets ────────────────────────────────────────────────
  String get alertAtTime => isNepali ? 'समयमा' : 'At time';
  String get alert15Min => isNepali ? '१५ मिनेट अगाडि' : '15 min before';
  String get alert1Hour => isNepali ? '१ घण्टा अगाडि' : '1 hour before';
  String get alert1Day => isNepali ? '१ दिन अगाडि' : '1 day before';

  String alertLabel(AlertKey alert) {
    switch (alert) {
      case AlertKey.atTime:
        return alertAtTime;
      case AlertKey.fifteenMin:
        return alert15Min;
      case AlertKey.oneHour:
        return alert1Hour;
      case AlertKey.oneDay:
        return alert1Day;
    }
  }

  // ─── App Update ────────────────────────────────────────────────────
  String get updateAvailable =>
      isNepali ? 'नयाँ अपडेट उपलब्ध छ' : 'Update available';
  String get currentVersionLabel =>
      isNepali ? 'हालको संस्करण' : 'Current version';
  String get newVersionLabel =>
      isNepali ? 'नयाँ संस्करण' : 'New version';
  String get whatsNew => isNepali ? 'के नयाँ छ?' : "What's new?";
  String get updateNow =>
      isNepali ? 'अपडेट गर्नुहोस्' : 'Update';
  String get downloading => isNepali ? 'डाउनलोड हुँदैछ...' : 'Downloading...';
  String get downloadFailed =>
      isNepali ? 'डाउनलोड असफल भयो' : 'Download failed';
  String get retry => isNepali ? 'पुनः प्रयास' : 'Retry';
  String get checkForUpdates =>
      isNepali ? 'अपडेट जाँच गर्नुहोस्' : 'Check for updates';
  String get checkForUpdatesSubtitle => isNepali
      ? 'नयाँ संस्करण जाँच गर्नुहोस्'
      : 'Check for a new version';
  String get noUpdateAvailable => isNepali
      ? 'तपाईंसँग पछिल्लो संस्करण छ'
      : 'You have the latest version';
  String get upToDate => isNepali ? 'अप टु डेट!' : 'Up to date!';
  String get installing => isNepali ? 'इन्स्टल हुँदैछ...' : 'Installing...';
  String get checkingForUpdates =>
      isNepali ? 'अपडेट जाँच गर्दै...' : 'Checking for updates...';
  String get close => isNepali ? 'बन्द गर्नुहोस्' : 'Close';

  // ─── Accent Color Names ───────────────────────────────────────────
  List<String> get accentColorNames => isNepali
      ? const [
          'बैजनी',
          'निलो',
          'हरियो',
          'सियान',
          'सुन्तला',
          'रातो',
          'गुलाबी',
          'एम्बर',
        ]
      : const [
          'Purple',
          'Blue',
          'Green',
          'Cyan',
          'Orange',
          'Red',
          'Pink',
          'Amber',
        ];
}

/// Mirror enums for localization lookups (avoids importing model in localizations).
enum ReminderCategoryKey {
  personal,
  financial,
  healthcare,
  cultural,
  birthday,
  anniversary,
  invitation,
  shopping,
  medicine,
  school,
}

enum RecurrenceKey { none, once, daily, weekly, monthly, yearly }

enum AlertKey { atTime, fifteenMin, oneHour, oneDay }
