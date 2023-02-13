# 🇺🇾 Uruguay API 🌞

UruguayAPI es un proyecto de código abierto que tiene como objetivo hacer que los datos sobre Uruguay sean fácilmente accesibles a través de una API simple. La API espera (en un futuro) brindar acceso a información sobre la geografía, la demografía, la economía y más de Uruguay. Los datos provienen de fuentes confiables, como sitios web gubernamentales y agencias estadísticas.

# Demo

Por el momento, la API esta alojada en [render](https://render.com/). La URL base:

```
https://uruguayapi.onrender.com/
```

# API Endpoints

## Cédula de Identidad - CI

### GET /api/v1/ci/validate?ci=

Valida un número de CI.

**Parámetros**

- CI: El número de CI a validar. Se extrae los números de la cadena de caracteres y chequea el dígito verificador, por lo que estos formatos son validos - 1.111.111-1, 1_111_111_1, 1.111.111/1

**Respuesta**

- 200 OK: Devuelve True/False que indica si el número de CI es válido.

### GET /api/v1/ci/validate_digit?ci=

Valida el último dígito de un número de CI. Se extraen los primeros 7 números de la CI y devuevlve el digito verificador

**Parámetros**

- CI: El número de CI para validar el último dígito.

**Respuesta**

- 200 OK: Devuelve el último digito verificador para la CI proporcionada.
- 422 Unprocessable Entities: Si se requiere el número de CI.

### GET /api/v1/ci/random

Devuelve un número de CI válido aleatorio.

**Respuesta**

- 200 OK: Devuelve un número de CI válido aleatorio.

## Cotizaciones - BROU

### GET /api/v1/rates/index

Devuelve las tasas de cambio actuales para varias monedas en el Banco de la República Oriental del Uruguay (BROU).

## BUSES - TRES CRUCES

### GET /api/v1/buses/options

Devuelve opciones de búsqueda para las rutas de autobuses.

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene las opciones de búsqueda. Las opciones son:
  - origins_and_destinations: un array que contiene todos los orígenes y destinos disponibles.
  - companies: un array que contiene todas las empresas de autobuses disponibles.
  - days: un array que contiene todos los días disponibles.
  - shifts: un array que contiene todos los turnos disponibles.

### GET /api/v1/buses/schedules

Devuelve los horarios de autobuses para una ruta específica.

**Parámetros**

- origin (requerido): el origen de la ruta. Debe ser una cadena que representa la ubicación.
- destination (requerido): el destino de la ruta. Debe ser una cadena que representa la ubicación.
- company_id (opcional): el ID de la empresa de autobuses. Debe ser un entero.
- day (opcional): el día de la semana. Debe ser una cadena que representa el día de la semana.
- shift (opcional): el turno de los horarios. Debe ser una cadena que representa el turno.
- pag (opcional): el número de página para los resultados de búsqueda. Debe ser un entero.

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene los horarios de autobuses para la ruta especificada. Los horarios son un array de objetos, cada uno de los cuales representa un horario de autobús.
  Los objetos tienen las siguientes claves:

  - departure_time: la hora de salida del autobús.
  - frequency: la frecuencia de los autobuses en minutos.
  - route: la ruta del autobús.
  - time: el tiempo de viaje en horas y minutos.
  - distance: la distancia del viaje en kilómetros.
  - company: la empresa de autobuses.

  También incluye un objeto JSON de paginación que contiene las siguientes claves:

  - max: el número máximo de páginas para los resultados de búsqueda.
  - current: el número de página actual para los resultados de búsqueda.
  - query_param: el parámetro de consulta utilizado para la paginación.
  - showing_all: un indicador booleano que indica si se han mostrado todos los resultados de búsqueda.

- 422 Unprocessable Entity: Si no se proporcionan los parámetros origin y destination.

### GET /api/v1/buses/all_schedules

Obtiene una lista de todos los horarios de autobuses disponibles entre dos ubicaciones.

**Parámetros**

- origin: Ubicación de origen del viaje (requerido).
- destination: Ubicación de destino del viaje (requerido).
- company_id: ID de la compañía de autobuses (opcional).
- day: Día de la semana del viaje (opcional).
- shift: Turno del viaje (opcional).
- pag: Número de página de los resultados (opcional).

**Respuesta**

- 200 OK: Devuelve una lista de objetos de horarios de autobuses que coinciden con los parámetros proporcionados. Cada objeto contiene la hora de salida, frecuencia, ruta, duración, distancia y compañía de autobuses.
- 400 Bad Request: Si no se proporciona una ubicación de origen o de destino.
- 422 Unprocessable Entity: Si el número de página de resultados es inválido.

---

### Inspirado por 💡:

https://brasilapi.com.br/
