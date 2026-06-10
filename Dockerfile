FROM public.ecr.aws/x8v8d7g8/mars-base:latest

WORKDIR /app

ENV NODE_ENV=development
ENV HOME=/home/model
ENV TMPDIR=/tmp
# Pin all build/test tool caches to /tmp subdirectories so they are
# always writable regardless of which UID the evaluator uses.
ENV VITE_CACHE_DIR=/tmp/.vite
ENV VITEST_CACHE_DIR=/tmp/.vitest
# rolldown / tsdown write temp artifacts here
ENV ROLLDOWN_TEMP_DIR=/tmp/.rolldown
# pnpm store cache
ENV npm_config_cache=/tmp/.npm

COPY package.json pnpm-lock.yaml ./

# Install dependencies offline-ready; no project build here (test.sh
# runs `pnpm build` once test.patch is injected at runtime, with
# internet disabled).
RUN pnpm install --frozen-lockfile --prefer-offline --prod=false

COPY . .

# Create user/group per rubric requirements
RUN groupadd -g 1000 model && useradd -u 1000 -g model -m model

# Pre-create all cache/temp directories that build and test tools will
# write to at runtime, and make them world-writable so any UID works.
# This eliminates "root-owned .vite-temp" EACCES failures.
RUN mkdir -p /tmp/.vite /tmp/.vitest /tmp/.rolldown /tmp/.npm /tmp/.cache \
 && chmod 1777 /tmp/.vite /tmp/.vitest /tmp/.rolldown /tmp/.npm /tmp/.cache

# Grant read+write to group/others on /app without elevating execute bits
# on regular files (`X` only adds execute where it already exists or on
# directories). Set setgid on dirs so runtime-created files inherit group.
RUN chown -R model:model /app /home/model \
 && chmod -R go+rwX /app \
 && find /app -type d -exec chmod g+s {} +

# Allow `git apply` / `git checkout` under a non-root UID on /app only.
RUN git config --system --add safe.directory /app

# CMD runs with a permissive umask so any files created inside the
# container (e.g. by `git apply`, `pnpm build`, vitest) stay writable
# for other UIDs that may follow.
CMD ["/bin/bash", "-c", "umask 0002 && exec /bin/bash"]
