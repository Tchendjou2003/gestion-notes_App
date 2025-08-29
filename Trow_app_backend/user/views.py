# user/views.py

from rest_framework import viewsets, status, permissions
from rest_framework.response import Response
from rest_framework.decorators import action # Permet d'ajouter des actions personnalisées aux ViewSets
from django.db.models import Q # Pour construire des requêtes complexes avec des conditions OR
from django.http import HttpResponse # Pour générer des réponses HTTP pour les fichiers (CSV)
import csv # Bibliothèque Python pour lire et écrire des fichiers CSV
from datetime import datetime # Pour générer des noms de fichiers basés sur la date/heure
from django.http import Http404

from .models import Profile, Cours, Note, Speciality, Promotion
from .serializers import (
    ProfileSerializer, RegisterSerializer, UserSerializer, CoursSerializer, NoteSerializer,
    SpecialitySerializer, PromotionSerializer
)

# --- Classes de Permissions Personnalisées ---
# DRF utilise des classes de permission pour contrôler l'accès aux API.
# Ces classes définissent qui peut faire quoi en fonction de leur rôle.

class IsAdmin(permissions.BasePermission):
    """
    Permet l'accès uniquement aux utilisateurs ayant le rôle 'admin'.
    """
    message = "Seuls les administrateurs ont la permission d'effectuer cette action."
    def has_permission(self, request, view):
        # Vérifie si l'utilisateur est authentifié et si son profil a le rôle 'admin'
        return request.user.is_authenticated and \
               hasattr(request.user, 'profile') and \
               request.user.profile.role == Profile.Roles.ADMIN

class IsTrainer(permissions.BasePermission):
    """
    Permet l'accès uniquement aux utilisateurs ayant le rôle 'formateur'.
    """
    message = "Seuls les formateurs ont la permission d'effectuer cette action."
    def has_permission(self, request, view):
        return request.user.is_authenticated and \
               hasattr(request.user, 'profile') and \
               request.user.profile.role == Profile.Roles.FORMATEUR

class IsAdminOrTrainer(permissions.BasePermission):
    """
    Permet l'accès uniquement aux utilisateurs ayant le rôle 'admin' ou 'formateur'.
    """
    message = "Seuls les administrateurs ou les formateurs ont la permission d'effectuer cette action."
    def has_permission(self, request, view):
        return request.user.is_authenticated and \
               hasattr(request.user, 'profile') and \
               request.user.profile.role in [Profile.Roles.ADMIN, Profile.Roles.FORMATEUR]

# --- ViewSets pour les entités Spécialité, Promotion, Profil, Cours, Note ---

class AdminWriteIsAuthenticatedReadViewSet(viewsets.ModelViewSet):
    """
    Un ViewSet de base qui autorise la lecture pour tout utilisateur authentifié
    et l'écriture uniquement pour les administrateurs.
    """
    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            permission_classes = [permissions.IsAuthenticated]
        else:
            permission_classes = [IsAdmin]
        return [permission() for permission in permission_classes]

# ViewSet pour la gestion des Spécialités (/api/specialities/)
class SpecialityViewSet(AdminWriteIsAuthenticatedReadViewSet):
    queryset = Speciality.objects.all() # Requête de base pour récupérer toutes les spécialités
    serializer_class = SpecialitySerializer # Sérialiseur à utiliser pour cette vue

# ViewSet pour la gestion des Promotions (/api/promotions/)
class PromotionViewSet(AdminWriteIsAuthenticatedReadViewSet):
    queryset = Promotion.objects.all()
    serializer_class = PromotionSerializer

# ViewSet pour la gestion des Profils utilisateurs (/api/profiles/)
class UserProfileViewSet(viewsets.ModelViewSet):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer

    def get_permissions(self):
        # La permission varie selon l'action demandée
        if self.action == 'register':
            # L'inscription est accessible à tous (même non authentifiés)
            permission_classes = [permissions.AllowAny]
        elif self.action in ['list', 'create', 'update', 'partial_update', 'destroy']:
            # Seuls les administrateurs peuvent lister tous les profils, créer d'autres rôles, les modifier ou les supprimer.
            permission_classes = [IsAdmin]
        elif self.action == 'retrieve':
            # Voir un profil spécifique : tout utilisateur authentifié peut le faire, la logique de restriction est dans `retrieve`
            permission_classes = [permissions.IsAuthenticated]
        else:
            permission_classes = [permissions.IsAuthenticated] # Par défaut, authentification requise
        return [permission() for permission in permission_classes]

    # Action personnalisée pour l'inscription d'un nouvel utilisateur
    # Accessible via POST /api/profiles/register/
    @action(detail=False, methods=['post'], permission_classes=[permissions.AllowAny])
    def register(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True) # Lève une erreur 400 si les données ne sont pas valides
        user = serializer.save() # Appelle la méthode `create` du RegisterSerializer pour créer User et Profile
        # Retourne une réponse avec les informations de l'utilisateur créé (sans le mot de passe)
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)

    # Surcharge de la méthode 'retrieve' pour contrôler qui peut voir quel profil
    # Un utilisateur ne peut voir que son propre profil, sauf si c'est un administrateur.
    def retrieve(self, request, pk=None):
        try:
            profile = self.get_object() # Tente de récupérer le profil par son ID
        except Http404:
            return Response({"detail": "Profil non trouvé."}, status=status.HTTP_404_NOT_FOUND)

        # Si l'utilisateur est admin, ou si c'est son propre profil, alors il peut le voir
        if request.user.profile.role == Profile.Roles.ADMIN or profile == request.user.profile:
            serializer = self.get_serializer(profile)
            return Response(serializer.data)
        
        # Sinon, accès refusé
        return Response({"detail": "Vous n'avez pas la permission de voir ce profil."}, status=status.HTTP_403_FORBIDDEN)

    # Surcharge de la méthode 'create' (pour les admins uniquement) pour utiliser le RegisterSerializer
    # Un admin peut créer n'importe quel type d'utilisateur
    def create(self, request, *args, **kwargs):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save() # Création de l'utilisateur et de son profil par l'admin
        return Response(UserSerializer(user).data, status=status.HTTP_201_CREATED)

# ViewSet pour la gestion des Cours (/api/courses/)
class CoursViewSet(viewsets.ModelViewSet):
    queryset = Cours.objects.all()
    serializer_class = CoursSerializer

    # Surcharge de get_queryset pour filtrer les cours visibles en fonction du rôle de l'utilisateur.
    # C'est une logique d'autorisation au niveau de l'objet.
    def get_queryset(self):
        user_profile = self.request.user.profile
        queryset = Cours.objects.select_related('formateur__user', 'speciality', 'promotion')

        if user_profile.role == Profile.Roles.FORMATEUR:
            # Un formateur peut voir :
            # 1. Les cours qu'il est désigné comme formateur principal (`formateur=user_profile`)
            # OU
            # 2. Les cours qui appartiennent à n'importe quelle spécialité à laquelle il est assigné (`speciality__in=user_profile.assigned_specialities.all()`)
            return queryset.filter(
                Q(formateur=user_profile) | Q(speciality__in=user_profile.assigned_specialities.all())
            ).distinct() # `distinct()` pour éviter les doublons si un cours correspond aux deux conditions
        elif user_profile.role == Profile.Roles.ETUDIANT:
            # Un étudiant ne peut voir que les cours de SA promotion OU de SA spécialité
            if user_profile.promotion:
                return queryset.filter(
                    Q(promotion=user_profile.promotion) | Q(speciality=user_profile.promotion.speciality)
                ).distinct()
            return Cours.objects.none()
        elif user_profile.role == Profile.Roles.ADMIN:
            # Un administrateur voit tous les cours
            return queryset.all()
        return Cours.objects.none() # Si le rôle n'est pas reconnu (ou pas authentifié), retourne un queryset vide

    def get_permissions(self):
        # Définition des permissions par action
        if self.action in ['list', 'retrieve']:
            permission_classes = [permissions.IsAuthenticated] # Tous les rôles authentifiés peuvent lister/voir les détails
        elif self.action in ['create', 'update', 'partial_update', 'destroy']:
            permission_classes = [IsAdminOrTrainer] # Seuls les admins et formateurs peuvent créer/modifier/supprimer
        else:
            permission_classes = [permissions.IsAuthenticated] # Default
        return [permission() for permission in permission_classes]

    def _check_trainer_course_permission(self, user_profile, course):
        """Vérifie si un formateur a la permission de modifier/supprimer un cours."""
        is_main_trainer = course.formateur == user_profile
        is_in_assigned_speciality = (
            course.speciality and
            course.speciality in user_profile.assigned_specialities.all()
        )
        if not (is_main_trainer or is_in_assigned_speciality):
            raise permissions.PermissionDenied("Vous ne pouvez agir que sur les cours que vous enseignez ou ceux de vos spécialités assignées.")

    # Logique exécutée juste avant la sauvegarde lors de la création d'un cours
    def perform_create(self, serializer):
        user_profile = self.request.user.profile

        if user_profile.role == Profile.Roles.FORMATEUR:
            # Si c'est un formateur qui crée le cours, il est automatiquement assigné comme formateur du cours.
            # ET on vérifie que la `speciality` spécifiée pour le cours est bien parmi les `assigned_specialities` du formateur.
            speciality_for_course = serializer.validated_data.get('speciality')
            if speciality_for_course and speciality_for_course not in user_profile.assigned_specialities.all():
                raise permissions.PermissionDenied("Vous ne pouvez créer de cours que pour les spécialités auxquelles vous êtes assigné en tant que formateur.")
            serializer.save(formateur=user_profile) # Assigne le formateur connecté comme formateur du cours
        elif user_profile.role == Profile.Roles.ADMIN:
            # Un admin peut créer un cours sans restriction et peut spécifier n'importe quel formateur (ou aucun)
            serializer.save()
        else:
            # Cette branche ne devrait normalement pas être atteinte si les permissions sont bien configurées
            raise permissions.PermissionDenied("Vous n'êtes pas autorisé à créer des cours.")

    # Logique exécutée juste avant la sauvegarde lors de la mise à jour d'un cours
    def perform_update(self, serializer):
        instance = self.get_object() # Le cours que l'on tente de modifier
        user_profile = self.request.user.profile

        if user_profile.role == Profile.Roles.FORMATEUR:
            self._check_trainer_course_permission(user_profile, instance)

            # Si le formateur essaie de changer la spécialité ou la promotion d'un cours existant,
            # on s'assure que la nouvelle spécialité fait toujours partie de ses spécialités assignées.
            new_speciality = serializer.validated_data.get('speciality')
            if new_speciality and new_speciality != instance.speciality and new_speciality not in user_profile.assigned_specialities.all():
                 raise permissions.PermissionDenied("Vous ne pouvez modifier un cours pour une spécialité qui ne vous est pas assignée.")

        serializer.save()

    # Logique exécutée juste avant la suppression d'un cours
    def perform_destroy(self, instance):
        user_profile = self.request.user.profile
        if user_profile.role == Profile.Roles.FORMATEUR:
            self._check_trainer_course_permission(user_profile, instance)
        instance.delete()


# ViewSet pour la gestion des Notes (/api/grades/)
class NoteViewSet(viewsets.ModelViewSet):
    queryset = Note.objects.all()
    serializer_class = NoteSerializer

    # Surcharge de get_queryset pour filtrer les notes visibles en fonction du rôle de l'utilisateur.
    def get_queryset(self):
        user_profile = self.request.user.profile
        queryset = Note.objects.select_related(
            'etudiant__user', 'cours', 'publie_par__user', 'cours__speciality'
        )

        if user_profile.role == Profile.Roles.ETUDIANT:
            # Un étudiant ne voit que SES propres notes.
            return queryset.filter(etudiant=user_profile)
        elif user_profile.role == Profile.Roles.FORMATEUR:
            # Un formateur peut voir :
            # 1. Les notes des cours qu'il enseigne (`cours__formateur=user_profile`)
            # OU
            # 2. Les notes des cours qui appartiennent à ses spécialités assignées (`cours__speciality__in=user_profile.assigned_specialities.all()`)
            # OU
            # 3. Les notes qu'il a publiées lui-même (`publie_par=user_profile`)
            return queryset.filter(
                Q(cours__formateur=user_profile) |
                Q(cours__speciality__in=user_profile.assigned_specialities.all()) |
                Q(publie_par=user_profile)
            ).distinct()
        elif user_profile.role == Profile.Roles.ADMIN:
            # Un administrateur voit toutes les notes.
            return queryset.all()

        return Note.objects.none() # Par défaut, aucun accès

    def get_permissions(self):
        # Définition des permissions par action
        if self.action == 'create':
            permission_classes = [IsTrainer] # Seuls les formateurs peuvent créer des notes
        elif self.action in ['update', 'partial_update', 'destroy']:
            permission_classes = [IsAdminOrTrainer] # Admins et formateurs peuvent modifier/supprimer
        elif self.action in ['list', 'retrieve']:
            permission_classes = [permissions.IsAuthenticated] # Tous les rôles authentifiés peuvent lister/voir
        elif self.action == 'export_csv':
            # Pour l'export CSV, on a une logique spécifique dans la méthode elle-même
            permission_classes = [permissions.IsAuthenticated] 
        else:
            permission_classes = [permissions.IsAuthenticated] # Default
        return [permission() for permission in permission_classes]

    def _check_trainer_note_permission(self, user_profile, note):
        """Vérifie si un formateur a la permission de modifier/supprimer une note."""
        cours_obj = note.cours
        is_main_trainer = cours_obj.formateur == user_profile
        is_in_assigned_speciality = (
            cours_obj.speciality and
            cours_obj.speciality in user_profile.assigned_specialities.all()
        )
        if not (is_main_trainer or is_in_assigned_speciality):
            raise permissions.PermissionDenied("Vous ne pouvez agir que sur les notes des cours que vous enseignez ou de vos spécialités assignées.")

    # Logique exécutée juste avant la sauvegarde lors de la création d'une note
    def perform_create(self, serializer):
        cours_obj = serializer.validated_data['cours'] # Le cours pour lequel la note est attribuée
        user_profile = self.request.user.profile

        if user_profile.role == Profile.Roles.FORMATEUR:
            self._check_trainer_note_permission(user_profile, Note(cours=cours_obj))

        # Le formateur connecté (ou l'admin) est automatiquement défini comme 'publie_par'
        serializer.save(publie_par=user_profile)

    # Logique exécutée juste avant la sauvegarde lors de la mise à jour d'une note
    def perform_update(self, serializer):
        instance = self.get_object() # La note que l'on tente de modifier
        if self.request.user.profile.role == Profile.Roles.FORMATEUR:
            self._check_trainer_note_permission(self.request.user.profile, instance)
        serializer.save()

    # Logique exécutée juste avant la suppression d'une note
    def perform_destroy(self, instance):
        if self.request.user.profile.role == Profile.Roles.FORMATEUR:
            self._check_trainer_note_permission(self.request.user.profile, instance)
        instance.delete()

    # Action personnalisée pour exporter les notes au format CSV
    # Accessible via GET /api/grades/export_csv/
    @action(detail=False, methods=['get'])
    def export_csv(self, request):
        user_profile = request.user.profile

        # Déterminez le queryset de notes que l'utilisateur a le droit d'exporter
        # On réutilise la logique de get_queryset pour la cohérence
        notes_to_export = self.get_queryset()

        # Optimisation pour éviter les requêtes N+1 lors de la génération du CSV
        notes = notes_to_export.select_related(
            'etudiant__user',
            'etudiant__promotion__speciality',
            'cours__speciality',
            'publie_par__user'
        )

        if not notes.exists() and user_profile.role != Profile.Roles.ADMIN:
             return Response({"detail": "Vous n'êtes pas autorisé à exporter des notes ou il n'y a aucune note à exporter."}, status=status.HTTP_403_FORBIDDEN)

        # Prépare la réponse HTTP pour un fichier CSV
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        # Définit le nom du fichier qui sera téléchargé
        response['Content-Disposition'] = f'attachment; filename="notes_{datetime.now().strftime("%Y%m%d_%H%M%S")}.csv"'
        
        writer = csv.writer(response)
        # Écrit l'en-tête du CSV (noms des colonnes)
        writer.writerow([
            'Nom Etudiant', 'Cours', 'Note', 'Date Publication', 'Publie Par',
            'Specialite Etudiant', 'Promotion Etudiant', 'Specialite Cours'
        ])
        
        # Itère sur les notes et écrit chaque ligne dans le CSV
        for note in notes:
            etudiant_profile = note.etudiant
            cours_obj = note.cours
            etudiant_speciality_name = etudiant_profile.promotion.speciality.name if etudiant_profile.promotion and etudiant_profile.promotion.speciality else 'N/A'

            writer.writerow([
                etudiant_profile.user.username,
                cours_obj.nom,
                str(note.valeur), # Convertir le Decimal en string pour le CSV
                note.date_publication.strftime("%Y-%m-%d %H:%M:%S"), # Formater la date
                note.publie_par.user.username if note.publie_par else 'N/A', # Gérer le cas où publie_par est NULL
                etudiant_speciality_name,
                etudiant_profile.promotion.name if etudiant_profile.promotion else 'N/A',
                cours_obj.speciality.name if cours_obj.speciality else 'N/A'
            ])
        return response