# Build Stage
FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bookworm-20240722-slim AS build

# System-Tools
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Projektverzeichnis
WORKDIR /app

# Hex & Rebar vorbereiten
RUN mix local.hex --force && mix local.rebar --force

# Mix-Dateien kopieren und Dependencies auflösen
COPY mix.exs mix.lock ./
COPY config ./config
RUN MIX_ENV=prod mix deps.get

# App-Code kopieren und kompilieren
COPY lib ./lib
COPY priv ./priv
RUN MIX_ENV=prod mix compile

# Assets überspringen, falls nicht vorhanden (kein npm, kein js)

# Release bauen
RUN MIX_ENV=prod mix release

# --- Deployment Stage ---
FROM debian:bookworm-slim AS app

# Laufzeitabhängigkeiten
RUN apt-get update && apt-get install -y \
    openssl \
    libstdc++6 \
    libssl-dev \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Arbeitsverzeichnis & Umgebungsvariablen
ENV LANG=C.UTF-8
ENV HOME=/app
WORKDIR /app

# Release aus vorherigem Build kopieren
COPY --from=build /app/_build/prod/rel/* ./

# User & Berechtigungen
RUN chown -R nobody: .

USER nobody

# Port und Entrypoint
EXPOSE 4000
ENTRYPOINT ["/app/bin/your_app_name"]
CMD ["start"]
