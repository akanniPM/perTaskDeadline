FROM public.ecr.aws/d3j8x8q7/olympus-base-typescript:latest

WORKDIR /app

# Keep dev dependencies (vitest, tsdown) and avoid NODE_ENV=production pruning.
ENV NODE_ENV=development
ENV HOME=/home/model
ENV TMPDIR=/tmp
# Pin build/test tool caches to /tmp subdirectories so they are always
# writable regardless of which UID the evaluator uses.
ENV VITE_CACHE_DIR=/tmp/.vite
ENV VITEST_CACHE_DIR=/tmp/.vitest
ENV ROLLDOWN_TEMP_DIR=/tmp/.rolldown
ENV npm_config_cache=/tmp/.npm

COPY package.json pnpm-lock.yaml ./

# Install dependencies offline-ready; no project build here (test.sh runs the
# build once test.patch is injected at runtime, with internet disabled).
RUN pnpm install --frozen-lockfile --prefer-offline --prod=false

COPY . .

# Provide a non-root user/group at uid/gid 1000 (idempotent: the base image may
# already define one).
RUN if ! getent group 1000 >/dev/null 2>&1; then groupadd -g 1000 model; fi \
 && if ! id -u 1000 >/dev/null 2>&1; then useradd -u 1000 -g 1000 -m model; fi \
 && mkdir -p /home/model && chmod 777 /home/model

# Pre-create all cache/temp directories that build and test tools will write to
# at runtime, and make them world-writable so any UID works.
RUN mkdir -p /tmp/.vite /tmp/.vitest /tmp/.rolldown /tmp/.npm /tmp/.cache \
 && chmod 1777 /tmp/.vite /tmp/.vitest /tmp/.rolldown /tmp/.npm /tmp/.cache

# Grant read+write to group/others on /app; setgid on dirs so runtime-created
# files inherit the group.
RUN chown -R 1000:1000 /app 2>/dev/null || true; \
    chmod -R go+rwX /app \
 && find /app -type d -exec chmod g+s {} +

# Allow git apply / git checkout under a non-root UID on /app only.
RUN git config --system --add safe.directory /app

# CMD runs with a permissive umask so files created inside the container stay
# writable for other UIDs that may follow.
CMD ["/bin/bash", "-c", "umask 0002 && exec /bin/bash"]
