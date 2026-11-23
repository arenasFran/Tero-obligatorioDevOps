FROM node:22
WORKDIR /app
COPY --chown=node:node package.json yarn.lock .yarnrc.yml ./
COPY --chown=node:node .yarn ./.yarn
RUN yarn install --immutable
COPY --chown=node:node . .
RUN yarn build
USER node
EXPOSE 8080
CMD ["node", "dist/main.js"]
