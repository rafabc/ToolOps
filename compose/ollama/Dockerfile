FROM ollama/ollama:latest

# Descarga del modelo durante el build
RUN ollama serve & \
    sleep 10 && \
    ollama pull llama3 && \
    pkill ollama

# Expone el puerto estándar
EXPOSE 11434

# Al iniciar el contenedor, ejecuta el servidor Ollama
CMD ["ollama", "serve"]