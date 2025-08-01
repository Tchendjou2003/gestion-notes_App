# user/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin # Importe l'admin de base pour User de Django
from django.contrib.auth.models import User # Importe le modèle User par défaut de Django
from .models import Profile, Cours, Note, Speciality, Promotion # Importe tous vos modèles

# Inline pour le Profile : permet d'éditer le Profile directement depuis la page de modification du User
class ProfileInline(admin.StackedInline): # StackedInline affiche les champs verticalement
    model = Profile
    can_delete = False # Empêche la suppression du Profile sans supprimer le User parent
    verbose_name_plural = 'Profil Utilisateur' # Nom affiché dans l'administration

    # Organise les champs du Profile dans des fieldsets (groupes)
    fieldsets = (
        (None, {'fields': ('role',)}), # Le rôle est toujours visible
        ('Informations Étudiant', { # Ce groupe est pour les étudiants
            'fields': ('promotion',),
            'classes': ('collapse',), # Le groupe est replié par défaut
            'description': 'Ces champs sont pour les utilisateurs ayant le rôle "Étudiant".'
        }),
        ('Spécialités Assignées (Formateur)', { # Ce groupe est pour les formateurs
            'fields': ('assigned_specialities',),
            'classes': ('collapse',), # Le groupe est replié par défaut
            'description': 'Sélectionnez les spécialités que ce formateur est autorisé à enseigner.',
        }),
    )
    # raw_id_fields: Pour les champs ForeignKey/ManyToManyField (Speciality, Promotion),
    # cela remplace la liste déroulante par un champ d'entrée d'ID avec une loupe.
    # Utile si vous avez un grand nombre de spécialités/promotions pour éviter de charger toutes les options.
    raw_id_fields = ('promotion', 'assigned_specialities')


# Personnalisation de l'administration du modèle User de Django
class UserAdmin(BaseUserAdmin):
    inlines = (ProfileInline,) # Ajoute notre inline Profile à l'administration de User
    
    # Ajoute de nouvelles colonnes à la liste des utilisateurs dans l'admin
    # BaseUserAdmin.list_display contient les colonnes par défaut de User (username, email, first_name, last_name, is_staff, is_active)
    list_display = BaseUserAdmin.list_display + ('get_profile_role', 'get_profile_speciality', 'get_profile_promotion')
    
    # Ajoutez ces champs aux filtres de liste
    list_filter = BaseUserAdmin.list_filter + ('profile__role', 'profile__promotion__speciality', 'profile__promotion')

    # Optimisation pour éviter les problèmes de N+1 requêtes dans la liste des utilisateurs
    def get_queryset(self, request):
        queryset = super().get_queryset(request)
        # Utilise select_related pour joindre les tables Profile, Promotion et Speciality en une seule requête
        queryset = queryset.select_related('profile__promotion__speciality')
        return queryset

    # Fonctions pour récupérer les données du profil lié et les afficher comme des colonnes
    def get_profile_role(self, obj):
        # Vérifie si l'utilisateur a un profil pour éviter les erreurs
        return obj.profile.get_role_display() if hasattr(obj, 'profile') else 'N/A'
    get_profile_role.short_description = 'Rôle' # Nom de la colonne dans l'admin

    def get_profile_speciality(self, obj):
        if hasattr(obj, 'profile') and obj.profile.promotion and obj.profile.promotion.speciality:
            return obj.profile.promotion.speciality.name
        return 'N/A'
    get_profile_speciality.short_description = 'Spécialité'

    def get_profile_promotion(self, obj):
        if hasattr(obj, 'profile') and obj.profile.promotion: # La jointure est déjà faite par get_queryset
            return obj.profile.promotion.name
        return 'N/A'
    get_profile_promotion.short_description = 'Promotion'

# Désenregistre le modèle User par défaut de l'admin et réenregistre notre version personnalisée
# C'est nécessaire pour appliquer notre `UserAdmin` personnalisé.
admin.site.unregister(User)
admin.site.register(User, UserAdmin)

# Personnalisation de l'administration du modèle Profile
# L'enregistrement de Profile est nécessaire pour que les popups de sélection
# (raw_id_fields ou autocomplete_fields) fonctionnent sur les autres modèles
# qui ont une ForeignKey vers Profile (ex: Cours, Note).
@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'role', 'promotion')
    list_filter = ('role', 'promotion__speciality', 'promotion')
    # Les champs de recherche sur le modèle User lié sont essentiels pour la recherche
    search_fields = ('user__username', 'user__first_name', 'user__last_name', 'user__email')
    raw_id_fields = ('user', 'promotion', 'assigned_specialities')


# Personnalisation de l'administration du modèle Cours
@admin.register(Cours) # Décorateur pour enregistrer le modèle dans l'admin
class CoursAdmin(admin.ModelAdmin):
    list_display = ('nom', 'formateur', 'speciality', 'promotion', 'description_courte') # Colonnes affichées
    list_filter = ('speciality', 'promotion', 'formateur__user__username') # Filtres sur la droite
    search_fields = ('nom', 'description', 'formateur__user__username', 'speciality__name', 'promotion__name') # Champs de recherche
    # Remplacer raw_id_fields par autocomplete_fields pour une meilleure expérience utilisateur.
    # Cela nécessite que les ModelAdmins pour Profile, Speciality et Promotion aient des `search_fields` définis.
    autocomplete_fields = ('formateur', 'speciality', 'promotion')

    # Fonction pour afficher une description courte dans la liste (pour ne pas surcharger l'affichage)
    def description_courte(self, obj):
        return (obj.description[:75] + '...') if obj.description and len(obj.description) > 75 else (obj.description or '')
    description_courte.short_description = 'Description' # Nom de la colonne


# Personnalisation de l'administration du modèle Note
@admin.register(Note)
class NoteAdmin(admin.ModelAdmin):
    list_display = ('etudiant', 'cours', 'valeur', 'date_publication', 'publie_par')
    # Filtres avancés incluant les relations (permet de filtrer par la spécialité de l'étudiant, par exemple)
    list_filter = (
        'cours__nom', 'etudiant__user__username', 'publie_par__user__username', 'etudiant__promotion__name',
        'etudiant__promotion__speciality__name', # Filtres par spécialité/promotion de l'étudiant
        'cours__speciality__name', 'cours__promotion__name'        # Filtres par spécialité/promotion du cours
    )
    search_fields = (
        'etudiant__user__username', 'cours__nom', 'publie_par__user__username',
        'valeur'
    )
    date_hierarchy = 'date_publication' # Ajoute une navigation par date en haut
    # Remplacer raw_id_fields par autocomplete_fields pour une meilleure expérience utilisateur.
    # Cela nécessite que les ModelAdmins pour Profile et Cours aient des `search_fields` définis.
    autocomplete_fields = ('etudiant', 'cours', 'publie_par')


# Personnalisation de l'administration du modèle Speciality
@admin.register(Speciality)
class SpecialityAdmin(admin.ModelAdmin):
    list_display = ('name', 'description')
    search_fields = ('name',) # Permet de rechercher par nom


# Personnalisation de l'administration du modèle Promotion
@admin.register(Promotion)
class PromotionAdmin(admin.ModelAdmin):
    list_display = ('name', 'year', 'speciality')
    list_filter = ('speciality', 'year',) # Filtres par spécialité et année
    search_fields = ('name', 'year',)
    raw_id_fields = ('speciality',) # Utiliser raw_id_fields si beaucoup de spécialités