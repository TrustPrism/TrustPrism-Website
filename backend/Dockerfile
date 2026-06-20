FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

# Install production dependencies only
RUN npm install --production

COPY . .

EXPOSE 5000

# Use production start command
CMD ["npm", "run", "start"]
