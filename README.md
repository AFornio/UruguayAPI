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

<details>
  <summary>Canasta de Alimentos - Supermercados</summary>

  ### GET /api/v1/supermarkets/food_basket_store_product?store=:store&product=:product

  Obtiene una lista de productos específicos de la canasta básica de un supermercado determinado.

  **Parámetros**

  - `store`: El nombre del supermercado. Opciones válidas: "tienda_inglesa", "disco", "devoto", "tata".
  - `product`: El nombre del producto de la canasta. Opciones válidas: "arroz", "azucar", "panes", "leche", "aceite", "yerba".

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con los productos encontrados para el supermercado y producto especificados.
    ```json
    {
      "products": {
        "nombre_del_supermercado": [
          {
            "name": "Nombre del Producto",
            "price": "Precio del Producto",
            "image": "URL de la Imagen (opcional)",
            "brand": "Marca del Producto (opcional)"
          }
        ]
      }
    }
    ```
  - 404 Not Found: Si el supermercado o el producto no son válidos, o si no se encuentran URLs para el producto en ese supermercado.

  ### GET /api/v1/supermarkets/food_basket_store?store=:store

  Obtiene todos los productos de la canasta básica para un supermercado específico.

  **Parámetros**

  - `store`: El nombre del supermercado. Opciones válidas: "tienda_inglesa", "disco", "devoto", "tata".

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con todos los productos de la canasta encontrados para el supermercado especificado.
    ```json
    {
      "products": {
        "nombre_del_supermercado": [
          {
            "name": "Nombre del Producto",
            "price": "Precio del Producto",
            "image": "URL de la Imagen (opcional)",
            "brand": "Marca del Producto (opcional)"
          },
          // ... más productos
        ]
      }
    }
    ```
  - 404 Not Found: Si el supermercado no es válido.

  ### GET /api/v1/supermarkets/food_basket

  Obtiene todos los productos de la canasta básica de todos los supermercados disponibles.

  **Parámetros**

  Este endpoint no requiere parámetros.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON que contiene los productos de la canasta básica organizados por supermercado.
    ```json
    {
      "products": {
        "tienda_inglesa": [
          {
            "name": "Nombre del Producto",
            "price": "Precio del Producto",
            "image": "URL de la Imagen (opcional)",
            "brand": "Marca del Producto (opcional)"
          }
          // ... más productos de Tienda Inglesa
        ],
        "disco": [
          {
            "name": "Nombre del Producto",
            "price": "Precio del Producto",
            "image": "URL de la Imagen (opcional)",
            "brand": "Marca del Producto (opcional)"
          }
          // ... más productos de Disco
        ],
        // ... otros supermercados y sus productos
      }
    }
    ```
  - 500 Internal Server Error: Si ocurre un error al intentar obtener los datos de los supermercados.
</details>

<details>
  <summary>Salario Líquido - Calculadora</summary>

  ### GET /api/v1/salary/net?salary=

  Calcula el sueldo líquido (neto) a partir del salario nominal bruto mensual, aplicando las deducciones obligatorias
  del sistema uruguayo: aportes jubilatorios (BPS), seguro de salud (FONASA), Fondo de Reconversión Laboral (FRL) e
  Impuesto a la Renta (IRPF).

  **Parámetros**

  - `salary` (requerido): Salario nominal bruto mensual en pesos uruguayos.
  - `has_spouse` (opcional, default: false): Si el trabajador tiene cónyuge a cargo en FONASA.
  - `children` (opcional, default: 0): Cantidad de hijos sin discapacidad a cargo.
  - `disabled_children` (opcional, default: 0): Cantidad de hijos con discapacidad a cargo.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con el desglose completo del cálculo.
    ```json
    {
      "gross_salary": 50000.0,
      "deductions": {
        "bps": 7500.0,
        "fonasa": 2250.0,
        "frl": 50.0,
        "irpf": 0.0,
        "total": 9800.0
      },
      "net_salary": 40200.0,
      "bpc": 6177,
      "currency": "UYU"
    }
    ```
  - 422 Unprocessable Entity: Si el parámetro `salary` no es proporcionado o no es un número positivo.

  **Deducciones aplicadas**

  | Concepto | Tasa |
  |----------|------|
  | BPS (Jubilatorio) | 15% (tope salarial: $236.309) |
  | FONASA | 3% o 4.5% (según ingreso) + 2% cónyuge + 1.5% hijos |
  | FRL | 0.1% |
  | IRPF | Franjas progresivas (0% a 36%) |

  **Franjas IRPF (en BPC mensuales)**

  | Desde | Hasta | Tasa |
  |-------|-------|------|
  | 0 | 7 BPC | 0% |
  | 7 | 10 BPC | 10% |
  | 10 | 15 BPC | 15% |
  | 15 | 30 BPC | 24% |
  | 30 | 50 BPC | 25% |
  | 50 | 75 BPC | 27% |
  | 75 | 115 BPC | 31% |
  | 115+ | - | 36% |
</details>

<details>
  <summary>Aguinaldo - Calculadora</summary>

  ### GET /api/v1/salary/aguinaldo?monthly_salaries=

  Calcula el aguinaldo (Sueldo Anual Complementario) a partir de los ingresos nominales del semestre,
  aplicando las mismas deducciones que al salario mensual (BPS, FONASA, FRL, IRPF).

  **Fórmula:** `Aguinaldo bruto = Suma de ingresos nominales del semestre ÷ 12`

  **Períodos:**
  - Junio: ingresos de diciembre anterior a mayo
  - Diciembre: ingresos de junio a noviembre

  **Parámetros**

  - `monthly_salaries` (requerido): Salarios nominales mensuales. Puede ser:
    - Un solo valor (se asume salario fijo para los 6 meses del semestre)
    - Lista separada por comas: `40000,42000,45000,48000,50000,55000`
    - Array: `monthly_salaries[]=40000&monthly_salaries[]=42000`
  - `has_spouse` (opcional, default: false): Si el trabajador tiene cónyuge a cargo en FONASA.
  - `children` (opcional, default: 0): Cantidad de hijos sin discapacidad a cargo.
  - `disabled_children` (opcional, default: 0): Cantidad de hijos con discapacidad a cargo.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con el desglose completo del cálculo.
    ```json
    {
      "gross_aguinaldo": 25000.0,
      "deductions": {
        "bps": 3750.0,
        "fonasa": 1125.0,
        "frl": 25.0,
        "irpf": 0.0,
        "total": 4900.0
      },
      "net_aguinaldo": 20100.0,
      "monthly_salaries": [50000.0, 50000.0, 50000.0, 50000.0, 50000.0, 50000.0],
      "currency": "UYU"
    }
    ```
  - 422 Unprocessable Entity: Si el parámetro `monthly_salaries` no es proporcionado, contiene valores negativos o tiene más de 6 meses.

  **Ingresos incluidos:** sueldo base, horas extra, comisiones, feriados trabajados, nocturnidad.

  **Ingresos excluidos:** tickets de alimentación, subsidios BPS, salario vacacional (salvo convenio colectivo).
</details>

<details>
  <summary>Salario Vacacional y Licencia - Calculadora</summary>

  ### GET /api/v1/salary/vacation?salary=&years_worked=

  Calcula los días de licencia y el salario vacacional según la antigüedad del trabajador.
  El salario vacacional se calcula sobre el sueldo líquido y está exento de BPS, FONASA y FRL,
  pero sujeto a IRPF a tasa marginal (Ley 19.321/2015).

  **Fórmula:** `Salario vacacional = (Sueldo líquido mensual ÷ 30) × Días de licencia`

  **Parámetros**

  - `salary` (requerido): Salario nominal bruto mensual en pesos uruguayos.
  - `years_worked` (requerido): Años de antigüedad del trabajador.
  - `has_spouse` (opcional, default: false): Si el trabajador tiene cónyuge a cargo.
  - `children` (opcional, default: 0): Cantidad de hijos sin discapacidad a cargo.
  - `disabled_children` (opcional, default: 0): Cantidad de hijos con discapacidad a cargo.
  - `is_domestic` (opcional, default: false): Si es trabajador/a doméstico/a (+15% adicional).

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con el cálculo de licencia y salario vacacional.
    ```json
    {
      "vacation_days": 20,
      "gross_vacation_pay": 13333.33,
      "irpf": 0.0,
      "net_vacation_pay": 13333.33,
      "is_domestic": false,
      "years_worked": 3,
      "currency": "UYU"
    }
    ```
  - 422 Unprocessable Entity: Si faltan parámetros requeridos o son inválidos.

  **Días de licencia por antigüedad (Ley 12.590)**

  | Años de servicio | Días |
  |------------------|------|
  | 0-4 | 20 |
  | 5 | 21 |
  | 9 | 22 |
  | 13 | 23 |
  | 17 | 24 |
  | 21 | 25 |
  | +4 años desde el 5to | +1 día (sin tope) |
</details>

<details>
  <summary>Indemnización por Despido - Calculadora</summary>

  ### GET /api/v1/salary/dismissal?salary=&years_worked=

  Calcula la indemnización por despido (IPD) según el tipo de trabajador, antigüedad y factores agravantes.

  **Parámetros**

  - `salary` (requerido): Salario mensual nominal (o jornal diario para jornaleros).
  - `years_worked` (requerido): Años de antigüedad.
  - `months_fraction` (opcional, default: 0): Meses adicionales sobre los años completos (fracción = año completo).
  - `worker_type` (opcional, default: "monthly"): Tipo de trabajador: `monthly`, `daily`, `domestic`.
  - `days_worked` (opcional, default: 0): Días trabajados en el período (solo para jornaleros).
  - `aggravating_factor` (opcional): Factor agravante: `illness`, `accident`, `bps_report`, `pregnancy`, `harassment`, `disability`.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con el cálculo de la indemnización.
    ```json
    {
      "base_ipd": 150000.0,
      "months_compensation": 3,
      "aggravating_factor": null,
      "aggravating_amount": 0.0,
      "total_ipd": 150000.0,
      "worker_type": "monthly",
      "currency": "UYU"
    }
    ```
  - 422 Unprocessable Entity: Si faltan parámetros requeridos o son inválidos.

  **Reglas por tipo de trabajador**

  | Tipo | Ley | Fórmula | Tope |
  |------|-----|---------|------|
  | Mensual | 10.489 | 1 sueldo × años | 6 meses |
  | Jornalero | 10.570 | Variable según días trabajados | 150 jornales |
  | Doméstico | 18.065 | Igual que mensual (mín. 90 días) | 6 meses |

  **Factores agravantes**

  | Factor | Efecto |
  |--------|--------|
  | Enfermedad | 2× IPD |
  | No readmisión tras accidente | 3× IPD |
  | Denuncia BPS | 3× IPD |
  | Embarazo/maternidad | IPD + 6 sueldos |
  | Acoso sexual | IPD + 6 sueldos |
  | Discapacidad | IPD + 6 sueldos |
</details>

<details>
  <summary>Valor Hora de Trabajo - Calculadora</summary>

  ### GET /api/v1/salary/hourly_rate?salary=&sector=

  Calcula el valor hora de trabajo según el sector laboral, incluyendo recargos por horas extra,
  feriados y nocturnidad.

  **Fórmula:** `Valor hora = Salario mensual ÷ Divisor mensual`

  **Parámetros**

  - `salary` (requerido): Salario mensual nominal en pesos uruguayos.
  - `sector` (requerido): Sector laboral. Opciones: `commerce`, `industry`, `standard`, `domestic`, `rural`.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con el valor hora y recargos.
    ```json
    {
      "sector": "commerce",
      "weekly_hours": 44,
      "monthly_divisor": 190,
      "base_hourly_rate": 263.16,
      "overtime_rate": 526.32,
      "holiday_rate": 657.89,
      "night_rate": 315.79,
      "currency": "UYU"
    }
    ```
  - 422 Unprocessable Entity: Si faltan parámetros o el sector es inválido.

  **Divisores por sector**

  | Sector | Horas/semana | Divisor mensual |
  |--------|-------------|-----------------|
  | commerce | 44 | 190 |
  | domestic | 44 | 190 |
  | industry | 48 | 208 |
  | rural | 48 | 208 |
  | standard | 40 | 173 |

  **Recargos**

  | Tipo | Multiplicador |
  |------|--------------|
  | Horas extra diurnas | 2× base |
  | Feriados/descanso | 2.5× base |
  | Nocturnidad (22:00-06:00) | 1.2× base |
</details>

<details>
  <summary>Seguro de Paro - Calculadora</summary>

  ### GET /api/v1/salary/unemployment?salary=&reason=

  Calcula el subsidio por desempleo (seguro de paro) según la causa de cese, tipo de trabajador,
  dependientes y edad.

  **Parámetros**

  - `salary` (requerido): Salario promedio mensual de los últimos 6 meses.
  - `reason` (requerido): Causa del desempleo: `dismissal` o `suspension`.
  - `worker_type` (opcional, default: "monthly"): Tipo de trabajador: `monthly` o `daily`.
  - `daily_rate` (opcional, default: 0): Jornal diario (solo para jornaleros).
  - `has_dependents` (opcional, default: false): Si tiene dependientes a cargo (+20%).
  - `age` (opcional, default: 0): Edad del trabajador (>= 50 extiende 6 meses).

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con el desglose mensual del subsidio.
    ```json
    {
      "reason": "dismissal",
      "worker_type": "monthly",
      "average_salary": 50000.0,
      "has_dependents": false,
      "age_50_plus": false,
      "monthly_benefits": [
        { "month": 1, "amount": 33000.0 },
        { "month": 2, "amount": 28500.0 },
        { "month": 3, "amount": 25000.0 },
        { "month": 4, "amount": 22500.0 },
        { "month": 5, "amount": 21000.0 },
        { "month": 6, "amount": 20000.0 }
      ],
      "total_benefit": 150000.0,
      "duration_months": 6,
      "currency": "UYU"
    }
    ```
  - 422 Unprocessable Entity: Si faltan parámetros requeridos o la razón es inválida.

  **Porcentajes por despido (mensual)**

  | Mes | % del promedio |
  |-----|---------------|
  | 1 | 66% |
  | 2 | 57% |
  | 3 | 50% |
  | 4 | 45% |
  | 5 | 42% |
  | 6 | 40% |

  **Suspensión:** 50% fijo, 4 meses máximo.

  **Jornaleros por despido:** 16, 14, 12, 11, 10, 9 jornales por mes.

  **Suplementos:** Dependientes +20% | Mayores de 50: +6 meses al 40%.
</details>

<details>
  <summary>Peajes - Tarifas y Ubicaciones</summary>

  ### GET /api/v1/tolls/prices

  Obtiene las tarifas vigentes de los peajes en Uruguay y las ubicaciones de los 15 peajes nacionales.

  **Fuentes de datos**

  - Tarifas: Ministerio de Transporte y Obras Públicas (gub.uy)
  - Ubicaciones: datosuruguay.com

  **Parámetros**

  Este endpoint no requiere parámetros.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con tarifas por categoría de vehículo, ubicaciones de peajes y la moneda.
    ```json
    {
      "rates": [
        {
          "category": "Categoría 1 - Autos y camionetas",
          "basic": "$ 120",
          "telepeaje": "$ 100",
          "sucive": "$ 90"
        }
      ],
      "locations": [
        {
          "name": "Barra de Santa Lucía",
          "route": "Ruta 1",
          "km": "23.5"
        }
      ],
      "currency": "UYU"
    }
    ```
  - 500 Internal Server Error: Si ocurre un error al intentar obtener los datos.

  **Categorías de vehículos**

  | Categoría | Descripción |
  |-----------|-------------|
  | 1 | Autos y camionetas (2 ejes, 4 ruedas no duales) |
  | 2 | Tractor sin semirremolque y ómnibus hasta 25 pasajeros |
  | 3 | Vehículos de carga de hasta 3 ejes y 6 ruedas |
  | 4 | Ómnibus de más de 25 pasajeros |
  | 5 | Vehículos de carga de 3 ejes y más de 6 ruedas |
  | 6 | Vehículos de 4 o más ejes, no tritrenes |
  | 7 | Vehículos de carga tritrenes |

  **Modalidades de pago**

  | Modalidad | Descripción |
  |-----------|-------------|
  | Básica | Pago en efectivo en cabina |
  | Telepeaje | Pago electrónico con tag |
  | SUCIVE | Sistema Único de Cobro de Ingresos Vehiculares |
</details>

<details>
  <summary>Economía - Indicadores Vigentes</summary>

  ### GET /api/v1/economy/values

  Obtiene los indicadores económicos vigentes de Uruguay: BPC, UR, UI, salario mínimo y otros valores
  publicados por el BPS (Banco de Previsión Social).

  **Fuente de datos:** BPS - Valores Actuales (bps.gub.uy)

  **Parámetros**

  Este endpoint no requiere parámetros.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con los indicadores económicos vigentes.
    ```json
    {
      "bpc": { "value": 6864.0, "currency": "UYU" },
      "minimum_wage": { "value": 24572.0, "currency": "UYU" },
      "domestic_minimum_wage": { "value": 31178.0, "currency": "UYU" },
      "ur": { "value": 1851.83, "currency": "UYU" },
      "ui": { "value": 6.4401, "currency": "UYU" },
      "mutual_quota": { "value": 1820.0, "currency": "UYU" },
      "cpe": { "value": 6693.0, "currency": "UYU" },
      "bfc": { "value": 1847.96, "currency": "UYU" }
    }
    ```
  - 500 Internal Server Error: Si ocurre un error al intentar obtener los datos.

  **Indicadores disponibles**

  | Clave | Descripción |
  |-------|-------------|
  | bpc | Base de Prestaciones y Contribuciones |
  | minimum_wage | Salario mínimo nacional |
  | domestic_minimum_wage | Salario mínimo servicio doméstico |
  | ur | Unidad Reajustable |
  | ui | Unidad Indexada |
  | mutual_quota | Cuota mutual |
  | cpe | Costo Promedio Equivalente |
  | bfc | Base Ficta de Contribución |
</details>

<details>
  <summary>Inflación - Indicadores INE</summary>

  ### GET /api/v1/inflation/indicators

  Obtiene las variaciones interanuales de los principales índices económicos publicados por el INE
  (Instituto Nacional de Estadística): IPC, IMS, IMSN e ICCV.

  **Fuente de datos:** INE (ine.gub.uy)

  **Parámetros**

  Este endpoint no requiere parámetros.

  **Respuesta**

  - 200 OK: Devuelve un objeto JSON con los indicadores y su variación interanual.
    ```json
    {
      "ipc": { "period": "01/26", "variation_12m": 3.46 },
      "ims": { "period": "12/25", "variation_12m": 5.99 },
      "imsn": { "period": "12/25", "variation_12m": 5.97 },
      "iccv": { "period": "12/25", "variation_12m": 3.66 }
    }
    ```
  - 500 Internal Server Error: Si ocurre un error al intentar obtener los datos.

  **Indicadores disponibles**

  | Clave | Descripción |
  |-------|-------------|
  | ipc | Índice de Precios del Consumo (inflación) |
  | ims | Índice Medio de Salarios |
  | imsn | Índice Medio de Salarios Nominales |
  | iccv | Índice de Costo de la Construcción de Viviendas |
</details>
---

### Inspirado por 💡:

https://brasilapi.com.br/
