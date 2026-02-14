# Stage 1: Build
FROM dart:stable AS build

# Set workdir to /app
WORKDIR /app

# Copy the ENTIRE backend_dart folder into /app/backend_dart
# This preserves the directory structure exactly
COPY backend_dart /app/backend_dart

# Switch into that directory
WORKDIR /app/backend_dart

# Verify we are in the right place (for debug logging if it fails, but it won't)
RUN ls -la

# Resolve dependencies
RUN dart pub get

# Compile
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Runtime
FROM debian:stable-slim

# Install HTTPS support
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled server from the build stage
# Note the specific path: /app/backend_dart/bin/server
COPY --from=build /app/backend_dart/bin/server /app/bin/server

# Start server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
