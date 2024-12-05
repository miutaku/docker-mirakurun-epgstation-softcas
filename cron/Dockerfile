FROM willfarrell/crontab:latest

# Copy the backup script and config file into the container
COPY ./scripts/check-not-subscription.sh /scripts/
COPY ./config.json /opt/crontab

# # Grant execution permissions
RUN chmod +x /scripts/check-not-subscription.sh
