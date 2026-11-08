# Imagen del backend para publicarlo en internet (Render u otro servicio con Docker)
# 1) Compila el proyecto con Maven
FROM eclipse-temurin:21-jdk AS construccion
WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw -B -q dependency:go-offline
COPY src src
RUN ./mvnw -B -q package -DskipTests

# 2) Imagen liviana solo con Java para ejecutar
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=construccion /app/target/*.jar app.jar
RUN mkdir -p uploads/alojamientos uploads/perfiles
# Usa como máximo el 75 % de la memoria disponible (el plan gratis tiene 512 MB)
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75 -XX:+UseSerialGC"
EXPOSE 8081
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
