# EPF Africa Q&A Platform

Une plateforme de questions-réponses pour les étudiants d'EPF Africa, développée avec Flutter (mobile) et une architecture microservices (backend).

## 🚀 Technologies utilisées

### Backend

- **User Service**: Spring Boot (Java 17) - Gestion de l'authentification et des utilisateurs
- **Content Service**: Node.js + Express - Gestion des questions, réponses et catégories
- **Base de données**:
  - H2 (en mémoire) pour le User Service
  - MongoDB pour le Content Service
- **Authentification**: JWT (JSON Web Tokens)

### Mobile

- **Framework**: Flutter 3.x
- **State Management**: Provider
- **HTTP Client**: http package
- **Stockage local**: shared_preferences

## 📋 Prérequis

- Docker & Docker Compose
- Flutter SDK (3.x ou supérieur)
- Java 17 (optionnel, pour le développement local)
- Node.js 18+ (optionnel, pour le développement local)

## 🛠️ Installation et démarrage

### 1. Cloner le projet

```bash
git clone https://github.com/elbachir67/epf_exam.git

cd epf-exam
```

### 2. Démarrer le backend

```bash
cd backend
docker-compose up -d
```

Les services seront disponibles sur :

- User Service: http://localhost:8080
- Content Service: http://localhost:3000
- MongoDB: localhost:27017

### 3. Démarrer l'application mobile

```bash
cd mobile
flutter pub get
flutter run
```

## 📱 Comptes de test

Deux comptes sont créés automatiquement :

| Username | Password   | Rôle    |
| -------- | ---------- | ------- |
| admin    | admin123   | Admin   |
| student  | student123 | Student |

## 🏗️ Architecture

```
epf-africa-qa/
├── backend/
│   ├── user-service/         # Service d'authentification (Spring Boot)
│   ├── content-service/      # Service de contenu (Node.js)
│   └── docker-compose.yml    # Configuration Docker
│
└── mobile/                   # Application Flutter
    ├── lib/
    │   ├── config/          # Configuration (API URLs, thème)
    │   ├── models/          # Modèles de données
    │   ├── providers/       # State management
    │   ├── screens/         # Écrans de l'application
    │   ├── services/        # Services API
    │   └── widgets/         # Widgets réutilisables
    └── pubspec.yaml
```

## 🔧 Configuration

### URLs pour Android Emulator

L'application détecte automatiquement la plateforme et utilise les bonnes URLs :

- Android Emulator : `10.0.2.2` (pour accéder à localhost de l'hôte)
- iOS Simulator : `localhost`
- Web/Desktop : `localhost`

### Variables d'environnement

Les variables sont définies dans `docker-compose.yml` :

- `JWT_SECRET` : Clé secrète pour les tokens JWT
- `MONGODB_URI` : URI de connexion MongoDB
- `SPRING_PROFILES_ACTIVE` : Profil Spring Boot

## 📝 Fonctionnalités

- ✅ Inscription et connexion des utilisateurs
- ✅ Création de questions par catégorie
- ✅ Réponses aux questions
- ✅ Système de votes (upvote/downvote)
- ✅ Acceptation de réponse par l'auteur de la question
- ✅ Recherche de questions
- ✅ Filtrage par catégorie

## 🐛 Dépannage

### Le backend ne démarre pas

1. Vérifiez que Docker est lancé
2. Vérifiez les ports (8080, 3000, 27017) ne sont pas utilisés
3. Consultez les logs : `docker-compose logs -f [service-name]`

### Erreur de connexion dans l'app mobile

1. Vérifiez que le backend est accessible
2. Pour Android Emulator, l'URL doit être `10.0.2.2` et non `localhost`
3. Vérifiez que le token JWT est bien sauvegardé après connexion

### Rebuilder les services

```bash
# Arrêter tout
docker-compose down -v

# Rebuilder et relancer
docker-compose up -d --build
```

## 🧪 Tests API

### User Service

```bash
# Health check
curl http://localhost:8080/api/auth/health

# Inscription
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test123"}'

# Connexion
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Content Service

```bash
# Lister les catégories
curl http://localhost:3000/api/categories

# Créer une question (nécessite un token)
curl -X POST http://localhost:3000/api/questions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"title":"Test","content":"Test content","categoryId":"CATEGORY_ID"}'
```

## 📄 License

Ce projet est développé dans le cadre du cours à EPF Africa.

## 👥 Auteurs

- Dr. El Hadji Bassirou TOURE
- DMI/FST/UCAD - Dakar, Sénégal
