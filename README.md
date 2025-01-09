# laravel

Laravel docker base image can be used for development and production.

## Features

Includes all you need for the Laravel framework:

- PHP
- Apache
- Composer
- Node.js
- NPM

Can be used with MongoDB, MySQL, PostgreSQL, SQLite, and SQL Server out of the box.

## Configuration

The image is configured to run Laravel out of the box. The Apache configuration is set up to use the `/var/www/html/public` directory as the web root.

It does *not* run migrations or similar tasks on startup. This is up to the user to implement.  
It only runs the web portion of the Laravel application, not the queue worker, scheduler, or similar.

## Usage

Can be used in a `Dockerfile` like this:

```dockerfile
FROM ghcr.io/the0mikkel/laravel:latest

# Insert data
COPY --chown=app:app ./ /var/www/html/ 

# Run npm build to compile frontend assets
RUN npm install && npm run build && rm -rf node_modules && composer install --no-dev --optimize-autoloader && php artisan storage:link
```

## Tags

Versioning is based on the PHP version and uses the latest Apache version for that PHP version, provided by the official PHP docker image.

- `latest` - Latest version of Laravel
- `8.4`, `8.4.X` - PHP 8.4 with Apache
- `8.3`, `8.3.X` - PHP 8.3 with Apache

*Only the "latest" version of PHP is updated. See the latest version being updated in `versions.txt`.*
