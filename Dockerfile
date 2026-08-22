FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
COPY apk /usr/share/nginx/html/apk
COPY www /usr/share/nginx/html/app
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
