# 📻 Radio Marea — Práctica 2 de IAW

### Administración de Sistemas Informáticos en Red (2.º ASIR)

**Módulo:** Implantación de Aplicaciones Web (IAW)  
**Proyecto:** Radio Marea — Web, API y base de datos  
**Tecnologías:** Docker, Nginx, PHP, Flask, Gunicorn, MariaDB y Bash

---

## 📑 Índice

1. [Descripción del proyecto](#1-descripción-del-proyecto)
2. [Objetivos de la práctica](#2-objetivos-de-la-práctica)
3. [Tecnologías utilizadas](#3-tecnologías-utilizadas)
4. [Arquitectura del proyecto](#4-arquitectura-del-proyecto)
5. [Estructura de archivos](#5-estructura-de-archivos)
6. [Instalación y puesta en marcha](#6-instalación-y-puesta-en-marcha)
7. [Bloque A — Nginx y PHP](#7-bloque-a--nginx-y-php)
8. [Bloque B — Flask y Gunicorn](#8-bloque-b--flask-y-gunicorn)
9. [Bloque C — MariaDB](#9-bloque-c--mariadb)
10. [Errores encontrados y soluciones](#10-errores-encontrados-y-soluciones)
11. [Comprobación de la práctica](#11-comprobación-de-la-práctica)
12. [Comandos útiles](#12-comandos-útiles)
13. [Seguridad implementada](#13-seguridad-implementada)
14. [Conclusiones](#14-conclusiones)

---

# 1. Descripción del proyecto

Radio Marea es una aplicación web que simula el funcionamiento de una emisora de radio local.

El proyecto incluye una página web donde los usuarios pueden consultar la programación y una API que proporciona información sobre los podcasts disponibles.

Además, cuenta con una base de datos MariaDB que almacena la información de los programas y podcasts.

La aplicación está dividida en varios servicios que funcionan mediante contenedores Docker.

El objetivo de la práctica ha sido configurar estos servicios, conectarlos entre sí y aplicar medidas de seguridad para conseguir una aplicación funcional.

### Funcionalidades principales

- Página web con información de Radio Marea.
- Consulta de la programación semanal.
- Consulta de podcasts mediante una API REST.
- Búsqueda de podcasts por título.
- Acceso protegido a determinadas rutas mediante sesiones.
- Conexión de PHP y Python con MariaDB.
- Protección frente a inyecciones SQL y XSS.
- Gestión de usuarios y permisos en MariaDB.
- Copias de seguridad de la base de datos.
- Comunicación segura mediante HTTPS.

---

# 2. Objetivos de la práctica

Los principales objetivos han sido:

1. Configurar Nginx para servir una aplicación PHP.
2. Conectar Nginx con PHP-FPM mediante FastCGI.
3. Configurar PHP para un entorno de producción.
4. Proteger la aplicación frente a ataques XSS.
5. Configurar Nginx como proxy inverso para una API Flask.
6. Implementar autenticación mediante sesiones.
7. Configurar Gunicorn para ejecutar la API.
8. Crear endpoints que devuelvan información en JSON.
9. Administrar usuarios y permisos en MariaDB.
10. Conectar PHP y Python con una base de datos.
11. Utilizar consultas preparadas para evitar inyecciones SQL.
12. Automatizar copias de seguridad mediante un script de shell.

La práctica está dividida en tres bloques:

| Bloque | Tecnologías principales | Objetivo |
|---|---|---|
| A | Nginx y PHP-FPM | Configurar y proteger la página web |
| B | Flask y Gunicorn | Configurar y proteger la API |
| C | MariaDB | Conectar los servicios y gestionar los datos |

---

# 3. Tecnologías utilizadas

| Tecnología | Función |
|---|---|
| Docker | Ejecutar los servicios en contenedores |
| Docker Compose | Gestionar todos los contenedores |
| Nginx | Servidor web y proxy inverso |
| PHP 8.3 | Desarrollo de la aplicación web |
| PHP-FPM | Ejecutar PHP mediante FastCGI |
| Python | Desarrollo de la API |
| Flask | Framework para crear los endpoints |
| Gunicorn | Servidor WSGI para ejecutar Flask |
| MariaDB 11.4 | Almacenar programas y podcasts |
| PDO | Conectar PHP con MariaDB |
| PyMySQL | Conectar Python con MariaDB |
| Bash / Shell | Automatizar tareas administrativas |
| Git y GitHub | Control de versiones |

---

# 4. Arquitectura del proyecto

La aplicación está formada por varios contenedores que se comunican entre sí.

```text
                       USUARIO
                          |
                          |
                        HTTPS
                          |
                          v
                       NGINX
                          |
              +-----------+-----------+
              |                       |
              v                       v
           PHP-FPM                 GUNICORN
          Página web               API Flask
              |                       |
              |                       |
             PDO                    PyMySQL
              |                       |
              +-----------+-----------+
                          |
                          v
                        MariaDB
                          |
                 Base de datos radio
                  /             \
                 v               v
             programas         podcasts
```

### Funcionamiento

Cuando un usuario accede a la web, la petición llega primero a Nginx.

Nginx decide qué servicio debe atenderla dependiendo de la dirección solicitada.

Si se solicita una página PHP, la petición se envía a PHP-FPM.

Si la dirección comienza por `/api/`, se envía a Gunicorn, que ejecuta nuestra aplicación Flask.

Tanto PHP como Python pueden conectarse a MariaDB para consultar los datos.

### Servicios Docker

| Servicio | Contenedor | Función |
|---|---|---|
| nginx | iawp2-nginx | Servidor web y proxy inverso |
| php | iawp2-php | Ejecutar las páginas PHP |
| app | iawp2-app | Ejecutar Flask y Gunicorn |
| db | iawp2-db | Servidor MariaDB |
| admin | iawp2-admin | Administración y copias de seguridad |
| cliente | iawp2-cliente | Realizar pruebas de acceso |

### Puertos

| Puerto | Protocolo | Función |
|---|---|---|
| 8091 | HTTP | Redirección hacia HTTPS |
| 8452 | HTTPS | Acceso seguro a Radio Marea |
| 9000 | FastCGI | Comunicación interna con PHP-FPM |
| 8000 | HTTP | Comunicación interna con Gunicorn |
| 3306 | MariaDB | Comunicación interna con la base de datos |

Los servicios internos no necesitan estar publicados directamente en el ordenador anfitrión.

La base de datos utiliza una red interna de Docker para reducir su exposición.

---

# 5. Estructura de archivos

```text
p2-radio-marea/
│
├── app/
│   └── app.py
│
├── web/
│   ├── index.php
│   ├── parrilla.php
│   ├── salud.php
│   └── inc/
│       ├── db.php
│       ├── datos.php
│       └── util.php
│
├── servidor/
│   ├── nginx/
│   │   └── radio.conf
│   │
│   ├── php/
│   │   └── produccion.ini
│   │
│   ├── gunicorn.conf.py
│   ├── radio.env
│   └── copia.sh
│
├── sql/
│   ├── 01-radio.sql
│   └── usuarios.sql
│
├── docker/
│
├── comprobador/
│
├── copias/
│
├── logs/
│
├── compose.yaml
├── practica.sh
└── README.md
```

### Archivos principales

**`servidor/nginx/radio.conf`**

Contiene la configuración de Nginx, las rutas de PHP, el proxy inverso y las restricciones de acceso.

**`servidor/php/produccion.ini`**

Contiene la configuración de seguridad de PHP.

**`app/app.py`**

Contiene la API Flask, sus rutas y las funciones de conexión con MariaDB.

**`web/inc/db.php`**

Gestiona la conexión de PHP con MariaDB mediante PDO.

**`web/inc/datos.php`**

Contiene las consultas utilizadas para obtener la programación.

**`sql/usuarios.sql`**

Crea los usuarios de MariaDB y establece sus permisos.

**`servidor/copia.sh`**

Realiza las copias de seguridad de MariaDB.

**`servidor/radio.env`**

Contiene las variables de configuración y las credenciales.

Este último archivo está excluido de Git mediante `.gitignore`.

---

# 6. Instalación y puesta en marcha

## 6.1. Requisitos

Para ejecutar la práctica necesitamos:

- Linux o un sistema compatible con Docker.
- Docker instalado y funcionando.
- Docker Compose.
- Git.
- Un navegador web.
- Terminal de Linux.

## 6.2. Entrar en la carpeta del proyecto

Situándonos en el repositorio de IAW:

```bash
cd practica2/kit-iaw-p2-radio-marea/p2-radio-marea
```

Todos los comandos siguientes se ejecutan desde esta carpeta.

## 6.3. Arrancar los servicios

```bash
./practica.sh arrancar
```

Este comando inicia los contenedores de Docker necesarios para ejecutar Radio Marea.

La primera vez también puede ser necesario construir las imágenes.

Podemos comprobar los contenedores mediante:

```bash
docker compose ps
```

## 6.4. Configuración de variables de entorno

La práctica necesita un archivo privado:

```text
servidor/radio.env
```

Debe contener las variables necesarias para los distintos servicios.

Ejemplo de estructura:

```ini
# Acceso al estudio
LOCUTOR_CLAVE=CAMBIAR_CLAVE_DEL_ESTUDIO

# Firma de sesiones de Flask
SECRET_KEY=CAMBIAR_POR_UNA_CLAVE_ALEATORIA_LARGA

# MariaDB
DB_HOST=db
DB_NAME=radio
DB_USER=radio_web
DB_PASS=COLOCAR_LA_CONTRASENA_DE_USUARIOS_SQL

# Usuario para copias
COPIAS_USER=radio_copias
COPIAS_PASS=COLOCAR_LA_CONTRASENA_DE_USUARIOS_SQL
```

**Los valores anteriores son marcadores de ejemplo y no son credenciales reales.**

Las contraseñas deben coincidir con las que se hayan establecido para los usuarios de MariaDB.

Se puede generar una clave aleatoria para Flask con:

```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

> Importante: nunca subir `radio.env` a GitHub ni compartir sus contraseñas.

## 6.5. Aplicar los usuarios de MariaDB

```bash
./practica.sh sql
```

Este comando ejecuta las instrucciones del archivo `sql/usuarios.sql`.

Crea los usuarios y aplica sus permisos.

En una instalación nueva, hay que asegurarse de que las contraseñas de `radio.env` coincidan con las configuradas en MariaDB.

## 6.6. Permisos de radio.env

Durante la práctica encontramos un problema porque PHP-FPM no podía leer `radio.env`.

En nuestro entorno se solucionó configurando el grupo que utiliza PHP-FPM y asignando permisos de lectura:

```bash
sudo chgrp 33 servidor/radio.env
chmod 640 servidor/radio.env
```

El GID 33 corresponde a `www-data` en el contenedor PHP utilizado en el laboratorio.

Podemos comprobarlo con:

```bash
docker compose exec -T --user www-data php \
sh -c 'test -r /etc/radio/radio.env && echo "Lectura correcta"'
```

Estos cambios solo deben aplicarse cuando los permisos y los usuarios del entorno lo requieran.

## 6.7. Recargar los servicios

```bash
./practica.sh recargar
```

El comando comprueba la configuración de Nginx, la recarga y reinicia PHP y la API.

## 6.8. Acceder a la aplicación

Abrir en el navegador:

```text
https://localhost:8452/
```

El certificado utilizado es de laboratorio, por lo que el navegador puede mostrar un aviso de seguridad.

---

# 7. Bloque A — Nginx y PHP

Este bloque consiste en configurar la página web de Radio Marea y aplicar medidas de seguridad.

## A0 — Configuración inicial de Nginx

El kit ya incluía la configuración básica de HTTPS y el servicio de archivos estáticos.

Entre otras cosas, Nginx redirige las peticiones HTTP hacia HTTPS mediante:

```nginx
return 301 https://$host$request_uri;
```

El código `301` indica una redirección permanente.

También puede servir archivos estáticos como `estilo.css`.

### Comprobación

```bash
./practica.sh comprobar A
```

---

## A1 — Conexión entre Nginx y PHP-FPM

### Objetivo

Conseguir que Nginx ejecute los archivos PHP utilizando PHP-FPM en lugar de descargarlos o tratarlos como archivos estáticos.

### Configuración

Archivo:

```text
servidor/nginx/radio.conf
```

Se configuró:

```nginx
index index.php;

location ~ \.php$ {
    try_files $uri =404;
    include fastcgi_params;
    fastcgi_pass php:9000;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
}
```

### Explicación

**`index index.php`**

Indica que Nginx debe buscar `index.php` como página principal.

**`location ~ \.php$`**

Identifica las peticiones que terminan en `.php`.

**`try_files $uri =404`**

Comprueba que el archivo solicitado existe.

Si no existe, Nginx devuelve un error 404.

**`include fastcgi_params`**

Carga los parámetros necesarios para comunicarse con PHP-FPM.

**`fastcgi_pass php:9000`**

Envía la petición al servicio `php` por el puerto 9000.

**`fastcgi_param SCRIPT_FILENAME ...`**

Indica a PHP-FPM qué archivo PHP debe ejecutar.

### Comprobación

```bash
./practica.sh recargar
./practica.sh comprobar A
```

El resultado esperado es que las páginas PHP se ejecuten y que un archivo PHP inexistente devuelva 404.

---

## A2 — Configuración segura de PHP

### Objetivo

Preparar PHP para producción, evitando mostrar información sensible a los visitantes.

Archivo:

```text
servidor/php/produccion.ini
```

### A2.1 — Ocultar la versión de PHP

```ini
expose_php = Off
```

Evita que PHP anuncie su versión mediante la cabecera `X-Powered-By`.

Esto reduce la información técnica que se muestra públicamente.

### A2.2 — Gestionar correctamente los errores

```ini
display_errors = Off
display_startup_errors = Off
log_errors = On
error_log = /var/log/radio/php-errores.log
```

Los errores no deben aparecer directamente en la página web.

En su lugar, quedan registrados en un archivo que puede consultar el administrador.

Así evitamos mostrar rutas internas y otros detalles de la aplicación.

### A2.3 — Deshabilitar funciones peligrosas

```ini
disable_functions = exec,shell_exec,system,passthru,proc_open,popen
```

Estas funciones permiten ejecutar comandos del sistema desde PHP.

Se han deshabilitado porque nuestra aplicación no necesita utilizarlas.

De esta manera reducimos las posibilidades de ejecutar órdenes del sistema a través de la aplicación PHP.

### Comprobación

```bash
./practica.sh recargar
./practica.sh comprobar A
```

---

## A3 — Protección frente a XSS

### Objetivo

Evitar que el contenido introducido por los usuarios se interprete como código HTML o JavaScript.

Archivo:

```text
web/inc/util.php
```

Creamos la función:

```php
function e(string $texto): string
{
    return htmlspecialchars(
        $texto,
        ENT_QUOTES | ENT_SUBSTITUTE,
        'UTF-8'
    );
}
```

### Explicación

`htmlspecialchars()` transforma los caracteres especiales en entidades HTML.

Por ejemplo:

```html
<script>alert('Hola')</script>
```

Se transforma en texto que el navegador puede mostrar sin ejecutar el script.

**`ENT_QUOTES`**

Permite escapar comillas simples y dobles.

Esto es importante tanto en el contenido HTML como dentro de atributos.

**`ENT_SUBSTITUTE`**

Sustituye secuencias de caracteres inválidas durante la conversión.

**`UTF-8`**

Indica la codificación de caracteres utilizada.

### Diferencia importante

Escapar HTML ayuda a prevenir ataques XSS, pero no sustituye a las consultas preparadas utilizadas para prevenir inyecciones SQL.

Son problemas de seguridad distintos.

---

## A4 — Protección de archivos internos

### Objetivo

Evitar que los visitantes puedan acceder directamente a determinados archivos de la aplicación.

### A4.1 — Bloquear diagnostico.php

```nginx
location = /diagnostico.php {
    return 403;
}
```

El símbolo `=` indica una coincidencia exacta.

Si alguien solicita `/diagnostico.php`, Nginx devuelve:

```text
403 Forbidden
```

Este archivo contiene información técnica que no debería estar disponible públicamente.

### A4.2 — Proteger la carpeta inc/

```nginx
location ^~ /inc/ {
    return 403;
}
```

La carpeta `inc/` contiene archivos internos utilizados por PHP.

No queremos que los visitantes puedan solicitarlos directamente.

El modificador `^~` hace que esta ubicación de prefijo tenga prioridad sobre las ubicaciones definidas mediante expresiones regulares cuando coincide.

Esto es importante porque también tenemos una ubicación que procesa archivos `.php`.

### Comprobación

```bash
./practica.sh comprobar A
```

Las rutas protegidas deben devolver 403.

---

# 8. Bloque B — Flask y Gunicorn

Este bloque consiste en configurar la API de Radio Marea y proteger el acceso a determinadas funciones.

## B0 — API inicial

El kit incluye una API desarrollada con Flask.

Entre sus rutas encontramos:

```text
/api/salud
/api/quien
/api/podcasts
/api/entrar
/api/estudio
```

Flask permite definir rutas mediante decoradores.

Por ejemplo:

```python
@app.route("/api/salud")
def salud():
    return jsonify({"ok": True})
```

`jsonify()` convierte los datos en una respuesta JSON.

---

## B1 — Nginx como proxy inverso

### Objetivo

Conseguir que las peticiones dirigidas a `/api/` lleguen a la aplicación Flask mediante Gunicorn.

Archivo:

```text
servidor/nginx/radio.conf
```

Configuración:

```nginx
location /api/ {
    proxy_pass http://app:8000;

    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

### Explicación

**`location /api/`**

Identifica las peticiones que comienzan por `/api/`.

**`proxy_pass http://app:8000`**

Envía esas peticiones al contenedor `app`, donde Gunicorn escucha en el puerto 8000.

Es importante no añadir una barra final innecesaria al destino, porque podría modificar la ruta que recibe Flask.

### Cabeceras

| Cabecera | Función |
|---|---|
| Host | Informa del nombre solicitado |
| X-Forwarded-Host | Conserva el host original |
| X-Forwarded-For | Transmite información de la IP del cliente |
| X-Forwarded-Proto | Informa del protocolo original, por ejemplo HTTPS |

Esto permite que la aplicación conozca información de la petición original.

---

## B2 — Protección del estudio y sesiones

### B2.1 — Restringir el acceso al estudio

Queremos que únicamente los locutores autenticados puedan acceder a `/api/estudio`.

En `app/app.py`:

```python
@app.route("/api/estudio")
def estudio():
    if "locutor" not in session:
        return jsonify({
            "error": "Primero, POST /api/entrar"
        }), 401

    return jsonify({
        "locutor": session.get("locutor"),
        "siguiente": "Noticias del puerto, a las 13:00"
    })
```

### Explicación

Cuando un locutor se autentica correctamente en `/api/entrar`, Flask guarda información de ese usuario en la sesión.

Después comprobamos:

```python
if "locutor" not in session:
```

Si no existe esa información, devolvemos un error HTTP 401.

El código `401 Unauthorized` indica que se necesita autenticación válida.

---

## B2.2 — Utilizar una clave secreta segura

Las sesiones de Flask necesitan una clave secreta para firmar sus cookies.

En lugar de escribir una clave fija en Python, utilizamos:

```python
app.secret_key = os.environ["SECRET_KEY"]
```

### Explicación

`os.environ` permite leer variables de entorno.

La clave se obtiene de `radio.env`, que no se sube a GitHub.

Además, al utilizar:

```python
os.environ["SECRET_KEY"]
```

la aplicación fallará al arrancar si la variable no existe, en lugar de utilizar silenciosamente una clave insegura.

---

## B2.3 — Evitar sesiones falsificadas

El kit utilizaba inicialmente una clave conocida.

Una persona que conociera esa clave podría intentar generar una cookie de sesión firmada con ella.

Al sustituirla por una clave larga y aleatoria, las cookies fabricadas con la clave anterior dejan de ser válidas.

### Comprobación

```bash
./practica.sh comprobar B
```

---

## B3 — Configuración de Gunicorn

### Objetivo

Configurar el número de procesos trabajadores de Gunicorn.

Archivo:

```text
servidor/gunicorn.conf.py
```

La práctica indica que el servidor de producción dispone de 3 CPU.

Utilizamos la regla:

```text
workers = 2 × CPU + 1
```

Por tanto:

```text
2 × 3 + 1 = 7
```

Configuración:

```python
workers = 7
```

### Explicación

Los workers son procesos que permiten a Gunicorn atender peticiones.

Esta fórmula es una regla orientativa utilizada en la práctica; en un servidor real habría que ajustar el número mediante pruebas de rendimiento.

---

## B4 — Consultar podcasts mediante su identificador

### B4.1 — Buscar un podcast por ID

Creamos la siguiente ruta:

```python
@app.route("/api/podcasts/<int:id>")
def podcast_por_id(id):
    for podcast in leer_podcasts():
        if podcast["id"] == id:
            return jsonify(podcast)

    return jsonify({
        "error": "No existe ese podcast"
    }), 404
```

### Explicación

**`<int:id>`**

Indica que la ruta recibe un número entero.

Por ejemplo:

```text
/api/podcasts/2
```

Flask convierte ese número en el parámetro `id`.

Después recorremos los podcasts obtenidos mediante `leer_podcasts()`.

Si encontramos el podcast solicitado, devolvemos sus datos en JSON.

Es importante utilizar `leer_podcasts()` porque posteriormente esa función fue modificada para obtener los datos reales desde MariaDB.

---

## B4.2 — Devolver errores 404 en JSON

Cuando un podcast no existe, devolvemos:

```python
return jsonify({
    "error": "No existe ese podcast"
}), 404
```

Esto devuelve dos cosas:

1. Un mensaje de error en JSON.
2. El código HTTP 404.

Inicialmente utilizábamos:

```python
abort(404)
```

Pero esa instrucción devuelve la respuesta de error predeterminada de Flask, normalmente en HTML.

Como estamos desarrollando una API, el ejercicio exige devolver el error en JSON.

---

## B4.3 — Rechazar métodos HTTP no permitidos

Nuestra ruta se define así:

```python
@app.route("/api/podcasts/<int:id>")
```

No hemos indicado:

```python
methods=["GET", "POST"]
```

Por defecto, Flask permite GET en esta ruta, además de gestionar automáticamente HEAD y OPTIONS.

Por tanto, si alguien intenta realizar una petición POST a esa dirección, Flask la rechaza.

### Ejemplo

```bash
curl -k -i -X POST \
https://localhost:8452/api/podcasts/2
```

Resultado esperado:

```text
405 Method Not Allowed
```

Esto significa que la ruta existe, pero no admite ese método HTTP.

### Códigos HTTP utilizados

| Código | Significado |
|---|---|
| 200 | Petición correcta |
| 301 | Redirección permanente |
| 401 | Autenticación necesaria |
| 403 | Acceso prohibido |
| 404 | Recurso no encontrado |
| 405 | Método HTTP no permitido |
| 502 | Error de comunicación con el servidor de destino |

---

# 9. Bloque C — MariaDB

Este bloque conecta la web y la API con una base de datos real.

## C0 — Comprobar la base de datos

Entramos en MariaDB mediante:

```bash
./practica.sh mariadb
```

Consultamos las tablas:

```sql
SHOW TABLES;
```

Resultado:

```text
podcasts
programas
```

También podemos consultar sus registros:

```sql
SELECT * FROM programas;
SELECT * FROM podcasts;
```

La base inicial contiene 20 programas y 6 podcasts.

Después salimos mediante:

```sql
exit;
```

---

## C1 — Crear usuarios y establecer permisos

### C1.1 — Crear radio_web

Creamos un usuario para que PHP y Python puedan consultar la base de datos.

En `sql/usuarios.sql`:

```sql
CREATE USER IF NOT EXISTS 'radio_web'@'%'
IDENTIFIED BY 'CONTRASENA_DE_LABORATORIO';

GRANT SELECT ON radio.* TO 'radio_web'@'%';
```

La contraseña mostrada es un marcador de ejemplo.

### Explicación

**`CREATE USER`**

Crea un usuario en MariaDB.

**`IF NOT EXISTS`**

Evita un error si el usuario ya existe.

**`'radio_web'@'%'`**

Permite que esa cuenta se autentique desde otros equipos, sujeto a las restricciones de red.

Esto es necesario porque PHP y Python están en contenedores diferentes del servidor MariaDB.

**`GRANT SELECT`**

Concede permisos de lectura.

**`ON radio.*`**

Aplica el permiso a todas las tablas de la base de datos `radio`.

El usuario no necesita permisos para modificar o eliminar información.

Esto aplica el principio de mínimo privilegio.

### C1.2 — Restringir el acceso de root

Añadimos:

```sql
DROP USER IF EXISTS 'root'@'%';
```

Eliminamos la cuenta que permitiría autenticarse como `root` desde cualquier host.

La cuenta local `root@localhost` permanece disponible.

### Aplicar los cambios

```bash
./practica.sh sql
```

---

## C2 — Conectar PHP y Python con MariaDB

### C2.1 — Configurar las credenciales

En `servidor/radio.env` configuramos:

```ini
DB_HOST=db
DB_NAME=radio
DB_USER=radio_web
DB_PASS=CONTRASENA_CONFIGURADA_EN_MARIADB
```

La contraseña debe coincidir con la del usuario creado en C1.

El archivo permanece fuera de GitHub.

---

## C2.2 — Conectar PHP mediante PDO

Archivo:

```text
web/inc/db.php
```

Creamos:

```php
function conectar(): PDO
{
    $cfg = leer_env('/etc/radio/radio.env');

    $dsn = "mysql:host={$cfg['DB_HOST']};dbname={$cfg['DB_NAME']};charset=utf8mb4";

    return new PDO(
        $dsn,
        $cfg['DB_USER'],
        $cfg['DB_PASS'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
        ]
    );
}
```

### Explicación

**`leer_env()`**

Lee las variables almacenadas en `radio.env`.

**`$dsn`**

Indica cómo conectarnos, qué servidor utilizar y qué base de datos queremos consultar.

**`new PDO()`**

Crea la conexión con MariaDB.

**`PDO::ERRMODE_EXCEPTION`**

Permite gestionar los errores mediante excepciones.

**`PDO::FETCH_ASSOC`**

Hace que los resultados se devuelvan como arrays asociativos.

### Comprobación

```bash
curl -ks https://localhost:8452/parrilla.php \
| grep -o 'Datos: [^<]*'
```

Resultado esperado:

```text
Datos: MariaDB, conectada como radio_web@%
```

---

## C2.3 — Conectar Python mediante PyMySQL

Archivo:

```text
app/app.py
```

Creamos:

```python
def conectar():
    return pymysql.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        database=os.environ["DB_NAME"],
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor
    )
```

### Explicación

`pymysql.connect()` establece la conexión con MariaDB.

Los datos de conexión se obtienen desde las variables de entorno.

`DictCursor` permite obtener los resultados como diccionarios de Python.

### Comprobación

```bash
curl -ks https://localhost:8452/api/salud
```

Resultado esperado:

```json
{
    "bd": "radio_web@%",
    "ok": true
}
```

---

## C2.4 — Proteger las contraseñas

Este apartado quedó resuelto al completar C2.2 y C2.3.

En lugar de escribir las contraseñas directamente en PHP o Python, las obtenemos desde `radio.env`.

En PHP:

```php
$cfg['DB_PASS']
```

En Python:

```python
os.environ["DB_PASS"]
```

Esto evita incluir las contraseñas directamente en el código de las aplicaciones.

El archivo de configuración se protege utilizando permisos adecuados y `.gitignore`.

---

## C3 — Consultar los datos reales de MariaDB

### C3.1 — Obtener los programas de la base de datos

Archivo:

```text
web/inc/datos.php
```

Sustituimos los programas de prueba por una consulta SQL:

```php
function programas(string $dia): array
{
    $st = conectar()->prepare(
        'SELECT hora, nombre, locutor FROM programas WHERE dia = ? ORDER BY hora'
    );

    $st->execute([$dia]);

    return $st->fetchAll();
}
```

### Explicación

`SELECT` selecciona las columnas que queremos consultar.

`FROM programas` indica la tabla.

`WHERE dia = ?` filtra los registros por día.

`ORDER BY hora` ordena la programación cronológicamente.

`fetchAll()` devuelve todos los registros obtenidos.

---

## C3.2 — Evitar inyecciones SQL

Este ejercicio también quedó resuelto al implementar C3.1.

Utilizamos:

```php
$st = conectar()->prepare(
    'SELECT hora, nombre, locutor FROM programas WHERE dia = ? ORDER BY hora'
);

$st->execute([$dia]);
```

La consulta está preparada y el día se pasa como un parámetro separado.

Esto evita que el contenido introducido por el usuario se interprete como una modificación de la consulta SQL.

### Ejemplo de intento de inyección

```text
lunes' OR '1'='1
```

Si concatenáramos directamente ese texto dentro de la consulta SQL, podría alterarse la condición `WHERE`.

Con `prepare()` y `execute()`, el contenido se interpreta como un valor y no como instrucciones SQL.

Por tanto, la consulta devuelve cero programas si no existe un día con ese nombre.

---

## C3.3 — Consultar los podcasts reales

Archivo:

```text
app/app.py
```

Modificamos `leer_podcasts()`:

```python
def leer_podcasts(buscar=""):
    with conectar() as conexion:
        with conexion.cursor() as cursor:
            cursor.execute(
                "SELECT id, titulo, programa, minutos "
                "FROM podcasts WHERE titulo LIKE %s ORDER BY fecha DESC",
                ("%" + buscar + "%",)
            )

            return cursor.fetchall()
```

### Explicación

La función obtiene los podcasts desde MariaDB.

**`LIKE`**

Permite buscar coincidencias de texto.

**`%s`**

Es un marcador para enviar parámetros de forma segura mediante PyMySQL.

**`ORDER BY fecha DESC`**

Ordena los podcasts desde el más reciente hasta el más antiguo.

**`fetchall()`**

Devuelve todos los resultados de la consulta.

### Comprobaciones

Consultar todos los podcasts:

```bash
curl -ks https://localhost:8452/api/podcasts
```

Buscar por título:

```bash
curl -ksG \
--data-urlencode "buscar=faro" \
https://localhost:8452/api/podcasts
```

La segunda consulta debe devolver el podcast cuyo título contiene la palabra `faro`.

---

## C4 — Copias de seguridad de MariaDB

### C4.1 — Crear las copias de seguridad

Archivo:

```text
servidor/copia.sh
```

Script:

```bash
#!/bin/sh

# C4.1 - Copia de seguridad de Radio Marea
set -e

# 1. Cargar las variables de radio.env
. /srv/servidor/radio.env

# 2. Obtener la fecha y la hora
FECHA=$(date +%Y%m%d-%H%M%S)

# 3. Crear la copia de seguridad
ARCHIVO="/copias/radio-$FECHA.sql"

mysqldump -h "$DB_HOST" -u "$COPIAS_USER" -p"$COPIAS_PASS" \
    --single-transaction --skip-lock-tables --no-tablespaces \
    "$DB_NAME" > "$ARCHIVO"

# 4. Eliminar copias antiguas
find /copias -maxdepth 1 -type f -name "radio-*.sql" -mtime +6 -delete

# 5. Mostrar el resultado
echo "Copia de seguridad creada: $ARCHIVO"
```

### Explicación

**`set -e`**

Hace que el script termine si falla una instrucción importante.

**`. /srv/servidor/radio.env`**

Carga las variables de configuración.

**`date +%Y%m%d-%H%M%S`**

Obtiene la fecha y hora utilizadas en el nombre de la copia.

**`mysqldump`**

Exporta la estructura y los datos de MariaDB a un archivo SQL.

**`--single-transaction`**

Permite realizar una copia consistente de tablas transaccionales como InnoDB sin bloquear normalmente las escrituras.

**`--skip-lock-tables`**

Evita solicitar bloqueos de tablas durante la exportación.

**`--no-tablespaces`**

Evita exportar información de espacios de tablas que requeriría permisos adicionales.

**`find ... -mtime +6 -delete`**

Elimina los archivos de copia con al menos siete días completos de antigüedad.

### Ejecutar una copia

```bash
./practica.sh copia
```

### Consultar las copias

```bash
ls -lh copias/
```

Ejemplo de nombre:

```text
radio-20261125-233000.sql
```

### Restauración

El comprobador restaura la copia en una base temporal denominada `radio_prueba`.

Después compara la cantidad de programas restaurados con la base original.

Esto verifica que la copia contiene información recuperable.

---

## C4.2 — Seguridad de las copias

El script también cumple las condiciones de C4.2.

Las principales medidas son:

- No incluir contraseñas directamente en `copia.sh`.
- Leer las credenciales desde `radio.env`.
- Utilizar el usuario específico `radio_copias`.
- Evitar bloqueos de tablas con `--single-transaction`.
- Evitar permisos innecesarios mediante `--no-tablespaces`.

El usuario `radio_copias` tiene permisos limitados de lectura.

Así no necesitamos utilizar `root` para realizar las copias.

En un entorno real, también sería necesario proteger los archivos de copia y almacenarlos en una ubicación externa.

---

# 10. Errores encontrados y soluciones

Durante el desarrollo aparecieron varios errores que nos ayudaron a comprender mejor el funcionamiento de los servicios.

## Error 1 — B4.2 devolvía HTML en lugar de JSON

### Problema

Cuando consultábamos un podcast inexistente, nuestra API devolvía un error 404, pero no en el formato solicitado.

Utilizábamos:

```python
abort(404)
```

### Causa

Flask generaba su respuesta de error predeterminada, normalmente en HTML.

Sin embargo, el ejercicio exigía devolver un error en JSON.

### Solución

Sustituimos:

```python
abort(404)
```

Por:

```python
return jsonify({
    "error": "No existe ese podcast"
}), 404
```

### Aprendizaje

Una API debe devolver respuestas con el formato esperado por sus consumidores.

No basta con devolver el código HTTP correcto: también importa el contenido de la respuesta.

---

## Error 2 — PHP-FPM no podía leer radio.env

### Problema

PHP podía conectarse a MariaDB desde la terminal, pero la página web mostraba:

```text
SQLSTATE[HY000] [2002] No such file or directory
```

### Diagnóstico

Comprobamos los permisos:

```bash
ls -l servidor/radio.env
```

El resultado era:

```text
-rw------- 1 arturo arturo servidor/radio.env
```

Esto equivalía a permisos 600.

El archivo solo podía leerlo su propietario.

Sin embargo, PHP-FPM ejecutaba las páginas con el usuario `www-data`.

Comprobamos la lectura mediante:

```bash
docker compose exec -T --user www-data php \
sh -c 'test -r /etc/radio/radio.env && echo OK || echo ERROR'
```

El resultado fue que `www-data` no podía leer el archivo.

### Solución

En nuestro laboratorio ejecutamos:

```bash
sudo chgrp 33 servidor/radio.env
chmod 640 servidor/radio.env
```

Con ello permitimos que el grupo utilizado por PHP-FPM tuviera permiso de lectura.

### Aprendizaje

Una aplicación puede tener un código correcto y seguir fallando si el usuario que ejecuta el servicio no tiene los permisos necesarios.

Por eso es importante comprobar tanto el código como los permisos de Linux.

---

## Error 3 — Nginx devolvía 502 Bad Gateway

### Problema

Después de completar las copias de seguridad, varios ejercicios que antes funcionaban aparecieron en rojo.

Las peticiones a PHP y a la API devolvían:

```text
502 Bad Gateway
```

### Diagnóstico

Comprobamos los contenedores:

```bash
docker compose ps
```

Los servicios estaban arrancados.

Después comprobamos las respuestas:

```bash
curl -ks -o /dev/null -w '%{http_code}\n' \
https://localhost:8452/salud.php
```

```bash
curl -ks -o /dev/null -w '%{http_code}\n' \
https://localhost:8452/api/salud
```

Ambas peticiones devolvían 502.

Esto indicaba que Nginx no conseguía comunicarse correctamente con los servicios internos.

### Solución

Reiniciamos Nginx:

```bash
docker compose restart nginx
```

Después de reiniciarlo, ambas peticiones volvieron a devolver:

```text
200 OK
```

Una explicación compatible con el problema es que Nginx estuviera utilizando direcciones IP antiguas de los contenedores, aunque no llegamos a confirmarlo mediante los registros de resolución de nombres.

### Aprendizaje

Que un contenedor aparezca como `Up` no significa necesariamente que todos los demás puedan comunicarse correctamente con él.

Ante un error 502 debemos revisar:

1. Si el servicio está arrancado.
2. Si escucha en el puerto esperado.
3. Si Nginx puede comunicarse con él.
4. Si los nombres de servicio se resuelven correctamente.
5. Qué indican los registros.

Comandos útiles:

```bash
docker compose ps
docker compose logs --tail=30 nginx
docker compose logs --tail=30 php
docker compose logs --tail=30 app
tail -n 30 logs/radio_error.log
```

---

# 11. Comprobación de la práctica

El kit incluye un comprobador que permite verificar los diferentes ejercicios.

## Comprobar el bloque A

```bash
./practica.sh comprobar A
```

Comprueba la configuración de Nginx, PHP-FPM, las medidas de seguridad y la protección de rutas.

## Comprobar el bloque B

```bash
./practica.sh comprobar B
```

Comprueba Flask, Gunicorn, sesiones y endpoints de la API.

## Comprobar el bloque C

```bash
./practica.sh comprobar C
```

Comprueba MariaDB, usuarios, permisos, conexiones, consultas SQL y copias de seguridad.

### Última comprobación realizada

El bloque C obtuvo:

```text
Bloque C: 12 de 12
```

Todas sus pruebas aparecieron en verde.

## Comprobar toda la práctica

```bash
./practica.sh comprobar
```

El objetivo de la entrega es conseguir:

```text
34 de 34 comprobaciones correctas
```

La comprobación completa de 34/34 debe ejecutarse antes de la entrega para confirmar que los bloques A, B y C funcionan conjuntamente.

---

# 12. Comandos útiles

| Comando | Función |
|---|---|
| `./practica.sh arrancar` | Arrancar la práctica |
| `./practica.sh parar` | Detener los contenedores |
| `./practica.sh recargar` | Aplicar cambios y reiniciar los servicios correspondientes |
| `./practica.sh comprobar` | Comprobar la práctica completa |
| `./practica.sh comprobar A` | Comprobar el bloque A |
| `./practica.sh comprobar B` | Comprobar el bloque B |
| `./practica.sh comprobar C` | Comprobar el bloque C |
| `./practica.sh sql` | Aplicar los usuarios y permisos de MariaDB |
| `./practica.sh mariadb` | Entrar en MariaDB |
| `./practica.sh copia` | Ejecutar una copia de seguridad |
| `./practica.sh logs` | Consultar registros |
| `docker compose ps` | Consultar el estado de los contenedores |
| `docker compose restart nginx` | Reiniciar Nginx |
| `docker compose logs app` | Consultar los registros del contenedor Python |
| `git status` | Consultar los cambios pendientes |
| `git push` | Subir los commits a GitHub |

### Advertencia importante

No ejecutar:

```bash
./practica.sh desde-cero
```

sin conocer sus consecuencias.

Este comando elimina el volumen de datos de MariaDB y vuelve a crear la base inicial.

---

# 13. Seguridad implementada

Durante la práctica hemos aplicado distintas medidas de seguridad.

| Medida | Tecnología | Objetivo |
|---|---|---|
| HTTPS | Nginx | Cifrar las comunicaciones |
| Ocultar versión de PHP | PHP | Reducir la exposición de información |
| Ocultar errores | PHP | Evitar revelar detalles internos |
| Deshabilitar funciones | PHP | Reducir la posibilidad de ejecutar comandos |
| Escapado HTML | PHP | Prevenir ataques XSS |
| Restricciones 403 | Nginx | Proteger archivos internos |
| Sesiones firmadas | Flask | Proteger la autenticación |
| Variables de entorno | PHP y Python | Separar credenciales del código |
| Usuarios con permisos limitados | MariaDB | Aplicar mínimo privilegio |
| Consultas preparadas | PDO y PyMySQL | Prevenir inyecciones SQL |
| Copias de seguridad | Shell y MariaDB | Facilitar la recuperación de datos |
| `.gitignore` | Git | Evitar publicar archivos privados |

### Principios aplicados

**Principio de mínimo privilegio**

Cada usuario o servicio debe disponer únicamente de los permisos necesarios.

**Separación de responsabilidades**

Nginx gestiona las peticiones, PHP y Python ejecutan las aplicaciones y MariaDB almacena los datos.

**Defensa en profundidad**

Aplicamos distintas medidas de seguridad en lugar de depender de una única protección.

**Protección de credenciales**

Las aplicaciones obtienen las contraseñas de su configuración privada, evitando escribirlas directamente en el código.

---

# 14. Conclusiones

Esta práctica me ha permitido comprender mejor cómo se conectan las diferentes tecnologías que forman una aplicación web.

En el bloque A aprendí a configurar Nginx y PHP-FPM, además de aplicar medidas de seguridad para proteger la web.

En el bloque B trabajé con Flask y Gunicorn, configuré el proxy inverso, protegí rutas mediante sesiones y creé endpoints que devuelven información en JSON.

En el bloque C aprendí a administrar usuarios de MariaDB, conectar PHP y Python con la base de datos, realizar consultas preparadas y crear copias de seguridad.

También tuve que solucionar problemas reales relacionados con permisos de Linux y comunicación entre contenedores Docker.

Uno de los errores más importantes fue el acceso a `radio.env`, porque me permitió comprender que una aplicación puede tener el código correctamente configurado y, aun así, fallar por los permisos del sistema.

Otro aprendizaje importante fue el error 502 de Nginx, que me enseñó a comprobar la comunicación entre servicios y no limitarme a verificar que los contenedores estuvieran arrancados.

En general, esta práctica me ha servido para relacionar conceptos de aplicaciones web, administración de sistemas, redes, bases de datos y seguridad.

---

## 📌 Estado del proyecto

| Bloque | Estado |
|---|---|
| Bloque A — Nginx y PHP | Implementado |
| Bloque B — Flask y Gunicorn | Implementado |
| Bloque C — MariaDB | ✅ 12/12 comprobaciones |
| Comprobación global | Pendiente de confirmar 34/34 |

---

**Práctica realizada para el módulo de Implantación de Aplicaciones Web — 2.º ASIR.**
