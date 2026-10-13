FROM debian:bookworm-slim
ARG GODOT_VERSION=4.7.2
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 && rm -rf /var/lib/apt/lists/* \
    && curl -fL --retry 3 "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip \
    && unzip /tmp/godot.zip -d /usr/local/bin \
    && mv /usr/local/bin/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot && rm /tmp/godot.zip
ENV GODOT_SILENCE_ROOT_WARNING=1
WORKDIR /app
COPY project.godot export_presets.cfg ./
COPY scripts ./scripts
COPY scenes ./scenes
COPY assets ./assets
RUN godot --headless --editor --import --quit && useradd -m -u 10001 game
USER game
ENV BIND_ADDRESS=0.0.0.0 PORT=9080
EXPOSE 9080
CMD ["godot", "--headless", "--path", "/app", "--", "--server"]
