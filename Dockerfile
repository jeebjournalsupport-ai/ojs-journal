FROM php:8.1-apache

# Install standard software + the 'intl' extension (This is what fixes the {{ }} bug!)
RUN apt-get update && apt-get install -y \
    libpng-dev libjpeg-dev libxml2-dev \
    libzip-dev zip unzip wget libpq-dev \
    libonig-dev libicu-dev \
    && docker-php-ext-configure gd --with-jpeg \
    && docker-php-ext-install gd pdo pdo_pgsql zip xml soap mbstring intl

# Allow clean URLs for OJS
RUN a2enmod rewrite
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Hide PHP warnings
RUN echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /usr/local/etc/php/php.ini \
    && echo "display_errors = Off" >> /usr/local/etc/php/php.ini \
    && echo "session.save_path = /tmp" >> /usr/local/etc/php/php.ini \
    && echo "file_uploads = On" >> /usr/local/etc/php/php.ini \
    && echo "upload_max_filesize = 50M" >> /usr/local/etc/php/php.ini \
    && echo "post_max_size = 50M" >> /usr/local/etc/php/php.ini \
    && echo "memory_limit = 256M" >> /usr/local/etc/php/php.ini \
    && chmod 777 /tmp

# Download OJS 3.3
WORKDIR /tmp
RUN wget https://pkp.sfu.ca/ojs/download/ojs-3.3.0-14.tar.gz \
    && tar -xzf ojs-3.3.0-14.tar.gz \
    && rm ojs-3.3.0-14.tar.gz

RUN rm -rf /var/www/html/* \
    && mv ojs-3.3.0-14/* /var/www/html/ \
    && mkdir -p /var/www/html/cache/t_cache \
    && mkdir -p /var/www/html/cache/t_compile \
    && mkdir -p /var/www/html/cache/_db \
    && mkdir -p /var/www/html/files \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# THE RAM FIX: Create 1GB of emergency "Swap" RAM so it never crashes on PDFs
RUN dd if=/dev/zero of=/swapfile bs=1M count=1024 \
    && chmod 600 /swapfile \
    && mkswap /swapfile \
    && swapon /swapfile
