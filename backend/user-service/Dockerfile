# Build stage
FROM gradle:8.4-jdk17 AS build
WORKDIR /app
COPY build.gradle settings.gradle ./
COPY gradle ./gradle
COPY src ./src
RUN gradle build --no-daemon -x test

# Runtime stage
FROM openjdk:17-jdk-slim
WORKDIR /app

# Installation de curl pour health check
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copier le JAR depuis le build stage
COPY --from=build /app/build/libs/user-service.jar app.jar

# Créer un utilisateur non-root
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=docker", "app.jar"]
