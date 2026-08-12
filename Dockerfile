# Build stage
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
# Download dependencies first to cache them
RUN mvn dependency:go-offline -B
COPY src ./src
COPY database ./database
RUN mvn package -DskipTests

# Run stage
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/melodymart-0.0.1-SNAPSHOT.jar app.jar
# Copy database schema and seed files for startup data initialization
COPY --from=build /app/database ./database
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
