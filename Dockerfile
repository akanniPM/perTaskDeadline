FROM public.ecr.aws/x8v8d7g8/mars-base:latest

WORKDIR /app

ENV NODE_ENV=development
ENV HOME=/home/model
ENV TMPDIR=/tmp
ENV VITE_CACHE_DIR=/tmp/.vite
ENV VITEST_CACHE_DIR=/tmp/.vitest
ENV ROLLDOWN_TEMP_DIR=/tmp/.rolldown
ENV npm_config_cache=/tmp/.npm

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile --prefer-offline --prod=false

COPY . .

RUN groupadd -g 1000 model && useradd -u 1000 -g model -m model

RUN mkdir -p /tmp/.vite /tmp/.vitest /tmp/.rolldown /tmp/.npm /tmp/.cache \
 && chmod 1777 /tmp/.vite /tmp/.vitest /tmp/.rolldown /tmp/.npm /tmp/.cache

RUN chown -R model:model /app /home/model \
 && chmod -R go+rwX /app \
 && find /app -type d -exec chmod g+s {} +

RUN git config --system --add safe.directory /app

CMD ["/bin/bash", "-c", "umask 0002 && exec /bin/bash"]
