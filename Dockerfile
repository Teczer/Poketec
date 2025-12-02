# ============================================
# STAGE 1: Build
# ============================================
FROM node:18-alpine AS build

# Définir le répertoire de travail
WORKDIR /app

# Installer pnpm globalement
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copier les fichiers de dépendances
COPY package.json pnpm-lock.yaml ./

# Installer les dépendances (inclut devDependencies pour le build)
RUN pnpm install --frozen-lockfile

# Copier le code source
COPY . .

# Build de production
ENV NODE_ENV=production
RUN pnpm run build

# ============================================
# STAGE 2: Production avec Nginx
# ============================================
FROM nginx:alpine AS production

# Supprimer la configuration par défaut de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copier la configuration Nginx personnalisée
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copier les fichiers buildés depuis le stage précédent
COPY --from=build /app/build /usr/share/nginx/html

# Exposer le port 80
EXPOSE 80

# Healthcheck pour Docker
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]
