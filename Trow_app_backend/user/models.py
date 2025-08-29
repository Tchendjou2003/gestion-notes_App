# user/models.py

from django.conf import settings
from django.db import models

# Modèle pour la Spécialité (ex: "Développement Web", "Réseaux et Sécurité")
# C'est une entité indépendante qui peut être créée, lue, modifiée, supprimée par l'administrateur.
class Speciality(models.Model):
    name = models.CharField(max_length=100, unique=True, verbose_name="Nom de la Spécialité")
    description = models.TextField(blank=True, null=True, verbose_name="Description de la Spécialité")

    # Meta est une classe interne qui fournit des options au modèle
    class Meta:
        verbose_name_plural = "Spécialités" # Nom convivial affiché dans l'administration Django
        ordering = ['name'] # Tri par défaut des enregistrements par nom

    def __str__(self):
        # Représentation en chaîne de caractères de l'objet, utile pour le débogage et l'admin
        return self.name

# Modèle pour la Promotion (ex: "Promo 2025 Développeurs", "L3 Info 2024")
# Une promotion est liée à une spécialité.
class Promotion(models.Model):
    name = models.CharField(max_length=100, verbose_name="Nom de la Promotion")
    year = models.IntegerField(verbose_name="Année de la Promotion") # Ex: 2025

    # Liaison à la Speciality : ForeignKey indique une relation plusieurs-à-un (plusieurs promotions pour une spécialité)
    # on_delete=models.CASCADE signifie que si la Speciality parente est supprimée, toutes les Promotions associées le sont aussi.
    speciality = models.ForeignKey(
        Speciality,
        on_delete=models.CASCADE,
        related_name='promotions', # Nom pour la relation inverse (permet d'accéder aux promotions depuis une spécialité : speciality.promotions.all())
        verbose_name="Spécialité associée"
    )

    class Meta:
        verbose_name_plural = "Promotions"
        # Combine ces champs pour s'assurer qu'une promotion avec le même nom n'existe qu'une seule fois par spécialité.
        unique_together = ('name', 'speciality')
        ordering = ['year', 'name']

    def __str__(self):
        return f"{self.name} ({self.year}) - {self.speciality.name}"


# Modèle Profile : étend le modèle User par défaut de Django
# C'est une bonne pratique de créer un modèle Profile lié à User plutôt que de modifier User directement.
# Cela nous permet d'ajouter des champs personnalisés (rôle, spécialité, etc.) sans "casser" les fonctionnalités de Django.
class Profile(models.Model):
    # Utilisation de TextChoices pour une meilleure lisibilité et maintenabilité
    class Roles(models.TextChoices):
        ETUDIANT = 'etudiant', 'Étudiant'
        FORMATEUR = 'formateur', 'Formateur'
        ADMIN = 'admin', 'Administrateur'

    # Relation un-à-un avec le modèle User de Django. Chaque User aura un seul Profile et vice-versa.
    # on_delete=models.CASCADE : si un User est supprimé, son Profile l'est aussi.
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='profile' # Permet d'accéder au Profile depuis un User via user.profile
    )
    # Champ pour le rôle de l'utilisateur
    role = models.CharField(
        max_length=10,
        choices=Roles.choices, # Les valeurs sont limitées aux options définies dans Roles
        default=Roles.ETUDIANT # Rôle par défaut si non spécifié
    )
    
    # Pour les étudiants : la Promotion à laquelle ils appartiennent. La spécialité est déduite de la promotion.
    # null=True et blank=True : Ces champs sont optionnels (ne s'appliquent qu'aux étudiants).
    # on_delete=models.SET_NULL : Si la Promotion est supprimée, ce champ devient NULL (ne supprime pas le profil de l'étudiant).
    promotion = models.ForeignKey(
        Promotion,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='etudiants_profiles', # Relation inverse
        verbose_name="Promotion (pour étudiant)"
    )

    # Pour les formateurs : les Spécialités qu'ils sont assignés à enseigner
    # ManyToManyField : un formateur peut être assigné à plusieurs spécialités, et une spécialité peut avoir plusieurs formateurs.
    # blank=True signifie que ce champ n'est pas obligatoire (un formateur peut ne pas avoir de spécialité assignée au début).
    assigned_specialities = models.ManyToManyField(
        Speciality,
        blank=True,
        related_name='assigned_formateurs', # Relation inverse
        verbose_name="Spécialités assignées (pour formateur)"
    )

    class Meta:
        verbose_name_plural = "Profils" # Nom affiché dans l'administration Django

    def __str__(self):
        # Représentation plus informative de l'objet Profile pour le débogage et l'administration
        role_display = self.get_role_display() # Méthode auto-générée par Django pour afficher la valeur "humaine" du choix
        if self.role == self.Roles.ETUDIANT and self.promotion:
            # La spécialité est accessible via la promotion pour garantir la cohérence
            return f"{self.user.username} ({role_display}) - {self.promotion.speciality.name} {self.promotion.name}"
        elif self.role == self.Roles.FORMATEUR:
            # Affiche les noms des spécialités assignées au formateur
            # Attention : ceci peut causer des requêtes N+1 dans l'admin. Utiliser prefetch_related dans le ModelAdmin.
            assigned_names = ", ".join([s.name for s in self.assigned_specialities.all()])
            if assigned_names:
                return f"{self.user.username} ({role_display}) - Spécialités: {assigned_names}"
        return f"{self.user.username} ({role_display})"


# Modèle Cours : représente un cours donné
class Cours(models.Model):
    nom = models.CharField(
        max_length=100,
        unique=True, # Le nom du cours doit être unique
        verbose_name="Nom du Cours"
    )
    description = models.TextField(
        blank=True, null=True, # La description est optionnelle
        verbose_name="Description Détaillée"
    )
    # Liaison au formateur : un formateur peut enseigner plusieurs cours.
    # limit_choices_to={'role': 'formateur'} : limite les choix de formateurs dans l'admin et les APIs.
    formateur = models.ForeignKey(
        Profile,
        on_delete=models.SET_NULL, # Si le Profile du formateur est supprimé, ce champ devient NULL
        null=True, blank=True,
        limit_choices_to={'role': 'formateur'},
        related_name='cours_enseignes', # Relation inverse
        verbose_name="Formateur Associé"
    )
    
    # Liaison du cours à une Spécialité et/ou une Promotion
    # null=True, blank=True : Un cours peut ne pas être directement lié à une spécialité ou promotion spécifique
    speciality = models.ForeignKey(
        Speciality,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='cours',
        verbose_name="Spécialité du Cours"
    )
    promotion = models.ForeignKey(
        Promotion,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name='cours',
        verbose_name="Promotion du Cours"
    )

    class Meta:
        verbose_name_plural = "Cours"
        ordering = ['nom'] # Tri par défaut par nom de cours

    def __str__(self):
        s_name = f" ({self.speciality.name})" if self.speciality else ""
        p_name = f" ({self.promotion.name})" if self.promotion else ""
        return f"{self.nom}{s_name}{p_name}"


# Modèle Note : représente une note donnée à un étudiant pour un cours
class Note(models.Model):
    # Liaison à l'étudiant : un étudiant peut avoir plusieurs notes.
    # limit_choices_to={'role': 'etudiant'} : limite les choix aux profils d'étudiants.
    etudiant = models.ForeignKey(
        Profile,
        on_delete=models.CASCADE, # Si le Profile de l'étudiant est supprimé, ses notes le sont aussi
        limit_choices_to={'role': 'etudiant'},
        related_name='notes_recues', # Relation inverse
        verbose_name="Étudiant"
    )
    # Liaison au cours : un cours peut avoir plusieurs notes.
    cours = models.ForeignKey(
        Cours,
        on_delete=models.CASCADE, # Si le Cours est supprimé, les notes associées le sont aussi
        related_name='notes_du_cours', # Relation inverse
        verbose_name="Cours"
    )
    valeur = models.DecimalField(
        max_digits=5, # Nombre total de chiffres (ex: 100.00 ou 15.75)
        decimal_places=2, # Nombre de chiffres après la virgule (ex: .00, .25, .50, .75)
        verbose_name="Valeur de la Note",
        help_text="Valeur numérique de la note (ex: 15.75)"
    )
    date_publication = models.DateTimeField(
        auto_now_add=True, # Rempli automatiquement à la création de l'objet Note
        verbose_name="Date de Publication",
        help_text="Date et heure auxquelles la note a été publiée"
    )
    # Celui qui a publié la note (généralement un formateur ou un admin)
    publie_par = models.ForeignKey(
        Profile,
        on_delete=models.SET_NULL, # Si le Profile du publicateur est supprimé, ce champ devient NULL
        null=True, blank=True, # Optionnel
        limit_choices_to={'role__in': ['formateur', 'admin']}, # Limite les choix aux formateurs et admins
        related_name='notes_publiees', # Relation inverse
        verbose_name="Publiée Par"
    )

    class Meta:
        # Assure qu'un étudiant n'a qu'une seule note par cours (contrainte d'unicité)
        unique_together = ('etudiant', 'cours')
        ordering = ['-date_publication'] # Tri par défaut par date de publication décroissante
        verbose_name_plural = "Notes"

    def __str__(self):
        return f"Note de {self.etudiant.user.username} ({self.valeur}) pour {self.cours.nom}"