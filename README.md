# Proyecto: Gestión de Aumentos Salariales y Administración de Asociados

Este proyecto consiste en la creación de una base de datos en SQL Server para gestionar la información de asociados, departamentos, y un sistema de aumentos salariales que permite aplicar incrementos de sueldo de manera global o por departamento.

## Tabla de Contenidos

1. [Estructura de la Base de Datos](#estructura-de-la-base-de-datos)
2. [Campos de Auditoría](#campos-de-auditoría)
3. [Procedimientos Almacenados (CRUD)](#procedimientos-almacenados-crud)
4. [Proceso de Cálculo de Aumentos](#proceso-de-cálculo-de-aumentos)
5. [Ejemplo de Ejecución de Procedimientos Almacenados](#ejemplo-de-ejecución-de-procedimientos-almacenados)
6. [Requisitos](#requisitos)
7. [Instalación](#instalación)

---

## Estructura de la Base de Datos

### 1. **Tabla `Departamentos`**
Esta tabla almacena los departamentos de la organización.

**Campos:**
- `DepartamentoID`: Identificador único (Primary Key, Identity)
- `Nombre`: Nombre del departamento
- `FechaCreacion`: Fecha en que se creó el registro
- `Estado`: Indica si el departamento está activo o inactivo
- `CreadoPor`: Usuario que creó el registro
- `ModificadoPor`: Usuario que modificó el registro
- `FechaModificacion`: Fecha de la última modificación

### 2. **Tabla `Asociados`**
Esta tabla almacena la información de los asociados de la empresa.

**Campos:**
- `AsociadoID`: Identificador único (Primary Key, Identity)
- `Nombre`: Nombre completo del asociado
- `Salario`: Salario actual del asociado
- `SalarioAnterior`: Salario anterior antes del último aumento
- `DepartamentoID`: Relación con la tabla `Departamentos` (Foreign Key)
- `FechaIngreso`: Fecha en que el asociado ingresó a la empresa
- `Estado`: Indica si el asociado está activo o inactivo
- `FechaUltimoAumento`: Fecha del último aumento salarial
- `CreadoPor`: Usuario que creó el registro
- `ModificadoPor`: Usuario que modificó el registro
- `FechaModificacion`: Fecha de la última modificación

### 3. **Tabla `Aumentos`**
Esta tabla registra los aumentos salariales aplicados.

**Campos:**
- `AumentoID`: Identificador único (Primary Key, Identity)
- `DepartamentoID`: Relación con la tabla `Departamentos` (NULL si aplica a todos)
- `Porcentaje`: Porcentaje del aumento salarial aplicado
- `Descripcion`: Descripción o motivo del aumento
- `CreadoPor`: Usuario que creó el registro

### 4. **Tabla `HistorialSalarios`**
Esta tabla almacena el historial de aumentos salariales de los asociados.

**Campos:**
- `HistorialID`: Identificador único (Primary Key, Identity)
- `AsociadoID`: Relación con la tabla `Asociados`
- `SalarioAnterior`: Salario antes del aumento
- `SalarioNuevo`: Salario después del aumento
- `AumentoID`: Relación con la tabla `Aumentos`
- `CreadoPor`: Usuario que creó el registro

---

## Campos de Auditoría

Todas las tablas incluyen campos para auditoría:
- `CreadoPor`: Usuario que realizó la creación del registro.
- `ModificadoPor`: Usuario que realizó la última modificación (si aplica).
- `FechaModificacion`: Fecha de la última modificación (si aplica).

Estos campos permiten un seguimiento claro de quién realiza cambios en los datos.

---

## Procedimientos Almacenados (CRUD)

Se han implementado procedimientos almacenados para la gestión de registros (Consulta, Inclusión, Modificación, Eliminación) de las tablas principales:

### 1. **Departamentos**
- `InsertarDepartamento`: Inserta un nuevo departamento.
- `ModificarDepartamento`: Modifica los datos de un departamento.
- `EliminarDepartamento`: Marca un departamento como inactivo.
- `ConsultarDepartamentos`: Consulta todos los departamentos.

### 2. **Asociados**
- `InsertarAsociado`: Inserta un nuevo asociado.
- `ModificarAsociado`: Modifica los datos de un asociado.
- `EliminarAsociado`: Marca un asociado como inactivo.
- `ConsultarAsociados`: Consulta todos los asociados.

### 3. **Aumentos**
- `InsertarAumento`: Registra un nuevo aumento salarial.
- `ModificarAumento`: Modifica un aumento registrado.
- `EliminarAumento`: Elimina un aumento (físicamente).
- `ConsultarAumentos`: Consulta todos los aumentos registrados.

---

## Proceso de Cálculo de Aumentos

El procedimiento almacenado `CalcularAumentoSalario` es el encargado de aplicar los aumentos salariales:

```sql
EXEC CalcularAumentoSalario @Porcentaje = 5.00, @DepartamentoID = NULL, @Usuario = 'admin';


