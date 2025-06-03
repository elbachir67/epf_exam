#!/bin/bash

echo "=== Réparation complète EPF Africa Backend ==="
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Se placer dans le bon répertoire
cd backend || { echo -e "${RED}❌ Dossier backend introuvable${NC}"; exit 1; }

echo "1. Arrêt et nettoyage complet..."
docker-compose down -v
docker system prune -f
echo -e "${GREEN}✅ Nettoyage terminé${NC}"

echo ""
echo "2. Suppression des images existantes..."
docker rmi backend-user-service backend-content-service 2>/dev/null
echo -e "${GREEN}✅ Images supprimées${NC}"

echo ""
echo "3. Génération du package-lock.json pour content-service..."
cd content-service
npm install
cd ..
echo -e "${GREEN}✅ package-lock.json généré${NC}"

echo ""
echo "4. Construction de MongoDB..."
docker-compose up -d mongodb
echo "Attente que MongoDB soit prêt..."
sleep 15

# Vérifier que MongoDB est bien démarré
until docker exec epf-africa-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    echo "En attente de MongoDB..."
    sleep 2
done
echo -e "${GREEN}✅ MongoDB est prêt${NC}"

echo ""
echo "5. Construction et démarrage du content-service..."
docker-compose up -d --build content-service
sleep 10

echo ""
echo "6. Construction et démarrage du user-service..."
docker-compose up -d --build user-service
sleep 20

echo ""
echo "7. Vérification des services..."
echo ""

# Test MongoDB
echo -n "MongoDB: "
if docker exec epf-africa-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR${NC}"
fi

# Test Content Service
echo -n "Content Service: "
CONTENT_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:3000/health 2>/dev/null | tail -n1)
if [ "$CONTENT_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR (HTTP $CONTENT_RESPONSE)${NC}"
fi

# Test User Service
echo -n "User Service: "
USER_RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8080/actuator/health 2>/dev/null | tail -n1)
if [ "$USER_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR (HTTP $USER_RESPONSE)${NC}"
    echo ""
    echo "Tentative de test dans le conteneur..."
    docker exec epf-africa-user-service curl -v http://localhost:8080/actuator/health
fi

echo ""
echo "8. État des conteneurs:"
docker-compose ps

echo ""
echo "9. Tests des endpoints:"
echo ""

# Test auth health
echo "Test /api/auth/health:"
curl -v http://localhost:8080/api/auth/health

echo ""
echo ""
echo "=== Instructions finales ==="
echo "Si les services ne fonctionnent toujours pas :"
echo "1. Vérifiez les logs : docker-compose logs -f [service-name]"
echo "2. Pour user-service : docker-compose logs -f user-service"
echo "3. Pour content-service : docker-compose logs -f content-service"