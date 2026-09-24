# Small official Node 16 image (Alpine = fewer packages, smaller attack surface)
FROM node:16-alpine

# Run Express in production mode
ENV NODE_ENV=production

WORKDIR /app

# Install ONLY production dependencies, exactly as locked in package-lock.json
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy the app code, owned by the non-root "node" user
COPY --chown=node:node app.js ./

# Never run the app as root
USER node

EXPOSE 8080

# Docker checks the /health page to know the app is working
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "app.js"]
