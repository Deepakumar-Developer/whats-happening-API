# Stage 1: The Build Environment
# We use a multi-stage build to keep the final image small.
# The 'dart:stable' image contains the Dart SDK and is used for compilation.
FROM dart:stable AS build

# Set the working directory inside the container for all subsequent commands.
# This is where your application code will live.
WORKDIR /app

# Copy the pubspec files first to fetch dependencies.
# This step is cached, speeding up future builds if dependencies don't change.
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copy the entire project into the container's working directory.
# This includes all your Dart files, routes, and other assets.
COPY . .

# Create a production build of the Dart Frog application.
# This prepares the project for compilation.
RUN dart_frog build

# Compile the Dart application into a single, native executable.
# This creates a highly optimized and self-contained binary.
# The output is placed in 'build/bin/server'.
RUN dart compile exe build/bin/server.dart -o build/bin/server

# -----------------------------------------------------------

# Stage 2: The Minimal Runtime Environment
# We start from a 'scratch' base image. 'Scratch' is an empty image,
# which results in a tiny final container, perfect for production.
FROM scratch

# Copy the Dart runtime libraries from the 'build' stage.
# These are necessary for the compiled executable to run.
COPY --from=build /runtime/ /

# Copy the compiled server executable from the 'build' stage.
# This is the single file that will run your application.
COPY --from=build /app/build/bin/server /app/build/bin/server

# Expose port 8080 to the outside world.
# This is the port your Dart Frog server will be listening on.
EXPOSE 8080

# The command to run the server when the container starts.
# The executable is the entrypoint for your application.
CMD ["/app/build/bin/server"]
