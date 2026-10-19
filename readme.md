# 📑 Memoria del Proyecto: NimbusDocs

**Portal Documental Seguro Multi-Marca**

Proyecto de administración de sistemas que implementa una infraestructura web multi-marca mediante Apache, Nginx y Docker Compose, incorporando terminación TLS, proxy inverso, cabeceras de seguridad, protección de recursos y limitación de peticiones.

---

## 📑 Índice

- [I. Diseño y requisitos](#-i-diseño-y-requisitos)
  - [1. Dominios ficticios elegidos](#1-dominios-ficticios-elegidos)
  - [2. Módulo de multiprocesamiento de Apache](#2-módulo-de-multiprocesamiento-de-apache-mpm)
- [II. Estructura del proyecto](#-ii-disposición-de-la-estructura-del-proyecto)
- [III. Fase 1: Backend Apache Multi-Marca](#-iii-fase-1-backend-apache-multi-marca-ud2)
  - [1. Creación de contenidos web](#1-creación-de-contenidos-web)
  - [2. Configuración de los Virtual Hosts](#2-configuración-de-los-virtual-hosts)
- [IV. Fase 2: Terminación TLS, Proxy Inverso y Seguridad en Nginx](#-iv-fase-2-terminación-tls-proxy-inverso-y-seguridad-en-nginx)
  - [1. Generación del certificado TLS](#1-generación-del-certificado-tls)
  - [2. Configuración de Nginx](#2-configuración-de-nginx)
  - [3. Justificación de las medidas de seguridad](#3-justificación-de-las-medidas-de-seguridad)
- [V. Despliegue y orquestación con Docker Compose](#-v-despliegue-y-orquestación-con-docker-compose)
  - [1. Configuración de Docker Compose](#1-configuración-de-docker-compose)
  - [2. Arranque del entorno](#2-arranque-del-entorno)
- [VI. Pruebas de verificación y resultados](#-vi-pruebas-de-verificación-y-resultados)
  - [1. Redirección HTTP a HTTPS](#1-verificación-de-la-redirección-http-a-https)
  - [2. Acceso HTTPS a las marcas](#2-verificación-del-acceso-https-a-las-marcas)
  - [3. Protección del recurso confidencial](#3-verificación-del-recurso-protegido-en-marca-beta)
  - [4. Rate Limiting](#4-verificación-del-rate-limiting)
- [VII. Arquitectura final](#-vii-arquitectura-final)
- [VIII. Conclusiones](#-viii-conclusiones)

---

# 🏗️ I. Diseño y requisitos

## 1. Dominios ficticios elegidos

Para el desarrollo del proyecto NimbusDocs se han definido dos dominios ficticios, diferenciando claramente el portal público del portal interno.

| Dominio | Tipo de portal | Finalidad |
|---|---|---|
| `alfa.nimbus-lab.local` | Marca pública | Portal técnico destinado a la publicación de documentación accesible a los usuarios. |
| `beta.nimbus-lab.local` | Marca privada | Portal interno destinado a documentación sensible y recursos de acceso restringido. |

### Justificación de la elección

Se han seleccionado estos nombres para mantener una diferenciación clara entre el entorno público y el restringido dentro de la infraestructura de NimbusDocs.

Además, se cumple la regla de originalidad del proyecto al utilizar dominios propios, evitando nombres genéricos de clase como `sitioa.iaw.local` o `app.iaw.local`.

Esta separación permite simular una infraestructura empresarial en la que diferentes marcas comparten una misma plataforma web, pero mantienen sus propios espacios y contenidos.

## 2. Módulo de multiprocesamiento de Apache (MPM)

**MPM seleccionado: `mpm_event`**

Se ha seleccionado el módulo `mpm_event` de Apache por su capacidad para gestionar conexiones concurrentes de forma eficiente.

### Justificación técnica

El MPM Event está diseñado para optimizar la gestión de conexiones persistentes, como las que utilizan `Keep-Alive`.

Entre sus principales características destacan:

- **Procesamiento multihilo:** permite atender múltiples solicitudes concurrentemente.
- **Gestión eficiente de conexiones:** evita mantener ocupado un hilo de trabajo innecesariamente durante determinados periodos de inactividad de las conexiones.
- **Optimización de recursos:** puede reducir el consumo de memoria y mejorar el aprovechamiento de los recursos del servidor frente a modelos menos eficientes.
- **Escalabilidad:** resulta adecuado para servicios web que deben gestionar múltiples conexiones simultáneas.

La elección de `mpm_event` responde al objetivo de ofrecer una infraestructura eficiente para un portal documental con varios usuarios concurrentes.

> **Nota técnica:** La configuración descrita corresponde a la elección de diseño. Para utilizar realmente `mpm_event`, es necesario comprobar que está habilitado en Apache. En la imagen oficial `httpd:2.4`, la configuración de los módulos y del MPM debe verificarse expresamente.

---

# 📁 II. Disposición de la estructura del proyecto

La estructura del proyecto se organiza en dos componentes principales: Nginx, responsable de la terminación TLS y el proxy inverso, y Apache, encargado de alojar los contenidos web de las diferentes marcas.

```text
nimbus-docs/
├── docker-compose.yml
│
├── nginx/
│   ├── default.conf
│   └── certs/
│       ├── nimbus.crt
│       └── nimbus.key
│
└── apache/
    ├── 01-marca-alfa.conf
    ├── 02-marca-beta.conf
    │
    ├── marca-alfa/
    │   └── index.html
    │
    └── marca-beta/
        ├── index.html
        └── secreto-beta.txt
```

## Descripción de los directorios y archivos

| Archivo o directorio | Función |
|---|---|
| `docker-compose.yml` | Define los servicios, los volúmenes, los puertos y la red de Docker. |
| `nginx/default.conf` | Configura los servidores HTTP y HTTPS, el proxy inverso y las medidas de seguridad. |
| `nginx/certs/nimbus.crt` | Contiene el certificado TLS utilizado por Nginx. |
| `nginx/certs/nimbus.key` | Contiene la clave privada asociada al certificado TLS. |
| `apache/01-marca-alfa.conf` | Define el Virtual Host de la marca Alfa. |
| `apache/02-marca-beta.conf` | Define el Virtual Host de la marca Beta y la protección del recurso confidencial. |
| `apache/marca-alfa/` | Almacena los contenidos públicos de Alfa. |
| `apache/marca-beta/` | Almacena los contenidos de Beta y el archivo confidencial de prueba. |

Esta organización facilita el mantenimiento de la infraestructura, separa las responsabilidades de cada servicio y permite modificar las configuraciones y los contenidos sin mezclar los componentes del proyecto.

---

# 🛡️ III. Fase 1: Backend Apache Multi-Marca (UD2)

## 1. Creación de contenidos web

En esta primera fase se crean los directorios correspondientes a las dos marcas del proyecto, así como sus páginas HTML y un recurso confidencial que posteriormente será protegido mediante la configuración de Apache.

### Estructura de directorios

```text
apache/
├── marca-alfa/
│   └── index.html
└── marca-beta/
    ├── index.html
    └── secreto-beta.txt
```

### Creación de directorios y archivos

```bash
mkdir -p apache/marca-alfa apache/marca-beta

echo "<h1>Portal Técnico Oficial - Marca Alfa</h1>" > apache/marca-alfa/index.html

echo "<h1>Portal Interno Restringido - Marca Beta</h1>" > apache/marca-beta/index.html

echo "DATOS_CONFIDENCIALES_DE_MARCA_BETA=CLAVE_SECRETA_9876" > apache/marca-beta/secreto-beta.txt
```

### Descripción de los recursos

| Recurso | Descripción | Acceso |
|---|---|---|
| `marca-alfa/index.html` | Página principal de la marca Alfa. | Público |
| `marca-beta/index.html` | Página principal de la marca Beta. | Público en esta fase |
| `marca-beta/secreto-beta.txt` | Archivo con información confidencial de prueba. | Denegado mediante Apache |

> **Nota:** La marca Beta representa un portal interno. En esta configuración, su página principal es accesible, pero el archivo `secreto-beta.txt` está protegido contra el acceso HTTP.

---

## 2. Configuración de los Virtual Hosts

Apache se configura para alojar dos sitios web independientes en un mismo servidor mediante **Virtual Hosts basados en el nombre de dominio**.

Cada marca dispone de su propio archivo de configuración, directorio raíz y archivos de registro.

### 2.1. Virtual Host de Marca Alfa

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

**Características principales:**

- `ServerName`: establece el dominio asociado a la marca Alfa.
- `DocumentRoot`: define el directorio que contiene la página web.
- `Options -Indexes`: impide mostrar automáticamente el listado de archivos de un directorio.
- `Options +FollowSymLinks`: permite seguir enlaces simbólicos.
- `AllowOverride None`: impide que los archivos `.htaccess` sobrescriban la configuración del directorio.
- `Require all granted`: permite el acceso a los recursos del directorio.
- `ErrorLog`: almacena los errores del sitio.
- `CustomLog`: registra las peticiones HTTP recibidas.

### 2.2. Virtual Host de Marca Beta

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

### Medida de seguridad aplicada

El bloque `<Files>` deniega las peticiones HTTP dirigidas al archivo `secreto-beta.txt`.

```apache
<Files "secreto-beta.txt">
    Require all denied
</Files>
```

La directiva `Require all denied` impide el acceso al archivo a través de Apache, independientemente de que el usuario conozca su nombre o su ruta.

Cuando se solicita el recurso, Apache devuelve:

```http
HTTP/1.1 403 Forbidden
```

> **Importante:** Esta restricción protege el acceso HTTP al archivo. No impide que un administrador con acceso al sistema de archivos pueda leerlo directamente.

---

# 🔐 IV. Fase 2: Terminación TLS, Proxy Inverso y Seguridad en Nginx

En esta fase se incorpora Nginx como punto de entrada de las conexiones web.

Nginx se encarga de gestionar HTTPS, redirigir las peticiones HTTP, aplicar medidas de seguridad y reenviar las solicitudes al backend Apache.

## 1. Generación del certificado TLS

Se genera un certificado autofirmado para el entorno de laboratorio utilizando criptografía de curva elíptica (ECC), concretamente la curva `secp384r1`.

### 1.1. Creación de la clave privada

```bash
cd nginx/certs

openssl ecparam -name secp384r1 -genkey -noout -out nimbus.key
```

Este comando genera una clave privada EC que se utilizará para las operaciones criptográficas de TLS.

### 1.2. Generación del certificado autofirmado

```bash
openssl req -new -x509 -days 365 \
    -key nimbus.key \
    -out nimbus.crt \
    -subj "/CN=alfa.nimbus-lab.local"
```

### 1.3. Regreso al directorio raíz

```bash
cd ../..
```

### Archivos generados

```text
nginx/
├── certs/
│   ├── nimbus.key
│   └── nimbus.crt
└── default.conf
```

| Archivo | Función |
|---|---|
| `nimbus.key` | Clave privada utilizada por Nginx para TLS. |
| `nimbus.crt` | Certificado autofirmado presentado a los clientes. |

**Características del certificado:**

- Algoritmo de clave: criptografía de curva elíptica (EC).
- Curva: `secp384r1`.
- Tipo: certificado autofirmado.
- Validez solicitada: 365 días.
- Nombre común (CN): `alfa.nimbus-lab.local`.

> **Nota de seguridad:** El certificado generado es autofirmado y está pensado para un laboratorio. Los navegadores y clientes no confiarán automáticamente en él. Además, aunque el certificado incluye el CN de Alfa, la configuración lo presenta también al acceder a Beta. Para un despliegue real, conviene utilizar nombres SAN que incluyan ambos dominios y un certificado emitido por una autoridad de confianza.

---

## 2. Configuración de Nginx

**Archivo:** `nginx/default.conf`

Nginx realiza la terminación TLS y actúa como proxy inverso hacia Apache.

La configuración incluye:

- Redirección HTTP a HTTPS.
- Protocolos TLS seguros.
- Cabeceras de seguridad HTTP.
- Reenvío de cabeceras al backend.
- Limitación de la tasa de peticiones mediante Rate Limiting.

### Configuración completa

```nginx
# Límite de peticiones: 5 solicitudes por segundo por IP
limit_req_zone $binary_remote_addr zone=nimbus_limit:10m rate=5r/s;

# ==========================================================
# SERVIDOR HTTP: REDIRECCIÓN A HTTPS
# ==========================================================

server {
    listen 80;

    server_name alfa.nimbus-lab.local beta.nimbus-lab.local;

    # Redirección permanente de HTTP a HTTPS
    return 301 https://$host$request_uri;
}

# ==========================================================
# SERVIDOR HTTPS: PROXY INVERSO
# ==========================================================

server {
    listen 443 ssl;

    server_name alfa.nimbus-lab.local beta.nimbus-lab.local;

    # Certificado y clave privada
    ssl_certificate /etc/nginx/certs/nimbus.crt;
    ssl_certificate_key /etc/nginx/certs/nimbus.key;

    # Protocolos TLS permitidos
    ssl_protocols TLSv1.2 TLSv1.3;

    # Cifrados permitidos
    ssl_ciphers HIGH:!aNULL:!MD5;

    # ------------------------------------------------------
    # CABECERAS DE SEGURIDAD
    # ------------------------------------------------------

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    add_header X-Content-Type-Options "nosniff" always;

    add_header X-Frame-Options "SAMEORIGIN" always;

    # ------------------------------------------------------
    # PROXY INVERSO Y RATE LIMITING
    # ------------------------------------------------------

    location / {

        # Limitar las peticiones por dirección IP
        limit_req zone=nimbus_limit burst=10 nodelay;

        # Reenviar las solicitudes al backend Apache
        proxy_pass http://apache-backend:80;

        # Preservar el dominio solicitado
        proxy_set_header Host $host;

        # Transmitir la IP original del cliente
        proxy_set_header X-Real-IP $remote_addr;

        # Mantener la cadena de IP de los intermediarios
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # Indicar el protocolo utilizado por el cliente
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Funcionamiento del proxy inverso

Cuando un usuario solicita una página web, el recorrido de la petición es el siguiente:

1. El cliente se conecta a Nginx.
2. Si utiliza HTTP, Nginx devuelve una redirección permanente a HTTPS.
3. Si utiliza HTTPS, Nginx establece la conexión TLS.
4. Nginx comprueba las reglas de limitación de peticiones.
5. La solicitud se reenvía a Apache mediante la red interna de Docker.
6. Apache identifica el Virtual Host a partir de la cabecera `Host`.
7. Apache procesa la solicitud y devuelve la respuesta.
8. Nginx transmite la respuesta al cliente.

**Ventaja principal:** Apache no necesita gestionar directamente las conexiones HTTPS de los clientes, ya que Nginx centraliza la terminación TLS.

---

## 3. Justificación de las medidas de seguridad

### 3.1. Redirección HTTP a HTTPS

```nginx
return 301 https://$host$request_uri;
```

La directiva devuelve el código HTTP `301 Moved Permanently`, indicando que el recurso debe solicitarse mediante HTTPS.

Esto permite dirigir al cliente hacia una conexión cifrada.

### 3.2. Restricción de protocolos TLS

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

Se permiten únicamente TLS 1.2 y TLS 1.3, evitando el uso de versiones antiguas e inseguras del protocolo.

### 3.3. Cabecera HSTS

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

La cabecera `Strict-Transport-Security` indica al navegador que debe utilizar HTTPS durante el periodo especificado.

| Parámetro | Función |
|---|---|
| `max-age=31536000` | Establece una duración de un año, expresada en segundos. |
| `includeSubDomains` | Extiende la política a los subdominios. |
| `always` | Solicita incluir la cabecera también en respuestas de error. |

**Consideración:** HSTS debe utilizarse con cuidado en dominios reales, especialmente cuando se incluye `includeSubDomains`. En este laboratorio, los nombres terminados en `.local` y el certificado autofirmado no constituyen una configuración pública de producción.

### 3.4. Protección contra MIME-Sniffing

```nginx
add_header X-Content-Type-Options "nosniff" always;
```

Esta cabecera indica al navegador que no debe intentar interpretar el contenido como un tipo MIME diferente del declarado por el servidor.

Ayuda a reducir determinados riesgos relacionados con la interpretación incorrecta de los recursos.

### 3.5. Protección contra Clickjacking

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
```

Esta cabecera restringe la incrustación de la página en marcos procedentes de otros orígenes.

Ayuda a reducir el riesgo de *Clickjacking*, un ataque que intenta engañar al usuario para que interactúe con una página incrustada de forma engañosa.

### 3.6. Rate Limiting

```nginx
limit_req_zone $binary_remote_addr zone=nimbus_limit:10m rate=5r/s;
```

Esta directiva define una zona compartida de memoria que controla la frecuencia de las peticiones en función de la dirección IP del cliente.

```nginx
limit_req zone=nimbus_limit burst=10 nodelay;
```

| Parámetro | Función |
|---|---|
| `rate=5r/s` | Establece una tasa media de 5 peticiones por segundo por IP. |
| `zone=nimbus_limit:10m` | Reserva una zona de memoria de 10 MB para mantener el estado del limitador. |
| `burst=10` | Permite una ráfaga de hasta 10 peticiones por encima de la tasa sostenida. |
| `nodelay` | Permite procesar inmediatamente las peticiones que caben en la ráfaga, en lugar de retrasarlas. |

Cuando se supera el límite admitido, Nginx rechaza las peticiones excedentes.

Por defecto, el módulo `limit_req` utiliza el código HTTP `503` cuando rechaza solicitudes, aunque este comportamiento puede modificarse mediante la directiva `limit_req_status`.

> **Importante:** `burst=10` no significa que el servidor acepte exactamente 15 peticiones por segundo. El limitador controla la tasa mediante un mecanismo de acumulación de solicitudes, y el resultado de una prueba depende del ritmo real de llegada de las peticiones y del estado previo del limitador.

---

# 🐳 V. Despliegue y orquestación con Docker Compose

## 1. Configuración de Docker Compose

Se utiliza Docker Compose para desplegar y conectar los servicios de Apache y Nginx.

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

### Descripción de los servicios

| Servicio | Función | Puertos publicados |
|---|---|---|
| `apache-backend` | Aloja los contenidos web y gestiona los Virtual Hosts. | Ninguno |
| `nginx-proxy` | Gestiona HTTPS, las redirecciones y el proxy inverso. | `8080:80` y `8443:443` |
| `nimbus-net` | Permite la comunicación entre los contenedores. | No aplica |

### Aspectos importantes de la configuración

#### Volúmenes de solo lectura

Los montajes terminados en `:ro` permiten que los contenedores lean los archivos del proyecto sin modificarlos desde dentro del contenedor.

#### Red interna

Ambos servicios están conectados a la red `nimbus-net`, por lo que Nginx puede acceder a Apache utilizando el nombre del servicio:

```nginx
proxy_pass http://apache-backend:80;
```

Docker Compose proporciona resolución de nombres entre los servicios conectados a la misma red.

#### Dependencia entre servicios

```yaml
depends_on:
  - apache-backend
```

Establece que Compose debe iniciar Apache antes que Nginx.

Sin embargo, `depends_on` por sí solo no garantiza que Apache esté preparado para recibir solicitudes cuando Nginx comience a funcionar.

#### Publicación de puertos

```yaml
ports:
  - "8080:80"
  - "8443:443"
```

Las conexiones recibidas en los puertos `8080` y `8443` del equipo anfitrión se dirigen a los puertos `80` y `443` del contenedor de Nginx, respectivamente.

### Consideración técnica sobre Apache

La configuración utiliza la imagen `httpd:2.4` y añade los archivos de Virtual Host al fichero principal mediante `Include`.

Para que funcione correctamente, Apache debe tener habilitado el módulo de autorización necesario para `Require all granted` y `Require all denied`, además de escuchar en el puerto 80.

También debe estar configurado el acceso a los directorios `/var/www/html/marca-alfa` y `/var/www/html/marca-beta`.

---

## 2. Arranque del entorno

Desde el directorio raíz del proyecto, ejecutar:

```bash
docker compose up -d
```

Este comando crea e inicia los servicios en segundo plano.

### Comprobar el estado de los contenedores

```bash
docker compose ps
```

### Consultar los registros

```bash
docker compose logs
```

Para consultar únicamente los registros de Nginx:

```bash
docker compose logs nginx-proxy
```

Para consultar los registros de Apache:

```bash
docker compose logs apache-backend
```

### Validar la configuración de Nginx

```bash
docker compose exec nginx-proxy nginx -t
```

### Detener el entorno

```bash
docker compose down
```

---

# 🧪 VI. Pruebas de verificación y resultados

Las pruebas permiten comprobar que la infraestructura funciona correctamente y que las medidas de seguridad implementadas producen el comportamiento esperado.

> **Requisito previo:** Los dominios `alfa.nimbus-lab.local` y `beta.nimbus-lab.local` deben resolver hacia la dirección IP del equipo anfitrión. Los ejemplos siguientes utilizan `curl --resolve` para forzar la resolución a `127.0.0.1` sin modificar el fichero `/etc/hosts`.

## 1. Verificación de la redirección HTTP a HTTPS

### Comando

```bash
curl -I \
  --resolve alfa.nimbus-lab.local:8080:127.0.0.1 \
  http://alfa.nimbus-lab.local:8080/
```

### Resultado esperado

```http
HTTP/1.1 301 Moved Permanently
Server: nginx
Location: https://alfa.nimbus-lab.local/
```

La cabecera `Location` indica la URL de destino de la redirección.

**Resultado:** La conexión HTTP se redirige a HTTPS mediante el código `301`.

> **Nota:** La redirección no conserva el puerto `8443` en la configuración actual. Por tanto, la URL generada apunta al puerto HTTPS predeterminado `443`, no al puerto `8443` publicado por Docker. Para que la prueba funcione en el entorno descrito, es necesario adaptar la redirección al puerto publicado.

Una alternativa para este laboratorio es utilizar:

```nginx
return 301 https://$host:8443$request_uri;
```

De esta forma, la redirección apunta al puerto HTTPS publicado en el equipo anfitrión.

---

## 2. Verificación del acceso HTTPS a las marcas

Se comprueba que Nginx recibe las peticiones HTTPS y las reenvía al Virtual Host correspondiente de Apache.

El parámetro `-k` permite que `curl` continúe la conexión aunque el certificado sea autofirmado y no esté firmado por una autoridad de confianza.

### 2.1. Acceso a Marca Alfa

**Comando:**

```bash
curl -k \
  --resolve alfa.nimbus-lab.local:8443:127.0.0.1 \
  https://alfa.nimbus-lab.local:8443/
```

**Resultado esperado:**

```html
<h1>Portal Técnico Oficial - Marca Alfa</h1>
```

**Interpretación:** La solicitud llega a Nginx, que conserva el nombre del dominio mediante la cabecera `Host`. Apache identifica el Virtual Host de Alfa y devuelve su página principal.

### 2.2. Acceso a Marca Beta

**Comando:**

```bash
curl -k \
  --resolve beta.nimbus-lab.local:8443:127.0.0.1 \
  https://beta.nimbus-lab.local:8443/
```

**Resultado esperado:**

```html
<h1>Portal Interno Restringido - Marca Beta</h1>
```

**Interpretación:** Apache identifica el dominio `beta.nimbus-lab.local` y sirve el contenido de la marca Beta.

### Conclusión de la prueba

Los resultados demuestran que una única instancia de Apache puede alojar varios sitios web independientes y que Nginx puede actuar como punto de entrada común para ambos dominios.

---

## 3. Verificación del recurso protegido en Marca Beta

Se comprueba que el archivo confidencial no puede descargarse mediante una petición HTTP.

### Comando

```bash
curl -k -I \
  --resolve beta.nimbus-lab.local:8443:127.0.0.1 \
  https://beta.nimbus-lab.local:8443/secreto-beta.txt
```

### Resultado esperado

```http
HTTP/1.1 403 Forbidden
```

### Interpretación

El código `403 Forbidden` indica que el servidor ha entendido la solicitud, pero deniega el acceso al recurso.

La restricción está definida en el Virtual Host de Apache mediante:

```apache
<Files "secreto-beta.txt">
    Require all denied
</Files>
```

Esta prueba confirma que el recurso confidencial está protegido frente a solicitudes HTTP directas.

---

## 4. Verificación del Rate Limiting

Se realizan múltiples solicitudes consecutivas a la página principal de Alfa para comprobar el comportamiento del limitador de peticiones configurado en Nginx.

### Comando

```bash
for i in {1..20}; do
    curl -k -s -o /dev/null \
        -w "%{http_code}\n" \
        --resolve alfa.nimbus-lab.local:8443:127.0.0.1 \
        https://alfa.nimbus-lab.local:8443/
done
```

### Explicación del comando

| Parámetro | Función |
|---|---|
| `for i in {1..20}` | Ejecuta el bloque 20 veces. |
| `curl -k` | Permite utilizar el certificado autofirmado. |
| `-s` | Reduce la salida de `curl`. |
| `-o /dev/null` | Descarta el contenido HTML de la respuesta. |
| `-w "%{http_code}\n"` | Muestra el código HTTP de cada petición. |
| `--resolve` | Asocia el dominio y el puerto a `127.0.0.1`. |

### Salida observada

```text
200
200
200
200
200
200
200
200
200
200
200
200
200
200
200
503
503
503
503
503
```

### Interpretación

- **HTTP 200 OK:** La petición se ha procesado correctamente.
- **HTTP 503 Service Temporarily Unavailable:** Nginx ha rechazado la petición por superar el límite configurado.

Los resultados observados muestran que las primeras solicitudes se procesan correctamente, mientras que las posteriores son rechazadas por el mecanismo de limitación.

> **Nota:** El resultado exacto puede variar según el ritmo de llegada de las peticiones y el estado del limitador. Si las solicitudes se ejecutan demasiado lentamente, puede que no se produzcan respuestas `503`. Para obtener resultados reproducibles, conviene ejecutar varias pruebas y consultar los registros de Nginx.

---

# 🏗️ VII. Arquitectura final

La infraestructura se divide en dos componentes principales:

- **Nginx:** punto de entrada para las conexiones de los clientes. Gestiona HTTP, HTTPS, los certificados TLS, las cabeceras de seguridad y el Rate Limiting.
- **Apache:** servidor web interno que aloja las marcas y aplica las reglas de acceso a los recursos.

## Diagrama lógico

```text
                     CLIENTE WEB
                          |
                          |
             +------------+------------+
             |                         |
             | HTTP :8080              | HTTPS :8443
             |                         |
             v                         v
                  NGINX REVERSE PROXY
                +-----------------------+
                | Redirección HTTP/HTTPS|
                | Terminación TLS       |
                | Cabeceras de seguridad|
                | Rate Limiting         |
                +-----------------------+
                          |
                          |
                    Red Docker
                     nimbus-net
                          |
                          v
                   APACHE BACKEND
                +-----------------------+
                | Virtual Host Alfa     |
                | Virtual Host Beta     |
                | Control de acceso     |
                | Registros separados   |
                +-----------------------+
                     |           |
                     |           |
                     v           v
                 MARCA ALFA  MARCA BETA
                 index.html  index.html
                             secreto-beta.txt
                             (acceso denegado)
```

### Estructura final del proyecto

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
│
├── nginx/
│   ├── certs/
│   │   ├── nimbus.key
│   │   └── nimbus.crt
│   └── default.conf
│
├── docker-compose.yml
└── README.md
```

---

# ✅ VIII. Conclusiones

En este proyecto se ha desplegado una infraestructura web multi-marca mediante Docker Compose, combinando Apache y Nginx para separar la publicación segura de los contenidos de su gestión interna.

Las principales funcionalidades implementadas son:

- **Alojamiento multi-marca:** dos sitios web independientes mediante Virtual Hosts de Apache.
- **Proxy inverso:** Nginx centraliza las conexiones de los clientes y reenvía las solicitudes al backend.
- **Terminación TLS:** se habilita HTTPS mediante un certificado autofirmado basado en criptografía de curva elíptica.
- **Redirección HTTP a HTTPS:** se establece el mecanismo para dirigir las conexiones hacia HTTPS.
- **Cabeceras de seguridad:** se implementan HSTS, `X-Content-Type-Options` y `X-Frame-Options`.
- **Protección de recursos:** Apache deniega el acceso HTTP al archivo confidencial de la marca Beta.
- **Rate Limiting:** Nginx limita la frecuencia de las peticiones por dirección IP.
- **Contenerización:** Docker Compose permite desplegar y conectar los servicios mediante una red virtual.

Las pruebas de verificación permiten comprobar el funcionamiento de los Virtual Hosts, la protección del recurso confidencial y el mecanismo de limitación de peticiones.

Como posibles mejoras para un entorno de producción, se propone incorporar certificados emitidos por una autoridad de confianza, configurar correctamente los nombres SAN, reforzar el control de acceso de la marca Beta y establecer comprobaciones de salud para los servicios.

---

**Proyecto:** NimbusDocs — Portal Documental Seguro Multi-Marca

**Tecnologías:** Apache HTTP Server · Nginx · Docker · Docker Compose · OpenSSL