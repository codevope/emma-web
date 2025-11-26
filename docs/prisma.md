# Prisma Migrations & Seed -- Guía Rápida

Este README explica cómo crear migraciones y sembrar datos iniciales
(seed) usando Prisma.

## 1. Instalación de Prisma CLI

``` bash
npm install -D prisma
```

Generar el cliente de Prisma:

``` bash
npx prisma generate
```

## 2. Crear Migración

Cada vez que definas o modifiques modelos en `schema.prisma`:

``` bash
npx prisma migrate dev --name nombre_de_migracion
```

Esto: - Genera un archivo SQL con cambios. - Aplica esos cambios en la
base de datos configurada en `DATABASE_URL`.

## 3. Sembrar Datos Iniciales (Seed)

### Configurar script en `package.json`

``` json
{
  "prisma": {
    "seed": "ts-node prisma/seed.ts"
  }
}
```

### Ejecutar el seed: `prisma/seed.ts`
``` bash
npx prisma db seed
```

## 4. Otros Comandos Útiles

-   **`npx prisma studio`** -- Abre una interfaz web para ver/editar
    datos.
-   **`npx prisma migrate reset`** -- Borra y recrea la base de datos
    aplicando migraciones y el seed.
-   **`npx prisma db push`** -- Aplica el schema a la base de datos
    **sin** migración (útil en prototipos).

------------------------------------------------------------------------
