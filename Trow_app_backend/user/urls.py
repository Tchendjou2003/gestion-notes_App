# user/urls.py

from rest_framework.routers import DefaultRouter
from django.urls import path, include
from .views import (
    UserProfileViewSet, CoursViewSet, NoteViewSet,
    SpecialityViewSet, PromotionViewSet
)

# DefaultRouter génère automatiquement les URLs pour les opérations CRUD (list, retrieve, create, update, delete)
router = DefaultRouter()

# Enregistre chaque ViewSet avec un préfixe d'URL et un nom de base
# Exemple : pour UserProfileViewSet, cela générera :
# /api/profiles/ (GET pour liste, POST pour créer)
# /api/profiles/{id}/ (GET pour détail, PUT/PATCH pour modifier, DELETE pour supprimer)
router.register(r'profiles', UserProfileViewSet, basename='profile')
router.register(r'courses', CoursViewSet, basename='course')
router.register(r'grades', NoteViewSet, basename='grade')
router.register(r'specialities', SpecialityViewSet, basename='speciality')
router.register(r'promotions', PromotionViewSet, basename='promotion')

urlpatterns = [
    # Inclut toutes les URLs générées par le routeur
    path('', include(router.urls)),
    # L'action personnalisée 'register' du UserProfileViewSet est accessible via /api/profiles/register/
    # (Pas besoin de la lister explicitement ici car @action la gère)
]