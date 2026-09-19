# Stage 1: Base image
FROM node:20-alpine AS base 
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable
WORKDIR /app

# Stage 2: Install dependencies
FROM base AS deps
# Check https://github.com to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile --fetch-timeout=300000 

# Stage 3: Build the application
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1     
# Next.js collects completely anonymous telemetry data about general usage.
RUN pnpm run build                        


# Stage 4: Production runner
FROM base AS runner
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs

# Automatically leverage output traces to reduce image size
# https://nextjs.org
COPY --from=builder  /app/.next/standalone ./              
COPY --from=builder  /app/.next/static ./.next/static      
# --chown=nextjs:nodejs
# --chown=nextjs:nodejs
# USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
