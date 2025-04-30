FROM docker.io/hexpm/elixir:1.17.2-erlang-27.0.1-debian-bookworm-20240722-slim as build

# for Node
RUN apt-get update -y && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# for Phoenix
RUN apt-get update -y && apt-get install -y \
    build-essential \
    git \
    nodejs \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN mix local.hex --force
RUN mix local.rebar --force

WORKDIR /build
COPY config ./config
COPY mix.exs .
COPY mix.lock .

ENV MIX_ENV=prod \
    LANG=C.UTF-8

#Install dependencies and build Release
RUN mix deps.get --only prod

RUN npm --version
RUN node --version



RUN mix compile
RUN mix assets.deploy
RUN mix release

#=================
# deployment Stage
#=================
FROM docker.io/debian:bookworm-20240722-slim as asm

RUN apt-get update -y && apt-get install -y \
    build-essential \
    ca-certificates \
    fontconfig \
    fonts-dejavu \
    fonts-font-awesome \
    fonts-freefont-ttf \
    fonts-linuxlibertine \
    fonts-open-sans \
    git \
    git-core \
    imagemagick \
    libfontconfig1-dev \
    libfontenc1 \
    libfreetype6-dev \
    libjpeg-dev \
    libjpeg62-turbo \
    libjpeg62-turbo-dev \
    libncurses5 \
    libssl-dev \
    libstdc++6 \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    locales \
    openssl \
    wget \
    xfonts-75dpi \
    xfonts-base \
    xfonts-encodings \
    xfonts-utils \
    zlib1g \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb && \
    dpkg -i wkhtmltox_0.12.6.1-3.bookworm_amd64.deb && \
    rm wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

RUN apt --fix-broken install

ENV LANG=C.UTF-8
ENV HOME=/opt/app

#Create /opt/app directory and default user \
# See: https://github.com/wkhtmltopdf/packaging/issues/2#issuecomment-725962861
RUN update-ca-certificates --fresh && \
    mkdir -p ${HOME} && \
    chown -R nobody: ${HOME}

WORKDIR ${HOME}

#Set environment variables and expose port
EXPOSE 4000

#Copy and extract .tar.gz Release file from the previous stage
COPY --from=build /build/_build/prod/rel/default .
RUN chown -R nobody: .

USER nobody

#Set default entrypoint and command
ENTRYPOINT ["/opt/app/bin/default"]
CMD ["start"]