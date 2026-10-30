# Build from the project root with:
# docker build -f edubox_server/Dockerfile .

# Build stage
FROM dart:3.12.2 AS build

# Create a minimal workspace that preserves locked server dependency versions.
WORKDIR /app
COPY pubspec.lock .
COPY edubox_fixtures edubox_fixtures
COPY edubox_server edubox_server
RUN printf '%s\n' \
  'name: _' \
  'environment:' \
  '  sdk: ^3.12.2' \
  'workspace:' \
  '  - edubox_fixtures' \
  '  - edubox_server' \
  > pubspec.yaml
RUN dart pub get

# Compile the server executable.
WORKDIR /app/edubox_server
RUN dart build cli --target bin/main.dart --output build
RUN mv build/bundle/bin/main build/bundle/bin/server

# Runtime configuration is mounted by compose; the image holds only the
# committed run-mode files.
RUN mkdir -p config web migrations

# Final stage
FROM alpine:latest
WORKDIR /app

# Environment defaults. The exec-form ENTRYPOINT takes no flags of its own, so
# every argument in a compose `command:` is appended to the binary; the default
# CMD is used only when the container is started without one.
ENV serverid=default
ENV logging=normal
ENV role=monolith

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy compiled server executable and native libraries
COPY --from=build /app/edubox_server/build/bundle/ ./

# Copy configuration files and resources
COPY --from=build /app/edubox_server/config/ config/
COPY --from=build /app/edubox_server/web/ web/
COPY --from=build /app/edubox_server/migrations/ migrations/

# This file is required to enable the endpoint log filter in Insights.
COPY --from=build /app/edubox_server/lib/src/generated/protocol.yaml lib/src/generated/protocol.yaml

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

# Define the entrypoint command. Exec form (not shell form) so compose
# `command:` / `docker run` arguments are appended, never discarded.
ENTRYPOINT ["./bin/server"]
CMD ["--mode=production", "--server-id=default", "--logging=normal", "--role=monolith"]
