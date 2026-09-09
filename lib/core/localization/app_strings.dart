/// Type-safe, consumer-grade localization contracts and implementations
/// for Bahasa Indonesia (Default) and English.
abstract class AppStrings {
  // --- Navigation ---
  String get navFinance;
  String get navTasks;
  String get navCalendar;
  String get navVault;
  String get navSettings;

  // --- Common Actions & Buttons ---
  String get save;
  String get cancel;
  String get delete;
  String get edit;
  String get create;
  String get update;
  String get close;
  String get all;
  String get search;
  String get copy;
  String get copied;
  String get error;
  String get success;
  String get confirm;
  String get loading;

  // --- Finance Module ---
  String get financeTitle;
  String get financeSubtitle;
  String get logTransaction;
  String get exportCsv;
  String get editTransaction;
  String get income;
  String get expense;
  String get totalBalance;
  String get monthlyCashFlow;
  String get recentTransactions;
  String get noTransactionsTitle;
  String get noTransactionsSubtitle;
  String get amountLabel;
  String get titleLabel;
  String get titleHint;
  String get categoryLabel;
  String get dateLabel;
  String get noteOptional;
  String get amountValidation;
  String get titleValidation;
  String get filterAll;
  String get filterIncome;
  String get filterExpense;

  // --- Tasks Module ---
  String get tasksTitle;
  String get tasksSubtitle;
  String get createTask;
  String get editTask;
  String get taskTitleLabel;
  String get taskTitleHint;
  String get descriptionOptional;
  String get priorityLabel;
  String get statusLabel;
  String get dueDateLabel;
  String get noDueDate;
  String get estCostLabel;
  String get kanbanTab;
  String get listTab;
  String get noTasksTitle;
  String get noTasksSubtitle;
  String get todoStatus;
  String get inProgressStatus;
  String get doneStatus;
  String get lowPriority;
  String get mediumPriority;
  String get highPriority;
  String get urgentPriority;
  String get logExpensePromptTitle;
  String get logExpensePromptSubtitle;
  String get logExpenseConfirm;

  // --- Calendar Module ---
  String get calendarTitle;
  String get calendarSubtitle;
  String get scheduleDay;
  String get noEventsTitle;
  String get noEventsSubtitle;
  String get taskDeadline;
  String get scheduledTransaction;

  // --- Vault & Notes Module ---
  String get vaultTitle;
  String get vaultSubtitle;
  String get lockVault;
  String get newNote;
  String get editNote;
  String get confidentialNotes;
  String get encryptedFiles;
  String get searchNotes;
  String get noNotesTitle;
  String get noNotesSubtitle;
  String get noteTitleLabel;
  String get noteContentLabel;
  String get noteTagsLabel;
  String get notePinnedLabel;

  // --- PIN & Security Dialogs ---
  String get createPinTitle; // "Buat 6 Digit PIN Pribadi Anda"
  String get confirmPinTitle; // "Konfirmasi PIN Anda"
  String get createPinStep1; // "Langkah 1 dari 2: Buat PIN"
  String get createPinSubtitle1;
  String get createPinStep2; // "Langkah 2 dari 2: Konfirmasi PIN"
  String get createPinSubtitle2;
  String get enterPinTitle; // "Buka Brankas Pribadi"
  String get enterPinSubtitle;
  String get pinMismatchError;
  String get incorrectPinError;
  String get forgotPinPrompt;
  String get resetPinTitle;
  String get recoveryCodeLabel;
  String get newPinLabel;
  String get resetAndUnlock;
  String get recoveryDialogTitle;
  String get recoveryDialogNotice;
  String get recoveryAcknowledgment;
  String get unlockAndEnterVault;
  String get recoveryCodeCopied;

  // --- Authentication Module ---
  String get appTagline;
  String get signInTab;
  String get signUpTab;
  String get signInTitle;
  String get signUpTitle;
  String get signInSubtitle;
  String get signUpSubtitle;
  String get fullNameLabel;
  String get emailLabel;
  String get passwordLabel;
  String get confirmPasswordLabel;
  String get passwordValidationHint;
  String get passwordStrengthWeak;
  String get passwordStrengthModerate;
  String get passwordStrengthStrong;
  String get signInButton;
  String get signUpButton;
  String get continueWithGoogle;
  String get offlineGuestButton;
  String get offlineGuestBadge;
  String get noAccountPrompt;
  String get haveAccountPrompt;
  String get verifyEmailTitle;
  String get verifyEmailSubtitle;
  String get otpCodeHint;
  String get verifyButton;
  String get resendCode;
  String get resendCodeWait;
  String get backToSignIn;

  // --- Settings & System Control ---
  String get settingsTitle;
  String get settingsSubtitle;
  String get accountSection;
  String get localAccountBadge;
  String get googleAccountBadge;
  String get guestAccountBadge;
  String get changePassword;
  String get currentPasswordLabel;
  String get newPasswordLabel;
  String get updatePasswordButton;
  String get wipeAllData;
  String get wipeDataConfirmTitle;
  String get wipeDataConfirmNotice;
  String get wipeDataConfirmButton;

  // Security (Consumer Copy)
  String get securitySection;
  String get vaultSecurityKeyTitle; // "Kunci Keamanan Brankas"
  String get vaultSecurityKeySubtitle;
  String get changeMasterPinButton;
  String get changePinDialogTitle;
  String get changePinDialogNotice;
  String get currentPinLabel;
  String get newPin6DigitLabel;
  String get confirmNewPinLabel;
  String get updatePinButton;
  String get emergencyRecoveryTitle;
  String get emergencyRecoverySubtitle;
  String get regenerateRecoveryButton;
  String get autoLockTitle;
  String get autoLockSubtitle;

  // Currency & Forex (Consumer Copy)
  String get currencySection;
  String get primaryCurrencyTitle; // "Mata Uang Utama"
  String get primaryCurrencySubtitle;
  String get liveRateSynced;
  String get cachedOfflineRate;
  String get syncRatesButton;

  // Storage & Cache (Consumer Copy)
  String get storageSection;
  String get totalStorageTitle;
  String get clearStorageCacheButton; // "Bersihkan Cache Penyimpanan"
  String get clearCacheNotice;
  String get cacheOptimizedNotice;
  String get databaseStorageTitle;
  String get vaultFilesStorageTitle;
  String get tempBuffersStorageTitle;

  // Language Section
  String get languageSection;
  String get languageTitle;
  String get languageSubtitle;
  String get indonesianLanguage;
  String get englishLanguage;

  // Diagnostics & Logout
  String get aboutSection;
  String get appVersionLabel;
  String get signOutButton;
  String get signOutConfirmTitle;
  String get signOutConfirmNotice;

  // --- Finance Expansion & Localization ---
  String get netBalance;
  String get totalIncome;
  String get totalExpenses;
  String get notBalanced;
  String get surplus;
  String get deficit;
  String get inflow;
  String get outflow;
  String get expenseBreakdown;
  String get dailyOutflowTrend;
  String get noExpenseData;
  String get logExpensesPrompt;
  String get noRecentExpenses;
  String get analyticsOverview;
  String get dateFilterAll;
  String get dateFilterToday;
  String get dateFilterThisWeek;
  String get dateFilterThisMonth;
  String get dateFilterCustom;
  String get transactions;

  // --- Safe-to-Spend & Financial Health ---
  String get safeToSpendTitle;
  String get safeToSpendSubtitle;
  String get safeToSpendGood;
  String get safeToSpendTight;
  String get safeToSpendOver;
  String get remainingDaysInMonth;
  String get dailyAllowance;
  String get financialHealthTitle;
  String get financialHealthSubtitle;
  String get financialHealthNeeds;
  String get financialHealthWants;
  String get financialHealthSavings;
  String get emergencyFundRatio;
  String get healthExcellent;
  String get healthGood;
  String get healthNeedsAttention;

  // --- Cross-Module Linkage ---
  String get linkedTaskLabel;
  String get attachVaultReceipt;
  String get attachedReceiptLabel;
  String get noReceiptAttached;

  // --- Offline Backup (.lhpack) ---
  String get backupRestoreTitle;
  String get backupRestoreSubtitle;
  String get exportBackupButton;
  String get importBackupButton;
  String get enterBackupPassword;
  String get backupPasswordHint;
  String get backupExportSuccess;
  String get backupRestoreSuccess;
  String get backupInvalidPassword;

  // --- Quick Action Speed-Dial ---
  String get quickActionTitle;
  String get quickActionLogExpense;
  String get quickActionLogIncome;
  String get quickActionAddTask;
  String get quickActionNewSecretNote;

  // --- Settings Hub Sub-Views ---
  String get settingsAccountTitle;
  String get settingsAccountSubtitle;
  String get settingsLanguageTitle;
  String get settingsLanguageSubtitle;
  String get settingsSecurityTitle;
  String get settingsSecuritySubtitle;
  String get settingsCurrencyTitle;
  String get settingsCurrencySubtitle;
  String get settingsStorageTitle;
  String get settingsStorageSubtitle;
  String get settingsAboutTitle;
  String get settingsAboutSubtitle;
  String get aboutMultiPlatform;
  String get settingsNotificationsTitle;
  String get settingsNotificationsSubtitle;
  String get settingsThemeTitle;
  String get settingsThemeSubtitle;
  String get dailyReminderTitle;
  String get dailyReminderSubtitle;
  String get billReminderTitle;
  String get billReminderSubtitle;
  String get taskReminderTitle;
  String get taskReminderSubtitle;

  // --- Dashboard ---
  String get navDashboard;
  String get dashboardTitle;
  String get dashboardFinanceSummary;
  String get dashboardHabits;
  String get dashboardWellness;
  String get dashboardModules;
  String get dashboardNoHabits;
  String get viewAll;

  // --- Habits Module ---
  String get habitsTitle;
  String get addHabit;
  String get noHabitsTitle;
  String get noHabitsSubtitle;
  String get habitsCompletedToday;
  String get habitStreakLabel;

  // --- Focus / Pomodoro Module ---
  String get focusTitle;
  String get focusStart;
  String get focusPause;
  String get focusResume;
  String get focusReset;
  String get focusSessionsCompleted;

  // --- Wellness Module ---
  String get wellnessTitle;
  String get waterTitle;
  String get waterSubtitle;
  String get waterQuickAdd;
  String get moodTitle;
  String get moodQuestion;
  String get moodLoggedToday;

  // --- Emergency SOS ---
  String get emergencyCardTitle;
  String get emergencyCardEmpty;
  String get emergencyCardOwner;
  String get emergencyAllergyLabel;
  String get emergencyMedicalLabel;
  String get emergencyContactsLabel;

  // --- Multi-Wallet ---
  String get walletsTitle;
  String get addWallet;
  String get defaultWalletLabel;

  // --- Biometric Auth ---
  String get biometricTitle;
  String get biometricSubtitle;
  String get biometricUnsupported;
  String get biometricEnabled;
  String get biometricDisabled;

  // --- Theme Variants ---
  String get themeLightExecutive;
  String get themeDarkMidnight;
  String get themeMonochromatic;
  String get themeVariantLabel;

  // --- Quick Actions (new) ---
  String get quickActionLogHabit;
  String get quickActionLogWater;
  String get quickActionLogWaterSubtitle;
  String get quickActionStartFocus;
  String get quickActionStartFocusSubtitle;
  String get quickActionLogExpenseSubtitle;
  String get quickActionLogIncomeSubtitle;
  String get quickActionAddTaskSubtitle;
  String get quickActionNewSecretNoteSubtitle;

  // --- AI Assistant (Gemini BYOK) ---
  String get aiAssistantTitle;
  String get aiAssistantSubtitle;
  String get aiApiKeyLabel;
  String get aiApiKeyHint;
  String get aiApiKeySaved;
  String get aiApiKeyRemoved;
  String get aiApiKeyTest;
  String get aiApiKeyTestSuccess;
  String get aiApiKeyTestFail;
  String get aiApiKeyNotSet;
  String get aiChatPlaceholder;
  String get aiChatSend;
  String get aiInsightTitle;
  String get aiInsightLoading;
  String get aiInsightError;
  String get aiCoachingTitle;

  // --- Cloud Sync (Supabase) ---
  String get cloudSyncTitle;
  String get cloudSyncSubtitle;
  String get cloudSyncEnabled;
  String get cloudSyncDisabled;
  String get cloudSyncNow;
  String get cloudSyncSuccess;
  String get cloudSyncError;
  String get cloudSyncOffline;
  String get cloudSyncLastSynced;
  String get cloudSyncNever;

  // --- Life OS Branding ---
  String get appName;
  String get appVersion;
  String get appTaglineOs;
}

/// Bahasa Indonesia Implementation (Default)
class IdAppStrings implements AppStrings {
  const IdAppStrings();

  @override
  String get navFinance => 'Keuangan';
  @override
  String get navTasks => 'Tugas';
  @override
  String get navCalendar => 'Kalender';
  @override
  String get navVault => 'Brankas';
  @override
  String get navSettings => 'Pengaturan';

  @override
  String get save => 'Simpan';
  @override
  String get cancel => 'Batal';
  @override
  String get delete => 'Hapus';
  @override
  String get edit => 'Ubah';
  @override
  String get create => 'Buat';
  @override
  String get update => 'Perbarui';
  @override
  String get close => 'Tutup';
  @override
  String get all => 'Semua';
  @override
  String get search => 'Cari';
  @override
  String get copy => 'Salin';
  @override
  String get copied => 'Berhasil disalin ke papan klip';
  @override
  String get error => 'Terjadi kesalahan';
  @override
  String get success => 'Berhasil';
  @override
  String get confirm => 'Konfirmasi';
  @override
  String get loading => 'Memuat...';

  @override
  String get financeTitle => 'Keuangan Pribadi';
  @override
  String get financeSubtitle => 'Kelola arus kas, pemasukan, dan pengeluaran harian';
  @override
  String get logTransaction => 'Catat Transaksi';
  @override
  String get exportCsv => 'Ekspor CSV Bulan Ini';
  @override
  String get editTransaction => 'Ubah Transaksi';
  @override
  String get income => 'Pemasukan';
  @override
  String get expense => 'Pengeluaran';
  @override
  String get totalBalance => 'Saldo Bersih';
  @override
  String get monthlyCashFlow => 'Arus Kas Bulanan';
  @override
  String get recentTransactions => 'Riwayat Transaksi';
  @override
  String get noTransactionsTitle => 'Belum Ada Transaksi';
  @override
  String get noTransactionsSubtitle => 'Tekan tombol + untuk mencatat transaksi keuangan pertama Anda.';
  @override
  String get amountLabel => 'Nominal';
  @override
  String get titleLabel => 'Judul / Keterangan';
  @override
  String get titleHint => 'mis. Belanja Bulanan, Gaji Pokok';
  @override
  String get categoryLabel => 'Kategori';
  @override
  String get dateLabel => 'Tanggal Transaksi';
  @override
  String get noteOptional => 'Catatan Tambahan (Opsional)';
  @override
  String get amountValidation => 'Masukkan nominal lebih dari 0';
  @override
  String get titleValidation => 'Judul transaksi wajib diisi';
  @override
  String get filterAll => 'Semua';
  @override
  String get filterIncome => 'Pemasukan';
  @override
  String get filterExpense => 'Pengeluaran';

  @override
  String get tasksTitle => 'Daftar Tugas';
  @override
  String get tasksSubtitle => 'Atur prioritas kerja dan rencana harian Anda';
  @override
  String get createTask => 'Buat Tugas Baru';
  @override
  String get editTask => 'Ubah Tugas';
  @override
  String get taskTitleLabel => 'Nama Tugas';
  @override
  String get taskTitleHint => 'Apa yang ingin Anda kerjakan?';
  @override
  String get descriptionOptional => 'Deskripsi (Opsional)';
  @override
  String get priorityLabel => 'Tingkat Prioritas';
  @override
  String get statusLabel => 'Status Pekerjaan';
  @override
  String get dueDateLabel => 'Batas Waktu';
  @override
  String get noDueDate => 'Tanpa Batas Waktu';
  @override
  String get estCostLabel => 'Estimasi Biaya';
  @override
  String get kanbanTab => 'Papan Kanban';
  @override
  String get listTab => 'Daftar Tabel';
  @override
  String get noTasksTitle => 'Semua Tugas Tuntas';
  @override
  String get noTasksSubtitle => 'Tidak ada tugas yang tertunda. Tekan + untuk menambah rencana baru.';
  @override
  String get todoStatus => 'Rencana';
  @override
  String get inProgressStatus => 'Dikerjakan';
  @override
  String get doneStatus => 'Selesai';
  @override
  String get lowPriority => 'Rendah';
  @override
  String get mediumPriority => 'Sedang';
  @override
  String get highPriority => 'Tinggi';
  @override
  String get urgentPriority => 'Mendesak';
  @override
  String get logExpensePromptTitle => 'Catat Pengeluaran Otomatis?';
  @override
  String get logExpensePromptSubtitle => 'Tugas ini memiliki estimasi biaya. Apakah Anda ingin mencatatnya langsung ke riwayat keuangan?';
  @override
  String get logExpenseConfirm => 'Catat ke Keuangan';

  @override
  String get calendarTitle => 'Agenda & Jadwal';
  @override
  String get calendarSubtitle => 'Sinkronisasi tenggat waktu tugas dan jadwal keuangan';
  @override
  String get scheduleDay => 'Agenda Hari Ini';
  @override
  String get noEventsTitle => 'Tidak Ada Agenda Terjadwal';
  @override
  String get noEventsSubtitle => 'Tenggat waktu tugas dan transaksi terjadwal akan muncul di sini.';
  @override
  String get taskDeadline => 'Tenggat Tugas';
  @override
  String get scheduledTransaction => 'Transaksi Keuangan';

  @override
  String get vaultTitle => 'Brankas Pribadi';
  @override
  String get vaultSubtitle => 'Catatan dan berkas rahasia terlindungi aman';
  @override
  String get lockVault => 'Kunci Brankas';
  @override
  String get newNote => 'Catatan Baru';
  @override
  String get editNote => 'Ubah Catatan';
  @override
  String get confidentialNotes => 'Catatan Rahasia';
  @override
  String get encryptedFiles => 'Dokumen Aman';
  @override
  String get searchNotes => 'Cari dalam catatan aman...';
  @override
  String get noNotesTitle => 'Belum Ada Catatan Aman';
  @override
  String get noNotesSubtitle => 'Catatan yang disimpan di sini dilindungi dengan perlindungan sandi pribadi.';
  @override
  String get noteTitleLabel => 'Judul Catatan';
  @override
  String get noteContentLabel => 'Isi Catatan Rahasia';
  @override
  String get noteTagsLabel => 'Label / Tag (Pisahkan dengan koma)';
  @override
  String get notePinnedLabel => 'Sematkan ke bagian atas';

  @override
  String get createPinTitle => 'Buat 6 Digit PIN Pribadi Anda';
  @override
  String get confirmPinTitle => 'Konfirmasi PIN Anda';
  @override
  String get createPinStep1 => 'Langkah 1 dari 2: Buat PIN';
  @override
  String get createPinSubtitle1 => 'PIN ini menjadi kunci pembuka brankas pribadi Anda di perangkat ini.';
  @override
  String get createPinStep2 => 'Langkah 2 dari 2: Konfirmasi PIN';
  @override
  String get createPinSubtitle2 => 'Masukkan kembali 6 digit PIN yang sama untuk konfirmasi.';
  @override
  String get enterPinTitle => 'Buka Brankas Pribadi';
  @override
  String get enterPinSubtitle => 'Masukkan 6 digit PIN untuk membuka catatan dan berkas aman Anda.';
  @override
  String get pinMismatchError => 'PIN tidak cocok. Silakan coba buat kembali dari awal.';
  @override
  String get incorrectPinError => 'PIN salah. Silakan coba lagi.';
  @override
  String get forgotPinPrompt => 'Lupa PIN? Gunakan Kode Pemulihan';
  @override
  String get resetPinTitle => 'Atur Ulang PIN Brankas';
  @override
  String get recoveryCodeLabel => 'Kode Pemulihan Darurat';
  @override
  String get newPinLabel => '6 Digit PIN Baru';
  @override
  String get resetAndUnlock => 'Atur Ulang & Buka';
  @override
  String get recoveryDialogTitle => 'Simpan Kode Pemulihan Darurat';
  @override
  String get recoveryDialogNotice => 'Brankas Anda dilindungi secara privat. Simpan kode pemulihan ini di tempat aman. Ini adalah SATU-SATUNYA cara mengakses data jika Anda lupa PIN:';
  @override
  String get recoveryAcknowledgment => 'Saya telah menyalin dan menyimpan kode pemulihan ini di tempat yang aman.';
  @override
  String get unlockAndEnterVault => 'Buka & Masuk ke Brankas';
  @override
  String get recoveryCodeCopied => 'Kode pemulihan berhasil disalin';

  @override
  String get appTagline => 'Pusat Kehidupan & Produktivitas Pribadi Anda';
  @override
  String get signInTab => 'Masuk';
  @override
  String get signUpTab => 'Daftar';
  @override
  String get signInTitle => 'Selamat Datang Kembali';
  @override
  String get signUpTitle => 'Buat Akun Pribadi';
  @override
  String get signInSubtitle => 'Masuk untuk mengakses keuangan, tugas, dan brankas Anda';
  @override
  String get signUpSubtitle => 'Daftar dengan cepat untuk menikmati perlindungan data terpadu';
  @override
  String get fullNameLabel => 'Nama Lengkap';
  @override
  String get emailLabel => 'Alamat Email';
  @override
  String get passwordLabel => 'Kata Sandi';
  @override
  String get confirmPasswordLabel => 'Konfirmasi Kata Sandi';
  @override
  String get passwordValidationHint => 'Minimal 8 karakter berisi kombinasi huruf dan angka';
  @override
  String get passwordStrengthWeak => 'Lemah (Perlu minimal 8 karakter & angka)';
  @override
  String get passwordStrengthModerate => 'Cukup Kuat';
  @override
  String get passwordStrengthStrong => 'Sangat Aman & Kuat';
  @override
  String get signInButton => 'Masuk ke Akun';
  @override
  String get signUpButton => 'Daftar Sekarang';
  @override
  String get continueWithGoogle => 'Lanjutkan dengan Google';
  @override
  String get offlineGuestButton => 'Masuk Mode Tamu Offline';
  @override
  String get offlineGuestBadge => 'Sesi Tamu Offline';
  @override
  String get noAccountPrompt => 'Belum punya akun? Daftar di sini';
  @override
  String get haveAccountPrompt => 'Sudah punya akun? Masuk di sini';
  @override
  String get verifyEmailTitle => 'Konfirmasi Kode Keamanan';
  @override
  String get verifyEmailSubtitle => 'Masukkan 6 digit kode verifikasi yang telah dikirimkan ke email Anda:';
  @override
  String get otpCodeHint => '6 Digit Kode';
  @override
  String get verifyButton => 'Verifikasi Akun';
  @override
  String get resendCode => 'Kirim Ulang Kode';
  @override
  String get resendCodeWait => 'Kirim ulang dalam';
  @override
  String get backToSignIn => 'Kembali ke Halaman Masuk';

  @override
  String get settingsTitle => 'Pengaturan & Kontrol';
  @override
  String get settingsSubtitle => 'Preferensi aplikasi, keamanan brankas, dan pengelolaan penyimpanan';
  @override
  String get accountSection => 'Akun & Profil';
  @override
  String get localAccountBadge => 'Akun Keamanan Lokal';
  @override
  String get googleAccountBadge => 'Akun Google Terhubung';
  @override
  String get guestAccountBadge => 'Akun Tamu Offline';
  @override
  String get changePassword => 'Ubah Kata Sandi';
  @override
  String get currentPasswordLabel => 'Kata Sandi Saat Ini';
  @override
  String get newPasswordLabel => 'Kata Sandi Baru';
  @override
  String get updatePasswordButton => 'Perbarui Kata Sandi';
  @override
  String get wipeAllData => 'Hapus Seluruh Data';
  @override
  String get wipeDataConfirmTitle => 'Hapus Seluruh Data Aplikasi?';
  @override
  String get wipeDataConfirmNotice => 'Tindakan ini permanen dan tidak dapat dibatalkan. Seluruh catatan transaksi, tugas, catatan aman, dan data akun di perangkat ini akan terhapus sepenuhnya.';
  @override
  String get wipeDataConfirmButton => 'Ya, Hapus Permanen';

  @override
  String get securitySection => 'Keamanan Brankas';
  @override
  String get vaultSecurityKeyTitle => 'Kunci Keamanan Brankas';
  @override
  String get vaultSecurityKeySubtitle => 'Catatan dan dokumen dienkripsi langsung di memori perangkat.';
  @override
  String get changeMasterPinButton => 'Ganti PIN Brankas';
  @override
  String get changePinDialogTitle => 'Ganti PIN Utama Brankas';
  @override
  String get changePinDialogNotice => 'PIN baru akan digunakan untuk mengamankan kembali seluruh berkas brankas Anda.';
  @override
  String get currentPinLabel => 'PIN 6-Digit Saat Ini';
  @override
  String get newPin6DigitLabel => 'PIN 6-Digit Baru';
  @override
  String get confirmNewPinLabel => 'Konfirmasi PIN 6-Digit Baru';
  @override
  String get updatePinButton => 'Perbarui & Simpan PIN';
  @override
  String get emergencyRecoveryTitle => 'Kode Pemulihan Darurat';
  @override
  String get emergencyRecoverySubtitle => 'Buat kode baru jika kode pemulihan Anda sebelumnya diketahui orang lain.';
  @override
  String get regenerateRecoveryButton => 'Buat Kode Baru';
  @override
  String get autoLockTitle => 'Waktu Kunci Otomatis';
  @override
  String get autoLockSubtitle => 'Kunci brankas secara otomatis jika tidak ada aktivitas.';

  @override
  String get currencySection => 'Mata Uang & Kurs';
  @override
  String get primaryCurrencyTitle => 'Mata Uang Utama';
  @override
  String get primaryCurrencySubtitle => 'Tentukan mata uang acuan untuk Keuangan, Ringkasan, dan Tugas.';
  @override
  String get liveRateSynced => 'Kurs Langsung Terhubung';
  @override
  String get cachedOfflineRate => 'Kurs Tersimpan (Offline)';
  @override
  String get syncRatesButton => 'Perbarui Kurs Sekarang';

  @override
  String get storageSection => 'Penyimpanan Perangkat';
  @override
  String get totalStorageTitle => 'Total Penggunaan Penyimpanan';
  @override
  String get clearStorageCacheButton => 'Bersihkan Cache Penyimpanan';
  @override
  String get clearCacheNotice => 'Berhasil membersihkan cache berkas sementara.';
  @override
  String get cacheOptimizedNotice => 'Penyimpanan cache sudah bersih dan optimal.';
  @override
  String get databaseStorageTitle => 'Penyimpanan Data Lokal';
  @override
  String get vaultFilesStorageTitle => 'Berkas Dokumen Brankas';
  @override
  String get tempBuffersStorageTitle => 'Cache & Memori Sementara';

  @override
  String get languageSection => 'Bahasa Aplikasi';
  @override
  String get languageTitle => 'Pilihan Bahasa (Language)';
  @override
  String get languageSubtitle => 'Pilih bahasa tampilan antarmuka aplikasi Anda.';
  @override
  String get indonesianLanguage => 'Bahasa Indonesia';
  @override
  String get englishLanguage => 'English (US)';

  @override
  String get aboutSection => 'Tentang Aplikasi';
  @override
  String get appVersionLabel => 'Versi Aplikasi';
  @override
  String get signOutButton => 'Keluar dari Akun';
  @override
  String get signOutConfirmTitle => 'Konfirmasi Keluar?';
  @override
  String get signOutConfirmNotice => 'Anda akan kembali ke halaman masuk. Akses brankas akan dikunci demi keamanan.';

  // --- Finance Expansion & Localization ---
  @override
  String get netBalance => 'Saldo Bersih';
  @override
  String get totalIncome => 'Total Pemasukan';
  @override
  String get totalExpenses => 'Total Pengeluaran';
  @override
  String get notBalanced => 'Belum Seimbang';
  @override
  String get surplus => 'Surplus';
  @override
  String get deficit => 'Defisit';
  @override
  String get inflow => 'Pemasukan';
  @override
  String get outflow => 'Pengeluaran';
  @override
  String get expenseBreakdown => 'Rincian Pengeluaran';
  @override
  String get dailyOutflowTrend => 'Tren Pengeluaran Harian';
  @override
  String get noExpenseData => 'Tidak Ada Data Pengeluaran di Periode Ini';
  @override
  String get logExpensesPrompt => 'Catat pengeluaran untuk melihat grafik dan rincian interaktif';
  @override
  String get noRecentExpenses => 'Belum ada pengeluaran terkini';
  @override
  String get analyticsOverview => 'Ringkasan Analisis';
  @override
  String get dateFilterAll => 'Semua Waktu';
  @override
  String get dateFilterToday => 'Hari Ini';
  @override
  String get dateFilterThisWeek => 'Minggu Ini';
  @override
  String get dateFilterThisMonth => 'Bulan Ini';
  @override
  String get dateFilterCustom => 'Kustom';
  @override
  String get transactions => 'Daftar Transaksi';

  // --- Safe-to-Spend & Financial Health ---
  @override
  String get safeToSpendTitle => 'Batas Aman Belanja Hari Ini';
  @override
  String get safeToSpendSubtitle => 'Dihitung berdasarkan sisa anggaran & tagihan berkala';
  @override
  String get safeToSpendGood => 'Anggaran Sangat Aman';
  @override
  String get safeToSpendTight => 'Waspada Pengeluaran';
  @override
  String get safeToSpendOver => 'Melebihi Anggaran Harian';
  @override
  String get remainingDaysInMonth => 'Sisa Hari Bulan Ini';
  @override
  String get dailyAllowance => 'Alokasi Harian';
  @override
  String get financialHealthTitle => 'Skor Kesehatan Finansial';
  @override
  String get financialHealthSubtitle => 'Berdasarkan rasio 50/30/20 & kesiapan dana darurat';
  @override
  String get financialHealthNeeds => 'Kebutuhan Pokok (50%)';
  @override
  String get financialHealthWants => 'Keinginan & Gaya Hidup (30%)';
  @override
  String get financialHealthSavings => 'Tabungan & Investasi (20%)';
  @override
  String get emergencyFundRatio => 'Rasio Dana Darurat';
  @override
  String get healthExcellent => 'Sangat Sehat';
  @override
  String get healthGood => 'Baik';
  @override
  String get healthNeedsAttention => 'Perlu Perhatian';

  // --- Cross-Module Linkage ---
  @override
  String get linkedTaskLabel => 'Tautan Tugas Terkait';
  @override
  String get attachVaultReceipt => 'Lampirkan Catatan/Struk Brankas';
  @override
  String get attachedReceiptLabel => 'Struk Brankas Terlampir';
  @override
  String get noReceiptAttached => 'Tidak ada struk terlampir';

  // --- Offline Backup (.lhpack) ---
  @override
  String get backupRestoreTitle => 'Cadangan & Pemulihan Terenkripsi';
  @override
  String get backupRestoreSubtitle => 'Cadangkan atau pulihkan data lokal dengan kata sandi (.lhpack)';
  @override
  String get exportBackupButton => 'Ekspor Cadangan (.lhpack)';
  @override
  String get importBackupButton => 'Pulihkan dari Cadangan (.lhpack)';
  @override
  String get enterBackupPassword => 'Masukkan Kata Sandi Cadangan';
  @override
  String get backupPasswordHint => 'Kata sandi untuk mengenkripsi berkas .lhpack';
  @override
  String get backupExportSuccess => 'Berkas cadangan berhasil diekspor!';
  @override
  String get backupRestoreSuccess => 'Data berhasil dipulihkan dari cadangan!';
  @override
  String get backupInvalidPassword => 'Kata sandi cadangan salah atau berkas rusak';

  // --- Quick Action Speed-Dial ---
  @override
  String get quickActionTitle => 'Aksi Cepat';
  @override
  String get quickActionLogExpense => 'Catat Pengeluaran';
  @override
  String get quickActionLogIncome => 'Catat Pemasukan';
  @override
  String get quickActionAddTask => 'Tambah Tugas';
  @override
  String get quickActionNewSecretNote => 'Catatan Rahasia Baru';

  // --- Settings Hub Sub-Views ---
  @override
  String get settingsAccountTitle => 'Akun & Profil';
  @override
  String get settingsAccountSubtitle => 'Kelola identitas pengguna, email, dan status keanggotaan';
  @override
  String get settingsLanguageTitle => 'Bahasa Aplikasi';
  @override
  String get settingsLanguageSubtitle => 'Pilih Bahasa Indonesia atau English';
  @override
  String get settingsSecurityTitle => 'Keamanan & Brankas';
  @override
  String get settingsSecuritySubtitle => 'PIN Master, waktu kunci otomatis, dan kode darurat';
  @override
  String get settingsCurrencyTitle => 'Mata Uang & Kurs';
  @override
  String get settingsCurrencySubtitle => 'Pilihan mata uang utama (IDR, USD, EUR, SGD) dan nilai kurs';
  @override
  String get settingsStorageTitle => 'Penyimpanan & Cadangan Data';
  @override
  String get settingsStorageSubtitle => 'Visualisasi cache, ekspor/impor cadangan .lhpack, dan titik pemulihan';
  @override
  String get settingsAboutTitle => 'Tentang Aplikasi';
  @override
  String get settingsAboutSubtitle => 'Informasi versi rilis dan platform Life OS';
  @override
  String get aboutMultiPlatform => 'Life OS Multi-Platform Edition (Support: Android, iOS, Windows & Web)';
  @override
  String get settingsNotificationsTitle => 'Notifikasi & Pengingat';
  @override
  String get settingsNotificationsSubtitle => 'Atur pengingat pencatatan harian, tagihan, dan tugas';
  @override
  String get settingsThemeTitle => 'Tema & Personalisasi';
  @override
  String get settingsThemeSubtitle => 'Gaya tampilan Light Fintech Executive, warna aksen, dan font';
  @override
  String get dailyReminderTitle => 'Pengingat Pencatatan Keuangan Harian';
  @override
  String get dailyReminderSubtitle => 'Notifikasi pukul 20:00 untuk mencatat arus kas hari ini';
  @override
  String get billReminderTitle => 'Pengingat Tagihan Rutin';
  @override
  String get billReminderSubtitle => 'Notifikasi H-2 sebelum jatuh tempo pembayaran tagihan';
  @override
  String get taskReminderTitle => 'Pengingat Batas Waktu Tugas';
  @override
  String get taskReminderSubtitle => 'Notifikasi tugas mendesak dan berprioritas tinggi';

  // --- Dashboard ---
  @override
  String get navDashboard => 'Beranda';
  @override
  String get dashboardTitle => 'Life OS';
  @override
  String get dashboardFinanceSummary => 'Ringkasan Keuangan Bulan Ini';
  @override
  String get dashboardHabits => 'Kebiasaan Hari Ini';
  @override
  String get dashboardWellness => 'Wellness Hari Ini';
  @override
  String get dashboardModules => 'Modul Lainnya';
  @override
  String get dashboardNoHabits => 'Belum ada kebiasaan. Ketuk untuk mulai!';
  @override
  String get viewAll => 'Lihat Semua';

  // --- Habits ---
  @override
  String get habitsTitle => 'Kebiasaan';
  @override
  String get addHabit => 'Tambah Kebiasaan';
  @override
  String get noHabitsTitle => 'Mulai Bangun Kebiasaan Positif';
  @override
  String get noHabitsSubtitle => 'Lacak rutinitas harian dan bangun konsistensi jangka panjang dengan streak tracker.';
  @override
  String get habitsCompletedToday => 'kebiasaan selesai';
  @override
  String get habitStreakLabel => 'Streak';

  // --- Focus ---
  @override
  String get focusTitle => 'Mode Fokus';
  @override
  String get focusStart => 'Mulai Fokus';
  @override
  String get focusPause => 'Jeda';
  @override
  String get focusResume => 'Lanjutkan';
  @override
  String get focusReset => 'Reset';
  @override
  String get focusSessionsCompleted => 'sesi selesai';

  // --- Wellness ---
  @override
  String get wellnessTitle => 'Wellness & Kesehatan';
  @override
  String get waterTitle => 'Asupan Air Harian';
  @override
  String get waterSubtitle => 'Targetkan 2000 ml per hari';
  @override
  String get waterQuickAdd => 'Tambah Cepat';
  @override
  String get moodTitle => 'Catatan Suasana Hati';
  @override
  String get moodQuestion => 'Bagaimana perasaanmu hari ini?';
  @override
  String get moodLoggedToday => 'Sudah dicatat hari ini';

  // --- Emergency SOS ---
  @override
  String get emergencyCardTitle => 'Kartu Darurat SOS';
  @override
  String get emergencyCardEmpty => 'Isi informasi medis dan kontak darurat Anda untuk situasi darurat.';
  @override
  String get emergencyCardOwner => 'Pemilik Kartu';
  @override
  String get emergencyAllergyLabel => 'ALERGI & PANTANGAN';
  @override
  String get emergencyMedicalLabel => 'CATATAN MEDIS';
  @override
  String get emergencyContactsLabel => 'KONTAK DARURAT';

  // --- Multi-Wallet ---
  @override
  String get walletsTitle => 'Dompet & Rekening';
  @override
  String get addWallet => 'Tambah Dompet';
  @override
  String get defaultWalletLabel => 'Rekening Utama';

  // --- Biometric ---
  @override
  String get biometricTitle => 'Kunci Biometrik';
  @override
  String get biometricSubtitle => 'Gunakan sidik jari atau Face ID untuk membuka brankas';
  @override
  String get biometricUnsupported => 'Biometrik tidak tersedia di perangkat ini';
  @override
  String get biometricEnabled => 'Biometrik aktif';
  @override
  String get biometricDisabled => 'Biometrik nonaktif';

  // --- Theme Variants ---
  @override
  String get themeLightExecutive => 'Light Fintech Executive';
  @override
  String get themeDarkMidnight => 'Dark Midnight';
  @override
  String get themeMonochromatic => 'Monokromatik Murni';
  @override
  String get themeVariantLabel => 'Tema Tampilan';

  // --- Quick Actions (new) ---
  @override
  String get quickActionLogHabit => 'Tandai Kebiasaan Selesai';
  @override
  String get quickActionLogWater => 'Catat Asupan Air';
  @override
  String get quickActionLogWaterSubtitle => 'Tambah 250 ml air minum';
  @override
  String get quickActionStartFocus => 'Mulai Sesi Fokus';
  @override
  String get quickActionStartFocusSubtitle => 'Timer pomodoro 25 menit';
  @override
  String get quickActionLogExpenseSubtitle => 'Kategori, jumlah & dompet';
  @override
  String get quickActionLogIncomeSubtitle => 'Catat pemasukan baru';
  @override
  String get quickActionAddTaskSubtitle => 'Prioritas & tenggat waktu';
  @override
  String get quickActionNewSecretNoteSubtitle => 'Tersimpan terenkripsi di vault';

  // --- AI Assistant ---
  @override
  String get aiAssistantTitle => 'Asisten AI';
  @override
  String get aiAssistantSubtitle => 'Wawasan keuangan & produktivitas bertenaga Gemini';
  @override
  String get aiApiKeyLabel => 'Kunci API Gemini';
  @override
  String get aiApiKeyHint => 'Masukkan kunci API Google AI Studio Anda';
  @override
  String get aiApiKeySaved => 'Kunci API berhasil disimpan';
  @override
  String get aiApiKeyRemoved => 'Kunci API dihapus';
  @override
  String get aiApiKeyTest => 'Uji Koneksi';
  @override
  String get aiApiKeyTestSuccess => 'Koneksi berhasil! AI siap digunakan.';
  @override
  String get aiApiKeyTestFail => 'Koneksi gagal. Periksa kunci API Anda.';
  @override
  String get aiApiKeyNotSet => 'Kunci API belum diatur. Tambahkan di Pengaturan.';
  @override
  String get aiChatPlaceholder => 'Tanya asisten AI Anda...';
  @override
  String get aiChatSend => 'Kirim';
  @override
  String get aiInsightTitle => 'Wawasan Keuangan AI';
  @override
  String get aiInsightLoading => 'Menganalisis keuangan Anda...';
  @override
  String get aiInsightError => 'Tidak dapat memuat wawasan AI';
  @override
  String get aiCoachingTitle => 'Coaching Harian';

  // --- Cloud Sync ---
  @override
  String get cloudSyncTitle => 'Sinkronisasi Cloud';
  @override
  String get cloudSyncSubtitle => 'Cadangkan data ke Supabase secara otomatis';
  @override
  String get cloudSyncEnabled => 'Sinkronisasi aktif';
  @override
  String get cloudSyncDisabled => 'Sinkronisasi nonaktif';
  @override
  String get cloudSyncNow => 'Sinkronkan Sekarang';
  @override
  String get cloudSyncSuccess => 'Data berhasil disinkronkan';
  @override
  String get cloudSyncError => 'Sinkronisasi gagal. Coba lagi nanti.';
  @override
  String get cloudSyncOffline => 'Offline — data tersimpan lokal';
  @override
  String get cloudSyncLastSynced => 'Terakhir disinkronkan';
  @override
  String get cloudSyncNever => 'Belum pernah disinkronkan';

  // --- Life OS Branding ---
  @override
  String get appName => 'Life OS';
  @override
  String get appVersion => 'Versi';
  @override
  String get appTaglineOs => 'Sistem Operasi Kehidupan Pribadi';
}

/// English Implementation
class EnAppStrings implements AppStrings {
  const EnAppStrings();

  @override
  String get navFinance => 'Finance';
  @override
  String get navTasks => 'Tasks';
  @override
  String get navCalendar => 'Calendar';
  @override
  String get navVault => 'Vault';
  @override
  String get navSettings => 'Settings';

  @override
  String get save => 'Save';
  @override
  String get cancel => 'Cancel';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get create => 'Create';
  @override
  String get update => 'Update';
  @override
  String get close => 'Close';
  @override
  String get all => 'All';
  @override
  String get search => 'Search';
  @override
  String get copy => 'Copy';
  @override
  String get copied => 'Copied to clipboard';
  @override
  String get error => 'An error occurred';
  @override
  String get success => 'Success';
  @override
  String get confirm => 'Confirm';
  @override
  String get loading => 'Loading...';

  @override
  String get financeTitle => 'Personal Finance';
  @override
  String get financeSubtitle => 'Manage cash flow, income, and daily expenses';
  @override
  String get logTransaction => 'Log Transaction';
  @override
  String get exportCsv => 'Export This Month CSV';
  @override
  String get editTransaction => 'Edit Transaction';
  @override
  String get income => 'Income';
  @override
  String get expense => 'Expense';
  @override
  String get totalBalance => 'Net Balance';
  @override
  String get monthlyCashFlow => 'Monthly Cash Flow';
  @override
  String get recentTransactions => 'Transaction History';
  @override
  String get noTransactionsTitle => 'No Transactions Yet';
  @override
  String get noTransactionsSubtitle => 'Tap the + button to record your first financial transaction.';
  @override
  String get amountLabel => 'Amount';
  @override
  String get titleLabel => 'Title / Description';
  @override
  String get titleHint => 'e.g. Grocery Store, Monthly Salary';
  @override
  String get categoryLabel => 'Category';
  @override
  String get dateLabel => 'Transaction Date';
  @override
  String get noteOptional => 'Additional Note (Optional)';
  @override
  String get amountValidation => 'Enter an amount greater than 0';
  @override
  String get titleValidation => 'Title is required';
  @override
  String get filterAll => 'All';
  @override
  String get filterIncome => 'Income';
  @override
  String get filterExpense => 'Expense';

  @override
  String get tasksTitle => 'Task Planner';
  @override
  String get tasksSubtitle => 'Organize work priorities and daily schedules';
  @override
  String get createTask => 'Create Task';
  @override
  String get editTask => 'Edit Task';
  @override
  String get taskTitleLabel => 'Task Title';
  @override
  String get taskTitleHint => 'What needs to be done?';
  @override
  String get descriptionOptional => 'Description (Optional)';
  @override
  String get priorityLabel => 'Priority Level';
  @override
  String get statusLabel => 'Task Status';
  @override
  String get dueDateLabel => 'Due Date';
  @override
  String get noDueDate => 'No Due Date';
  @override
  String get estCostLabel => 'Estimated Cost';
  @override
  String get kanbanTab => 'Kanban Board';
  @override
  String get listTab => 'List View';
  @override
  String get noTasksTitle => 'All Tasks Complete';
  @override
  String get noTasksSubtitle => 'No pending tasks found. Tap + to create a new one.';
  @override
  String get todoStatus => 'To Do';
  @override
  String get inProgressStatus => 'In Progress';
  @override
  String get doneStatus => 'Done';
  @override
  String get lowPriority => 'Low';
  @override
  String get mediumPriority => 'Medium';
  @override
  String get highPriority => 'High';
  @override
  String get urgentPriority => 'Urgent';
  @override
  String get logExpensePromptTitle => 'Log Expense Automatically?';
  @override
  String get logExpensePromptSubtitle => 'This task has an estimated cost. Would you like to log it directly into your finance ledger?';
  @override
  String get logExpenseConfirm => 'Log to Finance';

  @override
  String get calendarTitle => 'Calendar & Schedule';
  @override
  String get calendarSubtitle => 'Synchronize task deadlines and financial schedules';
  @override
  String get scheduleDay => 'Today\'s Agenda';
  @override
  String get noEventsTitle => 'No Scheduled Agenda';
  @override
  String get noEventsSubtitle => 'Task deadlines and financial dates will appear here.';
  @override
  String get taskDeadline => 'Task Deadline';
  @override
  String get scheduledTransaction => 'Finance Schedule';

  @override
  String get vaultTitle => 'Personal Vault';
  @override
  String get vaultSubtitle => 'Confidential notes and files securely protected';
  @override
  String get lockVault => 'Lock Vault';
  @override
  String get newNote => 'New Note';
  @override
  String get editNote => 'Edit Note';
  @override
  String get confidentialNotes => 'Confidential Notes';
  @override
  String get encryptedFiles => 'Secure Files';
  @override
  String get searchNotes => 'Search in secure notes...';
  @override
  String get noNotesTitle => 'No Secure Notes Found';
  @override
  String get noNotesSubtitle => 'Notes stored here are protected with personal PIN encryption.';
  @override
  String get noteTitleLabel => 'Note Title';
  @override
  String get noteContentLabel => 'Confidential Note Content';
  @override
  String get noteTagsLabel => 'Tags (Comma separated)';
  @override
  String get notePinnedLabel => 'Pin to top';

  @override
  String get createPinTitle => 'Create Your 6-Digit Personal PIN';
  @override
  String get confirmPinTitle => 'Confirm Your PIN';
  @override
  String get createPinStep1 => 'Step 1 of 2: Create PIN';
  @override
  String get createPinSubtitle1 => 'This PIN serves as the primary key to unlock your personal vault.';
  @override
  String get createPinStep2 => 'Step 2 of 2: Confirm PIN';
  @override
  String get createPinSubtitle2 => 'Re-enter the exact same 6-digit PIN to confirm.';
  @override
  String get enterPinTitle => 'Unlock Personal Vault';
  @override
  String get enterPinSubtitle => 'Enter your 6-digit PIN to access confidential notes and files.';
  @override
  String get pinMismatchError => 'PINs do not match. Please start over.';
  @override
  String get incorrectPinError => 'Incorrect PIN. Please try again.';
  @override
  String get forgotPinPrompt => 'Forgot PIN? Use Emergency Recovery Code';
  @override
  String get resetPinTitle => 'Reset Vault PIN';
  @override
  String get recoveryCodeLabel => 'Emergency Recovery Code';
  @override
  String get newPinLabel => 'New 6-Digit PIN';
  @override
  String get resetAndUnlock => 'Reset & Unlock';
  @override
  String get recoveryDialogTitle => 'Emergency Recovery Code';
  @override
  String get recoveryDialogNotice => 'Your vault is privately protected. Save this recovery code in a safe location. It is the ONLY way to recover access if you forget your PIN:';
  @override
  String get recoveryAcknowledgment => 'I have copied and safely stored my recovery code in an external, secure location.';
  @override
  String get unlockAndEnterVault => 'Unlock & Enter Secure Vault';
  @override
  String get recoveryCodeCopied => 'Recovery code copied to clipboard';

  @override
  String get appTagline => 'Your Personal Life & Productivity Hub';
  @override
  String get signInTab => 'Sign In';
  @override
  String get signUpTab => 'Create Account';
  @override
  String get signInTitle => 'Welcome Back';
  @override
  String get signUpTitle => 'Create Personal Account';
  @override
  String get signInSubtitle => 'Sign in to access your finances, tasks, and vault';
  @override
  String get signUpSubtitle => 'Sign up in seconds to enjoy unified personal protection';
  @override
  String get fullNameLabel => 'Full Name';
  @override
  String get emailLabel => 'Email Address';
  @override
  String get passwordLabel => 'Password';
  @override
  String get confirmPasswordLabel => 'Confirm Password';
  @override
  String get passwordValidationHint => 'At least 8 characters with letters & numbers';
  @override
  String get passwordStrengthWeak => 'Weak (Need 8+ characters & numbers)';
  @override
  String get passwordStrengthModerate => 'Moderate';
  @override
  String get passwordStrengthStrong => 'Strong & Secure';
  @override
  String get signInButton => 'Sign In';
  @override
  String get signUpButton => 'Sign Up';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get offlineGuestButton => 'Continue in Offline Guest Mode';
  @override
  String get offlineGuestBadge => 'Offline Guest Session';
  @override
  String get noAccountPrompt => 'Don\'t have an account? Sign up';
  @override
  String get haveAccountPrompt => 'Already have an account? Sign in';
  @override
  String get verifyEmailTitle => 'Confirm Security Code';
  @override
  String get verifyEmailSubtitle => 'Enter the 6-digit confirmation code sent to your email:';
  @override
  String get otpCodeHint => '6-Digit Code';
  @override
  String get verifyButton => 'Verify Account';
  @override
  String get resendCode => 'Resend Code';
  @override
  String get resendCodeWait => 'Resend in';
  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get settingsTitle => 'Settings & Control';
  @override
  String get settingsSubtitle => 'App preferences, vault security, and storage management';
  @override
  String get accountSection => 'Account & Profile';
  @override
  String get localAccountBadge => 'Local Security Account';
  @override
  String get googleAccountBadge => 'Connected Google Account';
  @override
  String get guestAccountBadge => 'Offline Guest Account';
  @override
  String get changePassword => 'Change Password';
  @override
  String get currentPasswordLabel => 'Current Password';
  @override
  String get newPasswordLabel => 'New Password';
  @override
  String get updatePasswordButton => 'Update Password';
  @override
  String get wipeAllData => 'Delete All Data';
  @override
  String get wipeDataConfirmTitle => 'Delete All Application Data?';
  @override
  String get wipeDataConfirmNotice => 'This action is irreversible. All transactions, tasks, confidential notes, and account data will be permanently deleted from this device.';
  @override
  String get wipeDataConfirmButton => 'Yes, Permanently Delete';

  @override
  String get securitySection => 'Vault Security';
  @override
  String get vaultSecurityKeyTitle => 'Vault Security Key';
  @override
  String get vaultSecurityKeySubtitle => 'Notes and files are decrypted strictly in device memory.';
  @override
  String get changeMasterPinButton => 'Change Master PIN';
  @override
  String get changePinDialogTitle => 'Change Master Vault PIN';
  @override
  String get changePinDialogNotice => 'Your new PIN will be used to protect all files in your vault.';
  @override
  String get currentPinLabel => 'Current 6-Digit PIN';
  @override
  String get newPin6DigitLabel => 'New 6-Digit PIN';
  @override
  String get confirmNewPinLabel => 'Confirm New 6-Digit PIN';
  @override
  String get updatePinButton => 'Update & Save PIN';
  @override
  String get emergencyRecoveryTitle => 'Emergency Recovery Code';
  @override
  String get emergencyRecoverySubtitle => 'Generate a new code if your previous one was compromised.';
  @override
  String get regenerateRecoveryButton => 'Generate New Code';
  @override
  String get autoLockTitle => 'Auto-Lock Timeout';
  @override
  String get autoLockSubtitle => 'Automatically locks vault when inactive.';

  @override
  String get currencySection => 'Currency & Exchange Rates';
  @override
  String get primaryCurrencyTitle => 'Primary Currency';
  @override
  String get primaryCurrencySubtitle => 'Select base currency for Finance, Overview, and Tasks.';
  @override
  String get liveRateSynced => 'Live Rate Connected';
  @override
  String get cachedOfflineRate => 'Saved Rate (Offline)';
  @override
  String get syncRatesButton => 'Sync Rates Now';

  @override
  String get storageSection => 'Device Storage';
  @override
  String get totalStorageTitle => 'Total Storage Used';
  @override
  String get clearStorageCacheButton => 'Clear Storage Cache';
  @override
  String get clearCacheNotice => 'Cleaned temporary cache files.';
  @override
  String get cacheOptimizedNotice => 'Storage cache is already clean and optimal.';
  @override
  String get databaseStorageTitle => 'Local Data Storage';
  @override
  String get vaultFilesStorageTitle => 'Vault Files & Documents';
  @override
  String get tempBuffersStorageTitle => 'Cache & Temporary Memory';

  @override
  String get languageSection => 'Language';
  @override
  String get languageTitle => 'App Language';
  @override
  String get languageSubtitle => 'Choose your preferred interface language.';
  @override
  String get indonesianLanguage => 'Bahasa Indonesia';
  @override
  String get englishLanguage => 'English (US)';

  @override
  String get aboutSection => 'About Application';
  @override
  String get appVersionLabel => 'Application Version';
  @override
  String get signOutButton => 'Sign Out';
  @override
  String get signOutConfirmTitle => 'Sign Out Confirmation';
  @override
  String get signOutConfirmNotice => 'You will return to the sign-in screen. Vault access will be locked for safety.';

  // --- Finance Expansion & Localization ---
  @override
  String get netBalance => 'Net Balance';
  @override
  String get totalIncome => 'Total Income';
  @override
  String get totalExpenses => 'Total Expenses';
  @override
  String get notBalanced => 'Not Balanced';
  @override
  String get surplus => 'Surplus';
  @override
  String get deficit => 'Deficit';
  @override
  String get inflow => 'Inflow';
  @override
  String get outflow => 'Outflow';
  @override
  String get expenseBreakdown => 'Expense Breakdown';
  @override
  String get dailyOutflowTrend => 'Daily Outflow Trend';
  @override
  String get noExpenseData => 'No Expense Data in Selected Period';
  @override
  String get logExpensesPrompt => 'Log expenses to see interactive breakdowns and trends';
  @override
  String get noRecentExpenses => 'No recent expenses';
  @override
  String get analyticsOverview => 'Analytics Overview';
  @override
  String get dateFilterAll => 'All Time';
  @override
  String get dateFilterToday => 'Today';
  @override
  String get dateFilterThisWeek => 'This Week';
  @override
  String get dateFilterThisMonth => 'This Month';
  @override
  String get dateFilterCustom => 'Custom';
  @override
  String get transactions => 'Transactions';

  // --- Safe-to-Spend & Financial Health ---
  @override
  String get safeToSpendTitle => 'Safe-to-Spend Today';
  @override
  String get safeToSpendSubtitle => 'Calculated from remaining budget & upcoming bills';
  @override
  String get safeToSpendGood => 'Budget Very Healthy';
  @override
  String get safeToSpendTight => 'Tight Budget Warning';
  @override
  String get safeToSpendOver => 'Exceeded Daily Budget';
  @override
  String get remainingDaysInMonth => 'Remaining Days This Month';
  @override
  String get dailyAllowance => 'Daily Allowance';
  @override
  String get financialHealthTitle => 'Financial Health Score';
  @override
  String get financialHealthSubtitle => 'Based on 50/30/20 ratio & emergency fund readiness';
  @override
  String get financialHealthNeeds => 'Needs (50%)';
  @override
  String get financialHealthWants => 'Wants (30%)';
  @override
  String get financialHealthSavings => 'Savings & Investment (20%)';
  @override
  String get emergencyFundRatio => 'Emergency Fund Ratio';
  @override
  String get healthExcellent => 'Excellent';
  @override
  String get healthGood => 'Good';
  @override
  String get healthNeedsAttention => 'Needs Attention';

  // --- Cross-Module Linkage ---
  @override
  String get linkedTaskLabel => 'Linked Task';
  @override
  String get attachVaultReceipt => 'Attach Vault Receipt/Note';
  @override
  String get attachedReceiptLabel => 'Vault Receipt Attached';
  @override
  String get noReceiptAttached => 'No receipt attached';

  // --- Offline Backup (.lhpack) ---
  @override
  String get backupRestoreTitle => 'Encrypted Backup & Restore';
  @override
  String get backupRestoreSubtitle => 'Backup or restore local data securely with password (.lhpack)';
  @override
  String get exportBackupButton => 'Export Backup (.lhpack)';
  @override
  String get importBackupButton => 'Restore from Backup (.lhpack)';
  @override
  String get enterBackupPassword => 'Enter Backup Password';
  @override
  String get backupPasswordHint => 'Password to encrypt .lhpack file';
  @override
  String get backupExportSuccess => 'Backup file exported successfully!';
  @override
  String get backupRestoreSuccess => 'Data successfully restored from backup!';
  @override
  String get backupInvalidPassword => 'Invalid backup password or corrupted file';

  // --- Quick Action Speed-Dial ---
  @override
  String get quickActionTitle => 'Quick Action';
  @override
  String get quickActionLogExpense => 'Log Expense';
  @override
  String get quickActionLogIncome => 'Log Income';
  @override
  String get quickActionAddTask => 'Add Task';
  @override
  String get quickActionNewSecretNote => 'New Secret Note';

  // --- Settings Hub Sub-Views ---
  @override
  String get settingsAccountTitle => 'Account & Profile';
  @override
  String get settingsAccountSubtitle => 'Manage user identity, email, and membership status';
  @override
  String get settingsLanguageTitle => 'App Language';
  @override
  String get settingsLanguageSubtitle => 'Select Bahasa Indonesia or English';
  @override
  String get settingsSecurityTitle => 'Vault Security';
  @override
  String get settingsSecuritySubtitle => 'Master PIN, auto-lock timeout, and emergency code';
  @override
  String get settingsCurrencyTitle => 'Currency & Exchange Rates';
  @override
  String get settingsCurrencySubtitle => 'Primary currency (IDR, USD, EUR, SGD) and exchange rates';
  @override
  String get settingsStorageTitle => 'Device Storage & Data';
  @override
  String get settingsStorageSubtitle => 'Cache visualizer, .lhpack backup/restore, and restore points';
  @override
  String get settingsAboutTitle => 'About Application';
  @override
  String get settingsAboutSubtitle => 'Life OS version and platform release info';
  @override
  String get aboutMultiPlatform => 'Life OS Multi-Platform Edition (Support: Android, iOS, Windows & Web)';
  @override
  String get settingsNotificationsTitle => 'Notifications & Reminders';
  @override
  String get settingsNotificationsSubtitle => 'Configure daily financial logging, bills, and task reminders';
  @override
  String get settingsThemeTitle => 'Theme & Customization';
  @override
  String get settingsThemeSubtitle => 'Light Fintech Executive style, accent colors, and typography';
  @override
  String get dailyReminderTitle => 'Daily Financial Log Reminder';
  @override
  String get dailyReminderSubtitle => 'Reminder at 20:00 to record today\'s cash flow';
  @override
  String get billReminderTitle => 'Recurring Bill Reminder';
  @override
  String get billReminderSubtitle => 'Reminder 2 days before recurring bills are due';
  @override
  String get taskReminderTitle => 'Task Deadline Reminder';
  @override
  String get taskReminderSubtitle => 'Alert for urgent and high-priority tasks';

  // --- Dashboard ---
  @override
  String get navDashboard => 'Home';
  @override
  String get dashboardTitle => 'Life OS';
  @override
  String get dashboardFinanceSummary => 'This Month\'s Finance';
  @override
  String get dashboardHabits => 'Today\'s Habits';
  @override
  String get dashboardWellness => 'Today\'s Wellness';
  @override
  String get dashboardModules => 'Modules';
  @override
  String get dashboardNoHabits => 'No habits yet. Tap to get started!';
  @override
  String get viewAll => 'View All';

  // --- Habits ---
  @override
  String get habitsTitle => 'Habits';
  @override
  String get addHabit => 'Add Habit';
  @override
  String get noHabitsTitle => 'Start Building Positive Habits';
  @override
  String get noHabitsSubtitle => 'Track daily routines and build long-term consistency with a streak tracker.';
  @override
  String get habitsCompletedToday => 'habits done';
  @override
  String get habitStreakLabel => 'Streak';

  // --- Focus ---
  @override
  String get focusTitle => 'Focus Mode';
  @override
  String get focusStart => 'Start Focus';
  @override
  String get focusPause => 'Pause';
  @override
  String get focusResume => 'Resume';
  @override
  String get focusReset => 'Reset';
  @override
  String get focusSessionsCompleted => 'sessions done';

  // --- Wellness ---
  @override
  String get wellnessTitle => 'Wellness & Health';
  @override
  String get waterTitle => 'Daily Water Intake';
  @override
  String get waterSubtitle => 'Target 2000 ml per day';
  @override
  String get waterQuickAdd => 'Quick Add';
  @override
  String get moodTitle => 'Mood Journal';
  @override
  String get moodQuestion => 'How are you feeling today?';
  @override
  String get moodLoggedToday => 'Already logged today';

  // --- Emergency SOS ---
  @override
  String get emergencyCardTitle => 'Emergency SOS Card';
  @override
  String get emergencyCardEmpty => 'Fill in your medical info and emergency contacts for critical situations.';
  @override
  String get emergencyCardOwner => 'Card Owner';
  @override
  String get emergencyAllergyLabel => 'ALLERGIES & RESTRICTIONS';
  @override
  String get emergencyMedicalLabel => 'MEDICAL NOTES';
  @override
  String get emergencyContactsLabel => 'EMERGENCY CONTACTS';

  // --- Multi-Wallet ---
  @override
  String get walletsTitle => 'Wallets & Accounts';
  @override
  String get addWallet => 'Add Wallet';
  @override
  String get defaultWalletLabel => 'Main Account';

  // --- Biometric ---
  @override
  String get biometricTitle => 'Biometric Lock';
  @override
  String get biometricSubtitle => 'Use fingerprint or Face ID to unlock your vault';
  @override
  String get biometricUnsupported => 'Biometrics not available on this device';
  @override
  String get biometricEnabled => 'Biometrics enabled';
  @override
  String get biometricDisabled => 'Biometrics disabled';

  // --- Theme Variants ---
  @override
  String get themeLightExecutive => 'Light Fintech Executive';
  @override
  String get themeDarkMidnight => 'Dark Midnight';
  @override
  String get themeMonochromatic => 'Pure Monochromatic';
  @override
  String get themeVariantLabel => 'Display Theme';

  // --- Quick Actions (new) ---
  @override
  String get quickActionLogHabit => 'Mark Habit Complete';
  @override
  String get quickActionLogWater => 'Log Water Intake';
  @override
  String get quickActionLogWaterSubtitle => 'Add 250 ml drinking water';
  @override
  String get quickActionStartFocus => 'Start Focus Session';
  @override
  String get quickActionStartFocusSubtitle => '25-minute pomodoro timer';
  @override
  String get quickActionLogExpenseSubtitle => 'Category, amount & wallet';
  @override
  String get quickActionLogIncomeSubtitle => 'Log new income';
  @override
  String get quickActionAddTaskSubtitle => 'Priority & due date';
  @override
  String get quickActionNewSecretNoteSubtitle => 'Encrypted in vault';

  // --- AI Assistant ---
  @override
  String get aiAssistantTitle => 'AI Assistant';
  @override
  String get aiAssistantSubtitle => 'Financial & productivity insights powered by Gemini';
  @override
  String get aiApiKeyLabel => 'Gemini API Key';
  @override
  String get aiApiKeyHint => 'Enter your Google AI Studio API key';
  @override
  String get aiApiKeySaved => 'API key saved successfully';
  @override
  String get aiApiKeyRemoved => 'API key removed';
  @override
  String get aiApiKeyTest => 'Test Connection';
  @override
  String get aiApiKeyTestSuccess => 'Connected! AI is ready to use.';
  @override
  String get aiApiKeyTestFail => 'Connection failed. Check your API key.';
  @override
  String get aiApiKeyNotSet => 'API key not set. Add it in Settings.';
  @override
  String get aiChatPlaceholder => 'Ask your AI assistant...';
  @override
  String get aiChatSend => 'Send';
  @override
  String get aiInsightTitle => 'AI Financial Insight';
  @override
  String get aiInsightLoading => 'Analyzing your finances...';
  @override
  String get aiInsightError => 'Could not load AI insight';
  @override
  String get aiCoachingTitle => 'Daily Coaching';

  // --- Cloud Sync ---
  @override
  String get cloudSyncTitle => 'Cloud Sync';
  @override
  String get cloudSyncSubtitle => 'Automatically back up data to Supabase';
  @override
  String get cloudSyncEnabled => 'Sync enabled';
  @override
  String get cloudSyncDisabled => 'Sync disabled';
  @override
  String get cloudSyncNow => 'Sync Now';
  @override
  String get cloudSyncSuccess => 'Data synced successfully';
  @override
  String get cloudSyncError => 'Sync failed. Try again later.';
  @override
  String get cloudSyncOffline => 'Offline — data saved locally';
  @override
  String get cloudSyncLastSynced => 'Last synced';
  @override
  String get cloudSyncNever => 'Never synced';

  // --- Life OS Branding ---
  @override
  String get appName => 'Life OS';
  @override
  String get appVersion => 'Version';
  @override
  String get appTaglineOs => 'Your Personal Operating System';
}

