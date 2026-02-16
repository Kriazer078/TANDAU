FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install dependencies (only production)
COPY package*.json ./
RUN npm ci --omit=dev  # Uses ci for consistent install

# Copy application source
# We copy src explicitly to avoid copying unexpected root files if .dockerignore acts up
COPY src ./src
COPY .env* ./  
# Note: Copying .env.example just for structure, secrets should be env vars

# Expose the default Cloud Run port
EXPOSE 8080

# Environment variable for port (Google Cloud sets PORT=8080)
ENV PORT=8080
ENV NODE_ENV=production

# Start the application
CMD [ "npm", "start" ]
