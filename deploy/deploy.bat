@echo off
REM EMMA Deploy Script para Windows (Estructura Interna)
REM Ubicación: web\deploy\deploy.bat

setlocal EnableDelayedExpansion

echo ╔═══════════════════════════════════════╗
echo ║         EMMA Deploy Script            ║
echo ║    Deploy para Windows (Interno)     ║
echo ╚═══════════════════════════════════════╝
echo.

REM Verificar Docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker no está instalado o no está en PATH
    pause
    exit /b 1
)

docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker Compose no está instalado o no está en PATH
    pause
    exit /b 1
)

echo [INFO] Docker está configurado correctamente

REM Moverse al directorio web
cd /d "%~dp0\.."

REM Verificar que estamos en el directorio correcto
if not exist package.json (
    echo [ERROR] No se encuentra package.json. Verifica que estés en el directorio web/
    pause
    exit /b 1
)

REM Verificar archivo .env
if not exist .env (
    if exist .env.example (
        echo [INFO] Copiando .env.example a .env...
        copy .env.example .env
        echo [WARNING] IMPORTANTE: Edita .env con tus credenciales de producción
        echo Variables críticas:
        echo - POSTGRES_PASSWORD
        echo - NEXTAUTH_SECRET
        echo.
        echo Presiona cualquier tecla cuando hayas configurado .env...
        pause
    ) else (
        echo [ERROR] No se encuentra .env.example
        pause
        exit /b 1
    )
)

REM Crear directorios necesarios
echo [INFO] Creando estructura de directorios...
mkdir deploy\nginx\ssl\live\descubre.emma.pe 2>nul
mkdir deploy\nginx\sites-enabled 2>nul
mkdir public\uploads\blog 2>nul
mkdir public\uploads\user 2>nul
mkdir public\uploads\slide 2>nul
mkdir public\uploads\recruitment 2>nul
mkdir backups\postgres 2>nul

REM Configurar nginx para HTTP inicial
echo [INFO] Configurando nginx para HTTP inicial...
if not exist deploy\nginx\sites-available\emma-http.conf (
    echo [ERROR] No se encuentra el archivo de configuración HTTP de nginx
    pause
    exit /b 1
)

REM Validar Docker Compose
echo [INFO] Validando configuración de Docker Compose...
docker-compose config >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Error en docker-compose.yml
    pause
    exit /b 1
)

REM Construir imagen
echo [INFO] Construyendo imagen de la aplicación...
docker-compose build webapp

REM FASE 1: Iniciar servicios HTTP
echo [INFO] FASE 1: Iniciando servicios en modo HTTP...
docker-compose up -d postgres webapp nginx

REM Esperar servicios
echo [INFO] Esperando a que los servicios estén listos...
timeout /t 30 /nobreak >nul

REM Ejecutar migraciones
echo [INFO] Ejecutando migraciones de base de datos...
docker-compose exec -T webapp npx prisma migrate deploy

echo [INFO] Ejecutando seeders...
docker-compose exec -T webapp npm run seed

REM Verificar aplicación HTTP
echo [INFO] Verificando aplicación en HTTP...
curl -f http://descubre.emma.pe >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Aplicación respondiendo en HTTP
) else (
    echo [WARNING] Aplicación no responde inmediatamente
)

REM FASE 2: SSL (simplificado para Windows)
echo [INFO] FASE 2: Para SSL automático, ejecuta manualmente:
echo docker-compose run --rm certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@emma.pe --agree-tos --no-eff-email -d descubre.emma.pe -d www.descubre.emma.pe

REM Verificación final
echo [INFO] Verificando servicios finales...
docker-compose ps

echo.
echo ╔═══════════════════════════════════════╗
echo ║           DEPLOY COMPLETADO           ║
echo ╚═══════════════════════════════════════╝
echo.
echo Aplicación disponible en: http://descubre.emma.pe
echo Para SSL, configura manualmente los certificados
echo.
echo Comandos útiles:
echo - Ver logs: docker-compose logs -f
echo - Reiniciar: docker-compose restart
echo - Detener: docker-compose down
echo.
pause

endlocal