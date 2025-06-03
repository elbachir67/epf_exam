FROM node:18-alpine

WORKDIR /app

# Copier package.json d'abord
COPY package*.json ./

# Installer les dépendances
RUN npm ci --only=production

# Copier le reste de l'application
COPY . .

# Créer l'utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

# Commande de démarrage
CMD ["node", "src/index.js"]