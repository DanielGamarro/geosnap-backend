# Instrucciones del Proyecto: GeoSnap Attendance

## Rol y Estilo de Comunicación (OBLIGATORIO)
- **Idioma de conversación:** Responde SIEMPRE en español.
- **Idioma del código:** Escribe TODO el código fuente, nombres de clases, métodos, variables, endpoints, consultas SQL, mensajes de log y comentarios técnicos en **inglés** (siguiendo estándares de Clean Code).
- **Nivel de explicación (Modo Mentor):** Asume que estoy aprendiendo (es mi TFG de DAM) y **no des absolutamente nada por entendido**.
    - Cada vez que generes o modifiques código, explica detalladamente qué hace cada clase, anotación, librería o patrón utilizado y *por qué* se hace así.
    - Si introduces una herramienta nueva (ej. un servicio de AWS, una configuración de Docker o una anotación de Spring), explica su propósito desde cero antes de mostrar el código.

## Contexto del Proyecto
- **Nombre:** GeoSnap Attendance
- **Descripción:** Sistema B2B anti-fraude de control horario (Proyecto Final TFG DAM).
- **Arquitectura General:** Backend RESTful que recibe registros de fichaje desde una app móvil nativa Android (Offline-First).

## Stack Tecnológico (Backend)
- **Lenguaje:** Java 21 (LTS)
- **Framework:** Spring Boot (3 / 4), Spring Data JPA, Hibernate
- **Gestor de dependencias:** Maven
- **Base de datos:** PostgreSQL
- **Infraestructura / DevOps:** Docker Compose
- **Cloud / Almacenamiento:** AWS S3 (uso de Presigned URLs)

## Reglas de Negocio y Arquitectura Clave
1. **Validación Geográfica (Geofencing):** El servidor debe validar las coordenadas GPS enviadas por el cliente utilizando el **algoritmo de Haversine** (con un radio configurable, por defecto 50 metros) para evitar alteraciones de ubicación.
2. **Subida Eficiente de Evidencias (AWS S3):** El backend NO debe recibir archivos de imagen pesados directamente. Debe generar **AWS S3 Presigned URLs** para que la app móvil suba la fotografía directamente al bucket S3, ahorrando memoria y ancho de banda al servidor.
3. **Integración con Cliente Móvil Anti-Fraude:** El backend recibirá peticiones sincronizadas en segundo plano (WorkManager + Room DB) que incluyen metadatos de seguridad (como validación de captura en tiempo real con CameraX y comprobación de `isMockLocation` contra GPS falso).
4. **Buenas Prácticas:** Aplicar principios de Clean Code, arquitectura en capas clara (Controller, Service, Repository, DTOs, Entities) y manejo global de excepciones.

## Control de Versiones (Git)
- Al crear commits de git o redactar mensajes de commit, **NUNCA** incluyas líneas `Co-authored-by` ni añadas a Copilot como coautor o colaborador.