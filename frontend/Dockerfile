FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 "${FLUTTER_HOME}" \
    && flutter config --enable-web \
    && flutter precache --web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

ARG GOOGLE_MAPS_JS_API_KEY
ARG API_BASE_URL=/api
RUN flutter build web --release \
    --dart-define=GOOGLE_MAPS_JS_API_KEY=$GOOGLE_MAPS_JS_API_KEY \
    --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
