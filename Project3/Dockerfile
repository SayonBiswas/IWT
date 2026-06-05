# Stage 1: Build with Java 21
FROM maven:3.9.6-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package

# Stage 2: Deploy to Tomcat 9 running on Java 21
FROM tomcat:9.0-jdk21
WORKDIR /usr/local/tomcat
RUN rm -rf webapps/ROOT
COPY --from=build /app/target/*.war webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]