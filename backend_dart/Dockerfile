# Use Google's official Dart image.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

# Copy app source code and build dependencies.
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Build run-time image
FROM debian:stable-slim

# Install ca-certificates (needed for HTTPS requests to Gemini/Firebase)
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# Copy the compiled executable
COPY --from=build /app/bin/server /app/bin/server

# Copy service account for Firebase (Make sure this file is in your repo if it's private!)
# REMOVED: COPY service_account.json ./ (Now using Render Secret Files)

# Start server.
ENV PORT=8080
EXPOSE 8080
CMD ["/app/bin/server"]
