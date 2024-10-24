-- Crear la base de datos
CREATE DATABASE MiEmpresaAsociados_DB;
GO

-- Usar la base de datos recién creada
USE MiEmpresaAsociados_DB;
GO

-- Crear la tabla Departamentos con campos adicionales
CREATE TABLE Departamentos (
    DepartamentoID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    FechaCreacion DATE NOT NULL DEFAULT GETDATE(),
    Estado NVARCHAR(10) NOT NULL CHECK (Estado IN ('Activo', 'Inactivo')),
    CreadoPor NVARCHAR(100) NOT NULL, -- campo de auditoría
    ModificadoPor NVARCHAR(100) NULL, -- campos de auditoría
    FechaModificacion DATE NULL -- campos de auditoría
);
GO

-- Crear la tabla Asociados con campos adicionales
CREATE TABLE Asociados (
    AsociadoID INT PRIMARY KEY IDENTITY(1,1),
    Nombre NVARCHAR(100) NOT NULL,
    Salario DECIMAL(18, 2) NOT NULL,
    FechaIngreso DATE NOT NULL DEFAULT GETDATE(),
    Estado NVARCHAR(10) NOT NULL CHECK (Estado IN ('Activo', 'Inactivo')),
    DepartamentoID INT,
    FechaUltimoAumento DATE NULL,
    SalarioAnterior DECIMAL(18, 2) NULL,
    CreadoPor NVARCHAR(100) NOT NULL, -- campo de auditoría
    ModificadoPor NVARCHAR(100) NULL, -- campo de auditoría
    FechaModificacion DATE NULL, -- campos de auditoría
    FOREIGN KEY (DepartamentoID) REFERENCES Departamentos(DepartamentoID)
);
GO

-- Crear la tabla Aumentos para registrar los aumentos salariales
CREATE TABLE Aumentos (
    AumentoID INT PRIMARY KEY IDENTITY(1,1),
    DepartamentoID INT NULL, -- NULL si es un aumento global
    Porcentaje DECIMAL(5, 2) NOT NULL, -- Porcentaje del aumento
    FechaAumento DATE NOT NULL DEFAULT GETDATE(),
    Descripcion NVARCHAR(255),
    CreadoPor NVARCHAR(100) NOT NULL, -- Auditoría
    FOREIGN KEY (DepartamentoID) REFERENCES Departamentos(DepartamentoID)
);
GO

-- Crear la tabla HistorialSalarios para registrar el historial de salarios
CREATE TABLE HistorialSalarios (
    HistorialID INT PRIMARY KEY IDENTITY(1,1),
    AsociadoID INT NOT NULL,
    SalarioAnterior DECIMAL(18, 2) NOT NULL,
    SalarioNuevo DECIMAL(18, 2) NOT NULL,
    FechaAjuste DATE NOT NULL DEFAULT GETDATE(),
    AumentoID INT NOT NULL,
    CreadoPor NVARCHAR(100) NOT NULL, -- Auditoría
    FOREIGN KEY (AsociadoID) REFERENCES Asociados(AsociadoID),
    FOREIGN KEY (AumentoID) REFERENCES Aumentos(AumentoID)
);
GO

-- Crear el procedimiento almacenado para calcular el aumento de salario
CREATE PROCEDURE CalcularAumentoSalario
    @Porcentaje DECIMAL(5, 2),
    @DepartamentoID INT = NULL, -- NULL si aplica a todos los departamentos
    @Usuario NVARCHAR(100) -- Usuario que realiza la operación (Auditoría)
AS
BEGIN
    DECLARE @AumentoID INT;
    
    -- Registrar el aumento en la tabla Aumentos
    INSERT INTO Aumentos (DepartamentoID, Porcentaje, CreadoPor)
    VALUES (@DepartamentoID, @Porcentaje, @Usuario);

    -- Obtener el ID del aumento recién creado
    SET @AumentoID = SCOPE_IDENTITY();

    -- Actualizar los salarios de los asociados
    UPDATE Asociados
    SET SalarioAnterior = Salario,
        Salario = Salario * (1 + @Porcentaje / 100),
        FechaUltimoAumento = GETDATE(),
        ModificadoPor = @Usuario,
        FechaModificacion = GETDATE()
    WHERE (@DepartamentoID IS NULL OR DepartamentoID = @DepartamentoID);

    -- Registrar los cambios en el historial
    INSERT INTO HistorialSalarios (AsociadoID, SalarioAnterior, SalarioNuevo, AumentoID, CreadoPor)
    SELECT AsociadoID, SalarioAnterior, Salario, @AumentoID, @Usuario
    FROM Asociados
    WHERE (@DepartamentoID IS NULL OR DepartamentoID = @DepartamentoID);
END;
GO

-- Crear roles y permisos
-- Crear rol para quienes puedan aplicar aumentos salariales
CREATE ROLE GerenteDeRecursosHumanos;
GO

-- Asignar permisos al rol GerenteDeRecursosHumanos para ejecutar el procedimiento
GRANT EXECUTE ON OBJECT::dbo.CalcularAumentoSalario TO GerenteDeRecursosHumanos;
GO

-- Crear rol para quienes puedan ver datos sensibles
CREATE ROLE SupervisorSalarios;
GO

-- Asignar permisos al rol SupervisorSalarios para consultar las tablas de aumentos y el historial
GRANT SELECT ON dbo.Aumentos TO SupervisorSalarios;
GRANT SELECT ON dbo.HistorialSalarios TO SupervisorSalarios;
GO

-- Crear login para Juan
CREATE LOGIN Carlos WITH PASSWORD = 'GerenteDeRecursosHumanos_123';

-- Crear login para Maria
CREATE LOGIN Eduardo WITH PASSWORD = 'SupervisorSalarios_123';
GO

CREATE USER Carlos FOR LOGIN Carlos;
CREATE USER Eduardo FOR LOGIN Eduardo;

-- Asignar roles a usuarios específicos
-- Ejemplo: Asignar el rol GerenteDeRecursosHumanos al usuario 'Juan'
EXEC sp_addrolemember 'GerenteDeRecursosHumanos', 'Carlos';
GO

-- Ejemplo: Asignar el rol SupervisorSalarios al usuario 'Maria'
EXEC sp_addrolemember 'SupervisorSalarios', 'Eduardo';
GO


------- PROCEDIMIENTOS ALMACENADOS - GESTIÓN DE DATOS -----------------------------------------------------

--PA's PARA LA ENTIDAD DE DEPARTAMENTOS:

-- Procedimiento para consultar todos los departamentos
CREATE PROCEDURE ConsultarDepartamentos
AS
BEGIN
    SELECT DepartamentoID, Nombre, FechaCreacion, Estado, CreadoPor, ModificadoPor, FechaModificacion
    FROM Departamentos;
END;
GO

-- Procedimiento para insertar un nuevo departamento
CREATE PROCEDURE InsertarDepartamento
    @Nombre NVARCHAR(100),
    @Estado NVARCHAR(10),
    @CreadoPor NVARCHAR(100)
AS
BEGIN
    INSERT INTO Departamentos (Nombre, FechaCreacion, Estado, CreadoPor)
    VALUES (@Nombre, GETDATE(), @Estado, @CreadoPor);
END;
GO

-- Procedimiento para modificar un departamento existente
CREATE PROCEDURE ModificarDepartamento
    @DepartamentoID INT,
    @Nombre NVARCHAR(100),
    @Estado NVARCHAR(10),
    @ModificadoPor NVARCHAR(100)
AS
BEGIN
    UPDATE Departamentos
    SET Nombre = @Nombre,
        Estado = @Estado,
        ModificadoPor = @ModificadoPor,
        FechaModificacion = GETDATE()
    WHERE DepartamentoID = @DepartamentoID;
END;
GO

-- Procedimiento para eliminar (lógicamente) un departamento
CREATE PROCEDURE EliminarDepartamento
    @DepartamentoID INT,
    @ModificadoPor NVARCHAR(100)
AS
BEGIN
    UPDATE Departamentos
    SET Estado = 'Inactivo', 
        ModificadoPor = @ModificadoPor,
        FechaModificacion = GETDATE()
    WHERE DepartamentoID = @DepartamentoID;
END;
GO




--PA's PARA LA ENTIDAD DE ASOCIADOS:

-- Procedimiento para consultar todos los asociados
CREATE PROCEDURE ConsultarAsociados
AS
BEGIN
    SELECT AsociadoID, Nombre, Salario, FechaIngreso, Estado, DepartamentoID, SalarioAnterior, FechaUltimoAumento, CreadoPor, ModificadoPor, FechaModificacion
    FROM Asociados;
END;
GO

-- Procedimiento para insertar un nuevo asociado
CREATE PROCEDURE InsertarAsociado
    @Nombre NVARCHAR(100),
    @Salario DECIMAL(18, 2),
    @DepartamentoID INT,
    @Estado NVARCHAR(10),
    @CreadoPor NVARCHAR(100)
AS
BEGIN
    INSERT INTO Asociados (Nombre, Salario, FechaIngreso, Estado, DepartamentoID, CreadoPor)
    VALUES (@Nombre, @Salario, GETDATE(), @Estado, @DepartamentoID, @CreadoPor);
END;
GO

-- Procedimiento para modificar un asociado existente
CREATE PROCEDURE ModificarAsociado
    @AsociadoID INT,
    @Nombre NVARCHAR(100),
    @Salario DECIMAL(18, 2),
    @DepartamentoID INT,
    @Estado NVARCHAR(10),
    @ModificadoPor NVARCHAR(100)
AS
BEGIN
    UPDATE Asociados
    SET Nombre = @Nombre,
        Salario = @Salario,
        DepartamentoID = @DepartamentoID,
        Estado = @Estado,
        ModificadoPor = @ModificadoPor,
        FechaModificacion = GETDATE()
    WHERE AsociadoID = @AsociadoID;
END;
GO

-- Procedimiento para eliminar (lógicamente) un asociado
CREATE PROCEDURE EliminarAsociado
    @AsociadoID INT,
    @ModificadoPor NVARCHAR(100)
AS
BEGIN
    UPDATE Asociados
    SET Estado = 'Inactivo', 
        ModificadoPor = @ModificadoPor,
        FechaModificacion = GETDATE()
    WHERE AsociadoID = @AsociadoID;
END;
GO




--PA's PARA LA ENTIDAD DE AUMENTOS:

-- Procedimiento para consultar todos los aumentos
CREATE PROCEDURE ConsultarAumentos
AS
BEGIN
    SELECT AumentoID, DepartamentoID, Porcentaje, FechaAumento, Descripcion, CreadoPor
    FROM Aumentos;
END;
GO

-- Procedimiento para insertar un nuevo aumento
CREATE PROCEDURE InsertarAumento
    @DepartamentoID INT = NULL, -- NULL si es global
    @Porcentaje DECIMAL(5, 2),
    @Descripcion NVARCHAR(255),
    @CreadoPor NVARCHAR(100)
AS
BEGIN
    INSERT INTO Aumentos (DepartamentoID, Porcentaje, FechaAumento, Descripcion, CreadoPor)
    VALUES (@DepartamentoID, @Porcentaje, GETDATE(), @Descripcion, @CreadoPor);
END;
GO

-- Procedimiento para modificar un aumento existente
CREATE PROCEDURE ModificarAumento
    @AumentoID INT,
    @DepartamentoID INT = NULL, -- NULL si es global
    @Porcentaje DECIMAL(5, 2),
    @Descripcion NVARCHAR(255),
    @ModificadoPor NVARCHAR(100)
AS
BEGIN
    UPDATE Aumentos
    SET DepartamentoID = @DepartamentoID,
        Porcentaje = @Porcentaje,
        Descripcion = @Descripcion,
        CreadoPor = @ModificadoPor -- Auditamos la modificación
    WHERE AumentoID = @AumentoID;
END;
GO

-- Procedimiento para eliminar un aumento (no se elimina lógicamente, porque es parte del historial)
CREATE PROCEDURE EliminarAumento
    @AumentoID INT
AS
BEGIN
    DELETE FROM Aumentos
    WHERE AumentoID = @AumentoID;
END;
GO


--PA's PARA LA ENTIDAD DE HistorialSalarios (Solo consulta):

-- Procedimiento para consultar el historial de salarios
CREATE PROCEDURE ConsultarHistorialSalarios
AS
BEGIN
    SELECT HistorialID, AsociadoID, SalarioAnterior, SalarioNuevo, FechaAjuste, AumentoID, CreadoPor
    FROM HistorialSalarios;
END;
GO


--EXEC'S
-- Insertar un departamento
EXEC InsertarDepartamento @Nombre = 'Recursos Humanos', @Estado = 'Activo', @CreadoPor = 'admin';
-- Modificar un departamento
EXEC ModificarDepartamento @DepartamentoID = 1, @Nombre = 'Recursos Humanos y Administración', @Estado = 'Activo', @ModificadoPor = 'admin';
-- Eliminar (lógicamente) un departamento
EXEC EliminarDepartamento @DepartamentoID = 1, @ModificadoPor = 'admin';
-- Consultar todos los departamentos
EXEC ConsultarDepartamentos;



-- Insertar un asociado
EXEC InsertarAsociado @Nombre = 'Juan Pérez', @Salario = 20000.00, @DepartamentoID = 1, @Estado = 'Activo', @CreadoPor = 'admin';
-- Modificar un asociado
EXEC ModificarAsociado @AsociadoID = 1, @Nombre = 'Juan Pérez Gómez', @Salario = 21000.00, @DepartamentoID = 1, @Estado = 'Activo', @ModificadoPor = 'admin';
-- Eliminar (lógicamente) un asociado
EXEC EliminarAsociado @AsociadoID = 1, @ModificadoPor = 'admin';
-- Consultar todos los asociados
EXEC ConsultarAsociados;



-- Insertar un aumento para un departamento específico
EXEC InsertarAumento @DepartamentoID = 1, @Porcentaje = 5.00, @Descripcion = 'Aumento anual', @CreadoPor = 'admin';
-- Insertar un aumento global (sin especificar departamento)
EXEC InsertarAumento @Porcentaje = 7.50, @Descripcion = 'Aumento de fin de año para todos', @CreadoPor = 'admin';
-- Modificar un aumento
EXEC ModificarAumento @AumentoID = 1, @DepartamentoID = 1, @Porcentaje = 6.00, @Descripcion = 'Ajuste en el aumento anual', @ModificadoPor = 'admin';
-- Eliminar (físicamente) un aumento
EXEC EliminarAumento @AumentoID = 1;
-- Consultar todos los aumentos
EXEC ConsultarAumentos;



-- Aumentar el salario de todos los asociados en un 5%
EXEC CalcularAumentoSalario @Porcentaje = 5.00, @DepartamentoID = NULL, @Usuario = 'admin';
-- Aumentar el salario de los asociados del departamento con ID = 1 en un 3%
EXEC CalcularAumentoSalario @Porcentaje = 3.00, @DepartamentoID = 1, @Usuario = 'admin';


-- Consultar el historial de salarios
EXEC ConsultarHistorialSalarios;




