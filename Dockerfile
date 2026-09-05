FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

WORKDIR /app
COPY . .

RUN flutter pub get

RUN flutter build web --release --web-renderer canvaskit --no-wasm --no-tree-shake-icons

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]