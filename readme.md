# 📑 Memoria del Proyecto: NimbusDocs

**Portal Documental Seguro Multi-Marca**

Proyecto de administración de sistemas que implementa una infraestructura web multi-marca mediante Apache, Nginx y Docker Compose. Incluye terminación TLS, proxy inverso, cabeceras de seguridad, protección de recursos y limitación de peticiones.

---

## 📑 Índice

- [I. Diseño y requisitos](#i-diseño-y-requisitos)
- [II. Estructura del proyecto](#ii-estructura-del-proyecto)
- [III. Backend Apache Multi-Marca](#iii-backend-apache-multi-marca)
- [IV. Terminación TLS y seguridad en Nginx](#iv-terminación-tls-y-seguridad-en-nginx)
- [V. Despliegue con Docker Compose](#v-despliegue-con-docker-compose)
- [VI. Pruebas de verificación](#vi-pruebas-de-verificación)
- [VII. Arquitectura final](#vii-arquitectura-final)
- [VIII. Conclusiones](#viii-conclusiones)

---

## 🏗️ I. Diseño y requisitos

### 1. Dominios elegidos

| Dominio | Tipo | Finalidad |
|---|---|---|
| `alfa.nimbus-lab.local` | Público | Portal técnico con documentación accesible. |
| `beta.nimbus-lab.local` | Interno | Portal con documentación y recursos restringidos. |

Esta separación permite simular una infraestructura empresarial en la que varias marcas comparten una plataforma, pero mantienen contenidos independientes.

### 2. Módulo MPM de Apache

Se selecciona **`mpm_event`** por su gestión eficiente de conexiones persistentes y su capacidad para atender múltiples solicitudes concurrentes.

Sus principales ventajas son:

- Gestión eficiente de conexiones `Keep-Alive`.
- Procesamiento concurrente mediante hilos.
- Mejor aprovechamiento de los recursos del servidor.

> **Nota técnica:** La elección de `mpm_event` debe verificarse en la configuración real de Apache. La imagen oficial `httpd:2.4` requiere comprobar qué MPM está habilitado.

---

## 📁 II. Estructura del proyecto

```text
nimbus-docs/
├── docker-compose.yml
├── nginx/
│   ├── default.conf
│   └── certs/
│       ├── nimbus.crt
│       └── nimbus.key
└── apache/
    ├── 01-marca-alfa.conf
    ├── 02-marca-beta.conf
    ├── marca-alfa/
    │   └── index.html
    └── marca-beta/
        ├── index.html
        └── secreto-beta.txt
```

- **Apache:** aloja los sitios web y controla el acceso a los recursos.
- **Nginx:** gestiona HTTPS, las redirecciones y el proxy inverso.
- **Docker Compose:** despliega y conecta los servicios.
- **Certificados:** permiten establecer conexiones TLS.

---

## 🛡️ III. Backend Apache Multi-Marca

### 1. Creación de contenidos

Se crean las páginas de ambas marcas y un archivo confidencial para comprobar las restricciones de acceso.

```bash
mkdir -p apache/marca-alfa apache/marca-beta

echo "<h1>Portal Técnico Oficial - Marca Alfa</h1>" > apache/marca-alfa/index.html

echo "<h1>Portal Interno Restringido - Marca Beta</h1>" > apache/marca-beta/index.html

echo "DATOS_CONFIDENCIALES_DE_MARCA_BETA=CLAVE_SECRETA_9876" > apache/marca-beta/secreto-beta.txt
```

### 2. Virtual Host de Marca Alfa

**Archivo:** `apache/01-marca-alfa.conf`

```apache
<VirtualHost *:80>
    ServerName alfa.nimbus-lab.local
    DocumentRoot /var/www/html/marca-alfa

    <Directory /var/www/html/marca-alfa>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog logs/alfa_error.log
    CustomLog logs/alfa_access.log combined
</VirtualHost>
```

Este Virtual Host asocia el dominio Alfa con su directorio web. `Options -Indexes` evita mostrar listados de archivos y `Require all granted` permite el acceso a sus contenidos.

### 3. Virtual Host de Marca Beta

**Archivo:** `apache/02-marca-beta.conf`

```apache
<VirtualHost *:80>
    ServerName beta.nimbus-lab.local
    DocumentRoot /var/www/html/marca-beta

    <Directory /var/www/html/marca-beta>
        Options -Indexes +FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    # Protección del fichero sensible
    <Files "secreto-beta.txt">
        Require all denied
    </Files>

    ErrorLog logs/beta_error.log
    CustomLog logs/beta_access.log combined
</VirtualHost>
```

La directiva `Require all denied` impide acceder al archivo `secreto-beta.txt` mediante HTTP, devolviendo:

```http
HTTP/1.1 403 Forbidden
```

Esta medida protege el recurso frente a solicitudes web, pero no impide que un administrador con acceso al sistema de archivos pueda leerlo.

---

## 🔐 IV. Terminación TLS y seguridad en Nginx

### 1. Generación del certificado TLS

Se genera una clave privada EC utilizando la curva `secp384r1` y un certificado autofirmado válido durante 365 días.

```bash
cd nginx/certs

openssl ecparam -name secp384r1 -genkey -noout -out nimbus.key

openssl req -new -x509 -days 365 \
    -key nimbus.key \
    -out nimbus.crt \
    -subj "/CN=alfa.nimbus-lab.local"

cd ../..
```

Los archivos generados son:

- `nimbus.key`: clave privada utilizada por Nginx.
- `nimbus.crt`: certificado presentado a los clientes.

> **Nota de seguridad:** El certificado es autofirmado y utiliza el CN de Alfa. Para producción, se recomienda un certificado de una autoridad de confianza con nombres SAN que incluyan ambos dominios.

### 2. Configuración de Nginx

**Archivo:** `nginx/default.conf`

```nginx
# Límite de peticiones: 5 solicitudes por segundo por IP
limit_req_zone $binary_remote_addr zone=nimbus_limit:10m rate=5r/s;

# Servidor HTTP: redirección a HTTPS
server {
    listen 80;
    server_name alfa.nimbus-lab.local beta.nimbus-lab.local;

    # Puerto HTTPS publicado por Docker en el equipo anfitrión
    return 301 https://$host:8443$request_uri;
}

# Servidor HTTPS: proxy inverso
server {
    listen 443 ssl;
    server_name alfa.nimbus-lab.local beta.nimbus-lab.local;

    ssl_certificate /etc/nginx/certs/nimbus.crt;
    ssl_certificate_key /etc/nginx/certs/nimbus.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Cabeceras de seguridad
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    location / {
        # Limitación de peticiones
        limit_req zone=nimbus_limit burst=10 nodelay;

        # Reenvío al backend Apache
        proxy_pass http://apache-backend:80;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3. Medidas de seguridad

| Medida | Función |
|---|---|
| Redirección HTTP a HTTPS | Dirige las conexiones hacia HTTPS mediante el código `301`. |
| TLS 1.2 y TLS 1.3 | Evita utilizar versiones antiguas del protocolo. |
| HSTS | Indica al navegador que debe utilizar HTTPS durante el periodo establecido. |
| `X-Content-Type-Options: nosniff` | Evita determinadas interpretaciones incorrectas de los tipos MIME. |
| `X-Frame-Options: SAMEORIGIN` | Restringe la incrustación de la página en marcos de otros orígenes. |
| Rate Limiting | Limita la frecuencia de las solicitudes por dirección IP. |

La directiva `limit_req_zone` establece una tasa media de cinco peticiones por segundo por IP. `burst=10` permite gestionar ráfagas de solicitudes y `nodelay` evita retrasar las solicitudes admitidas dentro de esa ráfaga.

Por defecto, Nginx puede devolver `503 Service Temporarily Unavailable` cuando rechaza solicitudes por superar el límite.

---

## 🐳 V. Despliegue con Docker Compose

### 1. Configuración de Docker Compose

**Archivo:** `docker-compose.yml`

```yaml
services:
  apache-backend:
    image: httpd:2.4
    container_name: apache-backend

    volumes:
      - ./apache/01-marca-alfa.conf:/usr/local/apache2/conf/extra/01-marca-alfa.conf:ro
      - ./apache/02-marca-beta.conf:/usr/local/apache2/conf/extra/02-marca-beta.conf:ro
      - ./apache/marca-alfa:/var/www/html/marca-alfa:ro
      - ./apache/marca-beta:/var/www/html/marca-beta:ro

    command: >
      bash -c "echo 'Include conf/extra/01-marca-alfa.conf' >> /usr/local/apache2/conf/httpd.conf &&
               echo 'Include conf/extra/02-marca-beta.conf' >> /usr/local/apache2/conf/httpd.conf &&
               httpd-foreground"

    networks:
      - nimbus-net

  nginx-proxy:
    image: nginx:latest
    container_name: nimbus_nginx

    ports:
      - "8080:80"
      - "8443:443"

    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro

    depends_on:
      - apache-backend

    networks:
      - nimbus-net

networks:
  nimbus-net:
    driver: bridge
```

### 2. Funcionamiento de los servicios

- **`apache-backend`:** aloja los contenidos y los Virtual Hosts.
- **`nginx-proxy`:** gestiona las conexiones HTTP/HTTPS y reenvía las peticiones.
- **`nimbus-net`:** permite la comunicación entre ambos contenedores.
- **Volúmenes `:ro`:** montan los archivos en modo de solo lectura.
- **`depends_on`:** establece el orden de inicio, pero no garantiza que Apache esté listo para recibir peticiones.

Nginx accede a Apache mediante el nombre del servicio:

```nginx
proxy_pass http://apache-backend:80;
```

Los puertos publicados son `8080` para HTTP y `8443` para HTTPS.

### 3. Comandos de administración

Iniciar el entorno:

```bash
docker compose up -d
```

Comprobar los contenedores:

```bash
docker compose ps
```

Consultar los registros:

```bash
docker compose logs
docker compose logs nginx-proxy
docker compose logs apache-backend
```

Validar la configuración de Nginx:

```bash
docker compose exec nginx-proxy nginx -t
```

Detener el entorno:

```bash
docker compose down
```

---

## 🧪 VI. Pruebas de verificación

Las siguientes pruebas comprueban las redirecciones, el acceso a los sitios, la protección del archivo confidencial y el funcionamiento del limitador.

Se utiliza `curl --resolve` para asociar los dominios a `127.0.0.1` sin modificar `/etc/hosts`. El parámetro `-k` permite realizar pruebas HTTPS con el certificado autofirmado.

### 1. Redirección HTTP a HTTPS

```bash
curl -I \
  --resolve alfa.nimbus-lab.local:8080:127.0.0.1 \
  http://alfa.nimbus-lab.local:8080/
```

**Resultado esperado:**

```http
HTTP/1.1 301 Moved Permanently
Server: nginx
Location: https://alfa.nimbus-lab.local:8443/
```

El código `301` indica que el cliente debe utilizar la URL HTTPS de destino.

### 2. Acceso HTTPS a las marcas

**Marca Alfa:**

```bash
curl -k \
  --resolve alfa.nimbus-lab.local:8443:127.0.0.1 \
  https://alfa.nimbus-lab.local:8443/
```

Resultado esperado:

```html
<h1>Portal Técnico Oficial - Marca Alfa</h1>
```

**Marca Beta:**

```bash
curl -k \
  --resolve beta.nimbus-lab.local:8443:127.0.0.1 \
  https://beta.nimbus-lab.local:8443/
```

Resultado esperado:

```html
<h1>Portal Interno Restringido - Marca Beta</h1>
```

Estas pruebas verifican que Apache identifica el Virtual Host correspondiente mediante la cabecera `Host` que Nginx conserva al reenviar las solicitudes.

### 3. Protección del archivo confidencial

```bash
curl -k -I \
  --resolve beta.nimbus-lab.local:8443:127.0.0.1 \
  https://beta.nimbus-lab.local:8443/secreto-beta.txt
```

**Resultado esperado:**

```http
HTTP/1.1 403 Forbidden
```

El resultado confirma que Apache deniega el acceso HTTP al recurso mediante la directiva `Require all denied`.

### 4. Rate Limiting

Se realizan veinte solicitudes consecutivas para comprobar la limitación de peticiones.

```bash
for i in {1..20}; do
    curl -k -s -o /dev/null \
        -w "%{http_code}\n" \
        --resolve alfa.nimbus-lab.local:8443:127.0.0.1 \
        https://alfa.nimbus-lab.local:8443/
done
```

- **`200 OK`:** la petición se ha procesado correctamente.
- **`503 Service Temporarily Unavailable`:** Nginx ha rechazado la petición por superar el límite configurado.

En una prueba realizada se observaron quince respuestas `200` y cinco respuestas `503`. Los resultados pueden variar según la velocidad de las solicitudes y el estado previo del limitador.

---

## 🏗️ VII. Arquitectura final

La infraestructura separa la entrada de las conexiones web de la gestión de los contenidos.

```text
                  CLIENTE WEB
                      |
            +---------+---------+
            |                   |
        HTTP :8080          HTTPS :8443
            |                   |
            v                   v
             NGINX REVERSE PROXY
             - Redirección HTTPS
             - Terminación TLS
             - Cabeceras de seguridad
             - Rate Limiting
                      |
                Red Docker
                 nimbus-net
                      |
                      v
                APACHE BACKEND
                - Virtual Host Alfa
                - Virtual Host Beta
                - Control de acceso
                - Registros separados
                   |          |
                   v          v
                MARCA ALFA  MARCA BETA
                index.html  index.html
                            secreto-beta.txt
                            (acceso denegado)
```

### Estructura final

```text
nimbus-docs/
├── apache/
│   ├── 01-marca-alfa.conf
│   ├── 02-marca-beta.conf
│   ├── marca-alfa/
│   │   └── index.html
│   └── marca-beta/
│       ├── index.html
│       └── secreto-beta.txt
├── nginx/
│   ├── certs/
│   │   ├── nimbus.key
│   │   └── nimbus.crt
│   └── default.conf
├── docker-compose.yml
└── README.md
```

---

## ✅ VIII. Conclusiones

NimbusDocs implementa una infraestructura web multi-marca utilizando Apache, Nginx y Docker Compose.

Las principales funcionalidades desarrolladas son:

- **Virtual Hosts:** permiten alojar dos sitios web independientes.
- **Proxy inverso:** centraliza las conexiones en Nginx.
- **Terminación TLS:** habilita HTTPS mediante un certificado autofirmado.
- **Redirección HTTP a HTTPS:** dirige las conexiones hacia el protocolo cifrado.
- **Cabeceras de seguridad:** añaden medidas de protección para los clientes web.
- **Control de acceso:** impide descargar el archivo confidencial de Beta mediante HTTP.
- **Rate Limiting:** limita la frecuencia de las peticiones por dirección IP.
- **Contenerización:** facilita el despliegue y la comunicación entre servicios.

Las pruebas permiten verificar el funcionamiento de los Virtual Hosts, el acceso HTTPS, la protección del recurso confidencial y la limitación de peticiones.

Como mejoras futuras, se propone incorporar certificados de una autoridad de confianza, configurar nombres SAN, reforzar el control de acceso al portal Beta y añadir comprobaciones de salud a los servicios.

**Proyecto:** NimbusDocs — Portal Documental Seguro Multi-Marca

**Tecnologías:** Apache HTTP Server · Nginx · Docker · Docker Compose · OpenSSL