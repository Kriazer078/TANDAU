# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Copy the dependency files first (for caching)
COPY backend_dart/pubspec.* ./

# Resolve dependencies
RUN dart pub get --no-precompile

# Copy app source code, assuming Dockerfile is run from parent directory
COPY backend_dart/ .

# Ensure offline get to confirm resolution
RUN dart pub get --offline

# Compile the server executable
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Runtime
FROM debian:stable-slim

# Install trusted ca-certificates for outbound HTTPS
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server

# Start server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
