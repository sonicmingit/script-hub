FROM node:18-alpine AS base

# 仅在需要时安装依赖
FROM base AS deps
# 查看 https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine 了解为什么可能需要 libc6-compat
RUN apk add --no-cache libc6-compat
WORKDIR /app

# 根据首选包管理器安装依赖
COPY package.json package-lock.json* ./
RUN npm ci

# 仅在需要时重新构建源代码
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js 收集关于一般用法的完全匿名遥测数据。
# 了解更多: https://nextjs.org/telemetry
# 如果你想在构建期间禁用遥测，请取消注释以下行。
ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build

# 生产镜像，复制所有文件并运行 next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# 设置预渲染缓存的正确权限
RUN mkdir .next
RUN chown nextjs:nodejs .next

# 自动利用输出跟踪来减小镜像大小
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# 创建数据目录并设置权限
RUN mkdir -p /app/data/scripts && chown -R nextjs:nodejs /app/data

USER nextjs

EXPOSE 7524

ENV PORT 7524
# 设置主机名为 localhost
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]
