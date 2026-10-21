FROM node:20-alpine

WORKDIR /app

# Install dependencies first for caching
COPY package*.json ./
RUN npm install --omit=dev

# Copy application source
COPY . .

# Ensure upload directory exists
RUN mkdir -p /app/uploads/evidences

EXPOSE 3000

CMD ["node", "src/index.js"]
