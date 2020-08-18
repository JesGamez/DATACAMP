-- 1) Temporal EDA, Variables y Date Manipulation
-- Introduccion del curso (VIDEO)

--1.1 Transacciones por dia

SELECT
  -- Select the date portion of StartDate
  CONVERT(DATE, StartDate) as StartDate,
  -- Measure how many records exist for each StartDate
  COUNT(ID) as CountOfRows 
FROM CapitalBikeShare 
-- Group by the date portion of StartDate
GROUP BY CONVERT(DATE, StartDate)
-- Sort the results by the date portion of StartDate
ORDER BY CONVERT(DATE, StartDate);

--1.2 ¿Segundos o sin segundos?

SELECT
	-- Contar el numero de identificadores
	COUNT(ID) AS Count,
    -- Usar DATEPART() para evaluar la segunda parte de StartDate
    "StartDate" = CASE WHEN DATEPART(SECOND, StartDate) = 0 THEN 'SECONDS = 0'
					   WHEN DATEPART(SECOND, StartDate) > 0 THEN 'SECONDS > 0' END
FROM CapitalBikeShare
GROUP BY
    -- Completa la declaracion CASE
	CASE WHEN DATEPART(SECOND, StartDate) = 0 THEN 'SECONDS = 0'
		 WHEN DATEPART(SECOND, StartDate) > 0 THEN 'SECONDS > 0' END

--1.3 ¿Qué día de la semana está más ocupado?

SELECT
    -- Seleccione el valor del dia de la semana para StartDate
	DATENAME(weekday, StartDate) as DayOfWeek,

    -- Calcular TotalTripHours
	SUM(DATEDIFF(second, StartDate, EndDate))/ 3600 as TotalTripHours 
FROM CapitalBikeShare 

-- Agrupar por dias de la semana
GROUP BY DATENAME(weekday, StartDate)

-- Ordene TotalTripHours en orden descendente
ORDER BY TotalTripHours DESC

--1.4 Encuentra los valores atípicos

SELECT
	-- Calcular TotalRideHours usando SUM() y DATEDIFF()
  	SUM(DATEDIFF(SECOND, StartDate, EndDate))/ 3600 AS TotalRideHours,

    -- Select the DATE portion of StartDate
  	CONVERT(DATE, StartDate) AS DateOnly,

    -- Selecciona el WEEKDAY
  	DATENAME(WEEKDAY, CONVERT(DATE, StartDate)) AS DayOfWeek 
FROM CapitalBikeShare

-- Solo incluye sabado
WHERE DATENAME(WEEKDAY, StartDate) = 'Saturday' 
GROUP BY CONVERT(DATE, StartDate);

--1.5 Variables para datos de fecha y hora (VIDEO)

--1.6 DECLARAR Y REPARAR

-- Crear @ShiftStartTime
DECLARE @ShiftStartTime AS time = '08:00 AM'

-- Crear @StartDate
DECLARE @StartDate AS date

-- Establecer StartDate en la primera StartDate de CapitalBikeShare
SET 
	@StartDate = (
    	SELECT TOP 1 StartDate 
    	FROM CapitalBikeShare 
    	ORDER BY StartDate ASC
		)

-- Crear ShiftStartDateTime
DECLARE @ShiftStartDateTime AS datetime

-- Cast StartDate y ShiftStartTime a tipos de datos de fecha y hora
SET @ShiftStartDateTime = CAST(@StartDate AS datetime) + CAST(@ShiftStartTime AS datetime) 

SELECT @ShiftStartDateTime

-- 1.7 DECLARAR UN TABLE

-- Declare @Shifts como una TABLE
DECLARE @Shifts TABLE(
    -- Crear columna StartDateTime 
	StartDateTime datetime,
    -- Crear columna EndDateTime
	EndDateTime datetime)
-- Rellenar @Shifts
INSERT INTO @Shifts (StartDateTime, EndDateTime)
	SELECT '3/1/2018 8:00 AM', '3/1/2018 4:00 PM' 
SELECT * 
FROM @Shifts

--1.8 INSERT INTO @TABLE

-- Declare @RideDates
DECLARE @RideDates TABLE(
    -- Crear RideStart
	RideStart date,
    -- Crear RideEnd
	RideEnd date)
-- Completar @RideDates
INSERT INTO @RideDates(RideStart, RideEnd)
-- seleccionar los valores de fecha unicos de StartDate y EndDate
SELECT DISTINCT
    -- Cast StartDate como fecha
	CAST(StartDate as date),
    -- Cast EndDate como fecha
	CAST(EndDate as date) 
FROM CapitalBikeShare 
SELECT * 
FROM @RideDates

--1.9 Manipulacion de la fecha (VIDEO)

--1.10 Los parámetros importan con DATEDIFF
-- 5 dias,0 semanas,1 mes

--1.11 Primer día del mes
-- Encuentra el primer dia del mes actual
SELECT DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)

--2) Funciones definidas por el usuario

--2.1 Funciones definidas por el usuario (VIDEO)

--2.2 ¿Qué dia fue ayer?

-- Crear GetYesterday()
CREATE FUNCTION GetYesterday()

-- Especificar el tipo de datos devueltos
RETURNS date
AS
BEGIN

-- Calcular el valor de la fecha de ayer
RETURN(SELECT DATEADD(day, -1, GETDATE()))
END 

--2.3 Uno en uno

-- Crear SumRideHrsSingleDay
CREATE FUNCTION SumRideHrsSingleDay (@DateParm date)

-- Especificar el tipo de datos devueltos
RETURNS numeric
AS

-- BEGIN
BEGIN
RETURN

-- Agregar la diferencia entre StartDate y EndDate
(SELECT SUM(DATEDIFF(second, StartDate, EndDate))/3600
FROM CapitalBikeShare

 -- Solo incluya transacciones donde StartDate = @DateParm
WHERE CAST(StartDate AS date) = @DateParm)

-- End
END

--2.4 Varias entradas una salida

-- Crear la funcion
CREATE FUNCTION SumRideHrsDateRange (@StartDateParm datetime, @EndDateParm datetime)

-- Especificar el tipo de datos resuelto
RETURNS numeric
AS
BEGIN
RETURN

-- Sumar la diferencia entre StartDate y EndDate
(SELECT SUM(DATEDIFF(second, StartDate, EndDate))/3600
FROM CapitalBikeShare

-- Incluir solo las transacciones relevantes
WHERE StartDate > @StartDateParm and StartDate < @EndDateParm)
END

--2.5 UDF con valores de tabla (VIDEO)

--2.6 TVF en linea

-- Crear la funcion
CREATE FUNCTION SumStationStats(@StartDate AS datetime)

-- Especificar el tipo de datos devueltos
RETURNS TABLE
AS
RETURN
SELECT
	StartStation,

    -- Usar COUNT() para seleccionar RideCount
	COUNT(ID) as RideCount,

    -- Usar SUM() para calcular TotalDuration
    SUM(DURATION) as TotalDuration
FROM CapitalBikeShare
WHERE CAST(StartDate as Date) = @StartDate

-- Group by StartStation
GROUP BY StartStation;

--2.7 TVF de declaración múltiple

-- Crear la funcion
CREATE FUNCTION CountTripAvgDuration (@Month CHAR(2), @Year CHAR(4))

-- Especificar la variable de retorno
RETURNS @DailyTripStats TABLE(
	TripDate	date,
	TripCount	int,
	AvgDuration	numeric)
AS
BEGIN

-- Insertar los datos de la consulta en @DailyTripStats
INSERT @DailyTripStats
SELECT

    -- Cast StartDate as a date
	CAST(StartDate AS date),
    COUNT(ID),
    AVG(Duration)
FROM CapitalBikeShare
WHERE
	DATEPART(month, StartDate) = @Month AND
    DATEPART(year, StartDate) = @Year

-- Group by StartDate as a date
GROUP BY CAST(StartDate AS date)

-- Return
RETURN
END

--2.8 UDF en accion (VIDEO)
--2.9 Ejecutar escalar con seleccionar

-- Crear @BeginDate
DECLARE @BeginDate AS date = '3/1/2018'

-- Crear @EndDate
DECLARE @EndDate AS date = '3/10/2018' 
SELECT

  -- Seleccionar @BeginDate
  @BeginDate AS BeginDate,

  -- Seleccionar @EndDate
  @EndDate AS EndDate,

  -- Ejecutar SumRideHrsDateRange()
  dbo.SumRideHrsDateRange(@BeginDate, @EndDate) AS TotalRideHrs

--2.10 EXEC escalar

-- Crear @RideHrs
DECLARE @RideHrs AS numeric

-- Ejecutar la funcion SumRideHrsSingleDay y almacenar el resultado en @RideHrs
EXEC @RideHrs = dbo.SumRideHrsSingleDay @DateParm = '3/5/2018' 
SELECT 
  'Total Ride Hours for 3/5/2018:', 
  @RideHrs

--2.11 Ejecute TVF en variable

-- Crear @StationStats
DECLARE @StationStats TABLE(
	StartStation nvarchar(100), 
	RideCount int, 
	TotalDuration numeric)

-- Completar @StationStats con los resultados de la funcion
INSERT INTO @StationStats
SELECT TOP 10 *

-- Ejecutar SumStationStats con 3/15/2018
FROM dbo.SumStationStats ('3/15/2018') 
ORDER BY RideCount DESC

-- Selecionar todos los registros de @StationStats
SELECT * 
FROM @StationStats

--2.12 Mantener funciones definidas por el usuario (VIDEO)

--2.13 CREATE o ALTER

-- Actualizar SumStationStats
CREATE OR ALTER FUNCTION dbo.SumStationStats(@EndDate AS date)

-- Habilitar SCHEMABINDING
RETURNS TABLE WITH SCHEMABINDING
AS
RETURN
SELECT
	StartStation,
    COUNT(ID) AS RideCount,
    SUM(DURATION) AS TotalDuration
FROM dbo.CapitalBikeShare
-- Cast EndDate as date y comparar con @EndDate
WHERE CAST(EndDate AS Date) = @EndDate
GROUP BY StartStation;

--2.14 Mejores prácticas
¿Qué hace que una función sea determinista?
--Si devuelve el pronostico de mañana

--3) Stored procedures (VIDEO)
-- 3.1 CREAR PROCEDIMIENTO con SALIDA

-- Crear el stored procedure
CREATE PROCEDURE dbo.cuspSumRideHrsSingleDay
    -- Declarar el parametro de entrada
	@DateParm date,
    -- Declarar el parametro de salida
	@RideHrsOut numeric OUTPUT
AS
-- No enviar el recuento de filas
SET NOCOUNT ON
BEGIN

-- Asignar el resultado de la consulta @RideHrsOut
SELECT
	@RideHrsOut = SUM(DATEDIFF(second, StartDate, EndDate))/3600
FROM CapitalBikeShare

-- Cast StartDate as date y comparar con @DateParm
WHERE CAST(StartDate AS date) = @DateParm
RETURN
END

-- 3.2 Parámetros de salida frente a valores de retorno
Seleccione la declaración que es FALSA al comparar los parámetros de salida y los valores de retorno.
-- Los parametros de salida deben usarse para comunicar errores a la aplicacion que realiza la llamada

--3.3 ¡OH CRUD! (VIDEO)
--3.4 Utilice SP para INSERTAR

-- Crear el stored procedure
CREATE PROCEDURE dbo.cusp_RideSummaryCreate 
    (@DateParm date, @RideHrsParm numeric)
AS
BEGIN
SET NOCOUNT ON

-- Insertar en las columnas Date y RideHours
INSERT INTO dbo.RideSummary(Date, RideHours)

-- Utilice valores de @DateParm y @RideHrsParm
VALUES(@DateParm, @RideHrsParm) 

-- Seleccione el registro que acaba de insertar
SELECT
    -- Seleccioanr la columna fecha
	Date,
    -- seleccionar la columna RideHours
    RideHours
FROM dbo.RideSummary

-- Comprobar si la fecha es igual a @DateParm
WHERE Date = @DateParm
END;

--3.5 Utilice SP para ACTUALIZAR

-- Crear el stored procedure
CREATE PROCEDURE dbo.cuspRideSummaryUpdate

	-- Specify @Date input parameter
	(@Date date,

     -- Specify @RideHrs input parameter
     @RideHrs numeric(18,0))
AS
BEGIN
SET NOCOUNT ON
-- Update RideSummary
UPDATE RideSummary
-- Set
SET
	Date = @Date,
    RideHours = @RideHrs
-- Include records where Date equals @Date
WHERE Date = @Date
END;

--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--