FROM node:20-slim

RUN apt-get update && \
    apt-get install -y \
      libreoffice \
      libreoffice-impress \
      fonts-dejavu \
      fonts-liberation \
      ca-certificates \
      poppler-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify poppler is present (fail build if missing)
RUN command -v pdftoppm && pdftoppm -h >/dev/null

WORKDIR /app

COPY package*.json ./
RUN npm install --omit=dev

COPY index.js .

ENV PORT=8080
CMD ["node", "index.js"]
