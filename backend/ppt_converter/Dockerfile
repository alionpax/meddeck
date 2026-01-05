FROM node:20-slim

# Install LibreOffice and required dependencies
RUN apt-get update && \
    apt-get install -y \
      libreoffice \
      libreoffice-impress \
      fonts-dejavu \
      fonts-liberation \
      ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY index.js .

ENV PORT=8080
CMD ["node", "index.js"]
