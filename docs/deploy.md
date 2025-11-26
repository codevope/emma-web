# Guía Completa de Deploy - EMMA HR Software

Esta guía te llevará paso a paso para desplegar EMMA en un servidor de producción con Docker, PostgreSQL, Nginx y certificados SSL automáticos.

## 📋 Tabla de Contenidos

1. [Prerequisitos](#prerequisitos)
2. [Configuración del Servidor](#configuración-del-servidor)
3. [Configuración DNS](#configuración-dns)
4. [Deploy Automático](#deploy-automático)
5. [Configuración SSL](#configuración-ssl)
6. [Mantenimiento](#mantenimiento)
7. [Troubleshooting](#troubleshooting)
8. [Backup y Restauración](#backup-y-restauración)

---

## 📦 Prerequisitos

### Servidor
- **OS**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **RAM**: Mínimo 2GB (Recomendado: 4GB+)
- **Storage**: Mínimo 20GB SSD
- **CPU**: 2 cores mínimo

### Software Requerido
- Docker 20.10+
- Docker Compose 2.0+
- Git

### Dominios Configurados
- `descubre.emma.pe`
- `www.descubre.emma.pe`

---

## 🌐 Configuración DNS

Antes del deploy, configura estos registros DNS en tu proveedor:

```dns
# Tipo A - Apuntar al IP de tu servidor
descubre.emma.pe.     300   IN   A   TU.IP.SERVIDOR.AQUI
www.descubre.emma.pe. 300   IN   A   TU.IP.SERVIDOR.AQUI

# Opcional: AAAA para IPv6
descubre.emma.pe.     300   IN   AAAA   tu:ipv6:aqui
www.descubre.emma.pe. 300   IN   AAAA   tu:ipv6:aqui
```

**Verificar DNS antes del deploy:**
```bash
nslookup descubre.emma.pe
nslookup www.descubre.emma.pe
```

---

## 🚀 Deploy Automático

### 1. Clonar el Repositorio
```bash
git clone https://github.com/tu-usuario/emma.git
cd emma
```

### 2. Configurar Variables de Entorno
```bash
cp .env.example .env
nano .env
```

**Edita las siguientes variables OBLIGATORIAS:**
```env
# Base de datos - ¡CAMBIA ESTAS CREDENCIALES!
POSTGRES_USER=emma_user
POSTGRES_PASSWORD=tu_password_super_seguro_aqui
POSTGRES_DB=emma_db

# NextAuth - ¡GENERA UN SECRET ÚNICO!
NEXTAUTH_SECRET=tu_nextauth_secret_de_32_caracteres_minimo
NEXTAUTH_URL=https://descubre.emma.pe

# URL de base de datos
DATABASE_URL=postgresql://emma_user:tu_password_super_seguro_aqui@postgres:5432/emma_db
```

**Generar secrets seguros:**
```bash
# Para NEXTAUTH_SECRET
openssl rand -base64 32

# Para POSTGRES_PASSWORD
openssl rand -base64 16
```

### 3. Ejecutar Deploy

**En Linux/macOS:**
```bash
chmod +x deploy/deploy.sh
./deploy/deploy.sh
```

**En Windows:**
```cmd
deploy\deploy.bat
```

### 4. Verificar Deploy
```bash
# Ver logs en tiempo real
docker-compose logs -f

# Verificar servicios corriendo
docker-compose ps

# Verificar salud de la aplicación
curl -I https://descubre.emma.pe
```

---

## 🔒 Configuración SSL Detallada

### Método 1: Let's Encrypt Automático (Recomendado)

El script de deploy maneja esto automáticamente, pero si necesitas configurarlo manualmente:

```bash
# 1. Iniciar nginx en modo HTTP primero
docker-compose up -d postgres webapp nginx

# 2. Obtener certificados
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@emma.pe \
    --agree-tos \
    --no-eff-email \
    -d descubre.emma.pe \
    -d www.descubre.emma.pe

# 3. Reiniciar nginx con SSL
docker-compose restart nginx
```

### Método 2: Certificados Existentes

Si ya tienes certificados SSL:

```bash
# Copiar certificados al directorio correcto
mkdir -p ./deploy/nginx/ssl/live/descubre.emma.pe/
cp tu-certificado.pem ./deploy/nginx/ssl/live/descubre.emma.pe/fullchain.pem
cp tu-clave-privada.key ./deploy/nginx/ssl/live/descubre.emma.pe/privkey.pem
```

### Renovación Automática

Los certificados se renuevan automáticamente cada 12 horas. Para verificar:

```bash
# Ver logs de certbot
docker-compose logs certbot

# Renovar manualmente (para testing)
docker-compose run --rm certbot renew --dry-run
```

---

## 🔧 Configuración del Servidor

### 1. Actualizar Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Instalar Docker
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Configurar Firewall
```bash
# UFW (Ubuntu)
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# O iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

### 4. Optimización de Sistema
```bash
# Aumentar límites de archivos
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimización de red
echo "net.core.somaxconn = 65536" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## 🔄 Mantenimiento

### Comandos Útiles

```bash
# Ver logs en tiempo real
docker-compose logs -f webapp
docker-compose logs -f postgres
docker-compose logs -f nginx

# Reiniciar servicios
docker-compose restart webapp
docker-compose restart nginx

# Actualizar aplicación
git pull
docker-compose build webapp
docker-compose up -d webapp

# Limpiar contenedores antiguos
docker system prune -a

# Ver métricas de recursos
docker stats
```

### Monitoreo de Salud

```bash
# Script de health check
cat > health-check.sh << 'EOF'
#!/bin/bash
STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://descubre.emma.pe)
if [ $STATUS -eq 200 ]; then
    echo "✅ Site is UP ($STATUS)"
else
    echo "❌ Site is DOWN ($STATUS)"
    # Reiniciar servicios si es necesario
    docker-compose restart webapp nginx
fi
EOF

chmod +x health-check.sh

# Agregar a crontab (verificar cada 5 minutos)
(crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/health-check.sh") | crontab -
```

---

## 💾 Backup y Restauración

### Backup Automático de PostgreSQL

```bash
cat > backup-postgres.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="./backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/emma_backup_$DATE.sql"

mkdir -p $BACKUP_DIR

# Crear backup
docker-compose exec -T postgres pg_dump -U emma_user emma_db > $BACKUP_FILE

# Comprimir
gzip $BACKUP_FILE

# Limpiar backups antiguos (mantener últimos 7 días)
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "✅ Backup completado: $BACKUP_FILE.gz"
EOF

chmod +x backup-postgres.sh

# Agregar a crontab (backup diario a las 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /path/to/backup-postgres.sh") | crontab -
```

### Restaurar desde Backup

```bash
# Listar backups disponibles
ls -la ./backups/postgres/

# Restaurar backup específico
BACKUP_FILE="./backups/postgres/emma_backup_20241107_020000.sql.gz"

# Detener aplicación
docker-compose stop webapp

# Restaurar base de datos
gunzip -c $BACKUP_FILE | docker-compose exec -T postgres psql -U emma_user -d emma_db

# Reiniciar aplicación
docker-compose start webapp
```

---

## 🛠 Troubleshooting

### Problemas Comunes

**1. Error: "Can't connect to PostgreSQL"**
```bash
# Verificar que PostgreSQL esté corriendo
docker-compose ps postgres

# Ver logs de PostgreSQL
docker-compose logs postgres

# Verificar conexión desde webapp
docker-compose exec webapp npx prisma db push
```

**2. Error: "SSL Certificate not found"**
```bash
# Verificar certificados
ls -la /etc/letsencrypt/live/descubre.emma.pe/

# Regenerar certificados
docker-compose run --rm certbot renew --force-renewal

# Reiniciar nginx
docker-compose restart nginx
```

**3. Error: "502 Bad Gateway"**
```bash
# Verificar que webapp esté corriendo
docker-compose ps webapp

# Verificar logs de nginx
docker-compose logs nginx

# Verificar configuración de nginx
docker-compose exec nginx nginx -t
```

**4. Rendimiento Lento**
```bash
# Verificar recursos del sistema
htop
df -h
docker stats

# Optimizar PostgreSQL
docker-compose exec postgres psql -U emma_user -d emma_db -c "ANALYZE;"
```

### Logs Importantes

```bash
# Ver todos los logs
docker-compose logs

# Ver logs específicos con timestamps
docker-compose logs -f -t webapp
docker-compose logs -f -t postgres
docker-compose logs -f -t nginx

# Ver logs de errores únicamente
docker-compose logs | grep -i error
```

---

## 📊 Métricas y Monitoreo

### Opcional: Configurar Prometheus + Grafana

Crear `docker-compose.monitoring.yml`:

```yaml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: emma_prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
    networks:
      - emma_network

  grafana:
    image: grafana/grafana:latest
    container_name: emma_grafana
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - emma_network

volumes:
  grafana_data:

networks:
  emma_network:
    external: true
```

```bash
# Iniciar monitoreo
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
```

---

## 📞 Soporte

Si encuentras problemas durante el deploy:

1. **Verificar logs**: `docker-compose logs`
2. **Verificar DNS**: `nslookup descubre.emma.pe`
3. **Verificar puertos**: `netstat -tulpn | grep -E ":80|:443"`
4. **Verificar certificados**: `openssl s_client -connect descubre.emma.pe:443`

Para soporte técnico, incluye:
- Output de `docker-compose ps`
- Logs relevantes
- Versión del sistema operativo
- Configuración de DNS

---

## ✅ Checklist de Deploy Exitoso

- [ ] ✅ DNS configurado correctamente
- [ ] ✅ Variables de entorno configuradas
- [ ] ✅ PostgreSQL corriendo y conectando
- [ ] ✅ Migraciones ejecutadas
- [ ] ✅ Seeders ejecutados
- [ ] ✅ Aplicación Next.js corriendo
- [ ] ✅ Nginx configurado y corriendo
- [ ] ✅ Certificados SSL obtenidos
- [ ] ✅ HTTPS funcionando
- [ ] ✅ Redirecciones HTTP→HTTPS funcionando
- [ ] ✅ Redirecciones www→no-www funcionando
- [ ] ✅ Backup automático configurado
- [ ] ✅ Monitoreo de salud configurado

---

**¡Tu aplicación EMMA debería estar funcionando en https://descubre.emma.pe!** 🚀