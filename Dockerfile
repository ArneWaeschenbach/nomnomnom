# --- Build Stage ---
FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bookworm-20240722-slim AS build

# System-Tools installieren
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Arbeitsverzeichnis setzen
WORKDIR /app

# Hex & Rebar installieren
RUN mix local.hex --force && mix local.rebar --force

# Mix-Dateien und Konfiguration kopieren
COPY mix.exs mix.lock ./
COPY config ./config

# Abhängigkeiten auflösen
RUN MIX_ENV=prod mix deps.get

# Applikationscode kopieren
COPY lib ./lib
COPY priv ./priv

# Kompilieren
RUN MIX_ENV=prod mix compile

RUN MIX_ENV=prod mix phx.digest

# Release bauen
RUN MIX_ENV=prod mix release


# --- Deployment Stage ---
FROM debian:bookworm-slim AS app

# Laufzeitabhängigkeiten installieren
RUN apt-get update && apt-get install -y \
    openssl \
    libstdc++6 \
    libssl-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Umgebungsvariablen & Arbeitsverzeichnis
ENV LANG=C.UTF-8
ENV HOME=/app
ENV PHX_SERVER=true
WORKDIR /app

# Release kopieren
COPY --from=build /app/_build/prod/rel/nomnomnom ./

# Nutzer wechseln
RUN chown -R nobody: .

USER nobody

# Port freigeben & Startkommando setzen
EXPOSE 4000
ENTRYPOINT ["/app/bin/nomnomnom"]
CMD ["start"]
