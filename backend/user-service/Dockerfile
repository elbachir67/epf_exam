# Build stage
FROM gradle:8.4-jdk17 AS build
WORKDIR /app

# Copier les fichiers Gradle
COPY build.gradle settings.gradle ./
COPY gradle ./gradle

# Copier le code source
COPY src ./src

# Build l'application
RUN gradle bootJar --no-daemon -x test

# Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app

# Installer curl pour les health checks
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Copier le JAR
COPY --from=build /app/build/libs/*.jar app.jar

# Exposer le port
EXPOSE 8080

# Commande de démarrage
ENTRYPOINT ["java", "-jar", "app.jar"]