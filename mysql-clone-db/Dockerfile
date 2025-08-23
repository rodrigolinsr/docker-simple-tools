FROM mysql:8.0

# Copy script into container
COPY db-copy.sh /usr/local/bin/db-copy.sh

RUN chmod +x /usr/local/bin/db-copy.sh

# Keep container alive
CMD ["tail", "-f", "/dev/null"]
