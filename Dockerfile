FROM node:20-slim
RUN useradd -m appuser
USER appuser
WORKDIR /home/appuser/app
COPY --chown=appuser:appuser . .
CMD ["node", "dist/index.js"]
