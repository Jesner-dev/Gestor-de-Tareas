-- Crear la base de datos Proyecto_1_Lenguajes
--CREATE DATABASE Proyecto_1_Lenguajes
USE Proyecto_1_Lenguajes
GO

---- TABLAS
-- Crear la tabla Usuario
--CREATE TABLE Usuario (
--    Id_Usuario INT PRIMARY KEY IDENTITY, -- Identificador único para cada usuario
--    Nombre NVARCHAR(255) NOT NULL, -- Nombre del usuario
--    Email NVARCHAR(255) NOT NULL UNIQUE, -- Email del usuario, debe ser único
--    Password NVARCHAR(MAX) NOT NULL, -- Contraseña del usuario
--    Admin BIT NOT NULL -- Indica si el usuario es administrador
--);
--GO

-- Crear la tabla Tarea
--CREATE TABLE Tarea (
--    Id_Tarea INT PRIMARY KEY IDENTITY, -- Identificador único para cada tarea
--    Titulo NVARCHAR(255) NOT NULL, -- Título de la tarea
--    Descripcion NVARCHAR(1000) NOT NULL, -- Descripción de la tarea
--    FechaVencimiento DATE NOT NULL, -- Fecha de vencimiento de la tarea
--    Prioridad NVARCHAR(10) CHECK (Prioridad IN ('Baja', 'Media', 'Alta')) NOT NULL, -- Prioridad de la tarea
--    Estado NVARCHAR(50) NOT NULL -- Estado de la tarea
--);
--GO

-- Crear la tabla intermedia Usuario_Tarea
--CREATE TABLE Usuario_Tarea (
--    Id_Usuario_Tarea INT PRIMARY KEY IDENTITY, -- Identificador único para cada relación usuario-tarea
--    Id_Usuario INT NOT NULL, -- Identificador del usuario
--    Id_Tarea INT NOT NULL, -- Identificador de la tarea
--    FOREIGN KEY (Id_Usuario) REFERENCES Usuario(Id_Usuario), -- Llave foránea hacia la tabla Usuario
--    FOREIGN KEY (Id_Tarea) REFERENCES Tarea(Id_Tarea) -- Llave foránea hacia la tabla Tarea
--);
--GO

-- PROCEDIMIENTOS ALMACENADOS

-- Procedimiento para crear un usuario
CREATE OR ALTER PROCEDURE sp_CrearUsuario
    @Nombre NVARCHAR(255),
    @Email NVARCHAR(255),
    @Password NVARCHAR(MAX),
    @Admin BIT 
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el email ya está registrado
        IF EXISTS (SELECT 1 FROM Usuario WHERE Email = @Email)
        BEGIN
            THROW 50001, 'El email ya está registrado.', 1;
        END

        -- Insertar el nuevo usuario en la tabla Usuario
        INSERT INTO Usuario (Nombre, Email, Password, Admin)
        VALUES (@Nombre, @Email, @Password, @Admin);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para actualizar un usuario
CREATE OR ALTER PROCEDURE sp_ActualizarUsuario
    @Id_Usuario INT,
    @Nombre NVARCHAR(255),
    @Email NVARCHAR(255)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el usuario existe
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE Id_Usuario = @Id_Usuario)
        BEGIN
            THROW 50002, 'El usuario no existe.', 1;
        END
        
        -- Verificar si el email ya está en uso por otro usuario
        IF EXISTS (SELECT 1 FROM Usuario WHERE Email = @Email AND Id_Usuario <> @Id_Usuario)
        BEGIN
            THROW 50003, 'El email ya está en uso por otro usuario.', 1;
        END
        
        -- Actualizar los datos del usuario
        UPDATE Usuario
        SET Nombre = @Nombre, Email = @Email
        WHERE Id_Usuario = @Id_Usuario;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para crear una tarea
CREATE OR ALTER PROCEDURE sp_CrearTarea
    @Titulo NVARCHAR(255),
    @Descripcion NVARCHAR(1000),
    @FechaVencimiento DATE,
    @Prioridad NVARCHAR(10),
    @Estado NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si la prioridad es válida
        IF @Prioridad NOT IN ('Baja', 'Media', 'Alta')
        BEGIN
            THROW 50004, 'La prioridad debe ser Baja, Media o Alta.', 1;
        END

        -- Insertar la nueva tarea en la tabla Tarea
        INSERT INTO Tarea (Titulo, Descripcion, FechaVencimiento, Prioridad, Estado)
        VALUES (@Titulo, @Descripcion, @FechaVencimiento, @Prioridad, @Estado);
        
        -- Obtener el ID de la tarea recién creada
        SELECT SCOPE_IDENTITY() AS IdTarea;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para actualizar una tarea
CREATE OR ALTER PROCEDURE sp_ActualizarTarea
    @Id_Tarea INT,
    @Titulo NVARCHAR(255),
    @Descripcion NVARCHAR(1000),
    @FechaVencimiento DATE,
    @Prioridad NVARCHAR(10),
    @Estado NVARCHAR(50)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si la tarea existe
        IF NOT EXISTS (SELECT 1 FROM Tarea WHERE Id_Tarea = @Id_Tarea)
        BEGIN
            THROW 50005, 'La tarea no existe.', 1;
        END
        
        -- Verificar si la prioridad es válida
        IF @Prioridad NOT IN ('Baja', 'Media', 'Alta')
        BEGIN
            THROW 50006, 'La prioridad debe ser Baja, Media o Alta.', 1;
        END
        
        -- Actualizar los datos de la tarea
        UPDATE Tarea
        SET Titulo = @Titulo, Descripcion = @Descripcion, FechaVencimiento = @FechaVencimiento, 
            Prioridad = @Prioridad, Estado = @Estado
        WHERE Id_Tarea = @Id_Tarea;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para eliminar una tarea
CREATE OR ALTER PROCEDURE sp_EliminarTarea
    @Id_Tarea INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si la tarea existe
        IF NOT EXISTS (SELECT 1 FROM Tarea WHERE Id_Tarea = @Id_Tarea)
        BEGIN
            THROW 50007, 'La tarea no existe.', 1;
        END
        
        -- Eliminar las relaciones de la tarea con los usuarios
        DELETE FROM Usuario_Tarea WHERE Id_Tarea = @Id_Tarea;
        -- Eliminar la tarea
        DELETE FROM Tarea WHERE Id_Tarea = @Id_Tarea;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para obtener tareas con sus usuarios asignados
CREATE OR ALTER PROCEDURE sp_ObtenerTareasConUsuarios
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Seleccionar tareas con sus usuarios asignados
        SELECT 
            T.Id_Tarea,
            T.Titulo,
            T.Descripcion,
            T.FechaVencimiento,
            T.Prioridad,
            T.Estado,
            U.Id_Usuario,
            U.Nombre AS Nombre_Usuario,
            U.Email AS Email_Usuario
        FROM Tarea T
        LEFT JOIN Usuario_Tarea UT ON T.Id_Tarea = UT.Id_Tarea
        LEFT JOIN Usuario U ON UT.Id_Usuario = U.Id_Usuario
        ORDER BY T.FechaVencimiento ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para obtener un usuario por su ID
CREATE OR ALTER PROCEDURE sp_ObtenerUsuario
    @Id_Usuario INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Verificar si el usuario existe
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE Id_Usuario = @Id_Usuario)
        BEGIN
            THROW 50008, 'El usuario no existe.', 1;
        END

        -- Obtener datos del usuario
        SELECT Id_Usuario, Nombre, Email
        FROM Usuario
        WHERE Id_Usuario = @Id_Usuario;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para obtener todos los usuarios que no son administradores
CREATE OR ALTER PROCEDURE sp_ObtenerUsuarios
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Obtener datos de los usuarios que no son administradores
        SELECT Id_Usuario, Nombre, Email, Password
        FROM Usuario
        WHERE Admin = 0

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para verificar el inicio de sesión
ALTER PROCEDURE [dbo].[sp_VerificarInicioSesion]
    @Email NVARCHAR(255),
    @Password NVARCHAR(MAX)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @RecuperadaPassword NVARCHAR(MAX);
        DECLARE @Id_Usuario INT;
        DECLARE @Nombre NVARCHAR(MAX);
        DECLARE @Admin BIT;

        -- Obtener la contraseña almacenada del usuario
        SELECT @RecuperadaPassword = Password, @Id_Usuario = Id_Usuario, @Nombre = Nombre, @Admin = Usuario.[Admin]
        FROM Usuario
        WHERE Email = @Email;

        -- Si no se encuentra el usuario, retornar error
        IF @RecuperadaPassword IS NULL
        BEGIN
            THROW 50009, 'Credenciales incorrectas.', 1;
        END

        -- Comparar la contraseña ingresada con la almacenada
        IF @RecuperadaPassword = @Password
        BEGIN
            -- Devolver datos del usuario si la contraseña es correcta
            SELECT @Id_Usuario AS Id_Usuario, @Nombre AS Nombre, @Email AS Email, @Admin as Admin
        END
        ELSE
        BEGIN
            THROW 50010, 'Credenciales incorrectas.', 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Procedimiento para insertar o eliminar una relación usuario-tarea
CREATE OR ALTER PROCEDURE sp_InsertarEliminarUsuarioTarea
    @Id_Usuario INT,
    @Id_Tarea INT,
    @Operacion BIT -- 1 para Insertar, 0 para Eliminar
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el usuario existe
        IF NOT EXISTS (SELECT 1 FROM Usuario WHERE Id_Usuario = @Id_Usuario)
        BEGIN
            RAISERROR('El usuario especificado no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Verificar si la tarea existe
        IF NOT EXISTS (SELECT 1 FROM Tarea WHERE Id_Tarea = @Id_Tarea)
        BEGIN
            RAISERROR('La tarea especificada no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @Operacion = 1 -- Insertar
        BEGIN
            -- Insertar en la tabla Usuario_Tarea solo si no existe
            IF NOT EXISTS (SELECT 1 FROM Usuario_Tarea WHERE Id_Usuario = @Id_Usuario AND Id_Tarea = @Id_Tarea)
            BEGIN
                INSERT INTO Usuario_Tarea (Id_Usuario, Id_Tarea)
                VALUES (@Id_Usuario, @Id_Tarea);
            END
        END
        ELSE -- Eliminar
        BEGIN
            -- Eliminar de la tabla Usuario_Tarea solo si existe
            IF EXISTS (SELECT 1 FROM Usuario_Tarea WHERE Id_Usuario = @Id_Usuario AND Id_Tarea = @Id_Tarea)
            BEGIN
                DELETE FROM Usuario_Tarea WHERE Id_Usuario = @Id_Usuario AND Id_Tarea = @Id_Tarea;
            END
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Procedimiento para actualizar el estado de una tarea
CREATE OR ALTER PROCEDURE sp_ActualizarEstadoTarea
    @Id_Tarea INT,
    @Estado NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si la tarea existe
        IF NOT EXISTS (SELECT 1 FROM Tarea WHERE Id_Tarea = @Id_Tarea)
        BEGIN
            RAISERROR('La tarea especificada no existe.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Actualizar el estado de la tarea
        UPDATE Tarea
        SET Estado = @Estado
        WHERE Id_Tarea = @Id_Tarea;
        
        COMMIT TRANSACTION;
        PRINT 'Estado actualizado correctamente';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Procedimiento para obtener una tarea por su ID
CREATE OR ALTER PROCEDURE sp_ObtenerTareaId
    @pId_Tarea INT 
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Seleccionar la tarea y sus usuarios asignados por ID de tarea
        SELECT 
            T.Id_Tarea,
            T.Titulo,
            T.Descripcion,
            T.FechaVencimiento,
            T.Prioridad,
            T.Estado,
            U.Id_Usuario,
            U.Nombre AS Nombre_Usuario,
            U.Email AS Email_Usuario
        FROM Tarea T
        LEFT JOIN Usuario_Tarea UT ON T.Id_Tarea = UT.Id_Tarea
        LEFT JOIN Usuario U ON UT.Id_Usuario = U.Id_Usuario
        WHERE T.Id_Tarea = @pId_Tarea
        ORDER BY T.FechaVencimiento ASC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO