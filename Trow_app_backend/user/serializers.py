# user/serializers.py

from rest_framework import serializers
from django.contrib.auth.models import User # Importe le modèle User par default de Django
from .models import Profile, Cours, Note, Speciality, Promotion # Importe tous vos modèles


# Serializer simple pour le modèle User de Django
# Utile pour afficher les détails de l'utilisateur lié dans d'autres sérialiseurs (ex: dans ProfileSerializer)
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

# Serializer pour le modèle Speciality
class SpecialitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Speciality
        fields = ['id', 'name', 'description']

# Serializer pour le modèle Promotion
class PromotionSerializer(serializers.ModelSerializer):
    # Pour afficher le nom de la spécialité liée lors de la lecture (ex: GET /api/promotions/)
    speciality_name = serializers.CharField(source='speciality.name', read_only=True)
    
    class Meta:
        model = Promotion
        fields = ['id', 'name', 'year', 'speciality', 'speciality_name']
        # 'speciality' est le champ ForeignKey. On le rend 'write_only'
        # car on veut que l'API reçoive l'ID de la spécialité lors de la création/mise à jour,
        # mais on affichera le `speciality_name` en lecture seule.
        extra_kwargs = {
            'speciality': {'write_only': True}
        }

# Serializer pour le modèle Profile
class ProfileSerializer(serializers.ModelSerializer):
    # Imbrique le UserSerializer pour afficher les détails de l'utilisateur lié (ex: username, email)
    user = UserSerializer()

    # Ajoute un champ en lecture seule pour afficher le nom "humain" du rôle (ex: "Étudiant" au lieu de "etudiant")
    role_display = serializers.CharField(source='get_role_display', read_only=True)

    # Utilisation d'un SerializerMethodField pour dériver le nom de la spécialité de la promotion.
    # C'est plus robuste car cela gère le cas où la promotion est None.
    speciality_name = serializers.SerializerMethodField()
    promotion_name = serializers.CharField(source='promotion.name', read_only=True)
    
    # Champ en écriture seule (ID) pour lier le Profile à une Promotion.
    # PrimaryKeyRelatedField attend l'ID de l'objet lié.
    promotion_id = serializers.PrimaryKeyRelatedField(
        queryset=Promotion.objects.all(), source='promotion', write_only=True, required=False, allow_null=True
    )

    # Pour les spécialités assignées au formateur (relation Many-to-Many)
    # `read_only=True` : Pour la lecture (GET), on veut les détails complets des spécialités.
    assigned_specialities = SpecialitySerializer(many=True, read_only=True)
    # `write_only=True` : Pour l'écriture (POST/PUT), on enverra une liste d'IDs de spécialités.
    assigned_specialities_ids = serializers.PrimaryKeyRelatedField(
        queryset=Speciality.objects.all(), many=True, write_only=True, required=False, source='assigned_specialities'
    )

    class Meta:
        model = Profile
        fields = [
            'id', 'user', 'role', 'role_display', 'speciality_name',
            'promotion_name', 'promotion_id',
            'assigned_specialities', 'assigned_specialities_ids' # Inclure les champs many-to-many
        ]
        # Le champ 'user' est en lecture seule dans ce contexte, car sa modification est gérée dans la méthode update.
        # Pour la création, on utilisera le RegisterSerializer.
        read_only_fields = ['user']

    def get_speciality_name(self, obj):
        # Méthode pour le SerializerMethodField. Retourne le nom de la spécialité via la promotion.
        if obj.promotion and obj.promotion.speciality:
            return obj.promotion.speciality.name
        return None

    # Surcharge de la méthode 'update' pour gérer la mise à jour des champs du 'User' imbriqué
    # et des relations ManyToMany (assigned_specialities) qui ne sont pas gérées automatiquement par ModelSerializer.
    def update(self, instance, validated_data):
        # Les données du 'user' ne sont pas dans validated_data car le champ est read_only.
        # On les récupère depuis les données initiales de la requête.
        user_data = self.initial_data.get('user', {})
        assigned_specialities_data = validated_data.pop('assigned_specialities', None)

        # Met à jour les champs du Profile en utilisant la méthode de la superclasse.
        # Cela gère automatiquement les champs comme 'role' et 'promotion'.
        instance = super().update(instance, validated_data)

        # Met à jour les champs du User lié (s'il y en a)
        if user_data:
            user_instance = instance.user
            user_instance.email = user_data.get('email', user_instance.email)
            user_instance.first_name = user_data.get('first_name', user_instance.first_name)
            user_instance.last_name = user_data.get('last_name', user_instance.last_name)
            user_instance.save()
        
        if assigned_specialities_data is not None: # La logique de permission doit être dans la VUE
            instance.assigned_specialities.set(assigned_specialities_data)

        return instance


# Serializer pour l'inscription de nouveaux utilisateurs via l'API (POST /api/profiles/register/)
class RegisterSerializer(serializers.ModelSerializer):
    # Le rôle est un champ obligatoire lors de l'inscription et doit être en écriture seule
    role = serializers.ChoiceField(choices=Profile.Roles.choices, write_only=True)
    # Le mot de passe est en écriture seule, requis, et son type est 'password' pour l'interface automatique de DRF
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})
    
    # Pour l'inscription d'un étudiant, on peut lui assigner directement une promotion par son ID.
    promotion_id = serializers.PrimaryKeyRelatedField(
        queryset=Promotion.objects.all(), source='promotion', write_only=True, required=False, allow_null=True
    )

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'role', 'first_name', 'last_name', 'promotion_id']
        extra_kwargs = {
            'password': {'write_only': True}, # S'assurer que le mot de passe n'est jamais retourné en lecture
            'email': {'required': True} # S'assurer que l'email est toujours requis
        }

    # Surcharge de la méthode 'create' pour créer à la fois l'objet User et son objet Profile lié.
    def create(self, validated_data):
        # Récupère les données spécifiques au Profile qui ne sont pas des champs du modèle User
        role_data = validated_data.pop('role')
        promotion_data = validated_data.pop('promotion', None)

        # Crée l'utilisateur Django standard
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        
        # Crée le Profile lié. Si c'est un étudiant, on assigne la promotion.
        # La spécialité est automatiquement déduite de la promotion.
        Profile.objects.create(
            user=user,
            role=role_data,
            promotion=promotion_data if role_data == Profile.Roles.ETUDIANT else None
        )

        return user

# Serializer pour le modèle Cours
class CoursSerializer(serializers.ModelSerializer):
    # Affiche le nom d'utilisateur du formateur lié pour la lecture
    formateur_username = serializers.CharField(source='formateur.user.username', read_only=True)
    # Champ en écriture seule pour l'ID du formateur (permet de lier un formateur existant lors de POST/PUT)
    formateur_id = serializers.PrimaryKeyRelatedField(
        queryset=Profile.objects.filter(role='formateur'), # Limite les choix aux profils de formateurs
        source='formateur', write_only=True, required=False, allow_null=True
    )

    # Nouveaux champs pour Speciality et Promotion (lecture seule, affiche le nom)
    speciality_name = serializers.CharField(source='speciality.name', read_only=True)
    promotion_name = serializers.CharField(source='promotion.name', read_only=True)

    # Nouveaux champs pour Speciality et Promotion (écriture seule, attend un ID)
    speciality_id = serializers.PrimaryKeyRelatedField(
        queryset=Speciality.objects.all(), source='speciality', write_only=True, required=False, allow_null=True
    )
    promotion_id = serializers.PrimaryKeyRelatedField(
        queryset=Promotion.objects.all(), source='promotion', write_only=True, required=False, allow_null=True
    )

    class Meta:
        model = Cours
        fields = [
            'id', 'nom', 'description',
            'formateur_username', 'formateur_id', # Inclure les champs lecture et écriture
            'speciality_name', 'speciality_id',
            'promotion_name', 'promotion_id'
        ]
        # Ces champs sont définis en lecture seule car ils sont gérés via leurs ID respectifs pour la modification
        extra_kwargs = {
            'formateur': {'read_only': True},
            'speciality': {'read_only': True},
            'promotion': {'read_only': True},
        }

# Serializer pour le modèle Note
class NoteSerializer(serializers.ModelSerializer):
    # Affiche le nom d'utilisateur de l'étudiant, le nom du cours et le nom de celui qui a publié la note
    etudiant_username = serializers.CharField(source='etudiant.user.username', read_only=True)
    cours_nom = serializers.CharField(source='cours.nom', read_only=True)
    publie_par_username = serializers.CharField(source='publie_par.user.username', read_only=True)

    # Champs en écriture seule pour les IDs des relations (ce que le frontend enverra)
    etudiant_id = serializers.PrimaryKeyRelatedField(
        queryset=Profile.objects.filter(role='etudiant'), # Limite les choix aux profils d'étudiants
        source='etudiant', write_only=True
    )
    cours_id = serializers.PrimaryKeyRelatedField(
        queryset=Cours.objects.all(), # Tous les cours
        source='cours', write_only=True
    )

    class Meta:
        model = Note
        fields = [
            'id', 'etudiant_id', 'etudiant_username',
            'cours_id', 'cours_nom', 'valeur',
            'date_publication', 'publie_par_username' # publie_par_username est en lecture seule, publie_par est rempli par la vue
        ]
        read_only_fields = ['date_publication', 'publie_par_username'] # Ces champs sont gérés par le backend

    # Validation personnalisée pour s'assurer qu'un étudiant n'a pas deux notes pour le même cours
    def validate(self, data):
        # Cette validation s'applique seulement lors de la création d'une nouvelle note (pas lors de la modification)
        if self.instance is None: # `self.instance` est None lors d'une création
            etudiant = data.get('etudiant')
            cours = data.get('cours')
            # Vérifie si une note existe déjà pour cet étudiant et ce cours
            if etudiant and cours and Note.objects.filter(etudiant=etudiant, cours=cours).exists():
                raise serializers.ValidationError(
                    {"non_field_errors": ["Cet étudiant a déjà une note pour ce cours."]}
                )
        return data