# EPF Africa Q&A Platform

Plateforme de questions-réponses pour les étudiants d'EPF Africa.

## Prérequis

- Docker et Docker Compose
- Flutter SDK (3.10+)
- Git

## Installation et lancement

### 1. Cloner le projet

```bash
git clone https://github.com/elbachir67/epf-africa-project.git
cd epf-africa-project
```

### 2. Lancer le backend (Docker)

```bash
cd backend
docker-compose up -d
```

Attendez 30 secondes que les services démarrent complètement.

### 3. Lancer l'application mobile

Dans un nouveau terminal :

```bash
cd mobile
flutter pub get
flutter run
```

## Ports utilisés

- **8080** : Service utilisateur (Spring Boot)
- **3000** : Service contenu (Node.js)
- **27017** : MongoDB

## Comptes de test (à créer par vous même)

- Username: `admin` / Password: `admin123`
- Username: `student` / Password: `student123`

## Commandes utiles

### Voir les logs

```bash
docker-compose logs -f
```

### Arrêter les services

```bash
docker-compose down
```

### Reconstruire les services

```bash
docker-compose up -d --build
```

## Résolution des problèmes

### Si les catégories ne se chargent pas

```bash
docker-compose restart content-service
```

### Si la connexion échoue sur mobile

Vérifiez que vous utilisez la bonne adresse IP :

- Émulateur Android : L'app utilise automatiquement `10.0.2.2`
- Appareil physique : Modifiez l'IP dans `mobile/lib/config/platform_config.dart`

## Architecture

- **Backend** : Microservices (Spring Boot + Node.js)
- **Base de données** : MongoDB
- **Mobile** : Flutter
- **Authentification** : JWT

## Contact

Pour toute question, contactez l'équipe EPF Africa.
