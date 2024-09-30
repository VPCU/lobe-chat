FROM node:20-slim AS base

## Sharp dependencies, copy all the files for production
FROM base AS sharp
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

RUN pnpm add sharp

## Install dependencies only when needed
FROM base AS builder
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

COPY package.json ./
COPY .npmrc ./

# If you want to build docker in China
# RUN npm config set registry https://registry.npmmirror.com/
RUN pnpm i

COPY . .

ENV NEXT_PUBLIC_BASE_PATH ""

# Sentry
ENV NEXT_PUBLIC_SENTRY_DSN ""
ENV SENTRY_ORG ""
ENV SENTRY_PROJECT ""

# Posthog
ENV NEXT_PUBLIC_ANALYTICS_POSTHOG ""
ENV NEXT_PUBLIC_POSTHOG_KEY ""
ENV NEXT_PUBLIC_POSTHOG_HOST ""

# Umami
ENV NEXT_PUBLIC_ANALYTICS_UMAMI ""
ENV NEXT_PUBLIC_UMAMI_SCRIPT_URL ""
ENV NEXT_PUBLIC_UMAMI_WEBSITE_ID ""

# Node
ENV NODE_OPTIONS "--max-old-space-size=8192"

# run build standalone for docker version
RUN npm run build:docker
RUN npm i -g bun
RUN npm run build-migrate-db

## Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=sharp --chown=nextjs:nodejs /app/node_modules/.pnpm ./node_modules/.pnpm

USER nextjs

# set hostname to localhost
ENV HOSTNAME "0.0.0.0"
ENV PORT 8080

# General Variables
ENV ACCESS_CODE ""

ENV API_KEY_SELECT_MODE ""

# Model Variables
ENV \
    # AI21
    AI21_API_KEY="" \
    # Ai360
    AI360_API_KEY="" \
    # Anthropic
    ANTHROPIC_API_KEY="" ANTHROPIC_PROXY_URL="" \
    # Amazon Bedrock
    AWS_ACCESS_KEY_ID="" AWS_SECRET_ACCESS_KEY="" AWS_REGION="" AWS_BEDROCK_MODEL_LIST="" \
    # Azure OpenAI
    AZURE_API_KEY="" AZURE_API_VERSION="" AZURE_ENDPOINT="" AZURE_MODEL_LIST="" \
    # Baichuan
    BAICHUAN_API_KEY="" \
    # DeepSeek
    DEEPSEEK_API_KEY="" \
    # Fireworks AI
    FIREWORKSAI_API_KEY="" FIREWORKSAI_MODEL_LIST="" \
    # GitHub
    GITHUB_TOKEN="" GITHUB_MODEL_LIST="" \
    # Google
    GOOGLE_API_KEY="" GOOGLE_PROXY_URL="" \
    # Groq
    GROQ_API_KEY="" GROQ_MODEL_LIST="" GROQ_PROXY_URL="" \
    # Hunyuan
    HUNYUAN_API_KEY="" HUNYUAN_MODEL_LIST="" \
    # Minimax
    MINIMAX_API_KEY="" \
    # Mistral
    MISTRAL_API_KEY="" \
    # Moonshot
    MOONSHOT_API_KEY="" MOONSHOT_PROXY_URL="" \
    # Novita
    NOVITA_API_KEY="" NOVITA_MODEL_LIST="" \
    # Ollama
    OLLAMA_MODEL_LIST="" OLLAMA_PROXY_URL="" \
    # OpenAI
    OPENAI_API_KEY="" OPENAI_MODEL_LIST="" OPENAI_PROXY_URL="" \
    # OpenRouter
    OPENROUTER_API_KEY="" OPENROUTER_MODEL_LIST="" \
    # Perplexity
    PERPLEXITY_API_KEY="" PERPLEXITY_PROXY_URL="" \
    # Qwen
    QWEN_API_KEY="" QWEN_MODEL_LIST="" \
    # SiliconCloud
    SILICONCLOUD_API_KEY="" SILICONCLOUD_MODEL_LIST="" SILICONCLOUD_PROXY_URL="" \
    # Spark
    SPARK_API_KEY="" \
    # Stepfun
    STEPFUN_API_KEY="" \
    # Taichu
    TAICHU_API_KEY="" \
    # TogetherAI
    TOGETHERAI_API_KEY="" TOGETHERAI_MODEL_LIST="" \
    # Upstage
    UPSTAGE_API_KEY="" \
    # 01.AI
    ZEROONE_API_KEY="" ZEROONE_MODEL_LIST="" \
    # Zhipu
    ZHIPU_API_KEY="" ZHIPU_MODEL_LIST=""

USER nextjs

EXPOSE 8080/tcp

CMD ["node", "/app/server.js"]
