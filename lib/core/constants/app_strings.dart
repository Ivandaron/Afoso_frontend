/// Toutes les chaînes UI de l'application AFOSO
/// Centralise les textes pour faciliter les traductions futures.
class AppStrings {
  AppStrings._();

  // ── APP ──────────────────────────────────────────────────────────────────
  static const String appName = 'AFOSO';
  static const String appTagline = 'Microfinance solidaire';

  // ── AUTH ─────────────────────────────────────────────────────────────────
  static const String login = 'Connexion';
  static const String loginTitle = 'Bon retour 👋';
  static const String loginSubtitle = 'Connectez-vous à votre compte AFOSO';
  static const String phoneLabel = 'Numéro de téléphone';
  static const String phonePlaceholder = '6XX XXX XXX';
  static const String passwordLabel = 'Mot de passe';
  static const String passwordPlaceholder = '••••••••';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String loginButton = 'Se connecter';
  static const String noAccount = 'Pas encore membre ?';
  static const String register = 'S\'inscrire';
  static const String logout = 'Se déconnecter';
  static const String logoutConfirm = 'Voulez-vous vous déconnecter ?';

  // ── REGISTER ─────────────────────────────────────────────────────────────
  static const String registerTitle = 'Créer un compte';
  static const String registerSubtitle = 'Rejoignez la communauté AFOSO';
  static const String firstNameLabel = 'Prénom';
  static const String lastNameLabel = 'Nom';
  static const String emailLabel = 'Email';
  static const String cityLabel = 'Ville';
  static const String addressLabel = 'Adresse';
  static const String birthDateLabel = 'Date de naissance';
  static const String paymentMethodLabel = 'Méthode de paiement';
  static const String paymentPhoneLabel = 'Numéro Mobile Money';
  static const String registrationFee = 'Frais d\'inscription : 5 000 FCFA';
  static const String registerButton = 'Créer mon compte';
  static const String alreadyAccount = 'Déjà membre ?';

  // ── NAVIGATION MEMBRE ─────────────────────────────────────────────────────
  static const String navHome = 'Accueil';
  static const String navDeposit = 'Cotisation';
  static const String navSolidarity = 'Solidarité';
  static const String navProfile = 'Profil';

  // ── NAVIGATION ADMIN ──────────────────────────────────────────────────────
  static const String navDashboard = 'Dashboard';
  static const String navRegistrations = 'Inscriptions';
  static const String navMembers = 'Membres';
  static const String navFunds = 'Cagnottes';

  // ── DASHBOARD MEMBRE ──────────────────────────────────────────────────────
  static const String greetingMorning = 'Bonjour';
  static const String greetingAfternoon = 'Bon après-midi';
  static const String greetingEvening = 'Bonsoir';
  static const String totalSaved = 'Total épargné';
  static const String currentMonth = 'Ce mois';
  static const String previousMonth = 'Mois précédent';
  static const String myDeposits = 'Mes cotisations';
  static const String seeAll = 'Voir tout';
  static const String noDepositsYet = 'Aucune cotisation pour l\'instant';
  static const String firstDeposit = 'Effectuer ma première cotisation';

  // ── DÉPÔTS ────────────────────────────────────────────────────────────────
  static const String newDeposit = 'Nouvelle cotisation';
  static const String depositHistory = 'Historique';
  static const String amountLabel = 'Montant (FCFA)';
  static const String amountPlaceholder = 'Ex: 5000';
  static const String initiatePayment = 'Initier le paiement';
  static const String depositSuccess = 'Dépôt initié avec succès';
  static const String transactionRef = 'Référence de transaction';
  static const String paymentConfirmInfo =
      'Confirme le paiement sur ton téléphone, puis reviens vérifier le statut.';
  static const String understood = 'Compris, je vais confirmer';

  // ── SOLIDARITÉ ────────────────────────────────────────────────────────────
  static const String activeFund = 'Cagnotte active';
  static const String fundHistory = 'Historique';
  static const String noActiveFund = 'Pas de cagnotte active';
  static const String noActiveFundDesc =
      'Aucune cagnotte solidaire n\'est ouverte pour le moment.';
  static const String beneficiary = 'Bénéficiaire';
  static const String targetAmount = 'Objectif';
  static const String collectedAmount = 'Collecté';
  static const String contributionAmount = 'Contribution fixe';
  static const String contribute = 'Contribuer';
  static const String contributionSuccess = 'Contribution envoyée ! 🎉';
  static const String alreadyContributed = 'Vous avez déjà contribué';

  // ── PROFIL ────────────────────────────────────────────────────────────────
  static const String myProfile = 'Mon profil';
  static const String changePassword = 'Changer le mot de passe';
  static const String oldPassword = 'Mot de passe actuel';
  static const String newPassword = 'Nouveau mot de passe';
  static const String confirmPassword = 'Confirmer le nouveau';
  static const String updatePassword = 'Modifier le mot de passe';
  static const String passwordUpdated = 'Mot de passe modifié avec succès 🔒';
  static const String balance = 'Solde';
  static const String totalEpargne = 'Total épargne';
  static const String transactions = 'Transactions';

  // ── ADMIN DASHBOARD ───────────────────────────────────────────────────────
  static const String dashboard = 'Tableau de bord';
  static const String totalDeposits = 'Épargne totale';
  static const String activeMembers = 'Membres actifs';
  static const String pendingRegistrations = 'Inscriptions en attente';
  static const String failedTransactions = 'Transactions échouées';
  static const String pendingRegistrationsSection = 'Inscriptions en attente';
  static const String approve = 'Approuver';
  static const String reject = 'Rejeter';
  static const String rejectReason = 'Motif du rejet (obligatoire)';
  static const String approveSuccess = '✅ Inscription approuvée !';
  static const String rejectSuccess = 'Inscription rejetée';

  // ── ADMIN MEMBRES ─────────────────────────────────────────────────────────
  static const String membersManagement = 'Gestion des membres';
  static const String searchMembers =
      'Rechercher par nom, matricule, téléphone…';
  static const String activateAccount = 'Activer le compte';
  static const String deactivateAccount = 'Désactiver le compte';
  static const String activate = 'Activer';
  static const String deactivate = 'Désactiver';

  // ── ADMIN CAGNOTTES ───────────────────────────────────────────────────────
  static const String manageFunds = 'Cagnottes solidaires';
  static const String createFund = 'Créer une cagnotte';
  static const String closeFund = 'Fermer la cagnotte';
  static const String fundTitle = 'Titre de la cagnotte';
  static const String fundDescription = 'Description';
  static const String fundTargetAmount = 'Objectif (FCFA)';
  static const String fundContributionAmount = 'Cotisation par membre (FCFA)';
  static const String beneficiaryName = 'Nom du bénéficiaire';
  static const String beneficiaryReason = 'Raison / Contexte (facultatif)';
  static const String createFundButton = 'Créer la cagnotte';
  static const String closeFundConfirm =
      'Confirmer la fermeture de cette cagnotte ?';
  static const String closeFundSuccess = 'Cagnotte fermée avec succès';

  // ── STATUTS ───────────────────────────────────────────────────────────────
  static const String statusActive = 'Actif';
  static const String statusInactive = 'Inactif';
  static const String statusPending = 'En attente';
  static const String statusSuspended = 'Suspendu';
  static const String statusPaid = 'Payé';
  static const String statusFailed = 'Échoué';
  static const String statusClosed = 'Fermée';

  // ── ERREURS & GÉNÉRIQUES ──────────────────────────────────────────────────
  static const String error = 'Erreur';
  static const String retry = 'Réessayer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String save = 'Enregistrer';
  static const String loading = 'Chargement…';
  static const String loadError = 'Impossible de charger les données';
  static const String networkError = 'Vérifiez votre connexion internet';
  static const String sessionExpired =
      'Votre session a expiré, veuillez vous reconnecter';
  static const String fieldRequired = 'Ce champ est requis';
  static const String invalidPhone =
      'Numéro de téléphone invalide (9 chiffres)';
  static const String invalidEmail = 'Adresse email invalide';
  static const String passwordTooShort =
      'Minimum 8 caractères, 1 majuscule, 1 chiffre';
  static const String passwordMismatch =
      'Les mots de passe ne correspondent pas';

  // ── MÉTHODES DE PAIEMENT ──────────────────────────────────────────────────
  static const String orangeMoney = 'Orange Money';
  static const String mtnMoney = 'MTN Money';
  static const String moovMoney = 'Moov Money';
}
