
# Eventos G62-5
## Inscripciones a eventos con control de acceso

Aplicación móvil desarrollada en Flutter para la gestión
de eventos, inscripciones, cupos y asistencia.

Proyecto académico de Desarrollo de Aplicaciones Móviles,
grupo G62, periodo 2026-2.

## 1. Descripción

Eventos G62-5 permite que organizadores creen y administren
eventos, que participantes soliciten inscripciones y que
auxiliares registren el ingreso de los asistentes.

La aplicación utiliza Firebase para autenticación y
persistencia remota, Drift/SQLite para almacenar solicitudes
locales y HTTP/JSON para consultar categorías y recintos.

Las solicitudes de inscripción siguen un enfoque local-first:
se almacenan en el dispositivo antes de intentar su
confirmación remota.

Una solicitud pendiente no representa un cupo reservado.
La confirmación definitiva se realiza en Firestore.

## 2. Objetivos

### Objetivo general

Desarrollar una aplicación móvil que permita administrar
eventos, inscripciones y control de acceso mediante
persistencia local y remota.

### Objetivos específicos

- Implementar autenticación con Firebase Authentication.
- Definir permisos para tres roles.
- Crear, publicar, editar y finalizar eventos.
- Controlar la capacidad disponible.
- Registrar inscripciones y cancelaciones.
- Impedir inscripciones duplicadas.
- Registrar ingresos y ausencias.
- Consultar información mediante HTTP/JSON.
- Guardar solicitudes offline usando Drift.
- Sincronizar solicitudes pendientes con Firestore.
- Conservar una preferencia con SharedPreferences.
- Registrar errores mediante Firebase Crashlytics.
- Ejecutar pruebas funcionales y de seguridad.

## 3. Tecnologías

| Tecnología | Uso |
|---|---|
| Flutter | Aplicación móvil |
| Dart | Lenguaje de programación |
| Firebase Authentication | Autenticación |
| Cloud Firestore | Base de datos remota |
| Drift | Persistencia local |
| SQLite | Base de datos del dispositivo |
| HTTP | Consumo de API/JSON |
| SharedPreferences | Preferencias locales |
| Firebase Crashlytics | Registro de errores |
| Firebase Emulator | Pruebas de seguridad |
| Git y GitHub | Control de versiones |

## 4. Arquitectura

El proyecto separa responsabilidades en modelos,
pantallas, repositories, servicios y base de datos.

### Modelos

Representan las entidades del negocio.

- Evento
- Inscripcion
- Categoria
- Recinto

### Pantallas

Implementan la interfaz de usuario.

- Login y registro
- Panel según rol
- Creación de eventos
- Edición de eventos
- Listado de eventos
- Mis inscripciones
- Catálogo HTTP
- Control de acceso
- Listado de inscritos

### Repositories

Coordinan las operaciones del negocio.

- EventoRepository
- InscripcionRepository
- CatalogoRepository

### Servicios

Proporcionan acceso a recursos externos.

- AuthService
- CatalogoHttpService

### Persistencia

Cloud Firestore almacena eventos, usuarios e inscripciones.

Drift/SQLite conserva solicitudes locales y su estado
de sincronización.

SharedPreferences conserva la preferencia de tema.

## 5. Roles

La aplicación contempla tres roles.

### Participante

Puede:

- Registrarse e iniciar sesión.
- Consultar eventos publicados.
- Solicitar inscripciones.
- Consultar el estado de sus solicitudes.
- Cancelar inscripciones dentro del plazo permitido.
- Consultar categorías y recintos.

### Organizador

Puede:

- Crear eventos.
- Seleccionar categoría y recinto.
- Publicar eventos.
- Consultar sus propios eventos.
- Editar datos permitidos.
- Cerrar inscripciones.
- Finalizar eventos.

No puede reducir la capacidad de un evento por debajo
del número de participantes confirmados.

### Auxiliar de acceso

Puede:

- Consultar eventos habilitados para control de acceso.
- Consultar participantes inscritos.
- Localizar inscripciones mediante identificadores.
- Registrar el ingreso durante el horario del evento.
- Marcar ausencias después de finalizar el evento.

No debe registrar dos veces el ingreso de una inscripción.

## 6. Modelo de datos

### Colección usuarios

Ruta:

usuarios/{uid}

Campos principales:

- nombre
- email
- rol
- createdAt

Roles permitidos en el flujo del proyecto:

- participante
- organizador
- auxiliar_acceso

El registro público crea usuarios participantes.
Las cuentas privilegiadas deben configurarse por
un administrador del entorno de pruebas.

### Colección eventos

Ruta:

eventos/{eventoId}

Campos principales:

- nombre
- capacidad
- inicio
- fin
- organizadorUid
- estado
- confirmados
- categoriaId
- recintoId
- createdAt
- updatedAt

Campos de seguimiento de inscripciones:

- ultimaOperacionUid
- ultimaOperacionTipo

### Colección inscripciones

Ruta:

inscripciones/{eventoId}_{participanteUid}

Campos principales:

- eventoId
- participanteUid
- estado
- fechaConfirmacion
- fechaCancelacion

Otros campos pueden registrar fecha de ingreso o ausencia.

### Base de datos local Drift

Tabla:

SolicitudesLocales

Campos:

- id
- eventoId
- usuarioUid
- estadoNegocio
- estadoSync
- actualizadoEn
- versionLocal
- ultimoError

El identificador de la solicitud es estable para permitir
reintentos sin crear inscripciones duplicadas.

## 7. Estados del negocio

### Estados de eventos

BORRADOR
  |
  v
ABIERTO
  |
  v
INSCRIPCIONES_CERRADAS
  |
  v
FINALIZADO

### Estados de inscripciones

SOLICITADA:
Solicitud todavía no confirmada remotamente.

CONFIRMADA:
Firestore reservó correctamente el cupo.

CANCELADA:
La inscripción fue cancelada dentro de las condiciones
permitidas.

INGRESO_REGISTRADO:
El auxiliar registró la asistencia.

AUSENTE:
La inscripción quedó marcada como no asistente.

### Estados de sincronización

PENDIENTE:
La solicitud está guardada localmente.

SINCRONIZADO:
La operación fue reconocida por Firestore.

CONFLICTO:
La operación no pudo confirmarse debido a una
restricción o condición de rechazo.

## 8. Reglas de negocio

- La capacidad de los eventos debe estar entre 1 y 50.
- La fecha de inicio debe ser anterior a la fecha de fin.
- Los eventos nuevos deben tener fechas futuras.
- Solo el organizador propietario puede editar un evento.
- La capacidad no puede ser inferior a confirmados.
- Solo se permiten inscripciones a eventos abiertos.
- No se permite superar la capacidad disponible.
- Cada usuario tiene una inscripción identificada
  de manera determinista para cada evento.
- La confirmación del cupo utiliza una transacción.
- Una cancelación válida libera un cupo.
- La cancelación debe hacerse al menos una hora antes
  del inicio del evento.
- El registro de ingreso solo se permite durante
  el horario del evento.
- Un ingreso no puede registrarse dos veces.
- Las ausencias se registran después de la finalización.

Las reglas definitivas se encuentran en firestore.rules.

## 9. Catálogo remoto HTTP/JSON

El catálogo proporciona categorías y recintos.

URL configurada en el servicio:

https://raw.githubusercontent.com/hola0511/eventos_g62_5/main/catalogo/catalogo.json

El servicio realiza una solicitud HTTP GET y valida
la estructura JSON recibida.

Los datos incluyen:

- Categorías disponibles.
- Recintos disponibles.
- Ubicación del recinto.
- Capacidad de referencia.

La capacidad del recinto es informativa y no reemplaza
el contador de cupos de cada evento en Firestore.

El servicio contempla errores HTTP, ausencia de conexión,
timeout y respuestas JSON inválidas.

Para probarlo, la URL debe ser accesible públicamente.

## 10. Requisitos de instalación

Se requiere:

- Flutter SDK compatible con pubspec.yaml.
- Dart SDK incluido con Flutter.
- Android Studio o Visual Studio Code.
- Android SDK.
- Emulador Android o dispositivo físico.
- Git.
- Acceso a un proyecto Firebase configurado.

Para validar el entorno:

```powershell
flutter --version
flutter doctor -v
git --version
```

Para las pruebas de Firestore Emulator también se
requieren Node.js, Firebase CLI y Java.

## 11. Obtener el proyecto

Repositorio:

https://github.com/hola0511/eventos_g62_5

Clonar:

```powershell
git clone https://github.com/hola0511/eventos_g62_5.git
cd eventos_g62_5
```

Instalar dependencias:

```powershell
flutter pub get
```

Generar las clases de Drift:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Verificar el proyecto:

```powershell
flutter analyze
```

Ejecutar las pruebas Flutter:

```powershell
flutter test
```

Iniciar la aplicación:

```powershell
flutter run
```

## 12. Configuración de Firebase

El proyecto utiliza Firebase Authentication,
Cloud Firestore y Firebase Crashlytics.

Se requiere una configuración Firebase válida para
la aplicación Android.

Archivos relevantes:

- firebase.json
- firestore.rules
- lib/firebase_options.dart
- android/app/google-services.json

Para configurar Firebase desde FlutterFire CLI,
si es necesario:

```powershell
flutterfire configure --project=eventos-g62-5 --platforms=android
```

El identificador de proyecto usado en este repositorio es:

eventos-g62-5

La configuración debe pertenecer a un proyecto al que
el equipo tenga acceso.

No incluir credenciales privadas ni archivos de cuentas
de servicio en el repositorio.

### Autenticación

Habilitar Email/Password en Firebase Authentication.

### Firestore

Crear la base de datos y publicar las reglas del proyecto.

No utilizar reglas abiertas en la entrega.

### Roles de prueba

Registrar participantes desde la aplicación.

Para crear cuentas de organizador y auxiliar en un
entorno de pruebas, un administrador debe establecer
el campo rol en usuarios/{uid} mediante Firebase Console.

No habilitar a los usuarios para asignarse roles
privilegiados a sí mismos.

## 13. Persistencia offline

Las solicitudes se guardan inicialmente en Drift/SQLite.

Flujo general:

1. El participante solicita una inscripción.
2. Se genera un identificador estable.
3. Se guarda el registro local como PENDIENTE.
4. Se intenta sincronizar con Firestore.
5. Firestore valida estado, cupos y duplicados.
6. Si se confirma, el registro queda SINCRONIZADO.
7. Si se rechaza, se conserva el motivo del conflicto.
8. Ante errores temporales, puede reintentarse.

La confirmación definitiva depende de Firestore.

La sincronización no garantiza ejecución en segundo
plano con la aplicación completamente cerrada.

## 14. SharedPreferences

La aplicación permite guardar la preferencia:

tema_oscuro

El modo oscuro debe persistir después de cerrar
y volver a abrir la aplicación.

Archivo:

lib/preferences/app_preferences.dart

## 15. Crashlytics

Se utiliza Firebase Crashlytics para registrar
errores de la aplicación.

La configuración incluye manejadores de errores Flutter
y errores no controlados, cuando la plataforma
es compatible.

La evidencia de funcionamiento debe obtenerse desde
Firebase Console después de ejecutar una prueba
controlada y verificar que el reporte haya llegado.

## 16. Pruebas

### Pruebas Flutter

```powershell
flutter test
```

### Análisis estático

```powershell
flutter analyze
```

### Pruebas de reglas de Firestore

Si están incorporados los archivos firebase.qa.json
y tests/firestore.rules.test.cjs, instalar:

```powershell
npm install
```

Ejecutar:

```powershell
firebase emulators:exec --config firebase.qa.json --project demo-eventos-g62-5 --only firestore "node --test tests/firestore.rules.test.cjs"
```

Las pruebas utilizan un proyecto de demostración
y no deben modificar Firebase de producción.

### Matriz QA

Documento:

docs/QA_G62_5.md

Evidencias:

docs/evidencias/

La matriz contempla pruebas de:

- Registro e inicio de sesión.
- Roles y permisos.
- Creación y edición de eventos.
- Publicación y cierre de inscripciones.
- Control de cupos.
- Cancelaciones.
- Control de asistencia.
- Persistencia offline.
- Sincronización.
- Catálogo HTTP.
- SharedPreferences.
- Crashlytics.

### Escenarios obligatorios

1. Dos participantes compiten por el último cupo:
   solo uno debe quedar confirmado.

2. El organizador intenta reducir capacidad por debajo
   de confirmados:
   la modificación debe rechazarse.

3. Un auxiliar intenta registrar dos ingresos
   para una misma inscripción:
   el segundo intento debe rechazarse.

Los resultados de QA deben registrarse con evidencias
reales. La existencia del código no equivale a
una prueba aprobada.

## 17. Compilación APK

Para generar un APK de prueba en release:

```powershell
flutter build apk --release
```

Ruta habitual del archivo generado:

build/app/outputs/flutter-apk/app-release.apk

El APK debe instalarse y probarse en un dispositivo
o emulador compatible.

Antes de la entrega, verificar la configuración de firma,
Firebase, conectividad, permisos y funcionamiento
de los tres roles.

## 18. Control de versiones

El proyecto se desarrolla de manera colaborativa.

Se recomienda trabajar mediante ramas por funcionalidad,
commits descriptivos y Pull Requests.

Antes de integrar cambios:

```powershell
git status
git fetch origin
```

Después de integrar:

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

No subir carpetas temporales ni credenciales privadas.

## 19. Organización del proyecto

lib/
  database/
  models/
  preferences/
  repositories/
  screens/
    auth/
  services/
  utils/
  firebase_options.dart
  main.dart

catalogo/
  catalogo.json

test/
  widget_test.dart

docs/
  QA_G62_5.md
  evidencias/

firestore.rules
firebase.json
pubspec.yaml
README.md

Algunos archivos de pruebas y documentación se agregan
en las etapas finales del proyecto.

## 20. Entregables

- Repositorio GitHub con código fuente.
- Aplicación Flutter funcional.
- Configuración Firebase.
- Reglas de seguridad.
- Catálogo HTTP/JSON.
- Persistencia Drift/SQLite.
- Preferencia con SharedPreferences.
- Evidencia Crashlytics.
- Matriz QA con resultados ejecutados.
- APK Android release.
- README y documentación del proyecto.

## 21. Estado de validación

Esta sección debe actualizarse antes de la entrega.

| Comprobación | Estado |
|---|---|
| flutter analyze | Pendiente de verificar |
| flutter test | Pendiente de verificar |
| Reglas Firestore | Pendiente de verificar |
| Matriz QA | Pendiente de completar |
| Crashlytics en consola | Pendiente de evidenciar |
| APK release | Pendiente de verificar |
| APK instalado | Pendiente de verificar |

No declarar una comprobación como aprobada sin haberla
ejecutado y conservado el resultado correspondiente.

## 22. Autores

Proyecto desarrollado en equipo para Desarrollo de
Aplicaciones Móviles, grupo G62, periodo 2026-2.

Integrantes:
- Completar nombre del integrante 1.
- Completar nombre del integrante 2.

## 23. Conclusión

Eventos G62-5 integra autenticación, control de roles,
administración de eventos, reservas de cupos,
asistencia y persistencia local/remota.

La validación definitiva del proyecto requiere ejecutar
las pruebas funcionales, verificar la seguridad de
Firestore y comprobar el APK release en Android.
