FROM openjdk:8-jdk-alpine
COPY HelloWorld.java /usr/src/HelloWorld.java
RUN javac /usr/src/HelloWorld.java
CMD ["java", "-cp", "/usr/src", "HelloWorld"]