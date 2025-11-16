# Use Node.js Alpine base image
FROM node:18-alpine AS build

# Create and set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the entire codebase to the working directory
COPY . .

RUN npm run build

FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html

# Expose the port your app runs on (replace <PORT_NUMBER> with your app's actual port)
EXPOSE 80

# Define the command to start your application (replace "start" with the actual command to start your app)
CMD ["nginx", "-g", "daemon off;"]
