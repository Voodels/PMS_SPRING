# Quick Commands

## Start Everything (Simple)
```bash
docker-compose up -d --build
```

## Stop Everything
```bash
docker-compose down
```

## View Running Services
```bash
docker ps
```

## View Logs
```bash
docker-compose logs -f [service-name]
# Example: docker-compose logs -f patient-service
```

## Test the Application
```bash
./test-application.sh
```

## Rebuild a Single Service
```bash
docker-compose up -d --build [service-name]
# Example: docker-compose up -d --build auth-service
```

That's it! No more confusing multiple compose files! 🎉
