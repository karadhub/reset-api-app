# syntax=docker/dockerfile:1
FROM node:18-alpine AS base
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev
COPY src ./src
EXPOSE 3000
CMD ["node", "src/index.js"]
