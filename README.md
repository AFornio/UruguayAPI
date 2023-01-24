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

**Respuesta**

- 200 OK: Devuelve un objeto JSON con las tasas de cambio actuales para las siguientes monedas: dólar, dólar ebrou, euro, peso argentino, real, libra esterlina, franco suizo, guaraní, unidad indexada, onza troy de oro.
- bid: precio de compra
- ask: precio de venta
- spread_bid: spread de compra
- spread_ask: spread de venta

---

### Inspirado por 💡:

https://brasilapi.com.br/
