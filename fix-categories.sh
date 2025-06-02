#!/bin/bash

echo "=== Réinitialisation complète des catégories EPF Africa ==="
echo ""

# Configuration
CONTENT_SERVICE_URL="http://localhost:3000"
MONGODB_CONTAINER="epf-africa-mongodb"

# 1. Vérifier l'état actuel
echo "1. Vérification de l'état actuel..."
echo "-----------------------------------"

# Vérifier si MongoDB est en cours d'exécution
if ! docker ps | grep -q $MONGODB_CONTAINER; then
    echo "❌ MongoDB n'est pas en cours d'exécution"
    echo "Lancement de Docker Compose..."
    cd backend && docker-compose up -d
    sleep 10
fi

# Vérifier les catégories actuelles
echo "Catégories actuelles dans la base de données :"
docker exec $MONGODB_CONTAINER mongosh epfafrica --quiet --eval "db.categories.find().pretty()"

echo ""
echo "2. Suppression des anciennes catégories..."
echo "-----------------------------------"
docker exec $MONGODB_CONTAINER mongosh epfafrica --quiet --eval "db.categories.deleteMany({})"

echo ""
echo "3. Insertion des nouvelles catégories..."
echo "-----------------------------------"
docker exec $MONGODB_CONTAINER mongosh epfafrica --quiet --eval '
db.categories.insertMany([
    {
        name: "Engineering",
        description: "Questions about engineering subjects and practices",
        color: "#1976D2",
        icon: "engineering",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: "Computer Science",
        description: "Programming, algorithms, software development",
        color: "#388E3C",
        icon: "computer",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: "Business",
        description: "Business management, entrepreneurship, economics",
        color: "#F57C00",
        icon: "business",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: "Mathematics",
        description: "Pure and applied mathematics questions",
        color: "#7B1FA2",
        icon: "calculate",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: "Sciences",
        description: "Physics, chemistry, biology and other sciences",
        color: "#C62828",
        icon: "science",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    },
    {
        name: "General",
        description: "General questions about EPF Africa and student life",
        color: "#455A64",
        icon: "school",
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date()
    }
]);
'

echo ""
echo "4. Vérification après insertion..."
echo "-----------------------------------"
CATEGORY_COUNT=$(docker exec $MONGODB_CONTAINER mongosh epfafrica --quiet --eval "db.categories.countDocuments()")
echo "Nombre de catégories insérées : $CATEGORY_COUNT"

echo ""
echo "5. Test de l'API..."
echo "-----------------------------------"
API_RESPONSE=$(curl -s "$CONTENT_SERVICE_URL/api/categories")
echo "Réponse de l'API :"
echo "$API_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$API_RESPONSE"

echo ""
echo "6. Redémarrage du service content..."
echo "-----------------------------------"
docker-compose restart content-service

echo ""
echo "=== Résumé ==="
echo "-----------------------------------"
if [ "$CATEGORY_COUNT" -eq "6" ]; then
    echo "✅ 6 catégories créées avec succès"
    echo ""
    echo "Actions recommandées :"
    echo "1. Relancez votre application Flutter"
    echo "2. Déconnectez-vous et reconnectez-vous"
    echo "3. Les catégories devraient maintenant apparaître"
else
    echo "❌ Problème lors de la création des catégories"
    echo "Vérifiez les logs : docker-compose logs content-service"
fi