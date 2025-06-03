FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Copy application files
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD node src/utils/healthcheck.js || exit 1

CMD ["node", "src/index.js"]
