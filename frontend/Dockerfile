FROM node:20-alpine AS builder

WORKDIR /app

# Accept build argument for API URL
ARG VITE_API_URL=""

COPY package*.json ./
RUN npm install

COPY . .

# Build the application
RUN VITE_API_URL=${VITE_API_URL} npm run build

# Production stage - use a lightweight web server
FROM node:20-alpine

WORKDIR /app

# Install a simple HTTP server
RUN npm install -g serve

# Copy built files from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

RUN npm install --production

EXPOSE 5173

# Serve the built application
# Use -s flag to serve index.html for all routes (SPA)
CMD ["serve", "-s", "dist", "-l", "5173"]
