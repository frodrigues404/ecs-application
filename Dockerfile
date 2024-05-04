FROM node:14-alpine

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json index.js package-lock.json ./ 
RUN npm install --production

EXPOSE  3000

CMD ["npm", "start"]
