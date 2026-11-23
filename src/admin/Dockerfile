FROM node:22
WORKDIR /app
COPY --chown=node:node package.json ./
RUN npm install
COPY --chown=node:node . .
RUN npm run build && chown -R node:node /app
USER node
ENV PORT=8080
EXPOSE 8080
CMD ["node", "dist/app.js"]
