# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Copy EVERYTHING. Yes, everything.
COPY . .

# Change directory to where our Dart project ACTUALLY is
WORKDIR /app/backend_dart

# Resolve dependencies
RUN dart pub get

# Compile
RUN dart compile exe bin/server.dart -o bin/server

# Stage 2: Runtime
FROM debian:stable-slim

# Install HTTPS support
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled server from previous stage
COPY --from=build /app/backend_dart/bin/server /app/bin/server

# Start server
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
