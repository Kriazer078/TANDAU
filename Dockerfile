# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# IMPORTANT: Copy ONLY the backend_dart folder contents into /app
# This ensures we don't accidentally pick up the Flutter project's pubspec.yaml from the parent folder
COPY backend_dart/ .

# Resolve dependencies (now running in a directory that ONLY has the server code)
RUN dart pub get

# Compile
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Runtime
FROM debian:stable-slim

# Install HTTPS support
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled server from previous stage
COPY --from=build /app/bin/server /app/bin/server

# Start server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
