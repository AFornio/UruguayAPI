# 🇺🇾 Uruguay API 🌞

UruguayAPI es un proyecto de código abierto que tiene como objetivo hacer que los datos sobre Uruguay sean fácilmente
accesibles a través de una API simple. La API espera (en un futuro) brindar acceso a información sobre la geografía, la
demografía, la economía y más de Uruguay. Los datos provienen de fuentes confiables, como sitios web gubernamentales y
agencias estadísticas.

Es importante aclarar que UruguayAPI es una "PROXY API", lo que significa que es una API intermedia que redirige las
solicitudes a otras fuentes de datos confiables, como sitios web gubernamentales y agencias estadísticas. Como
resultado, puede haber una ligera disminución en la velocidad de respuesta en comparación con una API que proporciona
datos directamente.

Nuestro objetivo principal es lanzar un MVP. A medida que el proyecto evoluciona, podremos trabajar en mejorar la
velocidad de respuesta y añadir más características y mejoras para hacer que la experiencia del usuario sea aún mejor.

# Demo

Por el momento, la API esta alojada en [render](https://render.com/). La URL base:

```
https://uruguayapi.onrender.com/
```

# API Endpoints


<details>
  <summary>Cédula de Identidad - CI</summary>

  ### GET /api/v1/ci/validate?ci=

  Valida un número de CI.

  **Parámetros**

  - CI: El número de CI a validar. Se extrae los números de la cadena de caracteres y chequea el dígito verificador, por
    lo que estos formatos son validos - 1.111.111-1, 1_111_111_1, 1.111.111/1

  **Respuesta**

  - 200 OK: Devuelve True/False que indica si el número de CI es válido.

  ### GET /api/v1/ci/validate_digit?ci=

  Valida el último dígito de un número de CI. Se extraen los primeros 7 números de la CI y devuevlve el digito
  verificador

  **Parámetros**

  - CI: El número de CI para validar el último dígito.

  **Respuesta**

  - 200 OK: Devuelve el último digito verificador para la CI proporcionada.
  - 422 Unprocessable Entities: Si se requiere el número de CI.

  ### GET /api/v1/ci/random

  Devuelve un número de CI válido aleatorio.

  **Respuesta**

  - 200 OK: Devuelve un número de CI válido aleatorio.
</details>

<details>
  <summary>Buses - Tres Cruces</summary>

### GET /api/v1/buses/schedules

Devuelve todos los datos de los horarios interdepartamentales de corta, media, larga distancia e internacionales.

**Respuesta**

- 200 OK: Devuelve un objeto JSON con todos los datos de los horarios de autobuses.
</details>


<details>
  <summary>Gasolina - Ancap</summary>

### GET /api/v1/gasoline

Obtiene una lista de precios de combustibles de Uruguay (Ancap)

**Parámetros**

Este endpoint no requiere parámetros.

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene los precios de los siguientes combustibles de Ancap: Super 95 Premium
  97
  Gasoil 10-S Gasoil 50-S.
  Cada combustible se presenta como una clave en el objeto JSON y tiene los siguientes valores:

- max_price: El precio máximo del combustible.
- ancap_price: El precio del combustible en las estaciones de servicio de Ancap.
- currency: La moneda en la que se expresan los precios (en este caso, siempre será "UYU").

- 500 Internal Server Error: Si ocurre algún error en el servidor al obtener los precios de combustibles.

### GET /api/v1/gasoline/:name

Obtiene los precios de un combustible específico de Uruguay (Ancap).

**Parámetros**

- name: El nombre del combustible que se desea obtener. Debe ser una de las siguientes opciones: "Super 95",
  "Premium
  97", "Gasoil 10-S" o "Gasoil 50-S".

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene los precios del combustible solicitado. El objeto JSON tiene los
  siguientes valores:

- max_price: El precio máximo del combustible.
- ancap_price: El precio del combustible en las estaciones de servicio de Ancap.
- currency: La moneda en la que se expresan los precios (en este caso, siempre será "UYU").

- 404 Not Found: Si el combustible solicitado no existe en la lista de combustibles de Ancap.

- 500 Internal Server Error: Si ocurre algún error en el servidor al obtener los precios de combustibles.
</details>


<details>
  <summary>Holidays</summary>

### GET /api/v1/holidays

Obtiene una lista de todas las festividades y días feriados en Uruguay para el año

</details>


<details>
  <summary>Noticias</summary>

### GET /api/v1/news/headlines

Obtiene una lista de los titulares de noticias más recientes en Uruguay.

</details>


<details>

  <summary>EVENTOS - QUE HACER?</summary>

### GET /api/v1/events/:event

Obtiene información sobre los eventos disponibles para la organización enviada

**Parámetros**

- event: De momento, puede ser "antel_arena"

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene una lista de items. Cada item es un objeto JSON que representa a un
  evento.

- 404 Not Found: Si el tipo de evento solicitado no existe.

- 500 Internal Server Error: Si ocurre algún error en el servidor al obtener la lista de items.

### GET /api/v1/events/billboard/:event_type

Obtiene una lista de items para una categoría específica.

**Parámetros**

- event_type: El tipo de evento que se desea obtener. Debe ser una de las siguientes opciones: "art," "cable,"
  "movies," "music," "theater," o "videos".

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene una lista de items para la categoría especificada. Cada item es un
  objeto JSON que representa a un evento.

- 404 Not Found: Si el tipo de evento solicitado no existe en la lista de categorías.

- 500 Internal Server Error: Si ocurre algún error en el servidor al obtener la lista de items.</details>
</details>

<details>
  <summary>BANCOS</summary>

### GET /api/v1/banks/brou_rates

Devuelve las tasas de cambio actuales para varias monedas en el Banco de la República Oriental del Uruguay (BROU).

### GET /api/v1/banks/:bank_benefits

Obtiene los beneficios existenes para el tipo de banco

**Parámetros**

- bank_benefits: De momento, puede ser "santander_benefits. "brou_benefits" o "scotiabank_benefits"

**Respuesta**

- 200 OK: Devuelve un objeto JSON que contiene una lista de items

- 500 Internal Server Error: Si ocurre algún error en el servidor al obtener la lista de items.
</details>

<details>
  <summary>Granos - Precios de Mercado</summary>

  ### GET /api/v1/grain/prices

  Obtiene los precios actuales de granos nacionales e internacionales del mercado.

  **Parámetros**

  Este endpoint no requiere parámetros.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con los precios de granos, estructurados en categorías "international" y "national".
    Cada categoría contiene objetos de granos, donde cada grano tiene fechas y, para cada fecha, el precio, la moneda
    ("US$/TON") y, si está disponible, el logo de la referencia.
  - 404 Not Found: Si no se encuentran datos de precios en la fuente.
  - 500 Internal Server Error: Si ocurre un error al intentar obtener los datos.
</details>

<details>
  <summary>Ganado - Precios de Mercado</summary>

  ### GET /api/v1/cattle/prices

  Obtiene los precios actuales del mercado ganadero, incluyendo ganado gordo, ovinos y reposición, desde la Asociación
  Consorcios Regionales de Ganaderos (ACG).

  **Parámetros**

  Este endpoint no requiere parámetros.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con los precios del ganado. La respuesta se estructura en tres categorías:
    `ganado_gordos`, `ovinos`, y `reposicion`. Cada categoría contiene objetos de tipo de ganado, donde cada uno incluye
    el `price`, `currency` (siempre "USD"), una `description` ("por kilo en cuarta balanza"), y opcionalmente el
    `logo` de la referencia.
  - 500 Internal Server Error: Si ocurre un error al intentar obtener los datos.
</details>

---

### Inspirado por 💡:

https://brasilapi.com.br/
