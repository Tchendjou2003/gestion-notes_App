from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

# Regrouper les URLs de l'API facilite le versioning.
# Toutes ces URLs seront accessibles via le préfixe 'api/v1/'.
api_urlpatterns = [
    # URLs pour l'authentification JWT
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # Inclut les URLs de l'application 'user' (profiles, courses, etc.)
    # Le préfixe 'api/v1/' sera ajouté par l'include() ci-dessous.
    path('', include('user.urls')),
]


urlpatterns = [
    # URL de l'interface d'administration de Django
    path('admin/', admin.site.urls),

    # Point d'entrée principal pour l'API versionnée
    path('api/v1/', include(api_urlpatterns)),
]
