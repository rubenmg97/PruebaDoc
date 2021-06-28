ALTER PROCEDURE [dbo].[spLsnetDocumentoContrato]
	@CveContrato char(15),
	@CveCliente  int,
	@CveEmpresa  int,
	@CveMoneda   int,
	@CveTOperacion  char(2),
	@FechaOperacion datetime,
	@CvePJuridica   char(2),
	@out_sMensajeError varchar(50) OUTPUT
AS
/*Tracker 6736:EAC:210507:Que salira la escritura de una persona fisica en las declaraciones, y sus apoderados en el proemio*/
/*Tracker 6870:EAC:110707:Se agrega la variable de puntos para que se puedan manejar en la tasa moratoria*/
/*Tracker 6984:EAC:191007:Se corrigio la sección de declaraciones de avales para personas morales*/
/*bug 275:ggv:04/03/2009*/
--BUG 275:GGV:02/04/2009: La declaración del apoderado de la financiera se obtiene de base de datos.
--Marredondo Se hacen correcciones al SP y se agregan nuevos campos
/*Tracker 9848 acarrillo 25/08/2010 formatos para MEGA*/
/*-----------------------------------------------------------------------------------
Generó               : Juan Araujo Esquivel
Fecha de creación    : 15 diciembre 2004
Fecha de modificación: 27 diciembre 2004
Descripción          : Stored Procedure para la generación de contrato
Nombre               : spLsnetDocumentoContrato
-----------------------------------------------------------------------------------*/
--La parte de la creación de la tabla va comentada
--CREATE TABLE #Claves
--(
--	Clave char(100),
--	Texto text
--)
DECLARE @PersonaAuxiliar int
DECLARE @PalabraAuxiliar varchar(8000)
DECLARE @ptr     varbinary(16)
DECLARE @ptr2     varbinary(16)
DECLARE @sTemp   char(8000)
DECLARE @NOFFSET int
DECLARE @NOFFSET2 int
DECLARE @Nombre         char(2000)
DECLARE	@Status	        int
DECLARE @ApePaterno     char(50)
DECLARE @ApeMaterno     char(50)
DECLARE @Representantes char(1000)
DECLARE @Auxiliar       char(250)
DECLARE @Contador       int
DECLARE @RFC            char(18)
DECLARE @CP             char(8)
DECLARE @EFed           char(50)
DECLARE @Ciudad         char(50)
DECLARE @Municipio      char(50)
DECLARE @Colonia        char(50)
DECLARE @Calle          char(50)
DECLARE @CantidadLetra  VARCHAR(500)
DECLARE @CveContratoMaestro varchar(20),
		@Apoderado  VARCHAR(200),
		@DeclaracionApoderado  VARCHAR(8000), --tracker ggv
		@Declaraciones varchar(8000),
		@Declaraciones1 varchar(8000),
		@ESC_DS_CIUDAD	VARCHAR(1000),
		@indiceApoderados tinyint,
		@textoApoderadoIndividual varchar(8000),
		@textoApoderadoIndividual1 varchar(8000),
		@textoApoderadosAcumulado varchar(8000),
		@apoderadoCliente varchar(100),
		@cat numeric(7,2),
		@primerPago varchar(25),
		@ultimoPago varchar(25),-- anc
		@plazo int,
		@periodPago varchar(50),
		@periodPagoNum varchar(30),
		@tasa varchar(50),
		@composicion varchar(50),
		@puntosAdic numeric(7,2),
		@montoFinanciar numeric(13,2),
		@PagoMontoParcial numeric(13,2),
		@ImpuestoVal numeric(13,2),
		@IVA numeric (13,2),
		@tasaNominal numeric(13,2),		
		@tasaMoratoria numeric(7,2),
		@factorMoratorio numeric(7,2),
		@montoCapital numeric(13,2),
		@montoEnganche numeric(13,2),
		@montoOpcCompra numeric(13,2),
		@ivaContrato numeric(7,2),
		@tasaBase numeric(7,2),
		@claveTasa int,
		@puntos numeric(7,2),
		@factor numeric(7,2),
		@tipoTasa tinyint,
		@tipoCalculo tinyint,
		@comServFinan numeric(7,2),
		@comServAdmin numeric(7,2), 
		@varDireccion varchar(1000), 
		@AvalesNombDirec varchar(2000) = '',
		@nomEmpresa varchar(500) = '',
		@sexoCliente varchar(50),
		@edoCivilCliente varchar(50),
		@curpCliente varchar(20),
		@empCliente varchar(30)
		
		
DECLARE @Dia varchar(2), @Mes varchar(25), @Año varchar(4)
	DECLARE @porcentajeOpcCompra VARCHAR(50)
	DECLARE @MontoPago1 VARCHAR(50) 
	DECLARE @MontoInteres1 VARCHAR(50)
	DECLARE @MontoAmortizacion1 VARCHAR(50)
	DECLARE @montoOCARGOS1 VARCHAR(50)
	DECLARE @MontoSinsoluto1 VARCHAR(50)
	DECLARE @MontoTotal1 VARCHAR (50)
	DECLARE @sumaMontoPago1 varchar(50)
	DECLARE @sumaMontoInteres1 varchar(50)
	DECLARE @sumaMontoAmortizacion1 varchar(50)
	DECLARE @sumaMontoSinsoluto1 varchar (50)
	DECLARE @sumaMontoTotal1 varchar (50)
	DECLARE @sumaMontoOCARGOS1 varchar (50)
	DECLARE @MontoIvaAmortizacion1 varchar(50)
	DECLARE @MontoIvaInteres1 varchar(50)
	DECLARE @sumaMontoIvaAmortizacion1 varchar(50)
	DECLARE @sumaMontoIvaInteres1 varchar(50)
	DECLARE @montoFinanciar1 VARCHAR(50)
	DECLARE @montoCapital1 VARCHAR(50)
	DECLARE @montoOpcCompra1 VARCHAR(50)
	DECLARE @montoEnganche1 VARCHAR(50)
	DECLARE @montoDeposito numeric(13,2)
	Declare @montoDeposito1  VARCHAR(50)

/* auto */

declare @AutMonto numeric(12,2), 
	@AutProducto varchar(50), 
	@AutNS varchar(50), 
	@AutMotor varchar(50), 
	@AutPlacas varchar(50), 
	@AutAdicional varchar(50), 
	@AutModelo varchar(50), 
	@AutMarca varchar(50),
	@AutTblCompleta varchar(max),
	@AutColor varchar(50),
	@AutDSProducto varchar (200),
	@AutAgencia varchar(200); 

set @AutTblCompleta = '';

/* Garantias */

declare @gtaValor money, 
	@gtaDescripcion varchar(5000), 
	@gtaTipo varchar(200), 
	@gtaTabla varchar(max),
	@gtaTablaAnidado varchar(max)

declare @per_tipodevivienda varchar(100), 
	@per_ocupacion varchar(200),
	@emp_EMPRESADONDELABORA varchar(500);

declare @emp_giro varchar(500),
	@emp_finioperaciones datetime,
	@emp_antiguedad varchar(100)

/* contacto */

declare @nombre_contacto varchar(300), 
        @apa_contacto varchar (300),
	    @ama_contacto varchar (300),
		@rfc_contacto varchar(20), 
		@telefono_contacto varchar(30),
		@correo_contacto varchar(50),
		@puesto_contacto varchar(30),
		@sexo_contacto varchar(20),
		@curp_contacto varchar(20)

/* contacto */

/*aval datos*/

declare @nombre_Aval varchar(50),
@apa_aval varchar (50),
@ama_aval varchar (50),
@rfc_Aval varchar (20),
@telefono_Aval varchar (30),
@correo_Aval varchar (50),
@sexo_Aval varchar (20),
@curp_Aval varchar (20),
@calle_Aval varchar (100),
@Num_Aval varchar (20),
@Colonia_Aval varchar (50),
@Ciudad_Aval varchar (50),
@CP_Aval varchar (20),
@Estado_Aval varchar (30),
@MunicipioAval varchar (30)
/*fin aval datos*/

	

SET @montoOpcCompra1 = '0.00'
SET @MontoIvaAmortizacion1 = '0.00'
SET @MontoIvaInteres1 = '0.00'
SET @MontoPago1 = '0.00'
SET @MontoInteres1 = '0.00'
SET @MontoAmortizacion1 = '0.00'
SET @MontoTotal1 = '0.00'
SET @MontoSinsoluto1 = '0.00'
SET @sumaMontoTotal1 = '0.00'
SET @sumaMontoPago1 = '0.00'
SET @sumaMontoInteres1 = '0.00'
SET @sumaMontoAmortizacion1 = '0.00'
SET @MontoIvaAmortizacion1 = '0.00'
SET @MontoIvaInteres1 = '0.00'
SET @sumaMontoIvaAmortizacion1 = '0.00'
SET @sumaMontoIvaInteres1 = '0.00'
SET @montoFinanciar1 = '0.00'
SET @montoCapital1 = '0.00'
SET @montoOpcCompra1 = '0.00'
SET @montoEnganche1 = '0.00'
SET @Declaraciones = ''
--SET @Apoderado = ''
--SET @DeclaracionApoderado = ''


CREATE TABLE #CLAVES(CLAVE CHAR(100), TEXTO TEXT)


--Nómero de cliente
INSERT INTO #Claves VALUES ('[%ClaveCliente%]',RTRIM(convert(varchar(20),@CveCliente)))
--Nómero de contrato
SET @CveContratoMaestro = ''
	select @CveContratoMaestro = (convert(varchar(20),CTO_FL_CVE_MAESTRO)) FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato

declare @texto varchar(50)
set @texto=''
select @texto=cpc_ds_valor from ccatalogo_contrato  where  cpc_no_catalogo=2 and  cto_fl_cve=@CveContrato

--AOB:se agrega validacion de cadena vacia

if @texto is null or  @texto = ''
begin
IF RTRIM(LTRIM(REPLACE(@CveContratoMaestro,CHAR(160),''))) <> ''
	INSERT INTO #Claves VALUES ('[%NoContrato%]',' \b ' + RTRIM(@CveContratoMaestro) + ' \b0 ')
ELSE
	INSERT INTO #Claves VALUES ('[%NoContrato%]',' \b ' + RTRIM(@CveContrato) + ' \b0 ')
end
else
begin
INSERT INTO #Claves VALUES ('[%NoContrato%]',' \b ' + RTRIM(@texto) + ' \b0 ')
end

select @per_tipodevivienda = ccpc.cpc_ds_valor
from CPERSONA cp
inner join CCATALOGO_PERSONA ccp
on cp.PNA_FL_PERSONA = ccp.PNA_FL_PERSONA
inner join CCATALOGOS_CONTRATOPERSONA ccpc
on  ccp.CPC_FL_CVE = ccpc.CPC_FL_CVE
and ccpc.cpc_no_catalogo = 3
where cp.pna_fl_persona = @CveCliente


select  @emp_EMPRESADONDELABORA = GRI_DS_NOMBRE
from CPERSONA cp
inner join CGRUPORIESGO cgr
on cp.GRI_FL_CVE = cgr.GRI_FL_CVE
where cp.pna_fl_persona = @CveCliente



INSERT INTO #Claves VALUES ('[%PER_TIPODEVIVIENDA%]', isnull(@per_tipodevivienda, ''));
INSERT INTO #Claves VALUES ('[%EMP_EMPRESADONDELABORA%]', isnull(@emp_EMPRESADONDELABORA, ''));


select @per_ocupacion = cp.PAR_DS_DESCRIPCION
from CPFISICA CPF
INNER JOIN CPARAMETRO CP
on cpf.PFI_FG_OCUPACION = cp.PAR_CL_VALOR
and PAR_FL_CVE = 15
where PNA_FL_PERSONA = @CveCliente

INSERT INTO #Claves VALUES ('[%PER_OCUPACION%]', isnull(@per_ocupacion, ''));

--cambió ARACELI NARANJO***************************

SELECT  @emp_giro = SEC_DS_SECTOR, 
	 @emp_finioperaciones = PMO_FE_CONSTITUCION,
	@emp_antiguedad = ltrim(datediff(yy, PMO_FE_CONSTITUCION, getdate())) + ' Años'
FROM CPMORAL CPM
left outer join CSECTOR CS
ON CPM.SEC_FL_CVE = CS.SEC_FL_CVE
WHERE PNA_FL_PERSONA = @CveCliente;
 EXEC lsntReplace @emp_antiguedad, @emp_antiguedad output
INSERT INTO #Claves VALUES ('[%emp_giro%]', isnull(@emp_giro, ''));
INSERT INTO #Claves VALUES ('[%emp_finioperaciones%]', convert(varchar(10), @emp_finioperaciones, 101));
INSERT INTO #Claves VALUES ('[%emp_antiguedad%]', isnull(@emp_antiguedad, ''));

/*	datos del contacto de la empresa	*/

select distinct @nombre_contacto = PFI_DS_NOMBRE,
				 @apa_contacto = PFI_DS_APATERNO,
				 @ama_contacto = PFI_DS_AMATERNO, 
				@rfc_contacto = PNA_CL_RFC, 
				@telefono_contacto = case when TFN_CL_EXTENSION is null
											then TFN_CL_LADA + TFN_CL_TELEFONO
										else TFN_CL_LADA + TFN_CL_TELEFONO + ' Ext. ' + TFN_CL_EXTENSION 
									end, 
				@correo_contacto = cpe.MAI_DS_EMAIL, 
				@puesto_contacto = PMO_DS_PTOCONTACTO, 
				@sexo_contacto = cpar.PAR_DS_DESCRIPCION, 
				@curp_contacto = PFI_CL_CURP
from CPRELACION cpr
inner join CPERSONA cp2
on cpr.PNA_FL_PERSONA = cp2.PNA_FL_PERSONA
left outer join CTELEFONO ct
on cp2.PNA_FL_PERSONA = ct.PNA_FL_PERSONA
left outer join CPERSONA_EMAIL cpe
on cp2.PNA_FL_PERSONA = cpe.PNA_FL_PERSONA
left outer join CPMORAL cpm
on cp2.PNA_FL_PERSONA = cpm.PNA_FL_PERSONA
left outer join CPFISICA cpf
on cp2.PNA_FL_PERSONA = cpf.pna_fl_persona
left outer join cparametro cpar
on cpf.PFI_FG_SEXO = cpar.PAR_CL_VALOR
and PAR_FL_CVE = 17
where cpr.PRE_FL_PERSONA = @CveCliente --@var

INSERT INTO #Claves VALUES ('[%nombre_contacto%]', isnull(@nombre_contacto, ''));
INSERT INTO #Claves VALUES ('[%apa_contacto%]', isnull(@apa_contacto, ''));
INSERT INTO #Claves VALUES ('[%ama_contacto%]', isnull(@ama_contacto, ''));
INSERT INTO #Claves VALUES ('[%rfc_contacto%]', isnull(@rfc_contacto, ''));
INSERT INTO #Claves VALUES ('[%telefono_contacto%]', isnull(@telefono_contacto, ''));
INSERT INTO #Claves VALUES ('[%correo_contacto%]', isnull(@correo_contacto, ''));
INSERT INTO #Claves VALUES ('[%puesto_contacto%]', isnull(@puesto_contacto, ''));
INSERT INTO #Claves VALUES ('[%sexo_contacto%]', isnull(@sexo_contacto, ''));
INSERT INTO #Claves VALUES ('[%curp_contacto%]', isnull(@curp_contacto, ''));


/*Datos del Aval*/

select  distinct @nombre_Aval = PFI_DS_NOMBRE,
				 @apa_aval = PFI_DS_APATERNO,
				 @ama_aval = PFI_DS_AMATERNO,
                @rfc_Aval = PNA_CL_RFC, 
				@telefono_Aval = case when TFN_CL_EXTENSION is null
											then TFN_CL_LADA + TFN_CL_TELEFONO
										else TFN_CL_LADA + TFN_CL_TELEFONO + ' Ext. ' + TFN_CL_EXTENSION 
									end, 
				@correo_Aval = cpe.MAI_DS_EMAIL, 
				@sexo_Aval = cpar.PAR_DS_DESCRIPCION, 
				@curp_Aval = PFI_CL_CURP,
				@calle_Aval = DMO_DS_CALLE_NUM,
				@Num_Aval = DMO_DS_NUMEXT,
				@Colonia_Aval = DMO_DS_COlONIA,
				@Ciudad_Aval = DMO_DS_CIUDAD,
				@CP_Aval = DMO_CL_CPOSTAL,
				@Estado_Aval = DMO_DS_EFEDERATIVA,
				@MunicipioAval = DMO_DS_MUNICIPIO
				
				
				
from CPRELACION cpr
inner join CPERSONA cp2
on cpr.PNA_FL_PERSONA = cp2.PNA_FL_PERSONA
INNER JOIN KCTO_ASIG_LEGAL_CLIENTE CP3 ON CP3.ALG_CL_TIPO_RELACION =CPR.PRE_FG_VALOR
AND CP3.PNA_FL_PERSONA =CPR.PRE_FL_PERSONA 
left outer join CDOMICILIO cd
ON cp2.PNA_FL_PERSONA = cd.PNA_FL_PERSONA
left outer join CTELEFONO ct
on cp2.PNA_FL_PERSONA = ct.PNA_FL_PERSONA
left outer join CPERSONA_EMAIL cpe
on cp2.PNA_FL_PERSONA = cpe.PNA_FL_PERSONA
left outer join CPMORAL cpm
on cp2.PNA_FL_PERSONA = cpm.PNA_FL_PERSONA
left outer join CPFISICA cpf
on cp2.PNA_FL_PERSONA = cpf.pna_fl_persona
left outer join cparametro cpar
on cpf.PFI_FG_SEXO = cpar.PAR_CL_VALOR
and PAR_FL_CVE = 17
where cpr.PRE_FL_PERSONA = @CveCliente --@var
AND CPR.PRE_FG_VALOR=3
AND CP3.CTO_FL_CVE =@CveContrato
exec lsntReplace @Ciudad_Aval, @Ciudad_Aval output
exec lsntReplace @ama_aval, @ama_aval output
INSERT INTO #Claves VALUES ('[%nombre_Aval%]', isnull(@nombre_Aval, ''));
INSERT INTO #CLAVES VAlUES ('[%apa_Aval%]', ISNULL (@apa_aval, ''));
INSERT INTO #CLAVES VAlUES ('[%ama_Aval%]', ISNULL (@ama_aval, ''));
INSERT INTO #Claves VALUES ('[%rfc_Aval%]', isnull(@rfc_Aval, ''));
INSERT INTO #Claves VALUES ('[%telefono_Aval%]', isnull(@telefono_Aval, ''));
INSERT INTO #Claves VALUES ('[%correo_Aval%]', isnull(@correo_Aval, ''));
INSERT INTO #Claves VALUES ('[%sexo_Aval%]', isnull(@sexo_Aval, ''));
INSERT INTO #Claves VALUES ('[%curp_Aval%]', isnull(@curp_Aval, ''));
INSERT INTO #Claves VALUES ('[%calle_Aval%]', isnull(@calle_Aval, ''));
INSERT INTO #Claves VALUES ('[%Num_Aval%]', isnull(@Num_Aval, ''));  -- 
INSERT INTO #Claves VALUES ('[%Colonia_Aval%]', isnull(@Colonia_Aval, ''));
INSERT INTO #Claves VALUES ('[%Ciudad_Aval%]', isnull(@Ciudad_Aval, ''));
INSERT INTO #Claves VALUES ('[%CP_Aval%]', isnull(@CP_Aval, ''));
INSERT INTO #Claves VALUES ('[%Estado_Aval%]', isnull(@Estado_Aval, ''));
INSERT INTO #Claves VALUES ('[%Muni_Aval%]', isnull(@MunicipioAval, ''));
INSERT INTO #Claves VALUES ('[%gtosAdmCob%]', '');

/*FIN datos del Aval*/



/*AOB: INICIA AVAL 1 Y 2*/

--DECLARE @NOMBREREP VARCHAR(100)
--DECLARE @DESCRIPREP VARCHAR(100)
--DECLARE @DOMREP VARCHAR(150)
--DECLARE @NUMEXTREP VARCHAR(10)
--DECLARE @COLREP VARCHAR(100)
--DECLARE @MUNREP VARCHAR(100)
--DECLARE @CIUDADREP VARCHAR(100)
--DECLARE @CPRP VARCHAR(10)
--DECLARE @EFEDERATIVAREP VARCHAR(100)


--CREATE TABLE #AVALES(ID INT IDENTITY, NOMBRE VARCHAR(100), DESCRIPCION VARCHAR(100), DOMICILIO VARCHAR(150), 
--NUMEXT VARCHAR, COLONIA VARCHAR(100),MUNICIPIO VARCHAR(100),CUIDAD VARCHAR(100), CP CHAR(10),EFEDERATIVA VARCHAR(100))

--INSERT INTO #AVALES
--select distinct  PNA_DS_NOMBRE, cpar.PAR_DS_DESCRIPCION,DMO_DS_CALLE_NUM,DMO_DS_NUMEXT,
--				  DMO_DS_COlONIA,DMO_DS_MUNICIPIO,DMO_DS_CIUDAD,DMO_CL_CPOSTAL,
--				  DMO_DS_EFEDERATIVA
--from CPRELACION cpr
--inner join CPERSONA cp2
--on cpr.PNA_FL_PERSONA = cp2.PNA_FL_PERSONA
--INNER JOIN KCTO_ASIG_LEGAL_CLIENTE CP3 ON CP3.ALG_CL_TIPO_RELACION =CPR.PRE_FG_VALOR
--AND CP3.PNA_FL_PERSONA =CPR.PRE_FL_PERSONA 
--left outer join CDOMICILIO cd ON cp2.PNA_FL_PERSONA = cd.PNA_FL_PERSONA
--left outer join CTELEFONO ct on cp2.PNA_FL_PERSONA = ct.PNA_FL_PERSONA
--left outer join CPERSONA_EMAIL cpe on cp2.PNA_FL_PERSONA = cpe.PNA_FL_PERSONA
--left outer join CPMORAL cpm on cp2.PNA_FL_PERSONA = cpm.PNA_FL_PERSONA
--left outer join CPFISICA cpf on cp2.PNA_FL_PERSONA = cpf.pna_fl_persona
--left outer join cparametro cpar on cpf.PFI_FG_SEXO = cpar.PAR_CL_VALOR
--and PAR_FL_CVE = 17
--where cpr.PRE_FL_PERSONA = @CveCliente
--AND CPR.PRE_FG_VALOR=3
--AND CP3.CTO_FL_CVE =@CveContrato


-- SELECT @NOMBREREP = NOMBRE , @DESCRIPREP = DESCRIPCION , @DOMREP = DOMICILIO , 
-- @NUMEXTREP = NUMEXT , @COLREP = COLONIA ,@MUNREP= MUNICIPIO,  @CIUDADREP = CUIDAD, @CPRP = CP ,@EFEDERATIVAREP = EFEDERATIVA 
-- FROM #AVALES
-- WHERE ID = 1



-- INSERT INTO #Claves VALUES ('[%nombreAval1%]', isnull(@NOMBREREP, ''))
-- INSERT INTO #Claves VALUES ('[%calle_Aval1%]', isnull(@DOMREP, ''))
-- INSERT INTO #Claves VALUES ('[%Num_Aval1%]', isnull(@NUMEXTREP, ''))
-- INSERT INTO #Claves VALUES ('[%Col_Aval1%]', isnull(@COLREP, ''))
-- INSERT INTO #Claves VALUES ('[%Muni_Aval1%]', isnull(@MUNREP, ''))
-- INSERT INTO #Claves VALUES ('[%Ciudad_Aval1%]', isnull(@CIUDADREP, ''))
-- INSERT INTO #Claves VALUES ('[%Cp_Aval1%]', isnull(@CPRP, ''))
-- INSERT INTO #Claves VALUES ('[%Ef_Aval1%]', isnull(@EFEDERATIVAREP, ''))


-- SELECT @NOMBREREP = NOMBRE , @DESCRIPREP = DESCRIPCION , @DOMREP = DOMICILIO , 
-- @NUMEXTREP = NUMEXT , @COLREP = COLONIA ,@MUNREP= MUNICIPIO, @CIUDADREP = CUIDAD, @CPRP = CP ,@EFEDERATIVAREP = EFEDERATIVA 
-- FROM #AVALES
-- WHERE ID = 2


-- INSERT INTO #Claves VALUES ('[%nombreAval2%]', isnull(@NOMBREREP, ''))
-- INSERT INTO #Claves VALUES ('[%calle_Aval2%]', isnull(@DOMREP, ''))
-- INSERT INTO #Claves VALUES ('[%Num_Aval2%]', isnull(@NUMEXTREP, ''))
-- INSERT INTO #Claves VALUES ('[%Col_Aval2%]', isnull(@COLREP, ''))
-- INSERT INTO #Claves VALUES ('[%Muni_Aval2%]', isnull(@MUNREP, ''))
-- INSERT INTO #Claves VALUES ('[%Ciudad_Aval2%]', isnull(@CIUDADREP, ''))
-- INSERT INTO #Claves VALUES ('[%Cp_Aval2%]', isnull(@CPRP, ''))
-- INSERT INTO #Claves VALUES ('[%Ef_Aval2%]', isnull(@EFEDERATIVAREP, ''))

--DROP TABLE #AVALES

/*TERMINA AVALES*/

/*	datos del contacto de la empresa	*/

/*INSERT INTO #Claves VALUES ('[%fechaFirma%]', CONVERT(VARCHAR(2), DAY(getDate()))+ ' de ' +
							CASE MONTH(getDate())
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(getDate())))*/

							INSERT INTO #Claves  select '[%fechaFirma%]', CONVERT(VARCHAR(2), DAY(CTO_FE_FIRMA_CONTRATO))+ ' de ' +
							CASE MONTH(CTO_FE_FIRMA_CONTRATO)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(CTO_FE_FIRMA_CONTRATO)) from kcontrato where cto_fl_cve=@cveContrato
							
	 --PREPAGO ANC
	 DECLARE @PREPAGO VARCHAR (25)
	 
	 SELECT @PREPAGO = CASE PPG_FL_CVE
				WHEN  1 THEN 'MESES'
				WHEN  2 THEN 'BIMESTRES'
				WHEN  3 THEN 'TRIMESTRES'
				WHEN  4 THEN 'CUATRIMESTRES'
				WHEN  5 THEN 'SEMESTRES'
				WHEN  6 THEN 'DIARIOS'
				WHEN  7 THEN 'AÑOS'
				WHEN  8 THEN 'SEMANAS'
				WHEN  9 THEN 'QUINCENAS'
				WHEN 10 THEN 'CATORCENAS'
			END
	FROM	KCONTRATO WHERE CTO_FL_CVE = @cveContrato
		INSERT INTO #Claves VALUES ('[%PREPAGO%]',RTRIM(convert(varchar(20),@PREPAGO)))





--Obtenemos e insertamos datos generales del contrato
set @montoCapital = 0.00
SELECT  @cat=KCONTRATO.CTO_NO_PORC_CATSIVA, @montoFinanciar=KCONTRATO.CTO_NO_MTO_FINANCIAR,  @primerPago=REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2),DAY(CTO_FE_PRIMER_PAGO))))) + RTRIM(CONVERT(CHAR(2),DAY(CTO_FE_PRIMER_PAGO)))+ ' de ' +
			CASE MONTH(CTO_FE_PRIMER_PAGO)
				WHEN  1 THEN 'Enero'
				WHEN  2 THEN 'Febrero'
				WHEN  3 THEN 'Marzo'
				WHEN  4 THEN 'Abril'
				WHEN  5 THEN 'Mayo'
				WHEN  6 THEN 'Junio'
				WHEN  7 THEN 'Julio'
				WHEN  8 THEN 'Agosto'
				WHEN  9 THEN 'Septiembre'
				WHEN 10 THEN 'Octubre'
				WHEN 11 THEN 'Noviembre'
				WHEN 12 THEN 'Diciembre'
			END + ' de ' +
			CONVERT(CHAR(4), YEAR(CTO_FE_PRIMER_PAGO)),
 @ultimoPago=REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2),DAY(CTO_FE_ULTPAGO))))) + RTRIM(CONVERT(CHAR(2),DAY(CTO_FE_ULTPAGO)))+ ' de ' +
			CASE MONTH(CTO_FE_ULTPAGO)
				WHEN  1 THEN 'Enero'
				WHEN  2 THEN 'Febrero'
				WHEN  3 THEN 'Marzo'
				WHEN  4 THEN 'Abril'
				WHEN  5 THEN 'Mayo'
				WHEN  6 THEN 'Junio'
				WHEN  7 THEN 'Julio'
				WHEN  8 THEN 'Agosto'
				WHEN  9 THEN 'Septiembre'
				WHEN 10 THEN 'Octubre'
				WHEN 11 THEN 'Noviembre'
				WHEN 12 THEN 'Diciembre'
			END + ' de ' +
			CONVERT(CHAR(4), YEAR(CTO_FE_ULTPAGO)), 
@plazo=KCONTRATO.CTO_NO_PLAZO, @periodPago=CPERPAGO.PPG_DS_PERPAGO, @periodPagoNum = PPG_NO_DCOMLES ,
@tasa=CTASA.TAS_DS_TASA,@composicion =kcontrato.CTO_DS_COMPOSICION , @claveTasa=CTASA.TAS_FL_CVE, @puntosAdic=KCONTRATO.CTO_NO_PUNTOS_ADIC,@tasaNominal=KCONTRATO.CTO_NO_TASA_NOMINAL,@tasaMoratoria=KCONTRATO.CTO_NO_NOMINAL_MORA,@factorMoratorio=KCONTRATO.CTO_NO_FACTOR_MORA,
@plazo=KCONTRATO.CTO_NO_PLAZO, @montoCapital= CTO_NO_CAPITAL, @montoEnganche=CTO_NO_MTO_ENGANCHE, @montoOpcCompra= CTO_NO_MTO_OPCIONCOMPRA,
@porcentajeOpcCompra = cto_no_prc_opcioncompra,
@ivaContrato=KCONTRATO.CTO_CL_IVA, @puntos=KCONTRATO.CTO_NO_PUNTOS_ADIC, @factor=KCONTRATO.CTO_NO_FACTOR, @tipoCalculo=KCONTRATO.TLO_FL_CVE,
@montoDeposito = CTO_NO_MTO_DEPRENTAS
FROM KCONTRATO, CPERPAGO, CTASA
WHERE
KCONTRATO.PPG_FL_CVE=CPERPAGO.PPG_FL_CVE
AND
KCONTRATO.TAS_FL_CVE=CTASA.TAS_FL_CVE
AND
CTO_FL_CVE=@CveContrato


		set @CantidadLetra=''
exec spLsnetCantidadLetra @montoFinanciar, 1,@cantidadletra output
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%montoFinanciarLetra%]', ltrim(@cantidadletra))


		set @CantidadLetra=''
exec spLsnetCantidadLetra @montoCapital, 1,@cantidadletra output
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%montoCapitalLetra2%]', ltrim(@cantidadletra))

/*PRUEBALETRA*/
select @PagoMontoParcial = SUM(ctp_no_mto_totpago)from 
ktpago_contrato 
where cto_fl_cve = @CveContrato
AND CTP_NO_PAGO=2;

set @CantidadLetra=''
exec spLsnetCantidadLetra @PagoMontoParcial, 1,@cantidadletra output
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%PagoMontoParcialLetra%]', ltrim(@cantidadletra))
/*FIN PRUEBA LETRA*/


/*gastos administrativos de cobranza ini*/
DECLARE @GTOSaDMcOB NUMERIC(13,2)
DECLARE @GTOSaDMcOB1 VARCHAR(50)

select @GTOSaDMcOB=CTP_NO_MTO_TOTPAGO from KTPAGO_CONTRATO A inner join KCTO_OCARGOS B on a.CTC_FL_CVE =b.CTC_FL_CVE    where CTP_CL_TTABLA =4 and KTM_CL_TMOVTO ='COBDOM' AND CTP_NO_PAGO=1 AND b.cto_fl_cve = @CveContrato


if @GTOSaDMcOB is not  null
begin
EXEC @GTOSaDMcOB1 = FormatNumber @GTOSaDMcOB,2,',','.'
UPDATE #Claves SET TEXTO= ltrim(@GTOSaDMcOB1) WHERE CLAVE='[%gtosAdmCob%]'
end
 else
  begin 
   UPDATE #Claves SET TEXTO= '0.0' WHERE CLAVE='[%gtosAdmCob%]'
  end
/*gastos administrativos de cobranza  fin*/



/*PURUEBA IMPUESTO AL VALOR AGREGADO LETRA*/
select @ImpuestoVal = CTP_NO_MTO_IVA FROM KTPAGO_CONTRATO
 WHERE CTO_FL_CVE =  @CveContrato
 AND CTP_CL_TTABLA = 1 
AND CTP_NO_PAGO=1;

set @CantidadLetra=''
exec spLsnetCantidadLetra @ImpuestoVal, 1,@cantidadletra output
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%ImpuestoValLetra%]', ltrim(@cantidadletra))
/*FIN PRUEBA*/


/*prueba letra iva*/

select @IVA =  CTO_CL_IVA from KCONTRATO
where CTO_FL_CVE = @CveContrato
set @CantidadLetra=''
exec spLsnetCantidadLetra @IVA, 1,@cantidadletra output
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%IVALetra%]', ltrim(@cantidadletra))
/*fin */

			if @montoOpcCompra = '0.00' 
				BEGIN
					IF @porcentajeOpcCompra <> '0.00'
					BEGIN
						SET @montoOpcCompra = CONVERT(NUMERIC(13,2),@montoCapital) * (CONVERT(NUMERIC(7,2),@porcentajeOpcCompra)/100)
					END
				END

			IF @montoOpcCompra <> '0.00'
				BEGIN
					EXEC @montoOpcCompra1 = FormatNumber @montoOpcCompra,2,',','.'
					SET @montoOpcCompra1 = @montoOpcCompra1
				END


				EXEC @montoFinanciar1 = FormatNumber @montoFinanciar,2,',','.'
				SET @montoFinanciar1 = @montoFinanciar1

				EXEC @montoCapital1 = FormatNumber @montoCapital,2,',','.'
				SET @montoCapital1 = @montoCapital1

				if @montoEnganche <> 0
				BEGIN
				EXEC @montoEnganche1 = FormatNumber @montoEnganche,2,',','.'		
				SET @montoEnganche1 = @montoEnganche1
				END
	IF @CveTOperacion = 'CD' OR @CveTOperacion = 'CR' OR @CveTOperacion = 'AF'  OR @CveTOperacion = 'AP'
	 BEGIN
		SELECT @montoFinanciar1 = SUM(FAC_NO_MONTO_CONV) FROM KCTO_FACT WHERE CTO_FL_CVE = @CveContrato
		EXEC @montoFinanciar1 = FormatNumber @montoFinanciar1,2,',','.'
	 END
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%cat%]', convert(varchar(10),@cat))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%primerPago%]', @primerPago)
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%ultimoPago%]', @ultimoPago)
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%plazo%]', convert(char(3), @plazo))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%periodPago%]', @periodPago)
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%periodPagoNum%]', @periodPagoNum)

select @nomEmpresa = emp_ds_nombre
from cempresa
where emp_fl_cve = @CveEmpresa;

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NOM_EMPRESA%]', @nomEmpresa)


Insert into #CLAVES values ('[%Periodicidad%]',RTRIM(@periodPago)+'ES')

Insert into #CLAVES values ('[%PeriodicidadS%]',RTRIM(@periodPago)+'IDAD')
Insert into #CLAVES values ('[%Periodicidades%]',RTRIM(@periodPago)+'IDADES')

set @CantidadLetra=''
exec spLsnetCantidadLetra @plazo,-1,@cantidadletra output
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%plazoLetra%]', rtrim(@cantidadletra))


set @plazo=0
Select @plazo=day(CTO_FE_PRIMER_PAGO)  from KCONTRATO where CTO_FL_CVE=@CveContrato

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%DiaPago%]', convert(char(5), @plazo))
set @CantidadLetra=''
exec spLsnetCantidadLetra @plazo,-1,@cantidadletra output

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%DiaPagoLetra%]', rtrim(@cantidadletra))


INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tasa%]', @tasa)
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%composicion%]', @tasa+@composicion)

--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%composicionmoratoria%]', @tasa+@composicion)

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%puntosAdic%]', convert(varchar(10),@puntosAdic))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%montoFinanciar%]',convert(varchar(14),@montoFinanciar1))
--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tasaNominal%]', convert(varchar(10),@tasaNominal))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%montoCapital%]', convert(varchar(14),@montoCapital1))
--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%montoEnganche%]', convert(varchar(14),@montoEnganche))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%montoOpcCompra%]', convert(varchar(14),@montoOpcCompra1))

--SCRIPT TEMPORAL
--determinamos la tasa nominal y tambien obtenemos el tipo de tasa

SELECT @tasaBase=TSV_NO_VALOR, @tipoTasa=A.TAS_FG_TTASA 
FROM CTASA A, KTASA_VALOR B  
WHERE A.TAS_FL_CVE = B.TAS_FL_CVE  
AND B.TSV_FE_GENERA = (SELECT MAX(TSV_FE_GENERA) FROM KTASA_VALOR D WHERE  B.TAS_FL_CVE = D.TAS_FL_CVE) 
AND A.TAS_FL_CVE = @claveTasa AND TAS_FG_STATUS = 1 
ORDER BY TAS_DS_TASA
--SELECT @tasaNominal=CASE WHEN (@tasaBase + @puntos)>(@tasaBase * @factor) THEN (@tasaBase + @puntos) ELSE (@tasaBase * @factor) END

--SCRIPT TEMPORAL
--Para el enganche determinamos si el esquema de financiamiento esta por enganche o por anticipo

SELECT @montoEnganche=CASE WHEN CESQUE_FINAN.ESQ_FG_ENGANCHE=1 THEN KCONTRATO.CTO_NO_MTO_ENGANCHE ELSE KCONTRATO.CTO_NO_MTO_ANTICIPO END
FROM KCONTRATO, CESQUE_FINAN, KTOPERACION
WHERE
KCONTRATO.TOP_CL_CVE=KTOPERACION.TOP_CL_CVE 
AND
KTOPERACION.ESQ_CL_CVE=CESQUE_FINAN.ESQ_CL_CVE
AND
KCONTRATO.CTO_FL_CVE=@CveContrato

IF @montoEnganche1 = '0.00'--El enganche había sido 0 y al serf
BEGIN
	EXEC @montoEnganche1 = FormatNumber @montoEnganche,2,',','.'		
				SET @montoEnganche1 = @montoEnganche1               
END
                                                             
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tasaNominal%]', convert(varchar(45),@tasaNominal))

set @CantidadLetra= ''
exec spLsnetCantidadLetra @tasaNominal, 0,@cantidadletra output


if @cantidadletra like '%PUNTO CERO%'
begin
set @cantidadletra = REPLACE(@cantidadletra,'PUNTO CERO','PUNTOS PORCENTUALES')
end
else 
begin
select @cantidadletra   =    @cantidadletra  + ' ' +  'PUNTOS PORCENTUALES'
end


--declare @Pos as int
--SET @Pos = CHARINDEX('PU', @cantidadletra)
--SET @cantidadletra = STUFF(@cantidadletra, @Pos, 100, 'PUNTOS PORCENTUALES')
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%tasaNominalLetra%]', ltrim(@cantidadletra))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tasaMoratoria%]', convert(varchar(45),@tasaMoratoria))

set @cantidadletra = 0;
exec spLsnetCantidadLetra @tasaMoratoria,0,@cantidadletra output;
if @cantidadletra like '%PUNTO CERO%'
begin
set @cantidadletra = REPLACE(@cantidadletra,'PUNTO CERO','PUNTOS PORCENTUALES')
end
else 
begin
select @cantidadletra   =    @cantidadletra + ' '  +   'PUNTOS PORCENTUALES'
end

--SET @cantidadletra = REPLACE(@cantidadletra,'PUNTO CERO','PUNTOS PORCENTUALES')
--declare @Pos1 as int
--SET @Pos1 = CHARINDEX('PU', @cantidadletra)
--SET @cantidadletra = STUFF(@cantidadletra, @Pos, 100, 'PUNTOS PORCENTUALES')
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tasaMoratoriaLetra%]', ltrim(@cantidadletra));

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%montoEnganche%]', convert(varchar(14),@montoEnganche1))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%factorMoratorio]', convert(varchar(10),@factorMoratorio))

set @CantidadLetra=''
exec spLsnetCantidadLetra @factorMoratorio,-1,@cantidadletra output
INSERT INTO #CLAVES(CLAVE, TEXTO) VALUES('[%factorMoratorioLetra%]', convert(varchar(10),@cantidadletra))

 select @AutMonto = isnull(KPF_NO_MONTO, 0.00), 
		@AutProducto = isnull(TPR_DS_TPRODUCTO, ''),

		@AutDSProducto = isnull(cp.prd_ds_producto,''),
		@AutNS = isnull([N/S], ''),
		@AutMotor = isnull(Motor, ''),
		@AutPlacas = isnull(Placas, ''),
		@AutAdicional = isnull(Adicional, ''),
		@AutAgencia = cd.pna_ds_nombre,
		@AutModelo = isnull(modelo, ''),
		@AutMarca = isnull(cm.MRC_DS_MARCA, ''),
		@AutColor = isnull(Color , ''),
		@AutTblCompleta = @AutTblCompleta + '{\trowd\trgaph108\trrh280\trleft2000' +
											'\trbrdrt\brdrs\brdrw10\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trbrdrr\brdrs\brdrw10' +
											'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx4250' +
											'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx6500' +
											'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx8750' +
											'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx11000' +
											'\pard'+
											'\intbl Nombre de la agencia donde se adquiere el automovil ' + cd.pna_ds_nombre + ' \par\tab \cell No. de Cuenta de Cheques ' + isnull((select top 1 PCT_NO_CUENTA  from CPCUENTA cpc where PNA_FL_PERSONA =kcf.pna_fl_persona and PCT_FG_STATUS =1 order by PCT_FL_CVE ),'')+' \par\tab \cell No. de Cuenta de Cheques CLABE  ' + isnull((select top 1 PCT_NO_CLABE  from CPCUENTA cpc where PNA_FL_PERSONA =kcf.pna_fl_persona and PCT_FG_STATUS =1 order by PCT_FL_CVE ),'')+' \par\tab \cell \cell\row' +										
											'\intbl  Precio de la unidad \par\tab  $' +  dbo.FormatNumber ( isnull(CPC_DS_VALOR, 0.00) ,2,',','.')    + ' \cell Marca \par\tab ' + isnull(cm.MRC_DS_MARCA , '') + ' \cell Tipo \par\tab ' + isnull(TPR_DS_TPRODUCTO, '') + ' \cell No. de serie  ' + isnull([N/S], '') + ' \cell\row' +											
											'\intbl  Año \par\tab ' + isnull(modelo, '') + ' \cell No. de motor \par\tab ' + isnull(Motor, '') + ' \cell Placas \par\tab ' + isnull(Placas, '') + ' \cell Equipo Adicional \par\tab ' + isnull(Adicional, '') + ' \cell\row\pard}'											
 from CCATALOGO_CONTRATO ccc
 inner join KPRODUCTO_FACTURA kpf on ccc.CTO_FL_CVE = kpf.CTO_FL_CVE

 inner join KCTO_FACT kcf on kcf.FAC_FL_CVE =kpf.FAC_FL_CVE
 inner join cpersona cd on cd.pna_fl_persona = kcf.pna_fl_persona 
 

 left outer join cproducto cp
 on kpf.prd_fl_cve = cp.prd_fl_cve
 
 left outer join CTPRODUCTO ctp
 on cp.TPR_FL_CVE = ctp.TPR_FL_CVE

 left outer join CMARCA cm on cm.MRC_FL_CVE =cp.MRC_FL_CVE 
 
 left outer join (SELECT kpf.FAC_FL_CVE, 
				max(case when cca.car_fl_cve = 1
					then CFP_DS_CARACT
				end) 'N/S', 
				max(case when cca.CAR_FL_CVE = 2
					then CFP_DS_CARACT
				end) 'Motor',
				max(case when cca.CAR_FL_CVE = 3
					then CFP_DS_CARACT
				end) 'Placas',
				max(case when cca.CAR_FL_CVE = 4
					then CFP_DS_CARACT
				end) 'Adicional',
				max(case when cca.CAR_FL_CVE = 25
					then CFP_DS_CARACT
				end) 'Modelo',
				max(case when cca.CAR_FL_CVE = 19
					then CFP_DS_CARACT
				end) 'Color'
			FROM kCARAC_PROD_FACT kpf
			left outer join CCARACTERISTICA cca
			on cca.CAR_FL_CVE = kpf.CAR_FL_CVE
			group by kpf.FAC_FL_CVE)c
on kpf.FAC_FL_CVE = c.FAC_FL_CVE
where kpf.cto_fl_Cve = @CveContrato and CPC_NO_CATALOGO = 7

/* inserta valores del activo */

INSERT INTO #Claves VALUES (convert(varchar(100),'[%AutMonto%]'), convert(varchar(18), isnull(@AutMonto, 0.00)));
INSERT INTO #Claves VALUES ('[%AutProducto%]', isnull (@AutProducto, ''));
INSERT INTO #Claves VALUES ('[%AutDSProducto%]', isnull (@AutDSProducto, ''));
INSERT INTO #Claves VALUES ('[%AutNS%]', isnull (@AutNS, ''));
INSERT INTO #Claves VALUES ('[%AutMotor%]', isnull (@AutMotor, ''));
INSERT INTO #Claves VALUES ('[%AutPlacas%]', isnull (@AutPlacas, ''));
INSERT INTO #Claves VALUES ('[%AutAdicional%]', isnull (@AutAdicional, ''));
INSERT INTO #Claves VALUES ('[%AutModelo%]', isnull (@AutModelo, ''));
INSERT INTO #Claves VALUES ('[%AutMarca%]', isnull (@AutMarca, ''));

INSERT INTO #Claves VALUES ('[%AutColor%]', isnull (@AutColor, ''));
INSERT INTO #Claves VALUES ('[%AutAgencia%]', isnull (@AutAgencia, ''));


EXEC lsntReplace @AutTblCompleta, @AutTblCompleta output

INSERT INTO #Claves VALUES ('[%AutTblCompleta%]', @AutTblCompleta);

/* termina inserta valores del activo */

set @gtaTabla = '';
set @gtaTablaAnidado = '';

select @gtaValor = GTA_NO_VALOR, 
	@gtaDescripcion = GTA_DS_DESCRIPCION, 
	@gtaTipo = GRT_DS_TGARANTIA + ' - ' +  STG_DS_STGARANTIA,

	@gtaTablaAnidado  = @gtaTablaAnidado +  '\qc\itap2{\*\nesttableprops\trowd \trgaph108\trrh280' +
							'\trbrdrt\brdrs\brdrw10\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trbrdrr\brdrs\brdrw10' +
							'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx4500' +
							'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx8500' +
							'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx10500' +											
							'\pard \itap2' +
							'\intbl\itap2 Descripción \par\tab ' + isnull(GTA_DS_DESCRIPCION, ' ') + ' \nestcell\itap2 Tipo \par\tab ' + isnull(GRT_DS_TGARANTIA, ' ') + ' - ' +  isnull(STG_DS_STGARANTIA, ' ') + ' \nestcell\itap2 Valor Aproximado \par\tab $' + case when isnumeric(isnull(GTA_NO_VALOR, ' '))=1 then dbo.FormatNumber ( convert(numeric(13,2),isnull(GTA_NO_VALOR, '0')) ,2,',','.') else '0' end + ' \nestcell\itap2\nestrow\pard} \trowd'

	,
	@gtaTabla = @gtaTabla +  '{\trowd\trgaph108\trrh280\trleft2000' +
							'\trbrdrt\brdrs\brdrw10\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trbrdrr\brdrs\brdrw10' +
							'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx5000' +
							'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx9000' +
							'\clbrdrt\brdrw15\brdrs\clbrdrl\brdrw15\brdrs\clbrdrb\brdrw15\brdrs\clbrdrr\brdrw15\brdrs\cellx11000' +											
							'\pard' +
							'\intbl Descripción \par\tab ' + isnull(GTA_DS_DESCRIPCION, ' ') + ' \cell Tipo \par\tab ' + isnull(GRT_DS_TGARANTIA, ' ') + ' - ' +  isnull(STG_DS_STGARANTIA, ' ') + ' \cell Valor Aproximado \par\tab $' + case when isnumeric(isnull(GTA_NO_VALOR, ' '))=1 then dbo.FormatNumber ( convert(numeric(13,2),isnull(GTA_NO_VALOR, '0')) ,2,',','.') else '0' end + ' \cell\row\pard}'
from kcontrato kc
left outer join KGARANTIA kg
on kc.CTO_FL_CVE = kg.CTO_FL_CVE
left outer join CTGARANTIA ctg
on kg.GRT_FL_CVE = ctg.GRT_FL_CVE
left outer join CSTGARANTIA cstg
on cstg.STG_FL_CVE = kg.STG_FL_CVE
where kc.CTO_FL_CVE = @CveContrato
and GTA_FG_STATUS = 1

EXEC lsntReplace @gtaTabla, @gtaTabla output
EXEC lsntReplace @gtaTablaAnidado, @gtaTablaAnidado output

/* Inserta Valores Garantias */

INSERT INTO #Claves VALUES ('[%gtaValor%]', convert(varchar(18), isnull(@gtaValor, 0.00)))
INSERT INTO #Claves VALUES ('[%gtaDescripcion%]', isnull(@gtaDescripcion, ''))
INSERT INTO #Claves VALUES ('[%gtaTipo%]', isnull(@gtaTipo, ''))
INSERT INTO #Claves VALUES ('[%gtaTabla%]', isnull(@gtaTabla, ''))
INSERT INTO #Claves VALUES ('[%gtaTablaAnidado%]', isnull(@gtaTablaAnidado, ''))

/* Termina Inserta Valores Garantias */


--Descripción de la Moneda
INSERT INTO #Claves SELECT '[%Moneda%]', PAR_DS_DESCRIPCION FROM CPARAMETRO WHERE PAR_FL_CVE = 4 AND PAR_CL_VALOR = @CveMoneda
--DatosEmpresa
DECLARE @NombreEmpresa    varchar(110)
------------------------------------------------------------------------------------
DECLARE @NomEmpCompleto char(150)
DECLARE @MaestroApertura    char(50)
------------------------------------------------------------------------------------
DECLARE @RFCEmpresa       char(18)
DECLARE @CPEmpresa        char(8)
DECLARE @EFedEmpresa      char(50)
DECLARE @CiudadEmpresa    char(50)
DECLARE @MunicipioEmpresa char(50)
DECLARE @ColoniaEmpresa   char(50)
DECLARE @CalleEmpresa     char(50)
DECLARE @RepEmpresa		  char(2000)
DECLARE @Opcional1		  char(50)
DECLARE @DirecCliente varchar(1000)
DECLARE @DirecCoacreditado VARCHAR(1000)
DECLARE @NombresApoderados varchar(1000)
-- DOMICILIOS
SELECT TOP 1 @DirecCliente = CASE DMO_DS_CALLE_NUM WHEN '' THEN '' ELSE ('CALLE ' + RTRIM(DMO_DS_CALLE_NUM)) END
						+ CASE DMO_DS_NUMEXT WHEN '' THEN '' ELSE (' NO. EXT. ' + RTRIM(DMO_DS_NUMEXT)) END
						+ CASE DMO_DS_NUMINT WHEN '' THEN ',' ELSE (' NO. INT. ' + RTRIM(DMO_DS_NUMINT) + ',') END
						+ CASE DMO_DS_COLONIA WHEN '' THEN '' ELSE (' COLONIA ' + RTRIM(DMO_DS_COLONIA) + ',') END						
						+ CASE DMO_DS_MUNICIPIO WHEN '' THEN ',' ELSE (' ' + RTRIM(DMO_DS_MUNICIPIO) + ',') END
						+ CASE DMO_DS_EFEDERATIVA WHEN '' THEN ',' ELSE (' ' + RTRIM(DMO_DS_EFEDERATIVA) + ',') END
						+ CASE DMO_CL_CPOSTAL WHEN '' THEN ',' ELSE (' CODIGO POSTAL ' + RTRIM(DMO_CL_CPOSTAL)) END
FROM         CDOMICILIO
WHERE     (DMO_FG_FACTURA = 1) AND (PNA_FL_PERSONA = @CveCliente) ORDER BY DMO_FG_TDIRECCION ASC

/*AND RTRIM(DMO_DS_MUNICIPIO) = RTRIM(DMO_DS_CIUDAD)

SELECT  @DirecCliente = RTRIM(DMO_DS_CALLE_NUM) + ' ' + RTRIM(DMO_DS_NUMEXT) + ' ' + RTRIM(DMO_DS_NUMINT) + ',' +
                        RTRIM(DMO_DS_COLONIA)  + ' C.P.' + RTRIM(DMO_CL_CPOSTAL) + ',' +
                        RTRIM(DMO_DS_MUNICIPIO)+ ',' + RTRIM(DMO_DS_CIUDAD) + ',' +
                        RTRIM(DMO_DS_EFEDERATIVA)
FROM         CDOMICILIO
WHERE     (DMO_FG_REGDEFAULT = 1) AND (PNA_FL_PERSONA = @CveCliente)
AND RTRIM(DMO_DS_MUNICIPIO) <> RTRIM(DMO_DS_CIUDAD)*/

EXEC lsntReplace @DirecCliente, @DirecCliente output   --> CAMBIO CARACTERES ESPECIALES

--Obtenemos la comision por servicios financieros y de administración

SELECT @comServFinan = CCI_NO_PORCENTAJE
FROM KCTO_CARGOINICIAL
WHERE CIN_FL_CVE=1
AND 
CTO_FL_CVE=@CveContrato

SELECT @comServFinan= ISNULL(@comServFinan, 0)

SELECT	@comServAdmin = CCI_NO_PORCENTAJE
FROM KCTO_CARGOINICIAL
WHERE CIN_FL_CVE=2
AND CTO_FL_CVE=@CveContrato

SELECT @comServAdmin= ISNULL(@comServAdmin, 0)

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%ComServFinan%]', convert(varchar(8),@comServFinan))
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%ComServAdmin%]', convert(varchar(8),@comServAdmin))



--Tracker ggv: Obtenemos el apoderado

SELECT @Apoderado=ISNULL(CEMPRESA_REPRESENTANTE.ERE_DS_NOMBRE + ' ' + CEMPRESA_REPRESENTANTE.ERE_DS_PATERNO,'') + ' ' + CEMPRESA_REPRESENTANTE.ERE_DS_MATERNO ,
		@DeclaracionApoderado = ISNULL(CEMPRESA_REPRESENTANTE.ERE_DS_NOMBRE + ' ' + CEMPRESA_REPRESENTANTE.ERE_DS_PATERNO + ' ' + CEMPRESA_REPRESENTANTE.ERE_DS_MATERNO  +
		' posee plena capacidad legal y poderes para celebrar el presente contrato en su representación, obligándola en los términos del mismo, acreditando su personalidad con la escritura pública número ' +
		CONVERT(VARCHAR(9), CREPRESENTANTE_ESCRITURA.RPE_NO_NUMERO) + ', de fecha ' +
		CONVERT(VARCHAR(2), DAY(CREPRESENTANTE_ESCRITURA.RPE_FE_FECHA))+ ' de ' +
							CASE MONTH(CREPRESENTANTE_ESCRITURA.RPE_FE_FECHA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(CREPRESENTANTE_ESCRITURA.RPE_FE_FECHA)) +
		', otorgada ante la fe del notario público ' +
		CREPRESENTANTE_ESCRITURA.RPE_DS_NOMBRE_NOTARIO + ' número ' +
		CONVERT(VARCHAR(6), CREPRESENTANTE_ESCRITURA.RPE_NO_NUMERO_NOTARIO) + ' de ' +
		CREPRESENTANTE_ESCRITURA.RPR_DS_CIUDAD +
		', e inscrita en el Registro Público de la Propiedad y del Comercio de ' +
		CREPRESENTANTE_ESCRITURA.RPE_DS_REG_PUB +
		', bajo el folio mercantil número ' +
		CREPRESENTANTE_ESCRITURA.RPE_DS_FOLIO_MERCANTIL +
		', de fecha  ' +
		CONVERT(VARCHAR(2), DAY(CREPRESENTANTE_ESCRITURA.RPE_FE_INSCRIPCION))+ ' de ' +
							CASE MONTH(CREPRESENTANTE_ESCRITURA.RPE_FE_INSCRIPCION)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(CREPRESENTANTE_ESCRITURA.RPE_FE_INSCRIPCION)) +
		', poder que no le ha sido revocado ni limitado en forma alguna.',' ')
FROM CEMPRESA_REPRESENTANTE, KCONTRATO, KCTO_ASIG_LEGAL_EMP, CREPRESENTANTE_ESCRITURA
WHERE KCONTRATO.CTO_FL_CVE=KCTO_ASIG_LEGAL_EMP.CTO_FL_CVE
AND CEMPRESA_REPRESENTANTE.ERE_FL_CVE=KCTO_ASIG_LEGAL_EMP.ERE_FL_CVE
AND CREPRESENTANTE_ESCRITURA.ERE_FL_CVE=CEMPRESA_REPRESENTANTE.ERE_FL_CVE
AND KCONTRATO.CTO_FL_CVE=@CveContrato

EXEC lsntReplace @Apoderado, @Apoderado output   --> CAMBIO CARACTERES ESPECIALES

Insert into #Claves values( '[%Apoderado%]', @Apoderado )

EXEC lsntReplace @DeclaracionApoderado, @DeclaracionApoderado output   --> CAMBIO CARACTERES ESPECIALES

Insert into #Claves values( '[%DeclaracionApoderado%]',@DeclaracionApoderado)







-----------------------------------------------------------------------------------
print '--          P  R   O  E  M  I  O    --'
-----------------------------------------------------------------------------------


SET @Representantes = ''
--  REPRESENTANTES CLIENTE  --
DECLARE @NombreCliente varchar(200)

Declare @ClavePFisica INT
set @ClavePFisica = 0

Select @ClavePFisica = PNA_CL_PJURIDICA 
FROM CPERSONA 
WHERE PNA_FL_PERSONA = @CveCliente

IF @ClavePFisica = 20
	begin
		SELECT @NombreCliente = RTRIM(PNA_DS_NOMBRE), 
			@sexoCliente = 'N/A',
			@edoCivilCliente = 'N/A',
			@curpCliente = 'N/A',
			@empCliente = isnull(rtrim(c.GRI_FL_CVE), '')
		FROM CPERSONA	
		left outer join CGRUPORIESGO c
		on CPERSONA.GRI_FL_CVE = c.GRI_FL_CVE
		WHERE (PNA_FL_PERSONA = @CveCliente)
	end
else
	begin
		SELECT @NombreCliente = RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )+' '+ RTRIM(PFI_DS_NOMBRE ), 
			@sexoCliente = isnull(RTRIM(cp1.PAR_DS_DESCRIPCION), ''), 
			@edoCivilCliente = isnull(RTRIM(cp2.PAR_DS_DESCRIPCION), ''),
			@curpCliente = isnull(rtrim(PFI_CL_CURP), ''),
			@empCliente = isnull(rtrim(c.GRI_FL_CVE), '')
		FROM CPERSONA 
		inner join CPFISICA 
		ON CPFISICA.PNA_FL_PERSONA =CPERSONA.PNA_FL_PERSONA 	
		left outer join CGRUPORIESGO c
		on CPERSONA.GRI_FL_CVE = c.GRI_FL_CVE
		left outer join cparametro cp1
		on cp1.PAR_FL_CVE = 17
		and PFI_FG_SEXO = cp1.PAR_CL_VALOR
		left outer join CPARAMETRO cp2
		on cp2.PAR_FL_CVE = 11
		and PFI_FG_EDO_CIVIL = cp2.PAR_CL_VALOR
		WHERE CPERSONA.PNA_FL_PERSONA = @CveCliente;
	end


EXEC lsntReplace @NombreCliente, @NombreCliente output   --> CAMBIO CARACTERES ESPECIALES

INSERT INTO #Claves VALUES ('[%NombreCliente%]',@NombreCliente)
INSERT INTO #Claves VALUES ('[%sexoCliente%]',@sexoCliente)
INSERT INTO #Claves VALUES ('[%edoCivilCliente%]',@edoCivilCliente)
INSERT INTO #Claves VALUES ('[%curpCliente%]',@curpCliente)
INSERT INTO #Claves VALUES ('[%empCliente%]',@empCliente)


--Iremos tambien haciendo la tabla de las firmas de los apoderados y obligados solidarios del cliente
				Declare @contenidoCeldas varchar(8000),
						@definicionCeldas  varchar(8000)


IF @CvePJuridica = 'PF'
	BEGIN
			----------------------------------------------------------
				print '-- DICTAMEN LEGAL DE PERSONA FÍSICA  -- '
			----------------------------------------------------------

			SELECT @Declaraciones= '2.1) ' + CPFISICA.PFI_DS_NOMBRE + ' ' + CPFISICA.PFI_DS_APATERNO + ' ' + CPFISICA.PFI_DS_AMATERNO + ' \par \par ' + '{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16' + ' Es una persona física, de nacionalidad ' + ISNULL(NACIONALIDAD.PAR_DS_DESCRIPCION,'') + '(a)' +
				', con plena capacidad para celebrar el presente contrato, con fecha de nacimiento ' +
				 CONVERT(VARCHAR(2), DAY(CPFISICA.PFI_FE_NACIMIENTO))+ ' de ' +
							CASE MONTH(CPFISICA.PFI_FE_NACIMIENTO)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo' 
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(CPFISICA.PFI_FE_NACIMIENTO)) +
				', originario de ' + PFI_DS_LNACIMIENTO + ', cuya ocupación es ' + OCUPACION.PAR_DS_DESCRIPCION + ', estado civil ' + ECIVIL.PAR_DS_DESCRIPCION +
				CASE  WHEN
					(ECIVIL.PAR_CL_VALOR=2)
				THEN
				' bajo el régimen ' + (SELECT PAR_DS_DESCRIPCION FROM CPARAMETRO WHERE PAR_FL_CVE=16 AND PAR_CL_VALOR=CPFISICA.PFI_FG_REGMAT)
				ELSE
					''
				END +
				' con Registro Federal de Causantes ' + RTRIM(LTRIM(CPERSONA.PNA_CL_RFC)) + ' y domicilio en ' +
-- DOMICILIOS
				  CASE CDOMICILIO.DMO_DS_CALLE_NUM WHEN '' THEN '' ELSE ('CALLE ' + RTRIM(CDOMICILIO.DMO_DS_CALLE_NUM)) END
				+ CASE CDOMICILIO.DMO_DS_NUMEXT WHEN '' THEN '' ELSE (' NO. EXT. ' + RTRIM(CDOMICILIO.DMO_DS_NUMEXT)) END
				+ CASE CDOMICILIO.DMO_DS_NUMINT WHEN '' THEN ',' ELSE (' NO. INT. ' + RTRIM(CDOMICILIO.DMO_DS_NUMINT)+ ',') END
				+ CASE CDOMICILIO.DMO_DS_COLONIA WHEN '' THEN '' ELSE (' COLONIA ' + RTRIM(CDOMICILIO.DMO_DS_COLONIA) + ',') END
				+ CASE CDOMICILIO.DMO_DS_MUNICIPIO WHEN '' THEN '' ELSE (' ' + RTRIM(CDOMICILIO.DMO_DS_MUNICIPIO) + ',') END
				+ CASE CDOMICILIO.DMO_DS_EFEDERATIVA WHEN '' THEN '' ELSE (' ' + RTRIM(CDOMICILIO.DMO_DS_EFEDERATIVA) + ',') END 
				+ CASE CDOMICILIO.DMO_CL_CPOSTAL WHEN '' THEN '' ELSE (' C\''d3DIGO POSTAL ' + RTRIM(CDOMICILIO.DMO_CL_CPOSTAL) + '.') END + '\par '
				FROM CPFISICA, CPARAMETRO ECIVIL, CPARAMETRO NACIONALIDAD, CPARAMETRO OCUPACION, CPERSONA, CDOMICILIO
				WHERE
				PFI_FG_EDO_CIVIL= ECIVIL.PAR_CL_VALOR
				AND ECIVIL.PAR_FL_CVE=11
				AND
				PFI_FG_NACIONALIDAD=NACIONALIDAD.PAR_CL_VALOR
				AND
				NACIONALIDAD.PAR_FL_CVE=26
				AND
				PFI_FG_OCUPACION=OCUPACION.PAR_CL_VALOR
				AND
				OCUPACION.PAR_FL_CVE=15
				AND
				CPFISICA.PNA_FL_PERSONA=CPERSONA.PNA_FL_PERSONA
				AND
				CPERSONA.PNA_CL_PJURIDICA=2
				AND
				CPFISICA.PNA_FL_PERSONA=CDOMICILIO.PNA_FL_PERSONA
				AND
				CDOMICILIO.DMO_FG_FACTURA = 1
				AND CPERSONA.PNA_FL_PERSONA=@CveCliente
			
--SET @Declaraciones= ' \par {\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16 hola \par '

			INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%Apoderados%]', '')
			INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tablaApoderados%]', '')
			INSERT INTO #Claves VALUES ('[%NombreClienteMoral%]','')

			--PONEMOS LA FIRMA DE LA PERSONA FÍSICA

			INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tablaFirmaPersonaFisica%]', ' __________________________________________ \par \b ' + @NombreCliente + ' \par \b0 ') 
													
	END; -- Fin de ver si es persona fisica

IF @CvePJuridica = 'PM'         --  PERSONAS MORALES

	BEGIN
				----------------------------------------------------------
				print '-- OBTENGO SU DICTAMEN LEGAL 2 -- '
				----------------------------------------------------------
				INSERT INTO #Claves VALUES ('[%NombreClienteMoral%]',' \b ' + RTRIM(@NombreCliente) + ' \b0 ')

				SELECT @Declaraciones='2.1) ' + @NombreCliente + ' \par \par ' +
				'{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16Es una sociedad mercantil constituida de conformidad con las leyes mexicanas, según consta en la Escritura Pública número ' + 
					rtrim(cast(KESCRITURA.ESC_NO_ESCRITURA as varchar(12))) + ', de fecha '+ 
						CONVERT(VARCHAR(2), DAY(KESCRITURA.ESC_FE_ESCRITURA))+ ' de ' +
							CASE MONTH(KESCRITURA.ESC_FE_ESCRITURA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(KESCRITURA.ESC_FE_ESCRITURA))+
					', otorgada ante la fe del Notario Público número ' + RTRIM(CAST(CNOTARIO.NOT_NO_NOTARIO AS varchar(10))) + ', de ' +
					CCIUDAD.CIU_NB_CIUDAD + ' ' + CEFEDERATIVA.EFD_DS_ENTIDAD + ', Licenciado ' + LTRIM(RTRIM(CNOTARIO.NOT_DS_NOMBRE)) 
					+ CASE WHEN LTRIM(RTRIM(CNOTARIO.NOT_DS_APATERNO)) = '' THEN '' ELSE ' ' + LTRIM(RTRIM(CNOTARIO.NOT_DS_APATERNO)) END
					+ CASE WHEN LTRIM(RTRIM(CNOTARIO.NOT_DS_AMATERNO)) = '' THEN '' ELSE ' ' + LTRIM(RTRIM(CNOTARIO.NOT_DS_AMATERNO)) END					
					+', cuyo primer testimonio quedó inscrito en el Registro Público de la Propiedad y del Comercio de ',-- + 
					@ESC_DS_CIUDAD = KESCRITURA.ESC_DS_CIUDAD,
--+ 
@Declaraciones1 = ', bajo el Número ' + RTRIM(LTRIM(KESCRITURA.ESC_DS_REGISTRO)) 
					+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO)) = '')) THEN ''  ELSE (' folio ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO))) END
					+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) = '')) THEN ''  ELSE (' a fojas ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS))) END
					+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) = '')) THEN ''  ELSE (', del Libro numero ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO))) END 
					+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) = '')) THEN ''  ELSE (', de la Secci\''f3n ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION))) END 
					+ ', el ' +  
					CONVERT(VARCHAR(2), DAY(KESCRITURA.ESC_FE_INSCRITA))+ ' de ' +
							CASE MONTH(KESCRITURA.ESC_FE_INSCRITA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(KESCRITURA.ESC_FE_INSCRITA)) + '.' +
				'\par Que su domicilio es en ' + @DirecCliente + ' y su RFC ' + (SELECT CPERSONA.PNA_CL_RFC FROM CPERSONA WHERE PNA_FL_PERSONA = @CveCliente) + '.'
				FROM    KESCRITURA,	CEFEDERATIVA, CCIUDAD, CNOTARIO
							WHERE KESCRITURA.NOT_FL_CVE = CNOTARIO.NOT_FL_CVE
							AND CNOTARIO.EFD_CL_CVE = CEFEDERATIVA.EFD_CL_CVE
							AND	CNOTARIO.EFD_CL_CVE = CCIUDAD.EFD_CL_CVE
							AND CNOTARIO.CIU_CL_CIUDAD = CCIUDAD.CIU_CL_CIUDAD
							AND	CEFEDERATIVA.EFD_CL_CVE = CCIUDAD.EFD_CL_CVE
							AND KESCRITURA.PNA_FL_PERSONA    = @CveCliente
							AND KESCRITURA.ESC_CL_TESCRITURA IN(1,5)-- ESCRITURAS (1)-CONSTITUTIVAS    (5)MIXTAS		
							--CORRECCION DE ESCRITURAS ASIGNADAS
							AND KESCRITURA.ESC_FL_CVE IN (SELECT ESC_FL_CVE FROM KCTO_ASIG_LEGAL_ESCRITURA WHERE CTO_FL_CVE = @CveContrato)
							--FIN CORRECCION DE ESCRITURAS ASIGNADAS
				
EXEC lsntReplace @ESC_DS_CIUDAD, @ESC_DS_CIUDAD output 

SET @Declaraciones = @Declaraciones + @ESC_DS_CIUDAD + @Declaraciones1

				SET @Declaraciones = ' \par ' + @Declaraciones


				--VAMOS POR LOS APODERADOS
				SET @indiceApoderados=99
				SET @textoApoderadosAcumulado = ''

				

				SET @contenidoCeldas=''
				SET @definicionCeldas=''
				SET @Contador=1
				DECLARE @ClaveApoderado INT

				DECLARE curDatosApoderado CURSOR FOR
				SELECT PNA_DS_NOMBRE,PNA_FL_PERSONA 
				FROM CPERSONA  
				WHERE PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
										FROM cprelacion 	
										WHERE PRE_FL_PERSONA = @CveCliente 
										AND PRE_FG_VALOR = 4 
										AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
																FROM KCTO_ASIG_LEGAL_CLIENTE 
																WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 4))										

			OPEN curDatosApoderado
				FETCH NEXT FROM curDatosApoderado INTO @apoderadoCliente, @ClaveApoderado
				WHILE (@@FETCH_STATUS = 0)
				BEGIN

				--SET @textoApoderadoIndividual =	(SELECT TOP 1 RTRIM(LTRIM((SELECT PNA_DS_NOMBRE FROM CPERSONA  WHERE PNA_FL_PERSONA = @ClaveApoderado))) + 
				SELECT TOP 1 @textoApoderadoIndividual = RTRIM(LTRIM((SELECT PNA_DS_NOMBRE FROM CPERSONA  WHERE PNA_FL_PERSONA = @ClaveApoderado))) + 
						' posee plena capacidad legal y poderes para celebrar el presente contrato en su representación, ' +
						'obligándola en los términos del mismo, acreditando su personalidad con la escritura pública número ' 	
					+ rtrim(cast(KE.ESC_NO_ESCRITURA as varchar(12))) + ', ' +
						'de fecha ' + CONVERT(VARCHAR(2), DAY(KE.ESC_FE_ESCRITURA))+ ' de ' +
							CASE MONTH(KE.ESC_FE_ESCRITURA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(KE.ESC_FE_ESCRITURA))+ ', otorgada ante la fe del notario público número ' + RTRIM(CAST(CN.NOT_NO_NOTARIO AS varchar(10))) + 
						' de ' + CC.CIU_NB_CIUDAD + ', ' + CE.EFD_DS_ENTIDAD + ', e inscrita en el Registro Público de la Propiedad y del Comercio de ' 

,@ESC_DS_CIUDAD = KE.ESC_DS_CIUDAD, @textoApoderadoIndividual1 = ', '
--+ KE.ESC_DS_CIUDAD +  ', '
					+	'bajo el folio mercantil número ' 
					+ RTRIM(LTRIM(KE.ESC_DS_REGISTRO)) 
					+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_FOLIO)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_FOLIO)) = '')) THEN ''  ELSE (' folio ' + LTRIM(RTRIM(KE.ESC_DS_FOLIO))) END
					+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_FOJAS)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_FOJAS)) = '')) THEN ''  ELSE (' a fojas ' + LTRIM(RTRIM(KE.ESC_DS_FOJAS))) END
					+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_LIBRO)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_LIBRO)) = '')) THEN ''  ELSE (', del Libro n\''famero ' + LTRIM(RTRIM(KE.ESC_DS_LIBRO))) END 
					+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '')) THEN ''  ELSE (', de la Secci\''f3n ' + LTRIM(RTRIM(KE.ESC_DS_SECCION))) END 

						--+ LTRIM(RTRIM(KE.ESC_DS_REGISTRO)) 
						--+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '')) THEN ''  ELSE (', Secci\''f3n ' + LTRIM(RTRIM(KE.ESC_DS_SECCION))) END 
						+ ' el ' + CONVERT(VARCHAR(2), DAY(KE.ESC_FE_INSCRITA))+ ' de ' +
							CASE MONTH(KE.ESC_FE_INSCRITA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(KE.ESC_FE_INSCRITA)) + ', poder que no le ha sido revocado ni limitado en forma alguna.'
				FROM CPERSONA CP 
				INNER JOIN KESCRITURA KE ON KE.PNA_FL_PERSONA = CP.PNA_FL_PERSONA
				INNER JOIN CNOTARIO CN ON CN.NOT_FL_CVE = KE.NOT_FL_CVE
				INNER JOIN CEFEDERATIVA CE ON CE.EFD_CL_CVE = CN.EFD_CL_CVE
				INNER JOIN CCIUDAD  CC ON CC.CIU_CL_CIUDAD = CN.CIU_CL_CIUDAD AND CC.EFD_CL_CVE = CN.EFD_CL_CVE
				WHERE CP.PNA_FL_PERSONA = @CveCliente 
				AND KE.ESC_CL_TESCRITURA IN(4,5) -- ESCRITURAS (4)-PODERES    (5)MIXTAS
				--CORRECCION DE ESCRITURAS ASIGNADAS
				AND KE.ESC_FL_CVE IN (SELECT ESC_FL_CVE FROM KCTO_ASIG_LEGAL_ESCRITURA WHERE CTO_FL_CVE = @CveContrato)
				--FIN CORRECCION DE ESCRITURAS ASIGNADAS
				ORDER BY KE.ESC_CL_TESCRITURA ASC--)

EXEC lsntReplace @ESC_DS_CIUDAD, @ESC_DS_CIUDAD output 
SET @textoApoderadoIndividual = @textoApoderadoIndividual + @ESC_DS_CIUDAD + @textoApoderadoIndividual1

EXEC lsntReplace @textoApoderadoIndividual, @textoApoderadoIndividual output 
					--** INICIO VIÑETAS MARREDONDO **--
					if (@CveMoneda = 1 AND @CveTOperacion = 'NE') or (@CveMoneda = 2 AND @CveTOperacion = 'AP')
					begin
					SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + '\par ' + @textoApoderadoIndividual + ' \par'  --+ ' \par'-- \par '
					end
					else
					begin
					SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + '\par ' + @textoApoderadoIndividual
					end
					--SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + '\par ' +  CHAR(@indiceApoderados) + ') ' + @textoApoderadoIndividual --+ ' \par'-- \par '
					--** FIN VIÑETAS MARREDONDO **--
					SET @indiceApoderados = @indiceApoderados + 1
					--vamos armando la tabla de los apoderados	
					if @Contador > 1
						SET @contenidoCeldas = @contenidoCeldas + '\par\par "ARRENDATARIA" \par ' + RTRIM(@NombreCliente) + ' \par\par\par\par  __________________________ \par ' + @apoderadoCliente + ' \par '
					else 				
						SET @contenidoCeldas = @contenidoCeldas + '\par  __________________________ \par ' + @apoderadoCliente + ' \par '
					SET @definicionCeldas= @definicionCeldas + '\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth2500\cellx' + convert(varchar(2), @Contador)
					SET @Contador=@Contador+1
					FETCH NEXT FROM curDatosApoderado INTO @apoderadoCliente, @ClaveApoderado					
				END		
				CLOSE curDatosApoderado
				DEALLOCATE curDatosApoderado
			
--SELECT @textoApoderadosAcumulado
				EXEC lsntReplace @textoApoderadosAcumulado, @textoApoderadosAcumulado output   --> CAMBIO CARACTERES ESPECIALES
--** INICIO VIÑETAS MARREDONDO **--
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%Apoderados%]', '')
--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%Apoderados%]', @textoApoderadosAcumulado)
IF @textoApoderadosAcumulado <> ''
BEGIN
SET @Declaraciones = @Declaraciones + @textoApoderadosAcumulado
END
--** FIN VIÑETAS MARREDONDO **--
				EXEC lsntReplace @contenidoCeldas, @contenidoCeldas output   --> CAMBIO CARACTERES ESPECIALES ( viñetas )
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tablaApoderados%]',' \b' + @contenidoCeldas + ' \b0 ')

				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tablaFirmaPersonaFisica%]', '')



END --Fin de ver si es persona moral (PM)

EXEC lsntReplace @Declaraciones, @Declaraciones output   --> CAMBIO CARACTERES ESPECIALES

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%Declaraciones1%]', @Declaraciones)

--VAMOS POR LOS OBLIGADOS SOLIDARIOS (AVALES)
DECLARE @AUXVIN INT
SELECT @AUXVIN =COUNT(*) FROM CPERSONA CP WHERE CP.PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
						FROM cprelacion 
						WHERE PRE_FL_PERSONA = @CveCliente 
						AND PRE_FG_VALOR = 3
						AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
											FROM KCTO_ASIG_LEGAL_CLIENTE 
											WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 3))
SET @indiceApoderados=97
SET @textoApoderadosAcumulado = ''

SET @contenidoCeldas=''
SET @definicionCeldas=''
declare @CONSECUTIVOAux int
set @CONSECUTIVOAux = 1
SET @Contador = 1
DECLARE @vinetas INT
SET @vinetas = 0

declare @auxvinetas int
set @auxvinetas = 1
--CAMBIO ARACELI NARANJO ********************
--IF @CveTOperacion = 'CD' OR @CveTOperacion = 'CR'
	set @auxvinetas = 0
DECLARE @ClaveAval INT, @PJURIDICA1 INT
DECLARE  CURAVAL CURSOR FOR
SELECT CP.PNA_FL_PERSONA,CP.PNA_CL_PJURIDICA
FROM CPERSONA CP
WHERE CP.PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
						FROM cprelacion 
						WHERE PRE_FL_PERSONA = @CveCliente 
						AND PRE_FG_VALOR = 3
						AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
											FROM KCTO_ASIG_LEGAL_CLIENTE 
											WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 3))
ORDER BY  CP.PNA_CL_PJURIDICA,CP.PNA_FL_PERSONA
OPEN CURAVAL
FETCH NEXT FROM CURAVAL INTO @ClaveAval,@PJURIDICA1
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			IF @PJURIDICA1 = 2 OR @PJURIDICA1 = 1
				BEGIN
			--PRIMERO POR LOS AVALES QUE SON PERSONAS FISICAS
	DECLARE curObligadosSolid CURSOR FOR
	SELECT CPFISICA.PFI_DS_NOMBRE + ' ' + CPFISICA.PFI_DS_APATERNO + ' ' + CPFISICA.PFI_DS_AMATERNO, 
			CPFISICA.PFI_DS_NOMBRE + ' ' + CPFISICA.PFI_DS_APATERNO + ' ' + CPFISICA.PFI_DS_AMATERNO + ' es una persona física, de nacionalidad ' + NACIONALIDAD.PAR_DS_DESCRIPCION + '(a)' +
	', con plena capacidad para celebrar el presente contrato, con fecha de nacimiento ' +
	CONVERT(VARCHAR(2), DAY(CPFISICA.PFI_FE_NACIMIENTO))+ ' de ' +
			CASE MONTH(CPFISICA.PFI_FE_NACIMIENTO)
				WHEN  1 THEN 'Enero'
				WHEN  2 THEN 'Febrero'
				WHEN  3 THEN 'Marzo'
				WHEN  4 THEN 'Abril'
				WHEN  5 THEN 'Mayo'
				WHEN  6 THEN 'Junio'
				WHEN  7 THEN 'Julio'
				WHEN  8 THEN 'Agosto'
				WHEN  9 THEN 'Septiembre'
				WHEN 10 THEN 'Octubre'
				WHEN 11 THEN 'Noviembre'
				WHEN 12 THEN 'Diciembre'
			END + ' de ' +
			CONVERT(VARCHAR(4), YEAR(CPFISICA.PFI_FE_NACIMIENTO)) +
		', originario de ' + PFI_DS_LNACIMIENTO + ', cuya ocupación es ' + OCUPACION.PAR_DS_DESCRIPCION + ', estado civil ' 
		+ ECIVIL.PAR_DS_DESCRIPCION + CASE  WHEN (ECIVIL.PAR_CL_VALOR=2) THEN
		' bajo el régimen ' + (SELECT PAR_DS_DESCRIPCION FROM CPARAMETRO WHERE PAR_FL_CVE=16 AND PAR_CL_VALOR=CPFISICA.PFI_FG_REGMAT)
		ELSE
			''
		END +
		' con Registro Federal de Causantes ' + CPERSONA.PNA_CL_RFC +
		CASE (SELECT COUNT(PNA_FL_PERSONA) FROM CDOMICILIO WHERE PNA_FL_PERSONA = (select TOP 1 PRE_FL_PERSONA
		from KCTO_ASIG_LEGAL_CLIENTE where cto_fl_cve = @CveContrato AND ALG_CL_TIPO_RELACION=3 AND PRE_FL_PERSONA = @ClaveAval)  AND	CDOMICILIO.DMO_FG_FACTURA = 1) WHEN 0 THEN '' ELSE 
		' y domicilio en ' +
  CASE CDOMICILIO.DMO_DS_CALLE_NUM WHEN '' THEN '' ELSE ('CALLE ' + RTRIM(CDOMICILIO.DMO_DS_CALLE_NUM)) END
+ CASE CDOMICILIO.DMO_DS_NUMEXT WHEN '' THEN '' ELSE (' NO. EXT. ' + RTRIM(CDOMICILIO.DMO_DS_NUMEXT)) END
+ CASE CDOMICILIO.DMO_DS_NUMINT WHEN '' THEN ',' ELSE (' NO. INT. ' + RTRIM(CDOMICILIO.DMO_DS_NUMINT)+ ',') END
+ CASE CDOMICILIO.DMO_DS_COLONIA WHEN '' THEN '' ELSE (' COLONIA ' + RTRIM(CDOMICILIO.DMO_DS_COLONIA) + ',') END
+ CASE CDOMICILIO.DMO_DS_MUNICIPIO WHEN '' THEN '' ELSE (' ' + RTRIM(CDOMICILIO.DMO_DS_MUNICIPIO) + ',') END
+ CASE CDOMICILIO.DMO_DS_EFEDERATIVA WHEN '' THEN '' ELSE (' ' + RTRIM(CDOMICILIO.DMO_DS_EFEDERATIVA) + ',') END 
+ CASE CDOMICILIO.DMO_CL_CPOSTAL WHEN '' THEN '' ELSE (' C\''d3DIGO POSTAL ' + RTRIM(CDOMICILIO.DMO_CL_CPOSTAL) + '.') END 
+ CASE @vinetas  WHEN 0 THEN ' \par ' ELSE '' END
--+ CASE @vinetas  WHEN 1 THEN ' \par ' ELSE '' END
END
FROM CPERSONA CPERSONA
INNER JOIN CPFISICA CPFISICA ON CPFISICA.PNA_FL_PERSONA=CPERSONA.PNA_FL_PERSONA
INNER JOIN KCTO_ASIG_LEGAL_CLIENTE KCTO_ASIG_LEGAL_CLIENTE ON CPFISICA.PNA_FL_PERSONA=KCTO_ASIG_LEGAL_CLIENTE.PRE_FL_PERSONA
LEFT JOIN CDOMICILIO CDOMICILIO ON CPFISICA.PNA_FL_PERSONA = CDOMICILIO.PNA_FL_PERSONA AND	CDOMICILIO.DMO_FG_FACTURA = 1			
INNER JOIN CPARAMETRO NACIONALIDAD ON PFI_FG_NACIONALIDAD=NACIONALIDAD.PAR_CL_VALOR
INNER JOIN CPARAMETRO ECIVIL ON PFI_FG_EDO_CIVIL= ECIVIL.PAR_CL_VALOR
INNER JOIN CPARAMETRO OCUPACION ON PFI_FG_OCUPACION=OCUPACION.PAR_CL_VALOR
WHERE KCTO_ASIG_LEGAL_CLIENTE.ALG_CL_TIPO_RELACION=3
AND ECIVIL.PAR_FL_CVE=11		
AND	NACIONALIDAD.PAR_FL_CVE=26			
AND	OCUPACION.PAR_FL_CVE=15
AND	CPERSONA.PNA_CL_PJURIDICA IN (1,2)
AND KCTO_ASIG_LEGAL_CLIENTE.CTO_FL_CVE= @CveContrato
AND KCTO_ASIG_LEGAL_CLIENTE.PRE_FL_PERSONA = @ClaveAval
OPEN curObligadosSolid
FETCH NEXT FROM curObligadosSolid INTO  @apoderadoCliente, @textoApoderadoIndividual
WHILE (@@FETCH_STATUS = 0)
BEGIN
--*** INICIO VIÑETAS
PRINT 'VIÑETAS'
PRINT @vinetas

IF @textoApoderadoIndividual <> ''
BEGIN
set @textoApoderadoIndividual = '{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16 ' + @textoApoderadoIndividual
set @vinetas = @vinetas + 1
END
PRINT '************************************************************************************'
PRINT @auxvinetas
PRINT @vinetas
PRINT @AUXVIN
if @auxvinetas = 1 and @vinetas = 2 AND @AUXVIN = 2--@AUXVIN-cUENTA N° AVALES
BEGIN
SET @textoApoderadoIndividual = @textoApoderadoIndividual + ' \par '
END
	if @auxvinetas = 1 and @vinetas > 1 AND @AUXVIN = 1--@AUXVIN-cUENTA N° AVALES
	BEGIN
		SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual + ' \par '
	END
	else
	BEGIN
		IF @vinetas > 2 AND @AUXVIN > 1
			BEGIN
			SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual + ' \par '
			END
		ELSE
			BEGIN
					SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual-- + ' \par '			
			END
	END


--SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + '\par ' + CHAR(@indiceApoderados) + ') ' + @textoApoderadoIndividual + ' \par'-- \par ' 
--*** FIN VIÑETAS
	SET @indiceApoderados = @indiceApoderados + 1
	--vamos armando la tabla de los obligados solidarios
	SET @contenidoCeldas = @contenidoCeldas + ' "OBLIGADO SOLIDARIO" \par \par \par \par __________________________ \par ' + @apoderadoCliente + ' \par\par\par '
	SET @definicionCeldas= @definicionCeldas + '\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth2500\cellx' + convert(varchar(2), @Contador)
	SET @Contador=@Contador+1	
	FETCH NEXT FROM curObligadosSolid INTO @apoderadoCliente, @textoApoderadoIndividual					
--IF (@@FETCH_STATUS <> 0)
--	SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual  + ' \par \par ' 
--ELSE
--	SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual + ' \par '-- \par ' 	

END		
CLOSE curObligadosSolid
DEALLOCATE curObligadosSolid
			END		

PRINT 'AVAL MORAL'
--SET @contenidoCeldas=''
--AHORA LOS AVALES QUE SON PERSONAS MORALES
IF @PJURIDICA1 = 20
				BEGIN
DECLARE curObligadosSolid CURSOR FOR
SELECT RTRIM(LTRIM(CPERSONA.PNA_DS_NOMBRE)), ' \pard\li320\qj\par 3.' + CONVERT(VARCHAR(3),@CONSECUTIVOAux) + ') ' + RTRIM(LTRIM(CPERSONA.PNA_DS_NOMBRE)) + ' \par \par ' +
						--** VIÑETAS MARREDONDO
							'{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16Es una sociedad mercantil constituida de conformidad con las leyes mexicanas, según consta en la Escritura Pública número ' + 
							rtrim(cast(KESCRITURA.ESC_NO_ESCRITURA as varchar(12))) + ', de fecha '+ 
							CONVERT(VARCHAR(2), DAY(KESCRITURA.ESC_FE_ESCRITURA))+ ' de ' +
										CASE MONTH(KESCRITURA.ESC_FE_ESCRITURA)
											WHEN  1 THEN 'Enero'
											WHEN  2 THEN 'Febrero'
											WHEN  3 THEN 'Marzo'
											WHEN  4 THEN 'Abril'
											WHEN  5 THEN 'Mayo'
											WHEN  6 THEN 'Junio'
											WHEN  7 THEN 'Julio'
											WHEN  8 THEN 'Agosto'
											WHEN  9 THEN 'Septiembre'
											WHEN 10 THEN 'Octubre'
											WHEN 11 THEN 'Noviembre'
											WHEN 12 THEN 'Diciembre'
										END + ' de ' +
										CONVERT(VARCHAR(4), YEAR(KESCRITURA.ESC_FE_ESCRITURA)) +
							', otorgada ante la fe del Notario Público número ' + RTRIM(CAST(CNOTARIO.NOT_NO_NOTARIO AS varchar(10))) + ', de ' +
							CCIUDAD.CIU_NB_CIUDAD + ' ' + CEFEDERATIVA.EFD_DS_ENTIDAD + ', Licenciado ' + CNOTARIO.NOT_DS_NOMBRE + ' ' + CNOTARIO.NOT_DS_APATERNO + ' ' + CNOTARIO.NOT_DS_AMATERNO +
							', cuyo primer testimonio quedó inscrito en el Registro Público de la Propiedad y del Comercio de ' 
--+ KESCRITURA.ESC_DS_CIUDAD +
,KESCRITURA.ESC_DS_CIUDAD,
 ', bajo el Número ' + RTRIM(LTRIM(KESCRITURA.ESC_DS_REGISTRO)) 
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO)) = '')) THEN ''  ELSE (' folio ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO))) END
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) = '')) THEN ''  ELSE ' a fojas ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) END
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) = '')) THEN ''  ELSE ', del Libro numero ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) END 
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) = '')) THEN ''  ELSE ', de la Seccion ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) END 
							+ ', el ' + CONVERT(VARCHAR(2), DAY(KESCRITURA.ESC_FE_INSCRITA))+ ' de ' +
								CASE MONTH(KESCRITURA.ESC_FE_INSCRITA)
													WHEN  1 THEN 'Enero'
													WHEN  2 THEN 'Febrero'
													WHEN  3 THEN 'Marzo'
													WHEN  4 THEN 'Abril'
													WHEN  5 THEN 'Mayo'
													WHEN  6 THEN 'Junio'
													WHEN  7 THEN 'Julio'
													WHEN  8 THEN 'Agosto'
													WHEN  9 THEN 'Septiembre'
													WHEN 10 THEN 'Octubre'
													WHEN 11 THEN 'Noviembre'
													WHEN 12 THEN 'Diciembre'
												END + ' de ' +
												CONVERT(VARCHAR(4), YEAR(KESCRITURA.ESC_FE_INSCRITA))+ + '.' +
	'\par Que su domicilio es en ' + 
			(SELECT	TOP 1 CASE DMO_DS_CALLE_NUM WHEN '' THEN '' ELSE ('CALLE ' + RTRIM(DMO_DS_CALLE_NUM)) END
						+ CASE DMO_DS_NUMEXT WHEN '' THEN '' ELSE (' NO. EXT. ' + RTRIM(DMO_DS_NUMEXT)) END
						+ CASE DMO_DS_NUMINT WHEN '' THEN ',' ELSE (' NO. INT. ' + RTRIM(DMO_DS_NUMINT) + ',') END
						+ CASE DMO_DS_COLONIA WHEN '' THEN '' ELSE (' COLONIA ' + RTRIM(DMO_DS_COLONIA)) END						
						+ CASE DMO_DS_MUNICIPIO WHEN '' THEN ',' ELSE (' ' + RTRIM(DMO_DS_MUNICIPIO) + ',') END
						+ CASE DMO_DS_EFEDERATIVA WHEN '' THEN ',' ELSE (' ' + RTRIM(DMO_DS_EFEDERATIVA)) END
					+ CASE DMO_CL_CPOSTAL WHEN '' THEN ',' ELSE (' C\''d3DIGO POSTAL ' + RTRIM(DMO_CL_CPOSTAL) + ',') END
FROM         CDOMICILIO
WHERE     (DMO_FG_FACTURA = 1) AND (PNA_FL_PERSONA = @ClaveAval) ORDER BY DMO_FG_TDIRECCION ASC)
						 + ' y su RFC ' + (SELECT CPERSONA.PNA_CL_RFC FROM CPERSONA WHERE PNA_FL_PERSONA = @ClaveAval)-- + ' \par '
FROM    KESCRITURA,	CEFEDERATIVA, CCIUDAD, CNOTARIO, CPERSONA, KCTO_ASIG_LEGAL_CLIENTE
			WHERE KESCRITURA.NOT_FL_CVE = CNOTARIO.NOT_FL_CVE
			AND CNOTARIO.EFD_CL_CVE = CEFEDERATIVA.EFD_CL_CVE
			AND	CNOTARIO.EFD_CL_CVE = CCIUDAD.EFD_CL_CVE
			AND CNOTARIO.CIU_CL_CIUDAD = CCIUDAD.CIU_CL_CIUDAD
			AND	CEFEDERATIVA.EFD_CL_CVE = CCIUDAD.EFD_CL_CVE
			AND KESCRITURA.ESC_CL_TESCRITURA IN(1,5)-- ESCRITURAS (1)-CONSTITUTIVAS    (5)MIXTAS
			--CORRECCION DE ESCRITURAS ASIGNADAS
			AND KESCRITURA.ESC_FL_CVE IN (SELECT ESC_FL_CVE FROM KCTO_ASIG_LEGAL_ESCRITURA WHERE CTO_FL_CVE = @CveContrato)
			--FIN CORRECCION DE ESCRITURAS ASIGNADAS
			AND KESCRITURA.PNA_FL_PERSONA=CPERSONA.PNA_FL_PERSONA
			AND CPERSONA.PNA_FL_PERSONA=KCTO_ASIG_LEGAL_CLIENTE.PRE_FL_PERSONA
			AND CPERSONA.PNA_CL_PJURIDICA=20
			AND KCTO_ASIG_LEGAL_CLIENTE.ALG_CL_TIPO_RELACION=3
			AND KCTO_ASIG_LEGAL_CLIENTE.CTO_FL_CVE=@CveContrato
			--AND PRE_FL_PERSONA=@CveCliente
			AND CPERSONA.PNA_FL_PERSONA = @ClaveAval

OPEN curObligadosSolid
FETCH NEXT FROM curObligadosSolid INTO  @apoderadoCliente, @textoApoderadoIndividual,@ESC_DS_CIUDAD,@textoApoderadoIndividual1
WHILE (@@FETCH_STATUS = 0)
BEGIN
--PRINT @CONSECUTIVOAux
EXEC lsntReplace @ESC_DS_CIUDAD, @ESC_DS_CIUDAD output 
SET @textoApoderadoIndividual = @textoApoderadoIndividual + @ESC_DS_CIUDAD + @textoApoderadoIndividual1
/**************************************************************************************************************************/
DECLARE @textApodAcum varchar(8000), @textoApodInd VARCHAR(8000), @textoApodInd1 VARCHAR(8000)			
				SET @textApodAcum = ''								
				SET @Contador=1
				DECLARE @ClaveApoderadoAval INT,@apoderadoAval VARCHAR(100)
				DECLARE curDatosApoderado CURSOR FOR
				SELECT PNA_DS_NOMBRE,PNA_FL_PERSONA 
				FROM CPERSONA  
				WHERE PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
										FROM cprelacion 	
										WHERE PRE_FL_PERSONA = @ClaveAval 
										AND PRE_FG_VALOR = 4 
										AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
																FROM KCTO_ASIG_LEGAL_CLIENTE 
																WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 4))										

			OPEN curDatosApoderado
				FETCH NEXT FROM curDatosApoderado INTO @apoderadoAval, @ClaveApoderadoAval
				WHILE (@@FETCH_STATUS = 0)
				BEGIN
				--SET @textoApodInd =	(SELECT TOP 1 RTRIM(LTRIM((SELECT PNA_DS_NOMBRE FROM CPERSONA  WHERE PNA_FL_PERSONA = @ClaveApoderadoAval))) + 
				SELECT TOP 1 @textoApodInd = RTRIM(LTRIM((SELECT PNA_DS_NOMBRE FROM CPERSONA  WHERE PNA_FL_PERSONA = @ClaveApoderadoAval))) + 
						' posee plena capacidad legal y poderes para celebrar el presente contrato en su representación, ' +
						'obligándola en los términos del mismo, acreditando su personalidad con la escritura pública número ' + rtrim(cast(KE.ESC_NO_ESCRITURA as varchar(12))) + ', ' +
						'de fecha ' + CONVERT(VARCHAR(2), DAY(KE.ESC_FE_ESCRITURA))+ ' de ' +
							CASE MONTH(KE.ESC_FE_ESCRITURA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(KE.ESC_FE_ESCRITURA))+ ', otorgada ante la fe del notario público número ' + RTRIM(CAST(CN.NOT_NO_NOTARIO AS varchar(10))) + 
						' de ' + CC.CIU_NB_CIUDAD + ', ' + CE.EFD_DS_ENTIDAD + ', e inscrita en el Registro Público de la Propiedad y del Comercio de ' 

, @ESC_DS_CIUDAD = KE.ESC_DS_CIUDAD , @textoApodInd1 =
--+ KE.ESC_DS_CIUDAD + 
						', ' +	'bajo el folio mercantil número ' + LTRIM(RTRIM(KE.ESC_DS_REGISTRO)) 
						+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '')) THEN ''  ELSE (', Secci\''f3n ' + LTRIM(RTRIM(KE.ESC_DS_SECCION))) END 
						+ ' el ' + CONVERT(VARCHAR(2), DAY(KE.ESC_FE_INSCRITA))+ ' de ' +
							CASE MONTH(KE.ESC_FE_INSCRITA)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							CONVERT(VARCHAR(4), YEAR(KE.ESC_FE_INSCRITA)) + ', poder que no le ha sido revocado ni limitado en forma alguna.'
				FROM CPERSONA CP 
				INNER JOIN KESCRITURA KE ON KE.PNA_FL_PERSONA = CP.PNA_FL_PERSONA
				INNER JOIN CNOTARIO CN ON CN.NOT_FL_CVE = KE.NOT_FL_CVE
				INNER JOIN CEFEDERATIVA CE ON CE.EFD_CL_CVE = CN.EFD_CL_CVE
				INNER JOIN CCIUDAD  CC ON CC.CIU_CL_CIUDAD = CN.CIU_CL_CIUDAD AND CC.EFD_CL_CVE = CN.EFD_CL_CVE
				WHERE CP.PNA_FL_PERSONA = @ClaveAval 
				AND KE.ESC_CL_TESCRITURA IN(4,5) -- ESCRITURAS (4)-PODERES    (5)MIXTAS
				--CORRECCION DE ESCRITURAS ASIGNADAS
				AND KE.ESC_FL_CVE IN (SELECT ESC_FL_CVE FROM KCTO_ASIG_LEGAL_ESCRITURA WHERE CTO_FL_CVE = @CveContrato)
				--FIN CORRECCION DE ESCRITURAS ASIGNADAS
				ORDER BY KE.ESC_CL_TESCRITURA ASC--)

EXEC lsntReplace @ESC_DS_CIUDAD, @ESC_DS_CIUDAD output 
SET @textoApodInd = @textoApodInd + @ESC_DS_CIUDAD + @textoApodInd1

					--** INICIO VIÑETAS MARREDONDO **--
					if (@CveMoneda = 1 AND @CveTOperacion = 'NE') or (@CveMoneda = 2 AND @CveTOperacion = 'AP')
					begin
					SET @textApodAcum = @textApodAcum + '\par ' + @textoApodInd + ' \par'  --+ ' \par'-- \par '
					end
					else
					begin
					SET @textApodAcum = @textApodAcum + '\par ' + @textoApodInd
					end
					--** FIN VIÑETAS MARREDONDO **--					
					--vamos armando la tabla de los apoderados	
					if @Contador > 1
						SET @contenidoCeldas = @contenidoCeldas + '\par\par\par  __________________________ \par ' + @apoderadoAval + ' \par '
					else 	
					 begin		
						if @CONSECUTIVOAux > 1	
							SET @contenidoCeldas = @contenidoCeldas + ' \par\par "OBLIGADO SOLIDARIO" \par ' + @apoderadoCliente + '\par\par\par\par__________________________ \par ' + @apoderadoAval + ' \par '
						else
							SET @contenidoCeldas = @contenidoCeldas + '"OBLIGADO SOLIDARIO" \par ' + @apoderadoCliente + '\par\par\par\par__________________________ \par ' + @apoderadoAval + ' \par '
					 end
					SET @Contador=@Contador+1
				FETCH NEXT FROM curDatosApoderado INTO @apoderadoAval, @ClaveApoderadoAval					
				END		
				CLOSE curDatosApoderado
				DEALLOCATE curDatosApoderado

/**********************************************************************************************************************************************/
set @textoApoderadoIndividual = @textoApoderadoIndividual + @textApodAcum + ' \par '
set  @CONSECUTIVOAux = @CONSECUTIVOAux + 1
if @PJURIDICA1 <> 20
begin
 --*** INICIO VIÑETAS
 IF @vinetas <> 1
  BEGIN	
		 
		 IF @textoApoderadoIndividual <> ''--1
		 BEGIN
		 set @textoApoderadoIndividual = '{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16 ' + @textoApoderadoIndividual
		 SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual
		end
  END
 ELSE
 BEGIN
 SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual + ' \par \par '
 END
 --SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + '\par ' + CHAR(@indiceApoderados) + ') ' + @textoApoderadoIndividual --+ ' \par \par '
 --*** FIN VIÑETAS	
	 SET @indiceApoderados = @indiceApoderados + 1
	 --vamos armando la tabla de los obligados solidarios
	 --EXEC lsntReplace @apoderadoCliente, @apoderadoCliente output   --> CAMBIO CARACTERES ESPECIALES 
	 SET @contenidoCeldas = @contenidoCeldas + ' "OBLIGADO SOLIDARIO" \par \par \par \par __________________________ \par ' + @apoderadoCliente + ' \par\par\par '
	 SET @definicionCeldas= @definicionCeldas + '\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth2500\cellx' + convert(varchar(2), @Contador)
	 SET @Contador=@Contador+1	
end
else
begin
	SET @textoApoderadosAcumulado = @textoApoderadosAcumulado + @textoApoderadoIndividual
end
	FETCH NEXT FROM curObligadosSolid INTO @apoderadoCliente, @textoApoderadoIndividual,@ESC_DS_CIUDAD,@textoApoderadoIndividual1				
END
CLOSE curObligadosSolid
DEALLOCATE curObligadosSolid
end
		FETCH NEXT FROM CURAVAL INTO @ClaveAval,@PJURIDICA1
	END		
	CLOSE CURAVAL
	DEALLOCATE CURAVAL

EXEC lsntReplace @textoApoderadosAcumulado, @textoApoderadosAcumulado output   --> CAMBIO CARACTERES ESPECIALES
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%ObligadosSolid%]', CASE WHEN @textoApoderadosAcumulado='' THEN 'N.A.' ELSE @textoApoderadosAcumulado END)
SET @textoApoderadosAcumulado = ''
--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%TituloObligados%]', CASE WHEN @textoApoderadosAcumulado='' THEN '' ELSE '"OBLIGADO(S) SOLIDARIO(S)"' END)
--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tablaObligados%]', @contenidoCeldas )
EXEC lsntReplace @contenidoCeldas, @contenidoCeldas output   --> CAMBIO CARACTERES ESPECIALES
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%TituloObligados%]',' \b ' + @contenidoCeldas + ' \b0 ')
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%tablaObligados%]',' \b ' + @textoApoderadosAcumulado + ' \b0 ')


--GENERAMOS LA TABLA DE ACTIVOS
DECLARE @facturaActual int,
		@facturaAnterior int,
		@productoActual int,
		@productoAnterior int,
		@consecutivoActual int,
		@consecutivoAnterior int,
		@desFactura varchar(1000),
		@claveDescrip varchar(100),
		@descrip varchar(100),
		@tablaActivos varchar(8000),
		@unaFila tinyint,
		@nombreProveedorActual varchar(100),
		@nombreProveedorAnterior varchar(100),
		@listaProveedores varchar(3000) 
		

SET @facturaAnterior=0
SET @productoAnterior=0
SET @consecutivoAnterior=0
SET @nombreProveedorAnterior=''
SET @listaProveedores=''
SET @unaFila=0

SET @tablaActivos=''
SET LANGUAGE Spanish
INSERT INTO #Claves VALUES( '[%tablaActivos%]', '' )
--la variable NOFFSET indica la posicion en memoria del apuntador
SET @NOFFSET = 0
SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%tablaActivos%]'
DECLARE @numFactura VARCHAR(500)
DECLARE @CARACTAUX VARCHAR(100)
DECLARE curACTIVOS CURSOR FOR	
SELECT C.FAC_FL_CVE, A.PRD_FL_CVE, C.KPF_NO_CONSECUTIVO,
			CASE FAC_CL_DOCUMETO 
			WHEN 2 THEN ('FACTURA ' + CONVERT(VARCHAR(50), KCTO_FACT.FAC_DS_NUMERO) + ', ')
			ELSE ''
			END
			--+ CTPRODUCTO.TPR_DS_TPRODUCTO + ', '
			,' MARCA ' + CMARCA.MRC_DS_MARCA + ', ' + ' MODELO ' + D.PRD_DS_PRODUCTO,
			B.CAR_DS_DESCRIPCION, A.CFP_DS_CARACT, CPERSONA.PNA_DS_NOMBRE		   
	FROM KCARAC_PROD_FACT A, CCARACTERISTICA B, KPRODUCTO_FACTURA C, CPRODUCTO D, CMARCA, CPERSONA, KCTO_FACT , CTPRODUCTO
	WHERE  
		A.FAC_FL_CVE = C.FAC_FL_CVE 
	   AND A.KPF_NO_CONSECUTIVO = C.KPF_NO_CONSECUTIVO 
	   AND B.CAR_FL_CVE = A.CAR_FL_CVE 
	   AND C.PRD_FL_CVE = A.PRD_FL_CVE 
	   AND A.PRD_FL_CVE = D.PRD_FL_CVE
		AND D.MRC_FL_CVE=CMARCA.MRC_FL_CVE
		AND C.FAC_FL_CVE=KCTO_FACT.FAC_FL_CVE
		AND KCTO_FACT.PNA_FL_PERSONA=CPERSONA.PNA_FL_PERSONA
		AND C.CTO_FL_CVE=@CveContrato
		AND CTPRODUCTO.TPR_FL_CVE = D.TPR_FL_CVE
		AND B.CAR_FL_CVE IN (1,11,16,17,18)--SOLO SE DEBEN INCLUIR SERIE,NUM. PEDIMENTO,ADUANA,FECHA DE PEDIMENTO
		AND A.CFP_DS_CARACT <> ''
	ORDER BY C.FAC_FL_CVE, A.PRD_FL_CVE, C.KPF_NO_CONSECUTIVO, B.CAR_FL_CVE
OPEN curACTIVOS
	FETCH NEXT FROM curACTIVOS INTO
	@facturaActual, @productoActual, @consecutivoActual,@numFactura, @desFactura, @claveDescrip, @descrip, @nombreProveedorActual
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @tablaActivos= ''
		IF @facturaAnterior<>@facturaActual OR @productoAnterior<>@productoActual OR @consecutivoAnterior<>@consecutivoActual
		BEGIN			
			IF @unaFila =1
			BEGIN
				--SI NO ES LA PRIMERA VEZ QUE PASA POR AQUI HACEMOS EL CIERRE DE FILA
				SET @tablaActivos= ' \cell}' +
				'{\trowd\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth9800\cellx1\row}'
			END
			SET @unaFila=1
			--SI CAMBIA EL PRODUCTO DECLARAMOS UNA NUEVA LÍNEA
			SET @CARACTAUX = (SELECT RTRIM(CFP_DS_CARACT) FROM KCARAC_PROD_FACT WHERE FAC_FL_CVE = @facturaActual AND CAR_FL_CVE = 11--Descripcion
														 AND KPF_NO_CONSECUTIVO = @consecutivoActual AND PRD_FL_CVE = @productoActual)
			SET @tablaActivos= @tablaActivos + '\trowd\intbl{' + @numFactura + @CARACTAUX + ',' + @desFactura

			--si el proveedor actual es diferente al anterior lo agregamos a la lista de proveedores
			IF @nombreProveedorAnterior<>@nombreProveedorActual
			BEGIN
				SET @listaProveedores= @listaProveedores + @nombreProveedorActual + ' \par '
				SET @nombreProveedorAnterior=@nombreProveedorActual
			END
		END
		IF @claveDescrip <> 'DESCRIPCION'
		BEGIN
				IF 	@claveDescrip = 'FECHA DE PEDIMENTO'
				BEGIN	
					SELECT @descrip = UPPER(@descrip)
					SELECT @Dia = CAST(DAY(@descrip) AS VARCHAR(2)),@Mes= DATENAME(MM, @descrip),@Año= CAST(YEAR(@descrip) AS VARCHAR(4))
					SET @descrip = @Dia + ' DE ' + UPPER(@Mes) + ' DE ' + @Año					
				END	
			SET @tablaActivos=  @tablaActivos + ', ' + @claveDescrip + ' ' + @descrip
		END
			
		UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @tablaActivos
		SET @NOFFSET = @NOFFSET + LEN(RTRIM(@tablaActivos))	

		SET @facturaAnterior=@facturaActual
		SET @productoAnterior=@productoActual
		SET @consecutivoAnterior=@consecutivoActual

		FETCH NEXT FROM curACTIVOS INTO
		@facturaActual, @productoActual, @consecutivoActual, @numFactura, @desFactura, @claveDescrip, @descrip, @nombreProveedorActual
	END		
CLOSE curACTIVOS
DEALLOCATE curACTIVOS


IF @unaFila =1
BEGIN
	--TENEMOS QUE CERRAR LA ULTIMA FILA SI ES QUE LA HUBO
	SET @tablaActivos= ' \cell}' +
		'{\trowd\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth9800\cellx1\row} \pard'
	UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @tablaActivos
END

EXEC lsntReplace @listaProveedores, @listaProveedores output   --> CAMBIO CARACTERES ESPECIALES
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%listaProveedores%]', @listaProveedores)

--DATOS DE TASAS
DECLARE @parrafoTasaVariable varchar(8000)

IF @tipoTasa=2
	BEGIN
		DECLARE @textTipoCalculo varchar(200)
		--SI ES TASA VARIABLE
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%leyendaTasa%]', '')
		IF @CveMoneda= 1
			BEGIN
				--dependiendo del tipo de calculo capturado en el contrato definimos el texto
				--de tipo de calculo
				SET @textTipoCalculo=
					CASE @tipoCalculo
						WHEN 4 THEN 'será la más alta de todas las tasas TIIE publicadas durante la "Periodicidad" señalada en el presente contrato'
						WHEN 7 THEN 'será la de 2 días hábiles anteriores al inicio de la "Periodicidad" señalada en el presente contrato'
						WHEN 8 THEN 'será el promedio aritmético de todas las tasas TIIE publicadas en cada Período ' + @periodPago + ' de cálculo de los intereses ordinarios'
						ELSE ''
					END
				--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%parrafosTasaVariable%]', 
				SET @parrafoTasaVariable= '"Tasa Sustituta" significa cualquier otra tasa que sustituya a la anterior.' + ' \par \par ' +
				'En caso de que la tasa TIIE resulte inferior a la Tasa de Costo de Fondeo de Caterpillar, ésta última será la que se aplique para el cálculo de los intereses. ' +
				'Por Tasa de Costo de Fondeo se entiende como la tasa que resulte del promedio del costo financiero que Caterpillar tenga contratados con instituciones financieras ' +
				'y terceros, en la inteligencia de que si por cualquier causa la aplicación de dicha tasa de interés fuere improcedente o nula, se aplicará la tasa TIIE.' + ' \par \par ' + 
				'La Tasa TIIE que se considerará para el cálculo de los intereses del presente contrato, ' + @textTipoCalculo + '. ' +
				'La Tasa TIIE será tomada de los periódicos El Financiero, El Economista o cualquier otro Periódico de mayor circulación dentro de la República Mexicana.' + ' \par \par '
			END
		ELSE
			BEGIN
				--dependiendo del tipo de calculo capturado en el contrato definimos el texto
				--de tipo de calculo
				SET @textTipoCalculo=
					CASE @tipoCalculo
						WHEN 4 THEN 'será la más alta de todas las tasas Libor publicadas durante la "Periodicidad" señalada en el presente contrato'
						WHEN 7 THEN 'será la de 2 días hábiles anteriores al inicio de la "Periodicidad" señalada en el presente contrato'
						WHEN 8 THEN 'será el promedio aritmético de todas las tasas Libor publicadas en cada Período ' + @periodPago + ' de cálculo de los intereses ordinarios'
						ELSE ''
					END
				--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%parrafosTasaVariable%]', 
				SET @parrafoTasaVariable= '"La Tasa" Libor que se considerará para el cálculo de los intereses del presente contrato, ' + @textTipoCalculo + '. ' + 
				'La Tasa Libor será tomada de los periódicos El Financiero, El Economista o cualquier otro Periódico de mayor circulación dentro de la República Mexicana.' + ' \par \par '
			END;
		--la variable NOFFSET indica la posicion en memoria del apuntador
		/*SET @NOFFSET = 0
		SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%parrafosTasaVariable%]'

		SELECT @NOFFSET = DATALENGTH(TEXTO) from #Claves where CLAVE='[%parrafosTasaVariable%]'
		UPDATETEXT #Claves.texto @ptr @NOFFSET NULL 'Las tasas de interés anteriormente mencionadas son variables y por lo tanto, la que resulte aplicable conforme a lo antes dispuesto, se ajustará con la periodicidad establecida en el Anexo A de este contrato, bajo el rubro "Periodicidad", durante cada período de intereses, de acuerdo con las variaciones de dichas tasas.'*/
		SET @parrafoTasaVariable= @parrafoTasaVariable + 'Las tasas de interés anteriormente mencionadas son variables y por lo tanto, la que resulte aplicable conforme a lo antes dispuesto, se ajustará con la periodicidad establecida en el Anexo A de este contrato, bajo el rubro "Periodicidad", durante cada período de intereses, de acuerdo con las variaciones de dichas tasas.'

		--en caso de que la moneda sea dólares agregamos un texto adicional al parrafo de tasa variable
		IF @CveMoneda= 2
			BEGIN
				--select @NOFFSET = DATALENGTH(TEXTO) from #Claves where CLAVE='[%parrafosTasaVariable%]'				
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL 'La tasa de interés determinada según lo dispuesto con anterioridad, se aplicará durante cada "Período de Intereses", según se define y especifica en el Anexo A de este contrato. \par \par El "Factor" pactado en el Anexo A del presente contrato, sólo será aplicado, cuando la Tasa Total considerada para su cálculo en el periodo correspondiente, sea igual o menor a  0%'
				SET @parrafoTasaVariable= @parrafoTasaVariable + ' La tasa de interés determinada según lo dispuesto con anterioridad, se aplicará durante cada "Período de Intereses", según se define y especifica en el Anexo A de este contrato. \par \par El "Factor" pactado en el Anexo A del presente contrato, sólo será aplicado, cuando la Tasa Total considerada para su cálculo en el periodo correspondiente, sea igual o menor a  0%'
			END;

		SET @parrafoTasaVariable= ' \par ' + @parrafoTasaVariable + ' \par '
		EXEC lsntReplace @parrafoTasaVariable, @parrafoTasaVariable output   --> CAMBIO CARACTERES ESPECIALES
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%parrafosTasaVariable%]', @parrafoTasaVariable)

		--Insertamos los datos de la tasa que deben ir en el cuadro informativo
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%descripTasaBase%]', @tasa)
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%descripPuntosPrc%]', CONVERT(VARCHAR(8),@puntosAdic))
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%descripTasaFija%]', 'NO APLICA')

		
	END
ELSE
	BEGIN
		--SI ES TASA FIJA
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%leyendaTasa%]', 'Tasa Fija: ' + CONVERT(VARCHAR(8), @tasaNominal) + ' %')
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%parrafosTasaVariable%]', '')
		--Insertamos los datos de la tasa que deben ir en el cuadro informativo
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%descripTasaBase%]', 'FIJA')
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%descripPuntosPrc%]', 'NO APLICA')
		INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%descripTasaFija%]', CONVERT(VARCHAR(8), @tasaNominal) + ' %')
	END;


---INICIO:AVH*************************************************************
--TASA MORA
DECLARE @TasaMora AS NUMERIC (13,2)
SELECT @TasaMora=CTM.TMR_NO_VALTASA FROM KCONTRATO KC
INNER JOIN CTMORATORIO CTM ON KC.TOP_CL_CVE=CTM.TOP_CL_CVE 
AND KC.TAS_FL_CVE=CTM.TAS_FL_CVE 
AND KC.CTO_CL_MONEDA=CTM.TMR_CL_MONEDA
WHERE CTO_FL_CVE=@CveContrato

INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%TasaMora%]', RTRIM(LTRIM(@TasaMora)) )

--TIPO CUENTA
DECLARE @TipoCuenta as varchar(200)
SELECT @TipoCuenta=(CPA.PAR_DS_DESCRIPCION) FROM KCONTRATO KC
INNER JOIN CPCUENTA CPC ON KC.PNA_FL_PERSONA=CPC.PNA_FL_PERSONA
INNER JOIN CPARAMETRO CPA ON CPC.PCT_CL_TCUENTA=CPA.PAR_CL_VALOR AND CPA.PAR_FL_CVE=71
WHERE KC.CTO_FL_CVE = @CveContrato
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%TipoCuenta%]', @TipoCuenta )

--AVAL,DIRECCION
DECLARE @MIN AS INT,@MAX AS INT
DECLARE @NombreCompletoAval AS VARCHAR(300)=''
DECLARE @DireccionAval as varchar(300)=''
SET @MIN=1
SELECT IDENTITY(INT,1,1) ID,(CP.PNA_DS_NOMBRE),isnull(CD.DMO_DS_CALLE_NUM +' '+ CD.DMO_DS_NUMEXT + ' Col. '+ CD.DMO_DS_COLONIA,'-')AS DOMICILIO into #AVALES FROM KCONTRATO KC
INNER JOIN CPRELACION CPR ON KC.PNA_FL_PERSONA=PRE_FL_PERSONA AND CPR.PRE_FG_VALOR=3
INNER JOIN CPERSONA CP ON CPR.PNA_FL_PERSONA=CP.PNA_FL_PERSONA
LEFT JOIN CDOMICILIO CD ON CP.PNA_FL_PERSONA=CD.PNA_FL_PERSONA
WHERE CTO_FL_CVE = @CveContrato

SELECT @MAX=(COUNT(ID))FROM #AVALES

WHILE @MIN<=@MAX
BEGIN
SET @NombreCompletoAval = @NombreCompletoAval+(SELECT RTRIM(PNA_DS_NOMBRE) FROM #AVALES WHERE ID=@MIN)+','
set @DireccionAval = @DireccionAval +(SELECT RTRIM(DOMICILIO) FROM #AVALES WHERE ID=@MIN)+','
SET @MIN=@MIN+1
END
DROP TABLE #AVALES
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NombreCompletoAval%]', @NombreCompletoAval)
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%DireccionAval%]', @DireccionAval)
--TASA CON IVA
DECLARE @TasaConIva as numeric (13,2)
SELECT @TasaConIva=(((CTO_CL_IVA /100)+1) * CTO_NO_TASA_NOMINAL) FROM KCONTRATO WHERE CTO_FL_CVE=@CveContrato
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%TasaNominalconIva%]',  RTRIM(LTRIM(@TasaConIva)) )
--PAGO SIN IVA
DECLARE @PagoSinIva as numeric (13,2)
SELECT @PagoSinIva=(CTP_NO_MTO_PAGO) FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE=@CveContrato
and CTP_NO_PAGO=1 
and CTP_NO_VERSION=(SELECT max(CTP_NO_VERSION) FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE=@CveContrato)
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%PagoSinIva%]',  RTRIM(LTRIM(@PagoSinIva)) )

--PAGO MAXIMO DEL PERIODO
DECLARE @PagoMaxPeriodo as numeric (13,2)
SELECT @PagoMaxPeriodo=(MAX(CTP_NO_MTO_TOTPAGO)) FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE=@CveContrato
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%PagoMaxPeriodo%]',  RTRIM(LTRIM(@PagoMaxPeriodo)) )


--MES AÑO
declare @MesA as varchar(100)
declare @añoA as varchar(100)
SELECT @MesA=DATENAME(MM, CTP_FE_EXIGIBILIDAD),@añoA=DATENAME(YYYY, CTP_FE_EXIGIBILIDAD)
from KTPAGO_CONTRATO 
where CTO_FL_CVE=@CveContrato
and CTP_NO_PAGO=1 
and CTP_NO_VERSION=(SELECT max(CTP_NO_VERSION) FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE=@CveContrato)
INSERT INTO #Claves VALUES( '[%MesA%]', @MesA)
INSERT INTO #Claves VALUES( '[%MesAn%]', @añoA)


--TOTAL RENTAS 
DECLARE @TotalRenta_Letra as varchar (100)
DECLARE @TotalRenta NUMERIC(13,2)

INSERT INTO #Claves VALUES( '[%MontoTotalRentas%]', '' )
INSERT INTO #Claves VALUES( '[%MontoTotalRentas_Letra%]', '' )
 
SELECT @TotalRenta=(sum(CTP_NO_MTO_TOTPAGO))FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE=@CveContrato
EXEC spLsnetCantidadLetra  @TotalRenta, 1,@TotalRenta_Letra output

UPDATE #Claves SET TEXTO= RTRIM(LTRIM(@TotalRenta))  WHERE CLAVE='[%MontoTotalRentas%]'
UPDATE #Claves SET TEXTO='(' + RTRIM(LTRIM(@TotalRenta_Letra)) + ')' WHERE CLAVE='[%MontoTotalRentas_Letra%]'
 

--TABLAS DE AMORTIZACIÓN
INSERT INTO #Claves VALUES( '[%tablaAmortizacion%]', '' )

DECLARE     @NumPagoTA int, 
			@FechaExiTA varchar(20), 
			@MontoPagoTA numeric(13,2), 
			@MontoInteresTA numeric(13,2),
			@MontoIvaInteresTA numeric(13,2),
			@MontoAmortizacionTA  numeric(13,2),
			@MontoIvaAmortizacionTA  numeric(13,2),
			@MontoSinsolutoTA numeric(13,2),
			@MontoOCARGOSTA NUMERIC(13,2),
			@MontoTotalTA numeric (13,2),
			@sTablaAmtnTA varchar(8000),
			@sumaMontoPagoTA numeric(13,2),
			@sumaMontoIvaInteresTA numeric(13,2), 
			@sumaMontoInteresTA numeric(13,2),
			@sumaMontoAmortizacionTA  numeric(13,2),
			@sumaMontoSinsolutoTA numeric (13,2),
			@sumaMontoTotalTA numeric (13,2),
			@sumaMontoIvaAmortizacionTA  numeric(13,2),
			@ivaInteresTA tinyint,
			@ivaCapitalTA tinyint,
			@sumaMontoOCARGOSTA numeric(13,2)

--MEDIANTE EL ESQUEMA DE FINANCIAMIENTO DETERMINAMOS SI SE CALCULARÁ IVA AL INTERES Y A LA AMORTIZACIÓN DE LAS RENTAS
SELECT  @ivaCapitalTA=ESQ_FG_IVACAPITAL, @ivaInteresTA=ESQ_FG_IVAINTERES
FROM CESQUE_FINAN, KTOPERACION, KCONTRATO
WHERE
KCONTRATO.TOP_CL_CVE=KTOPERACION.TOP_CL_CVE 
AND
KTOPERACION.ESQ_CL_CVE=CESQUE_FINAN.ESQ_CL_CVE
AND
KCONTRATO.CTO_FL_CVE=@CveContrato

IF 1=1--@CveTOperacion = 'CD' OR @CveTOperacion = 'CR'
BEGIN	

	SET @sumaMontoPagoTA=0
	SET	@sumaMontoInteresTA=0
	SET	@sumaMontoAmortizacionTA=0
	set @sumaMontoSinsolutoTA=0
	SET @sumaMontoTotalTA=0
	SET @sumaMontoOCARGOSTA=0


	--Determinamos la leyenda de periodicidad de pago
	IF  @periodPago='DIARIA'
	BEGIN
		SET @periodPago='DIARIO'
	END

	--la variable NOFFSET indica la posicion en memoria del apuntador
	SET @NOFFSET = 0
	SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%tablaAmortizacion%]'
	
	
	SET @sTablaAmtnTA = '\trowd\qc\intbl{ \b ' +
					' No. de pago '         + '\cell ' +
					' Fecha de pago  '       + '\cell ' +
					' Saldo '   + '\cell ' +
					' Capital '     + '\cell ' +
					' Intereses con IVA '     + '\cell ' +					
					' Pago ' + '\cell}' +
					'\pard\intbl ' +
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx2' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx6' +							
							'\row}'

	EXEC lsntReplace @sTablaAmtnTA, @sTablaAmtnTA output 
	UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtnTA
    SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtnTA))

--print @sTablaAmtn
	DECLARE curPAGOS CURSOR FOR 
		SELECT CTP_NO_PAGO, REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2),DAY(K1.CTP_FE_EXIGIBILIDAD))))) + RTRIM(CONVERT(CHAR(2),DAY(K1.CTP_FE_EXIGIBILIDAD)))+ '-' +
			CASE MONTH(CTP_FE_EXIGIBILIDAD)
				WHEN  1 THEN 'Ene'
				WHEN  2 THEN 'Feb'
				WHEN  3 THEN 'Mar'
				WHEN  4 THEN 'Abr'
				WHEN  5 THEN 'May'
				WHEN  6 THEN 'Jun'
				WHEN  7 THEN 'Jul'
				WHEN  8 THEN 'Ago'
				WHEN  9 THEN 'Sep'
				WHEN 10 THEN 'Oct'
				WHEN 11 THEN 'Nov'
				WHEN 12 THEN 'Dic'
			END + '-' +
			SUBSTRING(CONVERT(varchar(4),YEAR(CTP_FE_EXIGIBILIDAD)),3,2), 
			CTP_NO_MTO_PAGO, CTP_NO_MTO_INTERES+CTP_NO_MTO_IVA, CTP_NO_MTO_AMORTIZACION, CTP_NO_MTO_SINSOLUTO, CTP_NO_MTO_TOTPAGO,

			(SELECT isnull(SUM(DISTINCT KTPAGO_CONTRATO.CTP_NO_MTO_TOTPAGO),0) FROM KTPAGO_CONTRATO inner join kcto_ocargos on kcto_ocargos.ctc_fl_cve= KTPAGO_CONTRATO.ctc_fl_cve   WHERE KTPAGO_CONTRATO.CTO_FL_CVE = K1.CTO_FL_CVE AND KTPAGO_CONTRATO.CTP_CL_TTABLA = 4 and KTM_CL_TMOVTO ='COBDOM'  AND KTPAGO_CONTRATO.CTP_FE_EXIGIBILIDAD = K1.CTP_FE_EXIGIBILIDAD) TABLA4 
		FROM KTPAGO_CONTRATO K1 WHERE CTP_CL_TTABLA=1 AND CTP_NO_VERSION=1 AND CTO_FL_CVE= @CveContrato ORDER BY CTP_NO_PAGO
	OPEN curPAGOS
	FETCH NEXT FROM curPAGOS INTO
	@NumPagoTA, @FechaExiTA, @MontoPagoTA, @MontoInteresTA, @MontoAmortizacionTA, @MontoSinsolutoTA, @MontoTotalTA,@MontoOCARGOSTA
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
	
				SET @MontoPago1=''
				IF @MontoPagoTA >0.0
				BEGIN
				EXEC @MontoPago1 = FormatNumber @MontoPagoTA,2,',','.'
				SET @MontoPago1 = @MontoPago1
				END

				SET @MontoInteres1=''
				IF @MontoInteresTA >0.0
				BEGIN
				EXEC @MontoInteres1 = FormatNumber @MontoInteresTA,2,',','.'
				SET @MontoInteres1 = @MontoInteres1
				END

				SET @MontoAmortizacion1=''
				IF @MontoAmortizacionTA >0.0
				BEGIN
				EXEC @MontoAmortizacion1 = FormatNumber @MontoAmortizacionTA,2,',','.'
				SET @MontoAmortizacion1 = @MontoAmortizacion1
				END 
				
				SET @MontoOCARGOS1=''
				IF @MontoOCARGOSTA > 0.0
				BEGIN
				EXEC @MontoOCARGOS1 = FormatNumber @MontoOCARGOSTA,2,',','.'
				SET @MontoOCARGOS1 = @MontoOCARGOS1				
				END
							
				SET @MontoSinsoluto1 = ''
				IF @MontoSinsolutoTA >0.0
				BEGIN
				EXEC @MontoSinsoluto1 = FormatNumber @MontoSinsolutoTA,2,',','.'		
				SET @MontoSinsoluto1 = @MontoSinsoluto1
				END
				--Marredondo Se corrige error, el saldo insoluto del ultimo pago se quedaba igual al saldo insoluto del penúltimo pago
				ELSE
				BEGIN
					SET @MontoSinsoluto1 = @MontoSinsolutoTA
				END
				
				SET @MontoTotal1=''
				IF @MontoTotalTA >0.0
				BEGIN
				SET @MontoTotalTA=@MontoTotalTA+@MontoOCARGOSTA
				EXEC @MontoTotal1 = FormatNumber @MontoTotalTA  ,2,',','.'
				SET @MontoTotal1 = @MontoTotal1
				END
				
				
				SET @sTablaAmtnTA = '\trowd\intbl{' +
						' \qc ' + convert(varchar(4), @NumPagoTA) + ' \cell ' +
						' \qc ' + CASE WHEN @NumPagoTA=0 THEN 'A la firma' ELSE @FechaExiTA END + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoSinsoluto1  ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoAmortizacion1 ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoInteres1 ) + ' \cell ' +						
						' \qr ' + convert(varchar(20), @MontoTotal1) + ' \cell}' +
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx2' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx6' +							
							'\row}'

				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtnTA
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtnTA))
/*CAMBIO ANC */
				SET @sumaMontoPagoTA=@sumaMontoPagoTA + @MontoPagoTA
				SET	@sumaMontoInteresTA=@sumaMontoInteresTA + @MontoInteresTA
				SET	@sumaMontoAmortizacionTA=@sumaMontoAmortizacionTA + @MontoAmortizacionTA
				SET @sumaMontoSinsolutoTA=@sumaMontoSinsolutoTA + @MontoSinsolutoTA
				SET @sumaMontoTotalTA=@sumaMontoTotalTA + @MontoTotalTA 
				SET @sumaMontoOCARGOSTA=@sumaMontoOCARGOSTA+ @MontoOCARGOSTA
		FETCH NEXT FROM curPAGOS INTO
		@NumPagoTA, @FechaExiTA, @MontoPagoTA, @MontoInteresTA, @MontoAmortizacionTA, @MontoSinsolutoTA, @MontoTotalTA,@MontoOCARGOSTA					
	END		
	CLOSE curPAGOS
	DEALLOCATE curPAGOS	
	
	
	--Ponemos los totales
SET @sumaMontoPago1 = '0.00'
SET @sumaMontoInteres1 = '0.00'
SET @sumaMontoAmortizacion1 = '0.00'
set @sumaMontoSinsoluto1 = '0.00'
set @sumaMontoTotal1 = '0.00'

				IF @sumaMontoPagoTA >0.0
				BEGIN
				EXEC @sumaMontoPago1 = FormatNumber @sumaMontoPagoTA,2,',','.'
				SET @sumaMontoPago1 = @sumaMontoPago1
				END

				IF @sumaMontoInteresTA >0.0
				BEGIN
				EXEC @sumaMontoInteres1 = FormatNumber @sumaMontoInteresTA,2,',','.'
				SET @sumaMontoInteres1 = @sumaMontoInteres1
				END

				IF @sumaMontoAmortizacionTA >0.0
				BEGIN
				EXEC @sumaMontoAmortizacion1 = FormatNumber @sumaMontoAmortizacionTA,2,',','.'
				SET @sumaMontoAmortizacion1 = @sumaMontoAmortizacion1
				END
				
				IF @sumaMontoSinsolutoTA >0.0
				BEGIN
				EXEC @sumaMontoSinsoluto1 = FormatNumber @sumaMontoSinsolutoTA,2,',','.'
				SET @sumaMontoSinsoluto1 = @sumaMontoSinsoluto1
				END

				IF @sumaMontoOCARGOSTA >0.0
				BEGIN
				EXEC @sumaMontoOCARGOS1 = FormatNumber @sumaMontoOCARGOSTA,2,',','.'
				SET @sumaMontoOCARGOS1 = @sumaMontoOCARGOS1
				END

				
				IF @sumaMontoTotalTA >0.0
				BEGIN
				EXEC @sumaMontoTotal1 = FormatNumber @sumaMontoTotalTA,2,',','.'
				SET @sumaMontoTotal1 = @sumaMontoTotal1
				END

	SET @sTablaAmtnTA = '\trowd\intbl{' +
						' \qc  \cell ' +
						' \qc Total \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoSinsoluto1 ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoAmortizacion1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoInteres1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoOCARGOS1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoTotal1) + ' \cell }' +						
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx2' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx6' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx7' +
							--'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx8' +
							'\row} \pard \plain'


				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtnTA
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtnTA))
				
		SET @NOFFSET = 0

	
END

--select texto from #Claves where clave = '[%tablaAmortizacionContrato%]'




--FIN:AVH***************************************************************
	
--TABLAS DE AMORTIZACIÓN
INSERT INTO #Claves VALUES( '[%tablaAmortizacionContrato%]', '' )

DECLARE @NumPago int, 
			@FechaExi varchar(20), 
			@MontoPago numeric(13,2), 
			@MontoInteres numeric(13,2),
			@MontoIvaInteres numeric(13,2),
			@MontoAmortizacion  numeric(13,2),
			@MontoIvaAmortizacion  numeric(13,2),
			@MontoSinsoluto numeric(13,2),
			@MontoOCARGOS NUMERIC(13,2),
			@MontoTotal numeric (13,2),
			@sTablaAmtn varchar(8000),
			@sumaMontoPago numeric(13,2),
			@sumaMontoIvaInteres numeric(13,2), 
			@sumaMontoInteres numeric(13,2),
			@sumaMontoAmortizacion  numeric(13,2),
			@sumaMontoSinsoluto numeric (13,2),
			@sumaMontoTotal numeric (13,2),
			@sumaMontoIvaAmortizacion  numeric(13,2),
			@ivaInteres tinyint,
			@ivaCapital tinyint,
			@sumaMontoOCARGOS numeric(13,2)

--MEDIANTE EL ESQUEMA DE FINANCIAMIENTO DETERMINAMOS SI SE CALCULARÁ IVA AL INTERES Y A LA AMORTIZACIÓN DE LAS RENTAS
SELECT  @ivaCapital=ESQ_FG_IVACAPITAL, @ivaInteres=ESQ_FG_IVAINTERES
FROM CESQUE_FINAN, KTOPERACION, KCONTRATO
WHERE
KCONTRATO.TOP_CL_CVE=KTOPERACION.TOP_CL_CVE 
AND
KTOPERACION.ESQ_CL_CVE=CESQUE_FINAN.ESQ_CL_CVE
AND
KCONTRATO.CTO_FL_CVE=@CveContrato




IF 1=1--@CveTOperacion = 'CD' OR @CveTOperacion = 'CR'
BEGIN	

	SET @sumaMontoPago=0
	SET	@sumaMontoInteres=0
	SET	@sumaMontoAmortizacion=0
	set @sumaMontoSinsoluto=0
	SET @sumaMontoTotal=0
	SET @sumaMontoOCARGOS=0


	--Determinamos la leyenda de periodicidad de pago
	IF  @periodPago='DIARIA'
	BEGIN
		SET @periodPago='DIARIO'
	END

	--la variable NOFFSET indica la posicion en memoria del apuntador
	SET @NOFFSET = 0
	SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%tablaAmortizacionContrato%]'
	
	
	SET @sTablaAmtn = '\trowd\qc\intbl{ \b ' +
					' No. de pago '         + '\cell ' +
					' Fecha de pago  '       + '\cell ' +
					' Saldo '   + '\cell ' +
					' Capital '     + '\cell ' +
					' Intereses con IVA '     + '\cell ' +
					' Gatos por domiciliación ' + '\cell' +
					' Pago ' + '\cell}' +
					'\pard\intbl ' +
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx2' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx6' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx7' +
							'\row}'

	EXEC lsntReplace @sTablaAmtn, @sTablaAmtn output 
	UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtn
    SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtn))

--print @sTablaAmtn
	DECLARE curPAGOS CURSOR FOR 
		SELECT CTP_NO_PAGO, REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2),DAY(K1.CTP_FE_EXIGIBILIDAD))))) + RTRIM(CONVERT(CHAR(2),DAY(K1.CTP_FE_EXIGIBILIDAD)))+ '-' +
			CASE MONTH(CTP_FE_EXIGIBILIDAD)
				WHEN  1 THEN 'Ene'
				WHEN  2 THEN 'Feb'
				WHEN  3 THEN 'Mar'
				WHEN  4 THEN 'Abr'
				WHEN  5 THEN 'May'
				WHEN  6 THEN 'Jun'
				WHEN  7 THEN 'Jul'
				WHEN  8 THEN 'Ago'
				WHEN  9 THEN 'Sep'
				WHEN 10 THEN 'Oct'
				WHEN 11 THEN 'Nov'
				WHEN 12 THEN 'Dic'
			END + '-' +
			SUBSTRING(CONVERT(varchar(4),YEAR(CTP_FE_EXIGIBILIDAD)),3,2), 
			CTP_NO_MTO_PAGO, CTP_NO_MTO_INTERES+CTP_NO_MTO_IVA, CTP_NO_MTO_AMORTIZACION, CTP_NO_MTO_SINSOLUTO, CTP_NO_MTO_TOTPAGO,

			(SELECT isnull(SUM(DISTINCT KTPAGO_CONTRATO.CTP_NO_MTO_TOTPAGO),0) FROM KTPAGO_CONTRATO inner join kcto_ocargos on kcto_ocargos.ctc_fl_cve= KTPAGO_CONTRATO.ctc_fl_cve   WHERE KTPAGO_CONTRATO.CTO_FL_CVE = K1.CTO_FL_CVE AND KTPAGO_CONTRATO.CTP_CL_TTABLA = 4 and KTM_CL_TMOVTO ='COBDOM'  AND KTPAGO_CONTRATO.CTP_FE_EXIGIBILIDAD = K1.CTP_FE_EXIGIBILIDAD) TABLA4 
		FROM KTPAGO_CONTRATO K1 WHERE CTP_CL_TTABLA=1 AND CTP_NO_VERSION=1 AND CTO_FL_CVE= @CveContrato ORDER BY CTP_NO_PAGO
	OPEN curPAGOS
	FETCH NEXT FROM curPAGOS INTO
	@NumPago, @FechaExi, @MontoPago, @MontoInteres, @MontoAmortizacion, @MontoSinsoluto, @MontoTotal,@MontoOCARGOS
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
	
				SET @MontoPago1=''
				IF @MontoPago >0.0
				BEGIN
				EXEC @MontoPago1 = FormatNumber @MontoPago,2,',','.'
				SET @MontoPago1 = @MontoPago1
				END

				SET @MontoInteres1=''
				IF @MontoInteres >0.0
				BEGIN
				EXEC @MontoInteres1 = FormatNumber @MontoInteres,2,',','.'
				SET @MontoInteres1 = @MontoInteres1
				END

				SET @MontoAmortizacion1=''
				IF @MontoAmortizacion >0.0
				BEGIN
				EXEC @MontoAmortizacion1 = FormatNumber @MontoAmortizacion,2,',','.'
				SET @MontoAmortizacion1 = @MontoAmortizacion1
				END 
				
				SET @MontoOCARGOS1=''
				IF @MontoOCARGOS > 0.0
				BEGIN
				EXEC @MontoOCARGOS1 = FormatNumber @MontoOCARGOS,2,',','.'
				SET @MontoOCARGOS1 = @MontoOCARGOS1				
				END
							
				SET @MontoSinsoluto1 = ''
				IF @MontoSinsoluto >0.0
				BEGIN
				EXEC @MontoSinsoluto1 = FormatNumber @MontoSinsoluto,2,',','.'		
				SET @MontoSinsoluto1 = @MontoSinsoluto1
				END
				--Marredondo Se corrige error, el saldo insoluto del ultimo pago se quedaba igual al saldo insoluto del penúltimo pago
				ELSE
				BEGIN
					SET @MontoSinsoluto1 = @MontoSinsoluto
				END
				
				SET @MontoTotal1=''
				IF @MontoTotal >0.0
				BEGIN
				SET @MontoTotal=@MontoTotal+@MontoOCARGOS
				EXEC @MontoTotal1 = FormatNumber @MontoTotal  ,2,',','.'
				SET @MontoTotal1 = @MontoTotal1
				END
				
				
				SET @sTablaAmtn = '\trowd\intbl{' +
						' \qc ' + convert(varchar(4), @NumPago) + ' \cell ' +
						' \qc ' + CASE WHEN @NumPago=0 THEN 'A la firma' ELSE @FechaExi END + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoSinsoluto1  ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoAmortizacion1 ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoInteres1 ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoOCARGOS1) + ' \cell' +
						' \qr ' + convert(varchar(20), @MontoTotal1) + ' \cell}' +
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx2' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx6' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx7' +
							'\row}'

				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtn
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtn))
/*CAMBIO ANC */
				SET @sumaMontoPago=@sumaMontoPago + @MontoPago
				SET	@sumaMontoInteres=@sumaMontoInteres + @MontoInteres
				SET	@sumaMontoAmortizacion=@sumaMontoAmortizacion + @MontoAmortizacion
				SET @sumaMontoSinsoluto=@sumaMontoSinsoluto + @MontoSinsoluto
				SET @sumaMontoTotal=@sumaMontoTotal + @MontoTotal 
				SET @sumaMontoOCARGOS=@sumaMontoOCARGOS+ @MontoOCARGOS
		FETCH NEXT FROM curPAGOS INTO
		@NumPago, @FechaExi, @MontoPago, @MontoInteres, @MontoAmortizacion, @MontoSinsoluto, @MontoTotal,@MontoOCARGOS					
	END		
	CLOSE curPAGOS
	DEALLOCATE curPAGOS	
	
	
	--Ponemos los totales
SET @sumaMontoPago1 = '0.00'
SET @sumaMontoInteres1 = '0.00'
SET @sumaMontoAmortizacion1 = '0.00'
set @sumaMontoSinsoluto1 = '0.00'
set @sumaMontoTotal1 = '0.00'

				IF @sumaMontoPago >0.0
				BEGIN
				EXEC @sumaMontoPago1 = FormatNumber @sumaMontoPago,2,',','.'
				SET @sumaMontoPago1 = @sumaMontoPago1
				END

				IF @sumaMontoInteres >0.0
				BEGIN
				EXEC @sumaMontoInteres1 = FormatNumber @sumaMontoInteres,2,',','.'
				SET @sumaMontoInteres1 = @sumaMontoInteres1
				END

				IF @sumaMontoAmortizacion >0.0
				BEGIN
				EXEC @sumaMontoAmortizacion1 = FormatNumber @sumaMontoAmortizacion,2,',','.'
				SET @sumaMontoAmortizacion1 = @sumaMontoAmortizacion1
				END
				
				IF @sumaMontoSinsoluto >0.0
				BEGIN
				EXEC @sumaMontoSinsoluto1 = FormatNumber @sumaMontoSinsoluto,2,',','.'
				SET @sumaMontoSinsoluto1 = @sumaMontoSinsoluto1
				END

				IF @sumaMontoOCARGOS >0.0
				BEGIN
				EXEC @sumaMontoOCARGOS1 = FormatNumber @sumaMontoOCARGOS,2,',','.'
				SET @sumaMontoOCARGOS1 = @sumaMontoOCARGOS1
				END

				
				IF @sumaMontoTotal >0.0
				BEGIN
				EXEC @sumaMontoTotal1 = FormatNumber @sumaMontoTotal,2,',','.'
				SET @sumaMontoTotal1 = @sumaMontoTotal1
				END

	SET @sTablaAmtn = '\trowd\intbl{' +
						' \qc  \cell ' +
						' \qc Total \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoSinsoluto1 ) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoAmortizacion1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoInteres1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoOCARGOS1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoTotal1) + ' \cell }' +						
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx2' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx6' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx7' +
							--'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1498 \cellx8' +
							'\row} \pard \plain'


				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtn
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtn))
				
		SET @NOFFSET = 0

	
END

--select texto from #Claves where clave = '[%tablaAmortizacionContrato%]'

IF @CveTOperacion = 'AF' OR @CveTOperacion = 'NE'OR @CveTOperacion = 'FF' OR @CveTOperacion = 'AP'
BEGIN


					
	SET @sumaMontoPago=0
	SET	@sumaMontoInteres=0
	SET	@sumaMontoAmortizacion=0
	SET @sumaMontoIvaAmortizacion=0
	SET @sumaMontoIvaInteres=0
	set @sumaMontoSinsoluto=0
	SET @sumaMontoTotal=0

	--la variable NOFFSET indica la posicion en memoria del apuntador
	SET @NOFFSET = 0
	--SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%tablaAmortizacionContrato%]'

	
	SET @sTablaAmtn = '\trowd\qc\intbl{\f1\fs16 \b ' +
					' NUM \par DE \par PAGO '         + '\cell ' +
					' FECHA \par DEL \par PAGO \par (ddmmmyy) '       + '\cell ' +
					' RENTA \par ' + @periodPago + ' \par VENCIDA '   + '\cell ' +
					' IVA \par DE \par INTERES '     + '\cell ' +
					' INTERES \par VARIABLE  \par EN PAGO '     + '\cell ' +
					' IVA \par DE  \par CAPITAL '     + '\cell ' +
					' CAPITAL \par FIJO EN \par PAGO '     + '\cell ' +
					' CAPITAL \par INSOLUTO \par DESPUES \par DEL PAGO ' + '\cell}' +
					' CAPITAL \par TOTAL \par DESPUES \par DEL PAGO ' + '\cell}' +
					'\pard\intbl ' +
					'{\trowd' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx2' + 
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx3' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx4' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx5' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx6' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx7' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx8' +
					'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx9' +
					'\row}'
	UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtn
    SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtn))

	DECLARE curPAGOS CURSOR FOR 
		SELECT CTP_NO_PAGO, REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2),DAY(KTPAGO_CONTRATO.CTP_FE_EXIGIBILIDAD))))) + RTRIM(CONVERT(CHAR(2),DAY(KTPAGO_CONTRATO.CTP_FE_EXIGIBILIDAD)))+ ' ' +
			CASE MONTH(CTP_FE_EXIGIBILIDAD)
				WHEN  1 THEN 'Ene'
				WHEN  2 THEN 'Feb'
				WHEN  3 THEN 'Mar'
				WHEN  4 THEN 'Abr'
				WHEN  5 THEN 'May'
				WHEN  6 THEN 'Jun'
				WHEN  7 THEN 'Jul'
				WHEN  8 THEN 'Ago'
				WHEN  9 THEN 'Sep'
				WHEN 10 THEN 'Oct'
				WHEN 11 THEN 'Nov'
				WHEN 12 THEN 'Dic'
			END + ' ' +
			SUBSTRING(CONVERT(varchar(4),YEAR(CTP_FE_EXIGIBILIDAD)),3,2), 
			CTP_NO_MTO_PAGO, CTP_NO_MTO_INTERES * (@ivaContrato/100) * @ivaInteres, CTP_NO_MTO_INTERES, CTP_NO_MTO_AMORTIZACION * (@ivaContrato/100) * @ivaCapital, CTP_NO_MTO_AMORTIZACION, CTP_NO_MTO_SINSOLUTO, CTP_NO_MTO_TOTPAGO
		FROM KTPAGO_CONTRATO WHERE CTP_CL_TTABLA=1 AND CTP_NO_VERSION=1 AND CTO_FL_CVE= @CveContrato ORDER BY CTP_NO_PAGO
	OPEN curPAGOS
	FETCH NEXT FROM curPAGOS INTO
	@NumPago, @FechaExi, @MontoPago, @MontoIvaInteres, @MontoInteres, @MontoIvaAmortizacion, @MontoAmortizacion, @MontoSinsoluto, @MontoTotal
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
				--tomamos el primer pago para obtener su monto y fecha, datos que después
				--irán en el cuadro informativo
				IF @MontoPago > 0.0
				BEGIN
				EXEC @MontoPago1 = FormatNumber @MontoPago,2,',','.'
				SET @MontoPago1 = @MontoPago1
				END

				IF @MontoIvaInteres > 0.0
				BEGIN				
				EXEC @MontoIvaInteres1 = FormatNumber @MontoIvaInteres,2,',','.'
				SET @MontoIvaInteres1 = @MontoIvaInteres1
				END

				IF @MontoInteres > 0.0
				BEGIN				
				EXEC @MontoInteres1 = FormatNumber @MontoInteres,2,',','.'
				SET @MontoInteres1 = @MontoInteres1
				END

				IF @MontoIvaAmortizacion > 0.0
				BEGIN				
				EXEC @MontoIvaAmortizacion1 = FormatNumber @MontoIvaAmortizacion,2,',','.'
				SET @MontoIvaAmortizacion1 = @MontoIvaAmortizacion1
				END

				IF @MontoAmortizacion > 0.0
				BEGIN				
				EXEC @MontoAmortizacion1 = FormatNumber @MontoAmortizacion,2,',','.'
				SET @MontoAmortizacion1 = @MontoAmortizacion1
				END
				
								
				IF @MontoSinsoluto > 0.0
				BEGIN				
				EXEC @MontoSinsoluto1 = FormatNumber @MontoSinsoluto,2,',','.'		
				SET @MontoSinsoluto1 = @MontoSinsoluto1
				END
				--Marredondo Se corrige error, el saldo insoluto del ultimo pago se quedaba igual al saldo insoluto del penúltimo pago
				ELSE
				BEGIN
					SET @MontoSinsoluto1 = @MontoSinsoluto
				END
				

				
				IF @MontoTotal > 0.0
				BEGIN				
				EXEC @MontoTotal1 = FormatNumber @MontoTotal,2,',','.'		
				SET @MontoTotal1 = @MontoTotal1
				END
				
								

				IF @montoDeposito > 0.0
				BEGIN
				EXEC @montoDeposito1 = FormatNumber @montoDeposito,2,',','.'
				SET @montoDeposito1 = @montoDeposito1
				END

				IF @NumPago=1
				BEGIN
					INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%importeDeposito%]', convert(varchar(14),@montoDeposito1))
					--INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%importeDeposito%]', convert(varchar(14),@MontoPago1))
					DECLARE @FechaExiAux varchar(50)
					SELECT @FechaExiAux=REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2),DAY(KTPAGO_CONTRATO.CTP_FE_EXIGIBILIDAD)))))
							+ RTRIM(CONVERT(CHAR(2),DAY(KTPAGO_CONTRATO.CTP_FE_EXIGIBILIDAD)))+ ' de ' +
							CASE MONTH(CTP_FE_EXIGIBILIDAD)
								WHEN  1 THEN 'Enero'
								WHEN  2 THEN 'Febrero'
								WHEN  3 THEN 'Marzo'
								WHEN  4 THEN 'Abril'
								WHEN  5 THEN 'Mayo'
								WHEN  6 THEN 'Junio'
								WHEN  7 THEN 'Julio'
								WHEN  8 THEN 'Agosto'
								WHEN  9 THEN 'Septiembre'
								WHEN 10 THEN 'Octubre'
								WHEN 11 THEN 'Noviembre'
								WHEN 12 THEN 'Diciembre'
							END + ' de ' +
							SUBSTRING(CONVERT(varchar(4),YEAR(CTP_FE_EXIGIBILIDAD)),1,4)
					FROM KTPAGO_CONTRATO WHERE CTP_CL_TTABLA=1 AND CTP_NO_VERSION=1 AND CTO_FL_CVE= @CveContrato 
												AND CTP_NO_PAGO = 1
					INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%finaliza1erDep%]', @FechaExiAux)
				END

				SET @sTablaAmtn = '\trowd\intbl{' +
						' \qc ' + convert(varchar(4), @NumPago) + ' \cell ' +
						' \qc ' + CASE WHEN @NumPago=0 THEN 'A la firma' ELSE @FechaExi END + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoPago1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoIvaInteres1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoInteres1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoIvaAmortizacion1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoAmortizacion1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @MontoSinsoluto1) + ' \cell}' +
						' \qr ' + convert(varchar(20), @MontoTotal1) + ' \cell}' +
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx2' + 
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx6' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx7' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx8' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx9' +
							'\row}'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtn
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@sTablaAmtn))
--CAMBIO ANC
				SET @sumaMontoPago=@sumaMontoPago + @MontoPago
				SET	@sumaMontoInteres=@sumaMontoInteres + @MontoInteres
				SET	@sumaMontoAmortizacion=@sumaMontoAmortizacion + @MontoAmortizacion
				SET @sumaMontoIvaAmortizacion=@sumaMontoIvaAmortizacion + @MontoIvaAmortizacion
				SET @sumaMontoIvaInteres=@sumaMontoIvaInteres + @MontoIvaInteres
				set @sumaMontoSinsoluto=@sumaMontoSinsoluto + @MontoSinsoluto
				set @sumaMontoTotal=@sumaMontoTotal + @MontoTotal
		FETCH NEXT FROM curPAGOS INTO
		@NumPago, @FechaExi, @MontoPago, @MontoIvaInteres, @MontoInteres, @MontoIvaAmortizacion, @MontoAmortizacion, @MontoSinsoluto, @MontoTotal					
	END		
	CLOSE curPAGOS
	DEALLOCATE curPAGOS	
	
	
	--Ponemos los totales
SET @sumaMontoPago1 = '0.00'
SET @sumaMontoInteres1 = '0.00'
SET @sumaMontoAmortizacion1 = '0.00'
SET @sumaMontoIvaInteres1 = '0.00'
SET @sumaMontoIvaAmortizacion1 = '0.00'
set @sumaMontoSinsoluto1 = '0.00'
SET @sumaMontoTotal1 = '0.00'

				IF @sumaMontoPago > 0.0
				BEGIN
				EXEC @sumaMontoPago1 = FormatNumber @sumaMontoPago,2,',','.'
				SET @sumaMontoPago1 = @sumaMontoPago1
				END

				IF @sumaMontoInteres > 0.0
				BEGIN
				EXEC @sumaMontoInteres1 = FormatNumber @sumaMontoInteres,2,',','.'
				SET @sumaMontoInteres1 = @sumaMontoInteres1
				
				IF @sumaMontoSinsoluto > 0.0
				BEGIN
				EXEC @sumaMontoSinsoluto1 = FormatNumber @sumaMontoSinsoluto,2,',','.'
				SET @sumaMontoSinsoluto1 = @sumaMontoSinsoluto1
				end
				
				
				IF @sumaMontoTotal > 0.0
				BEGIN
				EXEC @sumaMontoTotal1 = FormatNumber @sumaMontoTotal,2,',','.'
				SET @sumaMontoTotal1 = @sumaMontoTotal1
				end
END
IF @sumaMontoAmortizacion > 0.0
				BEGIN
				EXEC @sumaMontoAmortizacion1 = FormatNumber @sumaMontoAmortizacion,2,',','.'
				SET @sumaMontoAmortizacion1 = @sumaMontoAmortizacion1
END
IF @sumaMontoIvaInteres > 0.0
				BEGIN
				EXEC @sumaMontoIvaInteres1 = FormatNumber @sumaMontoIvaInteres,2,',','.'
				SET @sumaMontoIvaInteres1 = @sumaMontoIvaInteres1
END
IF @sumaMontoIvaAmortizacion > 0.0
				BEGIN
				EXEC @sumaMontoIvaAmortizacion1 = FormatNumber @sumaMontoIvaAmortizacion,2,',','.'
				SET @sumaMontoIvaAmortizacion1 = @sumaMontoIvaAmortizacion1
END
	SET @sTablaAmtn = '\trowd\intbl{' +
						' \qc  \cell ' +
						' \qc Total \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoPago1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoIvaInteres1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoInteres1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoIvaAmortizacion1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoAmortizacion1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoSinsoluto1) + ' \cell ' +
						' \qr ' + convert(varchar(20), @sumaMontoTotal1) + ' \cell ' +
						' \qc  \cell}' +
						' {\trowd' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\clftsWidth3\clwWidth1200\cellx1' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx2' + 
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx3' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx4' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx5' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx6' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx7' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx8' +
							'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx9' +
							--'\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \clftsWidth3\clwWidth1200\cellx10' +
							'\row}'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @sTablaAmtn
		SET @NOFFSET = 0

	
END




IF @sumaMontoIvaInteres > 0.0
				BEGIN
				EXEC @sumaMontoPago1 = FormatNumber @sumaMontoPago,2,',','.'
				SET @sumaMontoPago1 = @sumaMontoPago1
END
INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%rentaTotal%]', convert(varchar(14),@sumaMontoPago1))


--*******************************COACREDITADOS**********************************

--verificamos si tiene coacreditados asignados el cliente
--DECLARE @CveContrato VARCHAR(30)
--DECLARE @CveCliente INT

DECLARE @DeclaracionCoacreditadoMoralAcu VARCHAR(8000)
--DECLARE @Contador INT
DECLARE @indiceApoderadosCoacreditado INT
DECLARE @textoApoIndColacreditado VARCHAR(1000)
DECLARE @textoApoIndColacreditado1 VARCHAR(1000)
DECLARE @PJURIDICA INT
DECLARE @ClaveCoacreditado INT
DECLARE @COACREDITADO VARCHAR (1000)
DECLARE @APODCCREDITADO VARCHAR (1000)
DECLARE @DeclaracionCoacreditadoMoral VARCHAR (1000)
DECLARE @DeclaracionCoacreditadoMoral1 VARCHAR (1000)
DECLARE @DeclaracionCoacreditadoFisica VARCHAR(1000)
DECLARE @ApoderadosCoacreditadosAcumulado VARCHAR(1000)
DECLARE @NombreCoacreditado VARCHAR(1000)
--DECLARE @Declaraciones VARCHAR(1000)
DECLARE @CONSECUTIVO INT 
--DECLARE @indiceApoderados INT
DECLARE @textoApodAcuCoacreditado VARCHAR(8000)
DECLARE @AcumuladoCoacreditadoFisica VARCHAR(8000)
DECLARE @FirmaCoacreditado VARCHAR(5000)
DECLARE @TituloCoacreditado VARCHAR(50)
--DECLARE @textoApoderadoIndividual VARCHAR(1000)
--
--CREATE TABLE #Claves(CLAVE VARCHAR(500), TEXTO VARCHAR(8000))

SET @COACREDITADO = ''
SET @APODCCREDITADO = ''
SET @CONSECUTIVO = 2
--SET @CveContrato =  '3316FF'
--SET @CveCliente = 8830
SET @DeclaracionCoacreditadoMoral = ''
SET @DeclaracionCoacreditadoFisica = ''
SET @indiceApoderadosCoacreditado = 0
SET @DeclaracionCoacreditadoMoralAcu = ''
SET @Contador = 0
SET @AcumuladoCoacreditadoFisica = ''
SET @FirmaCoacreditado = ''
set @textoApodAcuCoacreditado = ''

DECLARE @NomCoacreditado VARCHAR(MAX)
				SET @NomCoacreditado = ''
DECLARE @NomCoacreditadoAux VARCHAR(MAX)
				SET @NomCoacreditadoAux = ''
				

DECLARE  CURCOACREDITADOS CURSOR FOR

SELECT CP.PNA_FL_PERSONA,CP.PNA_CL_PJURIDICA,RTRIM(CP.PNA_DS_NOMBRE)
FROM CPERSONA CP
WHERE CP.PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
						FROM cprelacion 
						WHERE PRE_FL_PERSONA = @CveCliente--8830 
						AND PRE_FG_VALOR = 5
						AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
											FROM KCTO_ASIG_LEGAL_CLIENTE 
											WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 5))
ORDER BY  CP.PNA_CL_PJURIDICA,CP.PNA_FL_PERSONA


OPEN CURCOACREDITADOS
FETCH NEXT FROM CURCOACREDITADOS INTO @ClaveCoacreditado,@PJURIDICA,@NombreCoacreditado
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			
			IF @PJURIDICA = 2 OR @PJURIDICA = 1
				BEGIN
						----------------------------------------------------------
							print '-- DICTAMEN LEGAL DE PERSONA FÍSICA  -- '
						----------------------------------------------------------

						SELECT @DeclaracionCoacreditadoFisica= ' \pard\li320\qj 2.' + CONVERT(VARCHAR(3),@CONSECUTIVO) + ') ' + CPFISICA.PFI_DS_NOMBRE + ' ' + CPFISICA.PFI_DS_APATERNO + ' ' + CPFISICA.PFI_DS_AMATERNO + ' \par \par ' +
'{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16Es una persona física, de nacionalidad ' + NACIONALIDAD.PAR_DS_DESCRIPCION + '(a)' +
							', con plena capacidad para celebrar el presente contrato, con fecha de nacimiento ' +
							 CONVERT(VARCHAR(2), DAY(CPFISICA.PFI_FE_NACIMIENTO))+ ' de ' +
										CASE MONTH(CPFISICA.PFI_FE_NACIMIENTO)
											WHEN  1 THEN 'Enero'
											WHEN  2 THEN 'Febrero'
											WHEN  3 THEN 'Marzo'
											WHEN  4 THEN 'Abril'
											WHEN  5 THEN 'Mayo'
											WHEN  6 THEN 'Junio'
											WHEN  7 THEN 'Julio'
											WHEN  8 THEN 'Agosto'
											WHEN  9 THEN 'Septiembre'
											WHEN 10 THEN 'Octubre'
											WHEN 11 THEN 'Noviembre'
											WHEN 12 THEN 'Diciembre'
										END + ' de ' +
										CONVERT(VARCHAR(4), YEAR(CPFISICA.PFI_FE_NACIMIENTO)) +
							', originario de ' + PFI_DS_LNACIMIENTO + ', cuya ocupación es ' + OCUPACION.PAR_DS_DESCRIPCION + ', estado civil ' + ECIVIL.PAR_DS_DESCRIPCION +
							CASE  WHEN
								(ECIVIL.PAR_CL_VALOR=2)
							THEN
							' bajo el régimen ' + (SELECT PAR_DS_DESCRIPCION FROM CPARAMETRO WHERE PAR_FL_CVE=16 AND PAR_CL_VALOR=CPFISICA.PFI_FG_REGMAT)
							ELSE
								''
							END +
							' con Registro Federal de Causantes ' + RTRIM(LTRIM(CPERSONA.PNA_CL_RFC)) + 
CASE (SELECT COUNT(PNA_FL_PERSONA) FROM CDOMICILIO WHERE PNA_FL_PERSONA = @ClaveCoacreditado) WHEN 0 THEN '' ELSE 
' y domicilio en ' +
							CASE CDOMICILIO.DMO_DS_CALLE_NUM WHEN '' THEN '' ELSE ('CALLE ' + RTRIM(CDOMICILIO.DMO_DS_CALLE_NUM)) END
							+ CASE CDOMICILIO.DMO_DS_NUMEXT WHEN '' THEN '' ELSE (' NO. EXT. ' + RTRIM(CDOMICILIO.DMO_DS_NUMEXT)) END
							+ CASE CDOMICILIO.DMO_DS_NUMINT WHEN '' THEN ',' ELSE (' NO. INT. ' + RTRIM(CDOMICILIO.DMO_DS_NUMINT)+ ',') END
							+ CASE CDOMICILIO.DMO_DS_COLONIA WHEN '' THEN '' ELSE (' COLONIA ' + RTRIM(CDOMICILIO.DMO_DS_COLONIA) + ',') END
							+ CASE CDOMICILIO.DMO_DS_MUNICIPIO WHEN '' THEN '' ELSE (' ' + RTRIM(CDOMICILIO.DMO_DS_MUNICIPIO) + ',') END
							+ CASE CDOMICILIO.DMO_DS_EFEDERATIVA WHEN '' THEN '' ELSE (' ' + RTRIM(CDOMICILIO.DMO_DS_EFEDERATIVA) + ',') END 
							+ CASE CDOMICILIO.DMO_CL_CPOSTAL WHEN '' THEN '' ELSE (' C\''d3DIGO POSTAL ' + RTRIM(CDOMICILIO.DMO_CL_CPOSTAL) + '.') END
END + ' \par '
--							FROM CPFISICA, CPARAMETRO ECIVIL, CPARAMETRO NACIONALIDAD, CPARAMETRO OCUPACION, CPERSONA, CDOMICILIO
--							WHERE PFI_FG_EDO_CIVIL= ECIVIL.PAR_CL_VALOR
--							AND ECIVIL.PAR_FL_CVE=11
--							AND PFI_FG_NACIONALIDAD=NACIONALIDAD.PAR_CL_VALOR
--							AND NACIONALIDAD.PAR_FL_CVE=26
--							AND PFI_FG_OCUPACION=OCUPACION.PAR_CL_VALOR
--							AND OCUPACION.PAR_FL_CVE=15
--							AND CPFISICA.PNA_FL_PERSONA=CPERSONA.PNA_FL_PERSONA
--							AND CPERSONA.PNA_CL_PJURIDICA IN (2,1)
--							AND CPFISICA.PNA_FL_PERSONA=CDOMICILIO.PNA_FL_PERSONA
--							AND CDOMICILIO.DMO_FG_FACTURA = 1
--							AND CPERSONA.PNA_FL_PERSONA= @ClaveCoacreditado
FROM CPERSONA CPERSONA
INNER JOIN CPFISICA CPFISICA ON CPFISICA.PNA_FL_PERSONA=CPERSONA.PNA_FL_PERSONA
LEFT JOIN CDOMICILIO CDOMICILIO ON CPFISICA.PNA_FL_PERSONA = CDOMICILIO.PNA_FL_PERSONA AND	CDOMICILIO.DMO_FG_FACTURA = 1			
INNER JOIN CPARAMETRO NACIONALIDAD ON PFI_FG_NACIONALIDAD=NACIONALIDAD.PAR_CL_VALOR
INNER JOIN CPARAMETRO ECIVIL ON PFI_FG_EDO_CIVIL= ECIVIL.PAR_CL_VALOR
INNER JOIN CPARAMETRO OCUPACION ON PFI_FG_OCUPACION=OCUPACION.PAR_CL_VALOR
WHERE ECIVIL.PAR_FL_CVE=11		
AND	NACIONALIDAD.PAR_FL_CVE=26			
AND	OCUPACION.PAR_FL_CVE=15
AND	CPERSONA.PNA_CL_PJURIDICA IN (1,2)
AND CPERSONA.PNA_FL_PERSONA= @ClaveCoacreditado
						
						SET @AcumuladoCoacreditadoFisica = @AcumuladoCoacreditadoFisica + ' \par ' + @DeclaracionCoacreditadoFisica
						IF @CveTOperacion = 'AF' OR @CveTOperacion = 'NE'OR @CveTOperacion = 'FF' OR @CveTOperacion = 'AP'
							SET @FirmaCoacreditado = @FirmaCoacreditado + ' "ARRENDATARIA" \par \par \par \par ' + '__________________________ \par ' + @NombreCoacreditado + ' \par '
						ELSE
							SET @FirmaCoacreditado = @FirmaCoacreditado + ' "ACREDITADA" \par \par \par \par ' + '__________________________ \par ' + @NombreCoacreditado + ' \par '

						SET @CONSECUTIVO =  @CONSECUTIVO + 1

				END; -- Fin de ver si es persona fisica

		IF @PJURIDICA = 20         --  PERSONAS MORALES

			BEGIN
						----------------------------------------------------------
						print '-- OBTENGO SU DICTAMEN LEGAL 1 -- '
						----------------------------------------------------------
						
						SELECT @DeclaracionCoacreditadoMoral=' \pard\li320\qj\par 2.' + CONVERT(VARCHAR(3),@CONSECUTIVO) + ') ' + rtrim(@NombreCoacreditado) + ' \par \par ' +
						--** VIÑETAS MARREDONDO
							'{\pntext\f1 a)\tab}{\*\pn\pnlvlbody\pnf1\pnindent0\pnstart1\pnlcltr{\pntxta)}}\fi-400\li720\fs16Es una sociedad mercantil constituida de conformidad con las leyes mexicanas, según consta en la Escritura Pública número ' + 
							rtrim(cast(KESCRITURA.ESC_NO_ESCRITURA as varchar(12))) + ', de fecha '+ 
							CONVERT(VARCHAR(2), DAY(KESCRITURA.ESC_FE_ESCRITURA))+ ' de ' +
										CASE MONTH(KESCRITURA.ESC_FE_ESCRITURA)
											WHEN  1 THEN 'Enero'
											WHEN  2 THEN 'Febrero'
											WHEN  3 THEN 'Marzo'
											WHEN  4 THEN 'Abril'
											WHEN  5 THEN 'Mayo'
											WHEN  6 THEN 'Junio'
											WHEN  7 THEN 'Julio'
											WHEN  8 THEN 'Agosto'
											WHEN  9 THEN 'Septiembre'
											WHEN 10 THEN 'Octubre'
											WHEN 11 THEN 'Noviembre'
											WHEN 12 THEN 'Diciembre'
										END + ' de ' +
										CONVERT(VARCHAR(4), YEAR(KESCRITURA.ESC_FE_ESCRITURA)) +
							', otorgada ante la fe del Notario Público número ' + RTRIM(CAST(CNOTARIO.NOT_NO_NOTARIO AS varchar(10))) + ', de ' +
							CCIUDAD.CIU_NB_CIUDAD + ' ' + CEFEDERATIVA.EFD_DS_ENTIDAD + ', Licenciado ' + CNOTARIO.NOT_DS_NOMBRE + ' ' + CNOTARIO.NOT_DS_APATERNO + ' ' + CNOTARIO.NOT_DS_AMATERNO +
							', cuyo primer testimonio quedó inscrito en el Registro Público de la Propiedad y del Comercio de ' 

, @ESC_DS_CIUDAD = KESCRITURA.ESC_DS_CIUDAD , @DeclaracionCoacreditadoMoral1 =
--+ KESCRITURA.ESC_DS_CIUDAD +
 
							', bajo el Número ' + RTRIM(LTRIM(KESCRITURA.ESC_DS_REGISTRO)) 
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO)) = '')) THEN ''  ELSE (' folio ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_FOLIO))) END					
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) = '')) THEN ''  ELSE ' a folios ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_FOJAS)) END
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) = '')) THEN ''  ELSE ', del Libro numero ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_LIBRO)) END 
							+ CASE WHEN ((LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) = '')) THEN ''  ELSE ', de la Seccion ' + LTRIM(RTRIM(KESCRITURA.ESC_DS_SECCION)) END 
							+ ', el ' + CONVERT(VARCHAR(2), DAY(KESCRITURA.ESC_FE_INSCRITA))+ ' de ' +
								CASE MONTH(KESCRITURA.ESC_FE_INSCRITA)
													WHEN  1 THEN 'Enero'
													WHEN  2 THEN 'Febrero'
													WHEN  3 THEN 'Marzo'
													WHEN  4 THEN 'Abril'
													WHEN  5 THEN 'Mayo'
													WHEN  6 THEN 'Junio'
													WHEN  7 THEN 'Julio'
													WHEN  8 THEN 'Agosto'
													WHEN  9 THEN 'Septiembre'
													WHEN 10 THEN 'Octubre'
													WHEN 11 THEN 'Noviembre'
													WHEN 12 THEN 'Diciembre'
												END + ' de ' +
												CONVERT(VARCHAR(4), YEAR(KESCRITURA.ESC_FE_INSCRITA))+ + '.' +
						'\par Que su domicilio es en ' + --@DirecCoacreditado
(SELECT	TOP 1 CASE DMO_DS_CALLE_NUM WHEN '' THEN '' ELSE ('CALLE ' + RTRIM(DMO_DS_CALLE_NUM)) END
						+ CASE DMO_DS_NUMEXT WHEN '' THEN '' ELSE (' NO. EXT. ' + RTRIM(DMO_DS_NUMEXT)) END
						+ CASE DMO_DS_NUMINT WHEN '' THEN ',' ELSE (' NO. INT. ' + RTRIM(DMO_DS_NUMINT) + ',') END
						+ CASE DMO_DS_COLONIA WHEN '' THEN '' ELSE (' COLONIA ' + RTRIM(DMO_DS_COLONIA)) END						
						+ CASE DMO_DS_MUNICIPIO WHEN '' THEN ',' ELSE (' ' + RTRIM(DMO_DS_MUNICIPIO) + ',') END
						+ CASE DMO_DS_EFEDERATIVA WHEN '' THEN ',' ELSE (' ' + RTRIM(DMO_DS_EFEDERATIVA)) END
					+ CASE DMO_CL_CPOSTAL WHEN '' THEN ',' ELSE (' C\''d3DIGO POSTAL ' + RTRIM(DMO_CL_CPOSTAL) + ',') END
FROM         CDOMICILIO
WHERE     (DMO_FG_FACTURA = 1) AND (PNA_FL_PERSONA = @ClaveCoacreditado) ORDER BY DMO_FG_TDIRECCION ASC)
						 + ' y su RFC ' + (SELECT CPERSONA.PNA_CL_RFC FROM CPERSONA WHERE PNA_FL_PERSONA = @ClaveCoacreditado)
						FROM    KESCRITURA,	CEFEDERATIVA, CCIUDAD, CNOTARIO
									WHERE KESCRITURA.NOT_FL_CVE = CNOTARIO.NOT_FL_CVE
									AND CNOTARIO.EFD_CL_CVE = CEFEDERATIVA.EFD_CL_CVE
									AND	CNOTARIO.EFD_CL_CVE = CCIUDAD.EFD_CL_CVE
									AND CNOTARIO.CIU_CL_CIUDAD = CCIUDAD.CIU_CL_CIUDAD
									AND	CEFEDERATIVA.EFD_CL_CVE = CCIUDAD.EFD_CL_CVE
									AND  (KESCRITURA.PNA_FL_PERSONA  = @ClaveCoacreditado)
									AND KESCRITURA.ESC_CL_TESCRITURA IN(1,5)-- ESCRITURAS (1)-CONSTITUTIVAS    (5)MIXTAS
									--CORRECCION DE ESCRITURAS ASIGNADAS
									AND KESCRITURA.ESC_FL_CVE IN (SELECT ESC_FL_CVE FROM KCTO_ASIG_LEGAL_ESCRITURA WHERE CTO_FL_CVE = @CveContrato)
									--FIN CORRECCION DE ESCRITURAS ASIGNADAS

EXEC lsntReplace @ESC_DS_CIUDAD, @ESC_DS_CIUDAD output 
SET @DeclaracionCoacreditadoMoral = @DeclaracionCoacreditadoMoral + @ESC_DS_CIUDAD + @DeclaracionCoacreditadoMoral1												

						SET @Declaraciones = '? \par ' + @Declaraciones


						--VAMOS POR LOS APODERADOS
						SET @indiceApoderadosCoacreditado=99
						SET @textoApodAcuCoacreditado = ''--' \par ' AHORITA

						IF @CveTOperacion = 'AF' OR @CveTOperacion = 'NE'OR @CveTOperacion = 'FF' OR @CveTOperacion = 'AP'
							SET @FirmaCoacreditado = @FirmaCoacreditado + ' \par "ARRENDATARIA" \par ' + @NombreCoacreditado + ' \par \par '
						ELSE
							SET @FirmaCoacreditado = @FirmaCoacreditado + ' \par "ACREDITADA" \par ' + @NombreCoacreditado + ' \par \par '
--						DECLARE @ClaveApoderado INT

						DECLARE curDatosApoderado CURSOR FOR
						SELECT PNA_DS_NOMBRE,PNA_FL_PERSONA 
						FROM CPERSONA  
						WHERE PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
												FROM cprelacion 	
												WHERE PRE_FL_PERSONA = @ClaveCoacreditado 
												AND PRE_FG_VALOR = 4 
												AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
																		FROM KCTO_ASIG_LEGAL_CLIENTE 
																		WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 4))
												

						OPEN curDatosApoderado
						FETCH NEXT FROM curDatosApoderado INTO @apoderadoCliente, @ClaveApoderado
							WHILE (@@FETCH_STATUS = 0)
								BEGIN
									--SET @textoApoIndColacreditado =	(SELECT  TOP 1 RTRIM(LTRIM((SELECT PNA_DS_NOMBRE FROM CPERSONA  WHERE PNA_FL_PERSONA = @ClaveApoderado))) + 
		SELECT  TOP 1 @textoApoIndColacreditado = RTRIM(LTRIM((SELECT PNA_DS_NOMBRE FROM CPERSONA  WHERE PNA_FL_PERSONA = @ClaveApoderado))) + 
											' posee plena capacidad legal y poderes para celebrar el presente contrato en su representación, ' +
											'obligándola en los términos del mismo, acreditando su personalidad con la escritura pública número ' + rtrim(cast(KE.ESC_NO_ESCRITURA as varchar(12))) + ', ' +
											'de fecha ' + CONVERT(VARCHAR(2), DAY(KE.ESC_FE_ESCRITURA))+ ' de ' +
												CASE MONTH(KE.ESC_FE_ESCRITURA)
													WHEN  1 THEN 'Enero'
													WHEN  2 THEN 'Febrero'
													WHEN  3 THEN 'Marzo'
													WHEN  4 THEN 'Abril'
													WHEN  5 THEN 'Mayo'
													WHEN  6 THEN 'Junio'
													WHEN  7 THEN 'Julio'
													WHEN  8 THEN 'Agosto'
													WHEN  9 THEN 'Septiembre'
													WHEN 10 THEN 'Octubre'
													WHEN 11 THEN 'Noviembre'
													WHEN 12 THEN 'Diciembre'
												END + ' de ' +
												CONVERT(VARCHAR(4), YEAR(KE.ESC_FE_ESCRITURA))+ ', otorgada ante la fe del notario público número ' + RTRIM(CAST(CN.NOT_NO_NOTARIO AS varchar(10))) + 
											' de ' + CC.CIU_NB_CIUDAD + ', ' + CE.EFD_DS_ENTIDAD + ', e inscrita en el Registro Público de la Propiedad y del Comercio de ' 

, @ESC_DS_CIUDAD = KE.ESC_DS_CIUDAD , @textoApoIndColacreditado1 = 
--+ KE.ESC_DS_CIUDAD + 
						', ' +	'bajo el folio mercantil número ' + LTRIM(RTRIM(KE.ESC_DS_REGISTRO)) 
--+ ', Sección ' + LTRIM(RTRIM(KE.ESC_DS_SECCION)) 
+ CASE WHEN ((LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '0') OR(LTRIM(RTRIM(KE.ESC_DS_SECCION)) = '')) THEN ''  ELSE (', Secci\''f3n ' + LTRIM(RTRIM(KE.ESC_DS_SECCION))) END 
+ ' el ' + CONVERT(VARCHAR(2), DAY(KE.ESC_FE_INSCRITA))+ ' de ' +
												CASE MONTH(KE.ESC_FE_INSCRITA)
													WHEN  1 THEN 'Enero'
													WHEN  2 THEN 'Febrero'
													WHEN  3 THEN 'Marzo'
													WHEN  4 THEN 'Abril'
													WHEN  5 THEN 'Mayo'
													WHEN  6 THEN 'Junio'
													WHEN  7 THEN 'Julio'
													WHEN  8 THEN 'Agosto'
													WHEN  9 THEN 'Septiembre'
													WHEN 10 THEN 'Octubre'
													WHEN 11 THEN 'Noviembre'
													WHEN 12 THEN 'Diciembre'
												END + ' de ' +
												CONVERT(VARCHAR(4), YEAR(KE.ESC_FE_INSCRITA)) + ', poder que no le ha sido revocado ni limitado en forma alguna. '
									FROM CPERSONA CP 
									INNER JOIN KESCRITURA KE ON KE.PNA_FL_PERSONA = CP.PNA_FL_PERSONA
									INNER JOIN CNOTARIO CN ON CN.NOT_FL_CVE = KE.NOT_FL_CVE
									INNER JOIN CEFEDERATIVA CE ON CE.EFD_CL_CVE = CN.EFD_CL_CVE
									INNER JOIN CCIUDAD  CC ON CC.CIU_CL_CIUDAD = CN.CIU_CL_CIUDAD AND CC.EFD_CL_CVE = CN.EFD_CL_CVE
									WHERE CP.PNA_FL_PERSONA = @ClaveCoacreditado--@CveCliente
									AND KE.ESC_CL_TESCRITURA IN(4,5)-- ESCRITURAS (4)-PODERES    (5)MIXTAS)
									--CORRECCION DE ESCRITURAS ASIGNADAS
									AND KE.ESC_FL_CVE IN (SELECT ESC_FL_CVE FROM KCTO_ASIG_LEGAL_ESCRITURA WHERE CTO_FL_CVE = @CveContrato)--)
									--FIN CORRECCION DE ESCRITURAS ASIGNADAS

EXEC lsntReplace @ESC_DS_CIUDAD, @ESC_DS_CIUDAD output 
SET @textoApoIndColacreditado = @textoApoIndColacreditado + @ESC_DS_CIUDAD + @textoApoIndColacreditado1

									--** INICIO VIÑETAS MARREDONDO **--
									SET @textoApodAcuCoacreditado = @textoApodAcuCoacreditado + '\par ' + @textoApoIndColacreditado + ' \par'-- \par '
									--SET @textoApodAcuCoacreditado = @textoApodAcuCoacreditado +  '\par ' + char(@indiceApoderadosCoacreditado) + ') ' + @textoApoIndColacreditado + ' \par \par ' 
									--** FIN VIÑETAS MARREDONDO **--									
									SET @indiceApoderadosCoacreditado = @indiceApoderadosCoacreditado + 1
									--vamos armando la tabla de los obligados solidarios
									SET @FirmaCoacreditado = @FirmaCoacreditado + ' \par \par __________________________ \par ' + @apoderadoCliente + ' \par \par'
									SET @Contador=@Contador+1	
									
										FETCH NEXT FROM curDatosApoderado INTO @apoderadoCliente, @ClaveApoderado					
									END		
									CLOSE curDatosApoderado
									DEALLOCATE curDatosApoderado
					SET @CONSECUTIVO =  @CONSECUTIVO + 1
									--** INICIO VIÑETAS MARREDONDO **--
										SET @DeclaracionCoacreditadoMoralAcu = @DeclaracionCoacreditadoMoralAcu + @DeclaracionCoacreditadoMoral + @textoApodAcuCoacreditado
										--SET @DeclaracionCoacreditadoMoralAcu = @DeclaracionCoacreditadoMoralAcu + ' \par ' + @DeclaracionCoacreditadoMoral + ' \par '+ @textoApodAcuCoacreditado
									--** FIN VIÑETAS MARREDONDO **--
					
			END	
	IF @NomCoacreditado <> ''
	BEGIN
		SET @NomCoacreditado = @NomCoacreditado + ', ' + @NombreCoacreditado
		SET @NomCoacreditadoAux = @NomCoacreditadoAux + ',' + @NombreCoacreditado
	END
	ELSE
	BEGIN
		SET @NomCoacreditado = ', ' + @NombreCoacreditado
		SET @NomCoacreditadoAux = @NombreCoacreditado
	END
	
		FETCH NEXT FROM CURCOACREDITADOS INTO @ClaveCoacreditado,@PJURIDICA,@NombreCoacreditado
	END		
	CLOSE CURCOACREDITADOS
	DEALLOCATE CURCOACREDITADOS
	

				--IF @CONSECUTIVO > 2 
				--	BEGIN
						--SET @FirmaCoacreditado = '"COACREDITADO"' + @FirmaCoacreditado
						--Se cambia la palabra a ARRENDATARIA ya que así debe aparecer en el contrato aunque sea Coacreditado
				--		SET @FirmaCoacreditado = '"ARRENDATARIA"' + @FirmaCoacreditado						
				--	END

				EXEC lsntReplace @FirmaCoacreditado, @FirmaCoacreditado output   --> CAMBIO CARACTERES ESPECIALES
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%FirmaCoacreditado%]',' \b ' + @FirmaCoacreditado + ' \b0 ')

--				DECLARE @NomCoacreditado VARCHAR(100)
--				SET @NomCoacreditado = ''
--				IF @NombreCoacreditado <> ''
--				BEGIN
--				SET @NomCoacreditado = ', ' + @NombreCoacreditado
--				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NombreCoacreditado%]',@NombreCoacreditado)
--				END
--				ELSE
--				BEGIN
--				SET @NombreCoacreditado = ''
--				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NombreCoacreditado%]',@NombreCoacreditado)
--				END
--				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NomCoacreditado%]',@NomCoacreditado)
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NombreCoacreditado%]',@NomCoacreditadoAux)
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%NomCoacreditado%]',@NomCoacreditado)	
			
				EXEC lsntReplace @AcumuladoCoacreditadoFisica, @AcumuladoCoacreditadoFisica output   --> CAMBIO CARACTERES ESPECIALES						
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%DeclaracionCoacreditadoFisica%]', @AcumuladoCoacreditadoFisica)

				EXEC lsntReplace @DeclaracionCoacreditadoMoralAcu, @DeclaracionCoacreditadoMoralAcu output   --> CAMBIO CARACTERES ESPECIALES
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%DeclaracionCoacreditadoMoral%]', @DeclaracionCoacreditadoMoralAcu)
				EXEC lsntReplace @textoApodAcuCoacreditado, @textoApodAcuCoacreditado output   --> CAMBIO CARACTERES ESPECIALES
				INSERT INTO #Claves(CLAVE, TEXTO) VALUES('[%ApoderadosCoacreditados%]', @textoApodAcuCoacreditado)
----********************************TERMINA COACREDITADOS************************
--****************************INICIA CIE
DECLARE @NoCIE AS VARCHAR(6)
SET @NoCIE = ISNULL((SELECT TOP 1 convert(varchar,CPP_DS_REFERENCIA)+convert(varchar,CPP_NO_DIGVERIF)
							FROM KCTO_CTASPAGO WHERE PNA_FL_PERSONA = @CveCliente ),'')
INSERT INTO #Claves VALUES ('[%NoCIE%]',@NoCIE)
--****************************TERMINA CIE
--****************************INICIA PENA PREPAGO
DECLARE @penaPrepago AS NUMERIC(13,2)
SET @penaPrepago = 0.0
	SELECT @penaPrepago = ISNULL(KPR_NO_TASA_PREPAGO,0) FROM KCONTRATO A 
						LEFT JOIN KPROPUESTA_COMPLEMENTO B ON A.KPR_FL_CVE = B.KPR_FL_CVE
						WHERE A.CTO_FL_CVE = @CveContrato
INSERT INTO #Claves VALUES ('[%penaPrepago%]',CONVERT(VARCHAR(15),@penaPrepago) + ' %')
--****************************TERMINA PENA PREPAGO


/************************Seccion MEGA ***************************/
Insert into #Claves values ('[%FechaOperacion%]','')
Insert into #Claves values ('[%RazonSocial%]','')
Insert into #Claves values ('[%CalleMoral%]','')
Insert into #Claves values ('[%NumExtMoral%]','')
Insert into #Claves values ('[%ColoniaMoral%]','')
Insert into #Claves values ('[%CiudadMoral%]','')
Insert into #Claves values ('[%EFedMoral%]','')
Insert into #Claves values ('[%CPMoral%]','')
Insert into #Claves values ('[%RFCMoral%]','')
Insert into #Claves values ('[%CorreoMoral1%]','')
Insert into #Claves values ('[%CorreoMoral2%]','')
Insert into #Claves values ('[%CorreoMoral3%]','')
Insert into #Claves values ('[%NoEscritura%]','')
Insert into #Claves values ('[%FechaEscritura%]','')
Insert into #Claves values ('[%NombreNotario%]','')
Insert into #Claves values ('[%NumNotario%]','')
Insert into #Claves values ('[%CiudadNotario%]','')
Insert into #Claves values ('[%NoFolio%]','')
Insert into #Claves values ('[%NoVolumen%]','')
Insert into #Claves values ('[%NoRegistro%]','')
Insert into #Claves values ('[%NoFojas%]','')
Insert into #Claves values ('[%NoTomo%]','')
Insert into #Claves values ('[%NoLibro%]','')
Insert into #Claves values ('[%CiudadInscrita%]','')
Insert into #Claves values ('[%NoSeccion%]','')
Insert into #Claves values ('[%FechaInscrita%]','')
Insert into #Claves values ('[%RegistroEsc%]','')
Insert into #Claves values ('[%RepresentanteLegal%]','')
Insert into #Claves values ('[%IdApoderado%]','')
Insert into #Claves values ('[%RegistroPublico%]','')
Insert into #Claves values ('[%FechaRegistroPublico%]','')
Insert into #Claves values ('[%DelRegistro%]','')
Insert into #Claves values ('[%NumPoder%]','')
Insert into #Claves values ('[%FechaPoder%]','')
Insert into #Claves values ('[%NotarioPoder%]','')
Insert into #Claves values ('[%NumNotarioPoder%]','')
Insert into #Claves values ('[%CiudadPoder%]','')
Insert into #Claves values ('[%RegistroPoder%]','')
Insert into #Claves values ('[%ObjetoSocial%]','')
Insert into #Claves values ('[%CalleCliente%]','')
Insert into #Claves values ('[%NumCalleCliente%]','')
Insert into #Claves values ('[%ColoniaCliente%]','')
Insert into #Claves values ('[%CiudadCliente%]','')
Insert into #Claves values ('[%EstadoCliente%]','')
Insert into #Claves values ('[%CPCliente%]','')
Insert into #Claves values ('[%RFCCliente%]','')
Insert into #Claves values ('[%NumInt%]', '')
Insert into #Claves values ('[%NombrePFisica%]','')
Insert into #Claves values ('[%LugarNacPFisica%]','')
Insert into #Claves values ('[%FechaNacPFisica%]','')
Insert into #Claves values ('[%OcupacionPFisica%]','')
Insert into #Claves values ('[%EdoCivilPFisica%]','')
Insert into #Claves values ('[%RegimenPFisica%]','')
Insert into #Claves values ('[%DomicilioPFisica%]','')
Insert into #Claves values ('[%IdentificacionPFisica%]','')
Insert into #Claves values ('[%CorreoPFisica1%]','')
Insert into #Claves values ('[%CorreoPFisica2%]','')
Insert into #Claves values ('[%CorreoPFisica3%]','')
Insert into #Claves values ('[%FechaInicio%]','')
Insert into #Claves values ( '[%ProductosContrato%]','')
Insert into #Claves values ('[%MarcaCoche%]','')
Insert into #Claves values ('[%SubSerie%]','')
Insert into #Claves values ('[%AhoCoche%]','')
Insert into #Claves values ('[%ClaseCoche%]','')
Insert into #Claves values ('[%ModeloCoche%]','')
Insert into #Claves values ('[%CapacidadCoche%]','')
Insert into #Claves values ('[%NoSerieCoche%]','')
Insert into #Claves values ('[%NoMotorCoche%]','')
Insert into #Claves values ('[%CaractCoche%]','')
Insert into #Claves values ('[%UsoCoche%]','')
Insert into #Claves values ('[%KmCoche%]','')
Insert into #Claves values ('[%CaractSeguroCoche%]','')
Insert into #Claves values ('[%LugarFechaEntregaCoche%]','')
Insert into #Claves values ('[%EquipoMedico%]','')
Insert into #Claves values ('[%MarcaMedico%]','')
Insert into #Claves values ('[%CaractMedico%]','')
Insert into #Claves values ('[%UsoMedico%]','')
Insert into #Claves values ('[%LugarFechaEntregaMedico%]','')
Insert into #Claves values ('[%CaractSeguroMedico%]','')
Insert into #Claves values ('[%MontoVencimientoSinIva%]','')
Insert into #Claves values ('[%FechaVencimiento%]','')
Insert into #Claves values ('[%AnticipoEnganche%]','')
Insert into #Claves values ('[%DepositoAdicional%]','')
Insert into #Claves values ('[%Avales%]','')
Insert into #Claves values ('[%NombresAvales%]','')
Insert into #Claves values ('[%AvalesNombDirec%]','')
Insert into #Claves values ('[%NombreAvalPFisica%]','')
Insert into #Claves values ('[%LugarNacAvalPFisica%]','')
Insert into #Claves values ('[%FechaNacAvalPFisica%]','')
Insert into #Claves values ('[%OcupacionAvalPFisica%]','')
Insert into #Claves values ('[%EdoCivilAvalPFisica%]','')
Insert into #Claves values ('[%RFCAvalPFisica%]','')
Insert into #Claves values ('[%DomicilioAvalPFisica%]','')
Insert into #Claves values ('[%RegAvalPFisica%]','')
Insert into #Claves values ('[%IdentificacionAvalPFisica%]','')
Insert into #Claves values ('[%CorreoAvalPFisica1%]','')
Insert into #Claves values ('[%CorreoAvalPFisica2%]','')
Insert into #Claves values ('[%CorreoAvalPFisica3%]','')
Insert into #Claves values ('[%NacionalidadAvalPFisica%]','')
Insert into #Claves values ('[%NombreAvalPMoral%]','')
Insert into #Claves values ('[%CalleAvalPMoral%]','')
Insert into #Claves values ('[%NumCalleAvalPMoral%]','')
Insert into #Claves values ('[%ColoniaAvalPMoral%]','')
Insert into #Claves values ('[%CiudadAvalPMoral%]','')
Insert into #Claves values ('[%EstadoAvalPMoral%]','')
Insert into #Claves values ('[%CPAvalPMoral%]','')
Insert into #Claves values ('[%RFCAvalPMoral%]','')
Insert into #Claves values ('[%CorreoAvalPMoral1%]','')
Insert into #Claves values ('[%CorreoAvalPMoral2%]','')
Insert into #Claves values ('[%CorreoAvalPMoral3%]','')
Insert into #Claves values ('[%NumEscAvalPMoral%]','')
Insert into #Claves values ('[%FechaEscAvalPMoral%]','')
Insert into #Claves values ('[%NotarioAvalPMoral%]','')
Insert into #Claves values ('[%NumNotarioAvalPMoral%]','')
Insert into #Claves values ('[%CiudadEscAvalPMoral%]','')
Insert into #Claves values ('[%RegistroEscAvalPMoral%]','')
Insert into #Claves values ('[%ApoderadoAvalPMoral%]','')
Insert into #Claves values ('[%IdentificacionApoderadoAvalPMoral%]','')
Insert into #Claves values ('[%NumPoderAvalPMoral%]','')
Insert into #Claves values ('[%FechaPoderAvalPMoral%]','')
Insert into #Claves values ('[%NotarioPoderAvalPMoral%]','')
Insert into #Claves values ('[%NumNotarioPoderAvalPMoral%]','')
Insert into #Claves values ('[%CiudadPoderAvalPMoral%]','')
Insert into #Claves values ('[%RegistroPoderAvalPMoral%]','')
Insert into #Claves values ('[%ObjetoSocialAvalPMoral%]','')
Insert into #Claves values ('[%AseguradoPolizaVida%]','')
Insert into #Claves values ('[%TipoProducto%]','')
Insert into #Claves values ('[%ReferenciaPago%]','')
Insert into #Claves values ('[%RepresentantesEmpresa%]','')
Insert into #Claves values ('[%FirmasCliente%]','')
Insert into #Claves values ('[%FirmasAvales%]','')
Insert into #Claves values ('[%FirmasAvalesD%]','')
Insert into #Claves values ('[%DomicilioCliente%]','')
Insert into #Claves values ('[%DomicilioAval%]','')
Insert into #Claves values ('[%NumIFE%]','')
Insert into #Claves values ('[%FechaFirmaContrato%]','')
Insert into #Claves values ('[%montoCapitalLetra%]','')
Insert into #Claves values ('[%tablaPagare%]','')
Insert into #Claves values ('[%DeclaraArrendataria%]','')
Insert into #Claves values ('[%DeclaraAvales%]','')
Insert into #Claves values ('[%PrimeraClausula%]','')
Insert into #Claves values ('[%DepositoComision%]','')
Insert into #Claves values ('[%CuartaClausulaBancomer%]','A ')
Insert into #Claves values ('[%CuartaClausulaFifomi%]','A ')
Insert into #Claves values ('[%CuartaClausulaHSBC%]','A ')
Insert into #Claves values ('[%CuartaClausulaInbursa%]','A ')
Insert into #Claves values ('[%ClausulaEnvioEdoCta%]','')
Insert into #Claves values ('[%SeptimaClausula%]','')
Insert into #Claves values ('[%OctavaClausula%]','')
Insert into #Claves values ('[%OctavaClausulaSegVida%]','')
Insert into #Claves values ('[%DecimaCuartaClausula%]','')
Insert into #Claves values ('[%DecimoOctavaClausula%]','')
Insert into #Claves values ('[%DescripcionBienes%]','')
Insert into #Claves values ('[%MontoOpcionCompra%]','')
Insert into #Claves values ('[%NombreProducto%]','')
Insert into #Claves values ('[%MarcaProd%]','')
Insert into #Claves values ('[%AhoProd%]','')
Insert into #Claves values ('[%ClaseProd%]','')
Insert into #Claves values ('[%ModeloProd%]','')
Insert into #Claves values ('[%CapacidadProd%]','')
Insert into #Claves values ('[%NoSerieProd%]','')
Insert into #Claves values ('[%NoMotorProd%]','')
Insert into #Claves values ('[%CEspecialProd%]','')
Insert into #Claves values ('[%UsoProd%]','')
Insert into #Claves values ('[%KmProd%]','')
Insert into #Claves values ('[%Fecha1OPC%]','')
Insert into #Claves values ('[%Fecha2OPC%]','')
Insert into #Claves values ('[%LeyendaPlazo%]','')
Insert into #Claves values ('[%FechaPrimerPago%]','')
Insert into #Claves values ('[%FechaUltimoPago%]','')
Insert into #Claves values ('[%Comision%]','')
Insert into #Claves values ('[%Gastos%]','')
Insert into #Claves values ('[%PrimeraRenta%]','')
Insert into #Claves values ('[%PrimerPagoP%]','')
Insert into #Claves values ('[%PrimeraRentaLetra%]','')
Insert into #Claves values ('[%RentaEnDeposito%]','')
Insert into #Claves values ('[%Apertura%]','')
Insert into #Claves values ('[%Celebracion%]','')
Insert into #Claves values ('[%ServAdmon%]','')
Insert into #Claves values ('[%RentaAnt%]','')
Insert into #Claves values ('[%MontoCapital+Interes%]','')
insert into #Claves values ('[%MontoCapitalSoloLetra%]','')
insert into #Claves values ('[%MontoOpcionCompraLetra%]','')
insert into #Claves values ('[%MontoOpCompra+Intereses%]','')
insert into #CLAVES values ('[%TelefonoCliente%]','')
insert into #CLAVES values ('[%TelefonoOficina%]','')
insert into #CLAVES values ('[%FAXOtro%]','')
insert into #CLAVES values ('[%TelefonoOficinaSE%]','')
insert into #CLAVES values ('[%ExtOf%]','')
Insert into #Claves values ('[%DescripcionBienesA%]','')
Insert into #CLAVES values ('[%ClausulaFiadores%]','')
Insert into #Claves values ('[%CondicionesContrato%]','')
Insert into #Claves values ('[%EscrituraRepLegal%]','')
Insert into #Claves values ('[%BancosVentaPlazos%]','')


--Obtenemos los valores 
Declare @VariableNumero int
Declare @VariableNumero2 int
Declare @VariableNumero3 int
Declare @VariableNumero4 int
Declare @VariableFecha datetime
Declare @VariableFecha2 datetime
Declare @VariableTexto varchar(1000)
Declare @VariableTexto1 varchar(200)
Declare @VariableTexto2 varchar(200)
Declare @VariableTexto3 varchar(200)
Declare @VariableTexto4 varchar(200)
Declare @VariableTexto5 varchar(200)
Declare @VariableTexto6 varchar(200)
Declare @VariableTexto7 varchar(200)
Declare @VariableTexto8 varchar(200)
Declare @FechaTexto varchar(50)
Declare @VariableTextoLarga char(8000)
Declare @VariableTextoLarga1 char(8000)
Declare @VariableTextoLarga2 char(8000)

Declare @TipoProducto int
Declare @intContador int
DECLARE @SeccionTabla varchar(1000)
DECLARE @SeccionTabla2 varchar(1000)
DECLARE @SeccionTabla3 varchar(500)
DECLARE @SeccionTabla4 varchar(1000)
DECLARE @SeccionTabla5 varchar(1000)
SET @VariableNumero = 0
SET @VariableFecha = '19000101'
SET @VariableTexto =  ''
SET @VariableTexto1 =  ''
SET @VariableTexto2 =  ''
SET @VariableTexto3 =  ''
SET @VariableTexto4 =  ''
SET @VariableTexto5 =  ''
SET @VariableTexto6 =  ''
SET @intContador = 0

Select @TipoProducto = A.TPR_FL_CVE 
FROM CTPRODUCTO A INNER JOIN CPRODUCTO B ON A.TPR_FL_CVE= B.TPR_FL_CVE 
INNER JOIN KPRODUCTO_FACTURA C ON B.PRD_FL_CVE = C.PRD_FL_CVE 
WHERE C.CTO_FL_CVE=@CveContrato
ORDER BY C.KPF_NO_TOTAL DESC 

Select @VariableFecha = fec_fe_operacion from cfecha_operacion
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaOperacion%]'



EXEC lsntReplace @VariableTexto3, @VariableTexto3 output
 

Select @VariableTexto= A.DMO_DS_CALLE_NUM,@VariableTexto1=A.DMO_DS_NUMEXT ,@VariableTexto2=A.DMO_DS_COLONIA,
@VariableTexto3=A.DMO_DS_CIUDAD,@VariableTexto4=A.DMO_DS_EFEDERATIVA,@VariableTexto5=A.DMO_CL_CPOSTAL,
@VariableTexto6= B.PNA_CL_RFC, @VariableTexto8 = A.DMO_DS_NUMINT
FROM CDOMICILIO A INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA
WHERE B.PNA_FL_PERSONA = @CveCliente and DMO_FG_REGDEFAULT = 1



EXEC lsntReplace @VariableTexto3, @VariableTexto3 output


UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CalleCliente%]'
UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%NumCalleCliente%]'
UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%ColoniaCliente%]'
UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%CiudadCliente%]'
UPDATE #Claves SET TEXTO= @VariableTexto4 WHERE CLAVE='[%EstadoCliente%]'
UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CPCliente%]'
UPDATE #Claves SET TEXTO= @VariableTexto6 WHERE CLAVE='[%RFCCliente%]'
UPDATE #CLAVES SET TEXTO= @VariableTexto8 WHERE CLAVE='[%NumInt%]'


set @VariableTexto7 =''

set @VariableTexto7 = @VariableTexto + ' ' + @VariableTexto1 + ', ' + @VariableTexto8 + ', ' + @VariableTexto2 + ', C.P.' + @VariableTexto5
+ ', ' + @VariableTexto3 + ', ' + ' ' + @VariableTexto4
 
EXEC lsntReplace @VariableTexto7, @VariableTexto7 output 

UPDATE #Claves SET TEXTO= @VariableTexto7 
WHERE CLAVE='[%DomicilioPFisica%]'

print @VariableTexto7
UPDATE #Claves SET TEXTO= @VariableTexto7
WHERE CLAVE='[%DomicilioCliente%]'

set @VariableTexto=''
Select  TOP 1 @VariableTexto= ISNULL(TFN_CL_LARGA_DISTANCIA ,' ')+ 
CASE WHEN TFN_CL_LADA IS NOT NULL THEN '('+RTRIM(TFN_CL_LADA) +')' 
ELSE ' ' END + TFN_CL_TELEFONO + CASE WHEN TFN_CL_EXTENSION IS NOT NULL 
and LEN (RTRIM(ltrim(TFN_CL_EXTENSION)))>0 THEN ' EXT. ' + RTRIM(TFN_CL_EXTENSION)
 ELSE ' ' END 
FROM CDOMICILIO A INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA
INNER JOIN CTELEFONO CT ON CT.DMO_FL_CVE= A.DMO_FL_CVE 
WHERE B.PNA_FL_PERSONA = @CveCliente and DMO_FG_REGDEFAULT = 1
and ttl_fl_cve = 2
ORDER BY CT.TFN_FL_CVE ASC



UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelefonoCliente%]'

set @VariableTexto=''
set @VariableTexto1=''
set @VariableTexto2=''
Select  TOP 1 @VariableTexto= ISNULL(TFN_CL_LARGA_DISTANCIA ,' ')+ 
CASE WHEN TFN_CL_LADA IS NOT NULL THEN '('+RTRIM(TFN_CL_LADA) +')' 
ELSE ' ' END + TFN_CL_TELEFONO + CASE WHEN TFN_CL_EXTENSION IS NOT NULL 
and LEN (RTRIM(ltrim(TFN_CL_EXTENSION)))>0 THEN '\tab EXT. ' + RTRIM(TFN_CL_EXTENSION)
 ELSE ' ' END ,

 @VariableTexto1= ISNULL(TFN_CL_LARGA_DISTANCIA ,' ')+ 
CASE WHEN TFN_CL_LADA IS NOT NULL THEN '('+RTRIM(TFN_CL_LADA) +')' 
ELSE ' ' END + TFN_CL_TELEFONO ,

@VariableTexto2=  CASE WHEN TFN_CL_EXTENSION IS NOT NULL 
and LEN (RTRIM(ltrim(TFN_CL_EXTENSION)))>0 THEN 'EXT. ' + RTRIM(TFN_CL_EXTENSION)
ELSE ' ' END 
FROM CDOMICILIO A INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA
INNER JOIN CTELEFONO CT ON CT.DMO_FL_CVE= A.DMO_FL_CVE 
WHERE B.PNA_FL_PERSONA = @CveCliente and DMO_FG_REGDEFAULT = 1
and ttl_fl_cve = 3
ORDER BY CT.TFN_FL_CVE ASC

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelefonoOficina%]'
UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%TelefonoOficinaSE%]'
UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%ExtOf%]'


set @VariableTexto=''
Select  TOP 1 @VariableTexto= ISNULL(TFN_CL_LARGA_DISTANCIA ,' ')+ 
CASE WHEN TFN_CL_LADA IS NOT NULL THEN '('+RTRIM(TFN_CL_LADA) +')' 
ELSE ' ' END + TFN_CL_TELEFONO + CASE WHEN TFN_CL_EXTENSION IS NOT NULL 
and LEN (RTRIM(ltrim(TFN_CL_EXTENSION)))>0 THEN ' EXT. ' + RTRIM(TFN_CL_EXTENSION)
 ELSE ' ' END 
FROM CDOMICILIO A INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA
INNER JOIN CTELEFONO CT ON CT.DMO_FL_CVE= A.DMO_FL_CVE 
WHERE B.PNA_FL_PERSONA = @CveCliente 
and ttl_fl_cve = 1
ORDER BY CT.TFN_FL_CVE ASC

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FAXOtro%]'

Declare @ClavePJ INT
set @ClavePJ = 0

Select @ClavePJ = PNA_CL_PJURIDICA 
FROM CPERSONA 
WHERE PNA_FL_PERSONA = @CveCliente


IF @ClavePJ = 20
	Begin
		SELECT @VariableTexto = RTRIM(PMO_DS_RAZON_SOCIAL) FROM CPMORAL WHERE PNA_FL_PERSONA = @CveCliente
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTexto  WHERE CLAVE='[%RazonSocial%]'
		SELECT @VariableTexto = RTRIM(DMO_DS_CALLE_NUM)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @CveCliente AND DMO_FG_REGDEFAULT = 1
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CalleMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_NUMEXT)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @CveCliente AND DMO_FG_REGDEFAULT = 1
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NumExtMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_COLONIA)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @CveCliente AND DMO_FG_REGDEFAULT = 1	
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ColoniaMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_CIUDAD)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @CveCliente AND DMO_FG_REGDEFAULT = 1	
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CiudadMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_EFEDERATIVA)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @CveCliente AND DMO_FG_REGDEFAULT = 1	
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%EFedMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_CL_CPOSTAL)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @CveCliente AND DMO_FG_REGDEFAULT = 1	
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CPMoral%]'
		SELECT @VariableTexto = RTRIM(PNA_CL_RFC) FROM CPERSONA WHERE PNA_FL_PERSONA = @CveCliente		
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RFCMoral%]'
	
		set @VariableTexto = ''
		set @intContador = 1
		Declare curEmail CURSOR FOR
			SELECT MAI_DS_EMAIL FROM CPERSONA_EMAIL WHERE PNA_FL_PERSONA = @CveCliente
		open curEmail
		fetch next from curEmail into @VariableTexto
		while @@fetch_status = 0
			begin
				if @intContador = 1
					UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CorreoMoral1%]'	
				if @intContador = 2
					UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CorreoMoral2%]'	
				if @intContador = 3
					UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CorreoMoral3%]'	
				fetch next from curEmail into @VariableTexto
				set @intContador = @intContador + 1 
			end
		close curEmail
		deallocate curEmail
		SET @intContador = 0
		--Vamos por la escritura constitutiva
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_NO_ESCRITURA FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoEscritura%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_FOLIO FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoFolio%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_VOLUMEN FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoVolumen%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_REGISTRO FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoRegistro%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_FOJAS FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoFojas%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_TOMO FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoTomo%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_LIBRO FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoLibro%]'
		IF @VariableTexto <> ''
		
		set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_CIUDAD FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CiudadInscrita%]'
		IF @VariableTexto <> ''
		
			set @VariableTexto = ''
		SELECT top 1 @VariableTexto =  ESC_DS_SECCION FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND ESC_CL_TESCRITURA = 1 
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoSeccion%]'
		IF @VariableTexto <> ''
			Begin
				SELECT top 1 @VariableFecha =  ESC_FE_ESCRITURA FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND  ESC_CL_TESCRITURA = 1 
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
					
			
					
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaEscritura%]'
				
				
				SELECT top 1 @VariableFecha =  ESC_FE_INSCRITA FROM KESCRITURA WHERE PNA_FL_PERSONA = @CveCliente AND  ESC_CL_TESCRITURA = 1 
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
					
			
					
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaInscrita%]'
				
				
				SELECT @VariableTexto = RTRIM(A.NOT_DS_NOMBRE) + ' ' + RTRIM(A.NOT_DS_APATERNO) + ' ' + RTRIM(A.NOT_DS_AMATERNO), 
				@VariableTexto1 = A.NOT_NO_NOTARIO,@VariableTexto2 = RTRIM(C.CIU_NB_CIUDAD),@VariableTexto3 = RTRIM(B.ESC_DS_CIUDAD),@VariableFecha2 = B.ESC_FE_INSCRITA ,
				@VariableTexto4 = B.ESC_DS_REGISTRO + '  LIBRO:' + RTRIM(B.ESC_DS_LIBRO) + ' FOJAS:' + RTRIM(B.ESC_DS_FOJAS) + ' SECCION:' + RTRIM(B.ESC_DS_SECCION) + ' VOLUMEN:' + RTRIM( B.ESC_DS_VOLUMEN) + ' TOMO:' + RTRIM( ESC_DS_TOMO)
				FROM CNOTARIO A INNER JOIN KESCRITURA B ON A.NOT_FL_CVE = B.NOT_FL_CVE AND B.ESC_CL_TESCRITURA = 1
				INNER JOIN CCIUDAD C ON C.CIU_CL_CIUDAD = A.CIU_CL_CIUDAD AND C.EFD_CL_CVE = A.EFD_CL_CVE 
				WHERE B.PNA_FL_PERSONA =  @CveCliente				
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NombreNotario%]'
				UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%NumNotario%]'
				UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%CiudadNotario%]'
				UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%RegistroEsc%]'		
				UPDATE #Claves SET TEXTO= @VariableTexto4 WHERE CLAVE='[%RegistroPublico%]'
				if month(@VariableFecha2) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha2) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha2) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha2) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha2) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha2) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha2) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha2) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha2) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha2) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha2) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha2) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha2) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha2) as varchar(4))								
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaRegistroPublico%]'

				--Revisamos a quien escogieron como apoderado en la asignación legal
				SET @VariableNumero = 0
				Select  @VariableNumero = PRE_FL_PERSONA 
				from KCTO_ASIG_LEGAL_CLIENTE 
				WHERE PNA_FL_PERSONA = @CveCliente 
				AND  ALG_CL_TIPO_RELACION = 4
				
				IF @VariableNumero > 0 
					Begin
						--Si encontro un apoderado por lo que hay que ir por los datos
						Select @VariableTexto = RTRIM(A.PNA_DS_NOMBRE),@VariableTexto1 = ISNULL(RTRIM(PDA_DS_VALORAD),'')
						FROM CPERSONA A
						LEFT OUTER JOIN CPDATO_ADICIONAL B 
						ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA 
						AND B.PTI_FG_VALOR = 4 
						AND B.DTA_FL_CVE= 2
						WHERE A.PNA_FL_PERSONA = @VariableNumero;
						
						exec lsntReplace  @VariableTexto,@VariableTexto OUTPUT;																								
						
						UPDATE #Claves 																		
						SET TEXTO= @VariableTexto
						WHERE CLAVE='[%RepresentanteLegal%]'	
						
						DECLARE @RFCRL CHAR(13)
						DECLARE @TELRLCASA VARCHAR(20)
						DECLARE @TELRLOFIC VARCHAR(20)
						DECLARE @EXTRLOFIC VARCHAR(10)
						DECLARE @CELRL VARCHAR(20)
						DECLARE @FAXRL VARCHAR(20)
						DECLARE @PUESTORL VARCHAR(100)	
						

					
						


						

				        SELECT @RFCRL= isnull(A.PNA_CL_RFC,''),  @TELRLCASA =B.TFN_CL_LARGA_DISTANCIA+ B.TFN_CL_LADA + B.TFN_CL_TELEFONO ,
						@TELRLOFIC = C.TFN_CL_LARGA_DISTANCIA + C.TFN_CL_LADA +C.TFN_CL_TELEFONO, @EXTRLOFIC = C.TFN_CL_EXTENSION,  
						@CELRL = D.TFN_CL_LARGA_DISTANCIA + D.TFN_CL_LADA + D.TFN_CL_TELEFONO , @FAXRL = E.TFN_CL_TELEFONO, @PUESTORL = F.PDA_DS_VALORAD
						FROM CPERSONA A
						LEFT OUTER JOIN CTELEFONO B on A.PNA_FL_PERSONA = B.PNA_FL_PERSONA AND B.TTL_FL_CVE= 2
						LEFT OUTER JOIN CTELEFONO C ON A.PNA_FL_PERSONA = C.PNA_FL_PERSONA AND C.TTL_FL_CVE= 3
						LEFT OUTER JOIN CTELEFONO D ON A.PNA_FL_PERSONA = D.PNA_FL_PERSONA AND D.TTL_FL_CVE= 4
						LEFT OUTER JOIN CTELEFONO E ON A.PNA_FL_PERSONA = E.PNA_FL_PERSONA AND E.TTL_FL_CVE= 1
						LEFT OUTER JOIN CPDATO_ADICIONAL F ON A.PNA_FL_PERSONA = F.PNA_FL_PERSONA AND DTA_FL_CVE = 50
						WHERE A.PNA_FL_PERSONA = @CveCliente

	                    Insert into #Claves values ('[%RFCRepresentante%]',isnull(@RFCRL, 'No APLICA' ));
						Insert into #Claves values ('[%TelRepresentante%]',isnull(@TELRLCASA, ''));
						Insert into #Claves values ('[%TelOfiRepresentante%]',ISNULL (@TELRLOFIC, '')); 
						Insert into #Claves values ('[%ExtRepresentante%]',ISNULL(@EXTRLOFIC, ''));
						Insert into #Claves values ('[%CelRepresentante%]',ISNULL(@CELRL, ''));
						Insert into #Claves values ('[%FaxRepresentante%]',ISNULL(@FAXRL, ''));
						Insert into #Claves values ('[%PuestoRepresentante%]',ISNULL(@PUESTORL, ''));

						--UPDATE #Claves 	SET TEXTO= @RFCRL WHERE CLAVE='[%RFCRepresentante%]'
						--UPDATE #Claves 	SET TEXTO= @TELRLCASA WHERE CLAVE='[%TelRepresentante%]'
						--UPDATE #Claves 	SET TEXTO= @TELRLOFIC WHERE CLAVE='[%TelOfiRepresentante%]'
						--UPDATE #Claves 	SET TEXTO= @EXTRLOFIC WHERE CLAVE='[%ExtRepresentante%]'
						--UPDATE #Claves 	SET TEXTO= @CELRL WHERE CLAVE='[%CelRepresentante%]'
						--UPDATE #Claves 	SET TEXTO= @FAXRL WHERE CLAVE='[%FaxRepresentante%]'
						--UPDATE #Claves 	SET TEXTO= @PUESTORL WHERE CLAVE='[%PuestoRepresentante%]'
								
						
						UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%IdApoderado%]'
						--Obtenemos los datos del poder en donde se encuentre el apoderado
						Declare @PoderApoderado int
						SET @PoderApoderado	=0
						SELECT @PoderApoderado = ESC_FL_CVE FROM KESCRITURA WHERE PNA_FL_PERSONA = @VariableNumero 
						AND ESC_CL_TESCRITURA = 4 
						GROUP BY ESC_FL_CVE,ESC_FE_ESCRITURA 
						HAVING ESC_FE_ESCRITURA = MAX(ESC_FE_ESCRITURA)
						IF @PoderApoderado > 0
							Begin
								Select @VariableTexto=ESC_NO_ESCRITURA,@VariableFecha=ESC_FE_ESCRITURA,@VariableTexto1=B.NOT_NO_NOTARIO,@VariableTexto2=C.CIU_NB_CIUDAD,@VariableTexto3=A.ESC_DS_REGISTRO
								FROM KESCRITURA A INNER JOIN CNOTARIO B ON B.NOT_FL_CVE = A.NOT_FL_CVE
								INNER JOIN CCIUDAD C ON C.CIU_CL_CIUDAD = B.CIU_CL_CIUDAD and C.EFD_CL_CVE =B.EFD_CL_CVE 
								where A.ESC_FL_CVE = @PoderApoderado
								UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NumPoder%]'								
								UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%NumNotarioPoder%]'
								UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%CiudadPoder%]'
								UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%RegistroPoder%]'
								SET @VariableTexto = ''
								if month(@VariableFecha) = 1
									SET @Mes = 'Enero'
								if month(@VariableFecha) = 2
									SET @Mes = 'Febrero'
								if month(@VariableFecha) = 3
									SET @Mes = 'Marzo'
								if month(@VariableFecha) = 4
									SET @Mes = 'Abril'
								if month(@VariableFecha) = 5
									SET @Mes = 'Mayo'
								if month(@VariableFecha) = 6
									SET @Mes = 'Junio'
								if month(@VariableFecha) = 7
									SET @Mes = 'Julio'
								if month(@VariableFecha) = 8
									SET @Mes = 'Agosto'
								if month(@VariableFecha) = 9
									SET @Mes = 'Septiembre'
								if month(@VariableFecha) = 10
									SET @Mes = 'Octubre'
								if month(@VariableFecha) = 11
									SET @Mes = 'Noviembre'
								if month(@VariableFecha) = 12
									SET @Mes = 'Diciembre'
								set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								
								UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaPoder%]'
							End
					End
			End
		set @VariableTexto = ''
		SELECT @VariableTextoLarga = RTRIM(DLE_DS_OBJETOSOCIAL) FROM KDICTAMEN_LEGAL WHERE PNA_FL_PERSONA = @CveCliente
		exec lsntReplace  @VariableTextolarga,@VariableTextoLarga OUTPUT
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%ObjetoSocial%]'
		
	End
ELSE
	Begin
		--PERSONA FISICA
		Select @VariableTexto= rtrim(b.PFI_DS_NOMBRE) + ' ' +rtrim(b.PFI_DS_APATERNO)+ ' '+rtrim(b.PFI_DS_AMATERNO)   /* A.PNA_DS_NOMBRE*/,@VariableTexto1=isnull(RTRIM(B.PFI_DS_LNACIMIENTO),''),@VariableFecha=B.PFI_FE_NACIMIENTO,
		@VariableTexto2=isnull(RTRIM(D.PAR_DS_DESCRIPCION),''),@VariableTexto3=isnull(RTRIM(E.PAR_DS_DESCRIPCION),''),@VariableTexto4=isnull(RTRIM(F.PAR_DS_DESCRIPCION),'')
		FROM CPERSONA A
		LEFT OUTER JOIN CPFISICA B ON A.PNA_FL_PERSONA = B.PNA_FL_PERSONA		
		LEFT OUTER JOIN CPARAMETRO D ON D.PAR_CL_VALOR = B.PFI_FG_OCUPACION AND D.PAR_FL_CVE= 15
		LEFT OUTER JOIN CPARAMETRO E ON E.PAR_CL_VALOR = B.PFI_FG_EDO_CIVIL AND E.PAR_FL_CVE= 11
		LEFT OUTER JOIN CPARAMETRO F ON F.PAR_CL_VALOR = B.PFI_FG_REGMAT AND F.PAR_FL_CVE= 16
		where a.PNA_FL_PERSONA =@CveCliente
		
		EXEC lsntReplace @VariableTexto, @VariableTexto output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= rtrim(@VariableTexto) WHERE CLAVE='[%NombrePFisica%]'
		UPDATE #Claves SET TEXTO= rtrim(@VariableTexto1) WHERE CLAVE='[%LugarNacPFisica%]'
		

		if month(@VariableFecha) = 1
			SET @Mes = 'Enero'
		if month(@VariableFecha) = 2
			SET @Mes = 'Febrero'
		if month(@VariableFecha) = 3
			SET @Mes = 'Marzo'
		if month(@VariableFecha) = 4
			SET @Mes = 'Abril'
		if month(@VariableFecha) = 5
			SET @Mes = 'Mayo'
		if month(@VariableFecha) = 6
			SET @Mes = 'Junio'
		if month(@VariableFecha) = 7
			SET @Mes = 'Julio'
		if month(@VariableFecha) = 8
			SET @Mes = 'Agosto'
		if month(@VariableFecha) = 9
			SET @Mes = 'Septiembre'
		if month(@VariableFecha) = 10
			SET @Mes = 'Octubre'
		if month(@VariableFecha) = 11
			SET @Mes = 'Noviembre'
		if month(@VariableFecha) = 12
			SET @Mes = 'Diciembre'
		set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								
		
		--UPDATE #Claves SET TEXTO= convert(char(10),@VariableFecha,21) WHERE CLAVE='[%FechaNacPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaNacPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%OcupacionPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%EdoCivilPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto4 WHERE CLAVE='[%RegimenPFisica%]'		
		
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%IdentificacionPFisica%]'				

		SET @VariableNumero = 1
		SET @VariableTexto5 = ''
		DECLARE curCorreos CURSOR FOR
			Select rtrim(A.MAI_DS_EMAIL) FROM CPERSONA_EMAIL A WHERE A.PNA_FL_PERSONA = @CveCliente
		open curCorreos
		fetch next from curCorreos into @VariableTexto5
		while @@fetch_status = 0
			begin
				If @VariableNumero = 1
					UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CorreoPFisica1%]'
				If @VariableNumero = 2
					UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CorreoPFisica2%]'
				If @VariableNumero = 3
					UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CorreoPFisica3%]'			
				SET @VariableNumero = @VariableNumero + 1
				fetch next from curCorreos into @VariableTexto5
			end
		close curCorreos
		deallocate curCorreos					
	End

/* JDRA aumento id apoderado*/										
		
		set @VariableTexto = '';
		set @VariableTexto1 = '';

		Select @VariableTexto = isnull(RTRIM(A.PNA_DS_NOMBRE), ''),
			@VariableTexto1 = ISNULL(RTRIM(PDA_DS_VALORAD),'') 
		from KCTO_ASIG_LEGAL_CLIENTE ALC 
		inner join CPERSONA A 
		on A.PNA_FL_PERSONA = ALC.PRE_FL_PERSONA  
		LEFT OUTER JOIN CPDATO_ADICIONAL B 
		ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA 
		AND B.PTI_FG_VALOR = 4 AND B.DTA_FL_CVE= 2
		where CTO_FL_CVE =@CveContrato 	
		and ALG_CL_TIPO_RELACION =4
				
		exec lsntReplace  @VariableTexto,@VariableTexto OUTPUT;				
		
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RepresentanteLegal%]'		
		UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%IdApoderado%]'
				
		/* JDRA  */


UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%DelRegistro%]'

SELECT @VariableFecha = CTO_FE_INICIO FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato
SET @VariableTexto = ''
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaInicio%]'

/*******************SECCION PRODUCTOS**********************/
DECLARE @MarcaP varchar(200),@AñoP varchar(200),@ModeloP varchar(200),@NivP varchar(200),@UsoP varchar(200),@SubserieP varchar(200),@ProductoContrato varchar(200)
DECLARE @CapacidadP varchar(200),@ClaseP varchar(200),@NoSerieP varchar(200),@KmP varchar(200),@CarroceriaP varchar(200),@TProductoP varchar(200),@NoMotorP varchar(200),@CaractMed varchar(200)
SET @NOFFSET = 0

SELECT @ptr = TEXTPTR(#Claves.Texto)  
FROM #Claves 
WHERE Clave = '[%ProductosContrato%]'

SET @SeccionTabla = ' \trowd\trbrdrt\brdrs\brdrw10\trleft-70\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trbrdrr\brdrs\brdrw10 ' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = ' \clvertalt\clbrdrt\brdrs\brdrw10\clbrdrl\brdrs\brdrw10\clbrdrb\brdrs\brdrw10\clbrdrr\brdrs\brdrw10 '
SET @SeccionTabla3 = ' \cltxlrtb\clftsWidth3\ '
SET  @SeccionTabla4 = ' \pard\plain\ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 ' 
DECLARE curActivos CURSOR FOR 
		SELECT RTRIM(C.MRC_DS_MARCA) ,ISNULL(D.CFP_DS_CARACT,''),ISNULL(E.CFP_DS_CARACT,''),ISNULL(F.CFP_DS_CARACT,''),ISNULL(G.CFP_DS_CARACT,''),ISNULL(H.CFP_DS_CARACT,''),
		ISNULL(I.CFP_DS_CARACT,''),ISNULL(J.CFP_DS_CARACT,''),ISNULL(K.CFP_DS_CARACT,''),ISNULL(L.CFP_DS_CARACT,''),ISNULL(M.CFP_DS_CARACT,''),RTRIM(T.TPR_DS_TPRODUCTO),ISNULL(N.CFP_DS_CARACT,''),ISNULL(P.CFP_DS_CARACT,''),T.TPR_FL_CVE,B.PRD_DS_PRODUCTO
		FROM  KPRODUCTO_FACTURA A
		INNER JOIN CPRODUCTO B ON B.PRD_FL_CVE= A.PRD_FL_CVE 
		INNER JOIN CTPRODUCTO T ON T.TPR_FL_CVE = B.TPR_FL_CVE 
		INNER JOIN CMARCA C ON C.MRC_FL_CVE = B.MRC_FL_CVE 
		LEFT OUTER JOIN KCARAC_PROD_FACT D ON A.FAC_FL_CVE = D.FAC_FL_CVE AND A.PRD_FL_CVE = D.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = D.KPF_NO_CONSECUTIVO  AND D.CAR_FL_CVE = 3 --AÑO
		LEFT OUTER JOIN KCARAC_PROD_FACT E ON A.FAC_FL_CVE = E.FAC_FL_CVE AND A.PRD_FL_CVE = E.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = E.KPF_NO_CONSECUTIVO  AND E.CAR_FL_CVE = 5 -- MODELO
		LEFT OUTER JOIN KCARAC_PROD_FACT F ON A.FAC_FL_CVE = F.FAC_FL_CVE AND A.PRD_FL_CVE = F.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = F.KPF_NO_CONSECUTIVO  AND F.CAR_FL_CVE = 7 -- NIV
		LEFT OUTER JOIN KCARAC_PROD_FACT G ON A.FAC_FL_CVE = G.FAC_FL_CVE AND A.PRD_FL_CVE = G.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = G.KPF_NO_CONSECUTIVO  AND G.CAR_FL_CVE = 4 -- USO
		LEFT OUTER JOIN KCARAC_PROD_FACT H ON A.FAC_FL_CVE = H.FAC_FL_CVE AND A.PRD_FL_CVE = H.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = H.KPF_NO_CONSECUTIVO  AND H.CAR_FL_CVE = 12 -- SUBSERIE
		LEFT OUTER JOIN KCARAC_PROD_FACT I ON A.FAC_FL_CVE = I.FAC_FL_CVE AND A.PRD_FL_CVE = I.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = I.KPF_NO_CONSECUTIVO  AND I.CAR_FL_CVE = 13 -- CAPACIDAD
		LEFT OUTER JOIN KCARAC_PROD_FACT J  ON A.FAC_FL_CVE = J.FAC_FL_CVE AND A.PRD_FL_CVE = J.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = J.KPF_NO_CONSECUTIVO  AND J.CAR_FL_CVE = 14 -- CLASE
		LEFT OUTER JOIN KCARAC_PROD_FACT K  ON A.FAC_FL_CVE = K.FAC_FL_CVE AND A.PRD_FL_CVE = K.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = K.KPF_NO_CONSECUTIVO  AND K.CAR_FL_CVE = 1 -- NoSerie
		LEFT OUTER JOIN KCARAC_PROD_FACT L ON A.FAC_FL_CVE = L.FAC_FL_CVE AND A.PRD_FL_CVE = L.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = L.KPF_NO_CONSECUTIVO  AND L.CAR_FL_CVE = 17 -- KM
		LEFT OUTER JOIN KCARAC_PROD_FACT M ON A.FAC_FL_CVE = M.FAC_FL_CVE AND A.PRD_FL_CVE = M.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = M.KPF_NO_CONSECUTIVO  AND M.CAR_FL_CVE = 10 -- CARROCERIA
		LEFT OUTER JOIN KCARAC_PROD_FACT N ON A.FAC_FL_CVE = N.FAC_FL_CVE AND A.PRD_FL_CVE = N.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = N.KPF_NO_CONSECUTIVO  AND N.CAR_FL_CVE = 2 -- Motor
		LEFT OUTER JOIN KCARAC_PROD_FACT P ON A.FAC_FL_CVE = P.FAC_FL_CVE AND A.PRD_FL_CVE = P.PRD_FL_CVE AND A.KPF_NO_CONSECUTIVO = P.KPF_NO_CONSECUTIVO  AND P.CAR_FL_CVE = 6 -- CaractMed
		WHERE A.CTO_FL_CVE= @CveContrato 
OPEN curActivos 


FETCH NEXT FROM curActivos into @MarcaP,@AñoP,@ModeloP,@NivP,@UsoP,@SubserieP,@CapacidadP,@ClaseP,@NoSerieP,@KmP,@CarroceriaP,@TProductoP,@NoMotorP,@CaractMed,@VariableNumero,@ProductoContrato

--acarrillo ini
if @@FETCH_STATUS = 0
	begin	
	SET @VariableTexto = ''
	Select @VariableTexto = A.TPR_DS_TPRODUCTO 
		FROM CTPRODUCTO A WHERE A.TPR_FL_CVE =@VariableNumero
	UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TipoProducto%]'
	end
SET @VariableTexto = ''	
--acarrillo fin

WHILE @@FETCH_STATUS = 0
	BEGIN
	
		if 	@VariableNumero = 2 or @VariableNumero= 3 --Tipo de producto no medico
			Begin
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + @SeccionTabla4 +  '   Marca\cell ' + @MarcaP + ' \cell SubSerie:\cell  ' + @SubserieP +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			

				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + @SeccionTabla4 +  '   Año\cell ' + @AñoP + ' \cell Clase:\cell  ' + @ClaseP +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + @SeccionTabla4 +  '   Modelo\cell ' + @ModeloP + ' \cell Capacidad:\cell  ' + @CapacidadP +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + @SeccionTabla4 +  '   NoSerie\cell ' + @NoSerieP + ' \cell No de Motor:\cell  ' + @NoMotorP +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2590\cellx2520 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth6391\cellx8911 ' + @SeccionTabla4 +  '  Características Especiales\cell ' + '-' + ' \cell }\pard\plain{'						
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2590\cellx2520 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth6391\cellx8911 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

			
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + @SeccionTabla4 +  '   Uso\cell ' + @UsoP + ' \cell Kilometraje:\cell  ' + @KmP +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1329\cellx1259' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3781\cellx5040' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1623\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2248\cellx8911 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				
				SET @VariableTextoLarga =  ' { \par \par  } '				
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			
			End
		If  @VariableNumero = 5  --Es un equipo medico
			Begin
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth9190\cellx9120 ' + @SeccionTabla4  + '  ' + @ProductoContrato +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))					
				SET @VariableTextoLarga =@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth9190\cellx9120'  + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2297\cellx6822' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2298\cellx9120 ' + @SeccionTabla4 +  '  Uso\cell ' +  @UsoP + ' \cell }\pard\plain{'						
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = @SeccionTabla +@SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2297\cellx6822' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2298\cellx9120 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2297\cellx6822' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2298\cellx9120 ' + @SeccionTabla4 +  '  Lugar y Fecha de Entrega\cell ' +  '-' + ' \cell }\pard\plain{'						
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = @SeccionTabla +@SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2297\cellx6822' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2298\cellx9120 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2297\cellx6822' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2298\cellx9120 ' + @SeccionTabla4 +  '  Características del Seguro con que deberá contar el BIEN\cell ' +  '-' + ' \cell }\pard\plain{'						
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = @SeccionTabla +@SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2297\cellx6822' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2298\cellx9120 ' + ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =  ' { \par \par  } '				
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			
			End
				
				
		FETCH NEXT FROM curActivos into @MarcaP,@AñoP,@ModeloP,@NivP,@UsoP,@SubserieP,@CapacidadP,@ClaseP,@NoSerieP,@KmP,@CarroceriaP,@TProductoP,@NoMotorP,@CaractMed,@VariableNumero,@ProductoContrato
	END
CLOSE curActivos
DEALLOCATE curActivos

/******************* FIN SECCION PRODUCTOS**********************/

UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%MarcaCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%SubSerie%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%AhoCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%ClaseCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%ModeloCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CapacidadCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NoSerieCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NoMotorCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CaractCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%UsoCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%KmCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CaractSeguroCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%LugarFechaEntregaCoche%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%EquipoMedico%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%MarcaMedico%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CaractMedico%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%UsoMedico%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%LugarFechaEntregaMedico%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CaractSeguroMedico%]'
SET @VariableNumero = 0
SET @VariableTexto = ''
Select @VariableNumero = CTP_NO_MTO_PAGO from KTPAGO_CONTRATO WHERE CTO_FL_CVE = @CveContrato and CTP_CL_TTABLA = 1 AND CTP_NO_PAGO = 1
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%MontoVencimientoSinIva%]'
SET @VariableFecha = '19000101'
SELECT @VariableFecha = CTO_FE_ULTPAGO FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato
SET @VariableTexto = ''
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaVencimiento%]'
SET @VariableTexto = ''
SET @VariableNumero  = 0
SELECT @VariableNumero = CTO_NO_MTO_ENGANCHE FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AnticipoEnganche%]'
/*para MEGA el depósito adicional es el enganche SELECT @VariableNumero = CTO_NO_MTO_DEPRENTAS FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto*/
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DepositoAdicional%]'


SET @VariableTexto = ''
SET @VariableTexto2 = ''
SET @VariableTexto3 = ''
SELECT @VariableNumero = isnull(CTO_NO_MTO_OPCIONCOMPRA,0)  FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato
IF @VariableNumero=0
SELECT @VariableNumero = isnull(CTO_NO_MTO_VRESIDUAL,0)  FROM KCONTRATO WHERE CTO_FL_CVE = @CveContrato

EXEC spLsnetCantidadLetra  @VariableNumero, 1, @VariableTexto output
SET @VariableTexto2 = convert(varchar(20),convert(money,@VariableNumero),1)
SELECT @VariableTexto3 = '$'+rtrim(@VariableTexto2) + ' (' + RTRIM(LTRIM(@VariableTexto)) + ') '
SET @VariableTexto3 = REPLACE(@VariableTexto3,'  ','')
UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%MontoOpcionCompra%]'

UPDATE #Claves SET TEXTO= '(' + RTRIM(LTRIM(@VariableTexto)) + ')' WHERE CLAVE='[%MontoOpcionCompraLetra%]'
UPDATE #CLAVES SET TEXTO= '$'+rtrim(@VariableTexto2) WHERE CLAVE='[%MontoOpCompra+Intereses%]'



SET @VariableTexto = ''
SET @VariableTexto2 = ''
SET @VariableTexto3 = ''
SET @VariableTexto4 = ''
SET @VariableTexto5 = ''
SET @VariableTexto6 = ''
SET @VariableTexto7	 = ''
SET @VariableTexto8 = ''
SET @VariableNumero = 0
SET @VariableNumero2 = 0 



/*******Seccion DESCRIPCION BIENES**********************/
DECLARE @NombreProducto VARCHAR(50)
DECLARE @MarcaProd VARCHAR(50)
DECLARE @AhoProd VARCHAR(50)
DECLARE @ClaseProd VARCHAR(50)
DECLARE @ModeloProd VARCHAR(50)
DECLARE @CapacidadProd VARCHAR(50)
DECLARE @NoSerieProd VARCHAR(50)
DECLARE @NoMotorProd VARCHAR(50)
DECLARE @CEspecialProd VARCHAR(50)
DECLARE @UsoProd VARCHAR(50)
DECLARE @KmProd VARCHAR(50)
DECLARE @SubSerie VARCHAR(50)

DECLARE @NomCar varchar(50)
DECLARE @DesCar varchar(100)

declare @FAC_FL_CVE int
declare @PRD_FL_CVE int 
declare @KPF_NO_CONSECUTIVO int

declare @AFAC_FL_CVE int
declare @APRD_FL_CVE int 
declare @AKPF_NO_CONSECUTIVO int

set @AFAC_FL_CVE =0
set @APRD_FL_CVE =0
set @AKPF_NO_CONSECUTIVO =0

DECLARE @DescripcionProductosAutos varchar(8000)
DECLARE @ProdCto int
SET @DescripcionProductosAutos = ''
SET @SeccionTabla = ''
SET @NOFFSET = 0
	
	SELECT @ptr = TEXTPTR(#Claves.Texto)
	FROM #Claves WHERE Clave = '[%DescripcionBienesA%]';
	
SET @SeccionTabla = ' \trowd\trbrdrt\brdrs\brdrw10\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trleft-70\trbrdrr\brdrs\brdrw10 ' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = ' \clvertalt\clbrdrt\brdrs\brdrw10\clbrdrl\brdrs\brdrw10\clbrdrb\brdrs\brdrw10\clbrdrr\brdrs\brdrw10 '
SET @SeccionTabla3 = ' \cltxlrtb\clftsWidth3\ '
SET  @SeccionTabla4 = ' \pard\plain\ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 ' 
	
DECLARE curProductosA CURSOR FOR
select RTRIM(B.PRD_DS_PRODUCTO),RTRIM(C.MRC_DS_MARCA),RTRIM(E.CAR_DS_DESCRIPCION),ISNULL(RTRIM(D.CFP_DS_CARACT),''),B.TPR_FL_CVE 
		,A.FAC_FL_CVE,A.PRD_FL_CVE,A.KPF_NO_CONSECUTIVO
	FROM KPRODUCTO_FACTURA A
	INNER JOIN CPRODUCTO B ON B.PRD_FL_CVE = A.PRD_FL_CVE
	INNER JOIN CMARCA C ON C.MRC_FL_CVE = B.MRC_FL_CVE 
	INNER JOIN CTPRODUCTO N ON N.TPR_FL_CVE = B.TPR_FL_CVE 
	INNER JOIN kCARAC_PROD_FACT D ON D.FAC_FL_CVE = A.FAC_FL_CVE AND D.PRD_FL_CVE = A.PRD_FL_CVE AND D.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO
	INNER JOIN CCARACTERISTICA E ON E.CAR_FL_CVE = D.CAR_FL_CVE
	WHERE A.CTO_FL_CVE = @CveContrato
	order by A.FAC_FL_CVE,A.PRD_FL_CVE,A.KPF_NO_CONSECUTIVO
		open curProductosA
		fetch next from curProductosA into @NombreProducto,@MarcaProd,@NomCar,@DesCar,@VariableNumero,@FAC_FL_CVE,@PRD_FL_CVE,@KPF_NO_CONSECUTIVO				
		WHILE @@fetch_status = 0 
	begin
		IF @FAC_FL_CVE != @AFAC_FL_CVE or @PRD_FL_CVE !=@APRD_FL_CVE  or @KPF_NO_CONSECUTIVO!=@AKPF_NO_CONSECUTIVO
		BEGIN
				
				--SET @SeccionTabla = ' \ltrrow}\trowd \irow0\irowband0\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trwWidth14000 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				--SET @SeccionTabla = '\trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrt\brdrs\brdrw10 \clbrdrt\brdrs\brdrw10 \clbrdrt\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth9422\clshdrawnil \cellx9422\pard \ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20  '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				--SET @SeccionTabla = @NombreProducto
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				--SET @SeccionTabla	= '}{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 \cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 \trowd \irow0\irowband0\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				--SET @SeccionTabla = ' \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth9422\clshdrawnil \cellx9422\row '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
												
				SET @VariableTextoLarga = '\par \ltrrow' + @SeccionTabla+ @SeccionTabla2  + '\cltxlrtb\cellx9356' + @SeccionTabla4 +'\qc ' +  @NombreProducto + '\cell }\pard\plain{'						
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =  '\row}\pard\plain' 
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

		END				
		
				
				--SET @SeccionTabla = '\ltrrow}\trowd \irow5\irowband5\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2590\clshdrawnil \cellx2590\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth6832\clshdrawnil \cellx6832\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 ' 
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))												
				--SET @SeccionTabla = @NomCar+' \cell '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				--SET @SeccionTabla = ' }\pard\plain \ltrpar\s4\ql \li0\ri0\keepn\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\outlinelevel3\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\cgrid\langnp1034\langfenp3082 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0  ' 
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))												
				--SET @SeccionTabla = @DesCar + '}{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0  \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \trowd \irow5\irowband5\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				--SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth2590\clshdrawnil \cellx2520\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth6832\clshdrawnil \cellx6832\row \ltrrow} '
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				

				SET @VariableTextoLarga =  @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx2590' + @SeccionTabla2 + '\cltxlrtb\cellx9356' + @SeccionTabla4 +  @NomCar + '\cell ' +  RTRIM(@DesCar) +   '\cell}\pard\plain{'						
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =  '\row}\pard\plain' 
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

															
				--SET @SeccionTabla = '\pard\ltrpar\ql\li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \af38 \ltrch\fcs0 '--}-- \par }'
				--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
						
				set @AFAC_FL_CVE=@FAC_FL_CVE
				set @APRD_FL_CVE=@PRD_FL_CVE
				set @AKPF_NO_CONSECUTIVO=@KPF_NO_CONSECUTIVO
		
		fetch next from curProductosA into @NombreProducto,@MarcaProd,@NomCar,@DesCar,@VariableNumero,@FAC_FL_CVE,@PRD_FL_CVE,@KPF_NO_CONSECUTIVO
	end
close curProductosA
deallocate curProductosA

SET @DescripcionProductosAutos = ''
SET @SeccionTabla = ''
SET @NOFFSET = 0
	SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%DescripcionBienes%]'
 
 
DECLARE curProductos CURSOR FOR
	Select  RTRIM(B.PRD_DS_PRODUCTO),RTRIM(C.MRC_DS_MARCA),ISNULL(RTRIM(D.CFP_DS_CARACT),''),ISNULL(RTRIM(E.CFP_DS_CARACT),''),ISNULL(RTRIM(F.CFP_DS_CARACT),'')
	,ISNULL(RTRIM(G.CFP_DS_CARACT),''),ISNULL(RTRIM(H.CFP_DS_CARACT),''),ISNULL(RTRIM(I.CFP_DS_CARACT),''),ISNULL(RTRIM(J.CFP_DS_CARACT),''),ISNULL(RTRIM(K.CFP_DS_CARACT),''),ISNULL(RTRIM(L.CFP_DS_CARACT),''),ISNULL(RTRIM(M.CFP_DS_CARACT),'')
	,B.TPR_FL_CVE 
	FROM KPRODUCTO_FACTURA A
	INNER JOIN CPRODUCTO B ON B.PRD_FL_CVE = A.PRD_FL_CVE
	INNER JOIN CMARCA C ON C.MRC_FL_CVE = B.MRC_FL_CVE 
	INNER JOIN CTPRODUCTO N ON N.TPR_FL_CVE = B.TPR_FL_CVE 
	LEFT OUTER JOIN kCARAC_PROD_FACT D ON D.FAC_FL_CVE = A.FAC_FL_CVE AND D.PRD_FL_CVE = A.PRD_FL_CVE AND D.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND D.CAR_FL_CVE =5  --Año
	LEFT OUTER JOIN kCARAC_PROD_FACT E ON E.FAC_FL_CVE = A.FAC_FL_CVE AND E.PRD_FL_CVE = A.PRD_FL_CVE AND E.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND E.CAR_FL_CVE =19  --Clase
	LEFT OUTER JOIN kCARAC_PROD_FACT F ON F.FAC_FL_CVE = A.FAC_FL_CVE AND F.PRD_FL_CVE = A.PRD_FL_CVE AND F.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND F.CAR_FL_CVE =0  --Modelo
	LEFT OUTER JOIN kCARAC_PROD_FACT G ON G.FAC_FL_CVE = A.FAC_FL_CVE AND G.PRD_FL_CVE = A.PRD_FL_CVE AND G.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND G.CAR_FL_CVE =0  --Capacidad
	LEFT OUTER JOIN kCARAC_PROD_FACT H ON H.FAC_FL_CVE = A.FAC_FL_CVE AND H.PRD_FL_CVE = A.PRD_FL_CVE AND H.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND H.CAR_FL_CVE =1  --No Serie
	LEFT OUTER JOIN kCARAC_PROD_FACT I ON I.FAC_FL_CVE = A.FAC_FL_CVE AND I.PRD_FL_CVE = A.PRD_FL_CVE AND I.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND I.CAR_FL_CVE =0  --NoMotor
	LEFT OUTER JOIN kCARAC_PROD_FACT J ON J.FAC_FL_CVE = A.FAC_FL_CVE AND J.PRD_FL_CVE = A.PRD_FL_CVE AND J.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND J.CAR_FL_CVE =11  --Carac especial
	LEFT OUTER JOIN kCARAC_PROD_FACT K ON K.FAC_FL_CVE = A.FAC_FL_CVE AND K.PRD_FL_CVE = A.PRD_FL_CVE AND K.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND K.CAR_FL_CVE =14  --Uso
	LEFT OUTER JOIN kCARAC_PROD_FACT L ON L.FAC_FL_CVE = A.FAC_FL_CVE AND L.PRD_FL_CVE = A.PRD_FL_CVE AND L.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND L.CAR_FL_CVE =0  --KM
	LEFT OUTER JOIN kCARAC_PROD_FACT M ON M.FAC_FL_CVE = A.FAC_FL_CVE AND M.PRD_FL_CVE = A.PRD_FL_CVE AND M.KPF_NO_CONSECUTIVO = A.KPF_NO_CONSECUTIVO  AND M.CAR_FL_CVE =0  --SubSerie
	WHERE A.CTO_FL_CVE = @CveContrato
open curProductos
fetch next from curProductos into @NombreProducto,@MarcaProd,@AhoProd,@ClaseProd,@ModeloProd,@CapacidadProd,@NoSerieProd,@NoMotorProd,@CEspecialProd,@UsoProd,@KmProd,@SubSerie,@VariableNumero
WHILE @@fetch_status = 0 
	begin
		IF @VariableNumero <>5 --No equipo Medico
			Begin
				SET @SeccionTabla = ' \ltrrow}\trowd \irow0\irowband0\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = '\trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrt\brdrs\brdrw10 \clbrdrt\brdrs\brdrw10 \clbrdrt\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth8981\clshdrawnil \cellx8911\pard \ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20  '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = @NombreProducto +  '}{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 \cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 \trowd \irow0\irowband0\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth8981\clshdrawnil \cellx8911\row \ltrrow}\trowd \irow1\irowband1\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth3781\clshdrawnil \cellx5040\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1623\clshdrawnil \cellx6663\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10  '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))															
				SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth2248\clshdrawnil \cellx8911\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 Marca:\cell }\pard\plain \ltrpar\s4\ql \li0\ri0\keepn\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\outlinelevel3\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\cgrid\langnp1034\langfenp3082 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \lang1033\langfe3082\langnp1033 ' + @MarcaProd
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \lang1033\langfe3082\langnp1033 \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 Sub Serie:\cell }{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 ' + @SubSerie +'}{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 \cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 \trowd \irow1\irowband1\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth3781\clshdrawnil \cellx5040\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1623\clshdrawnil \cellx6663\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2248\clshdrawnil \cellx8911\row \ltrrow}\trowd \irow2\irowband2\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2521\clshdrawnil \cellx3780\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1260\clshdrawnil \cellx5040\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth3871\clshdrawnil \cellx8911\pard \ltrpar\ql \li0\ri0\widctlpar\intbl'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 A\''f1o:\cell }\pard\plain \ltrpar\s15\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs20\alang1025 \ltrch\fcs0 \fs20\lang1033\langfe3082\cgrid\langnp1033\langfenp3082 {\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 ' + @AhoProd + '}{\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 \cell }'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 Clase: }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \cell }\pard\plain \ltrpar\s15\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs20\alang1025 \ltrch\fcs0 \fs20\lang1033\langfe3082\cgrid\langnp1033\langfenp3082 {\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = @ClaseProd + '}{\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \trowd \irow2\irowband2\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2521\clshdrawnil \cellx3780\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1260\clshdrawnil \cellx5040\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth3871\clshdrawnil \cellx8911\row \ltrrow}\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \f37\fs20\lang1034\langfe3082\langnp1034 Modelo:\cell }\pard\plain \ltrpar\s15\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs20\alang1025 \ltrch\fcs0 \fs20\lang1033\langfe3082\cgrid\langnp1033\langfenp3082 {\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 ' + @ModeloProd + '}{\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \langnp1034 Capacidad:\cell }\pard\plain \ltrpar\s15\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs20\alang1025 \ltrch\fcs0 \fs20\lang1033\langfe3082\cgrid\langnp1033\langfenp3082 {\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 ' + @CapacidadProd + '}{\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \trowd \irow3\irowband3\ltrrow\ts11\trgaph70\trleft-70'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2521\clshdrawnil \cellx3780\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1260\clshdrawnil \cellx5040\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth3871\clshdrawnil \cellx8911\row \ltrrow}\trowd \irow4\irowband4\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2521\clshdrawnil \cellx3780\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1620\clshdrawnil '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \cellx5400\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth3511\clshdrawnil \cellx8911\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 No. Serie:\cell }{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 ' + @NoSerieProd + ' }{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \cell No. de Motor:\cell }{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 ' + @NoMotorProd + '}{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \f37\fs20\lang1034\langfe3082\langnp1034 \trowd \irow4\irowband4\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1329\clshdrawnil \cellx1259\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2521\clshdrawnil \cellx3780\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1620\clshdrawnil \cellx5400\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth3511\clshdrawnil \cellx8911\row \ltrrow}\trowd \irow5\irowband5\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2590\clshdrawnil \cellx2520\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth6391\clshdrawnil \cellx8911\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 Caracteristicas Especiales:\cell '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' }\pard\plain \ltrpar\s4\ql \li0\ri0\keepn\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\outlinelevel3\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\cgrid\langnp1034\langfenp3082 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0  ' + @CEspecialProd + '}{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0  \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 \trowd \irow5\irowband5\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth2590\clshdrawnil \cellx2520\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth6391\clshdrawnil \cellx8911\row \ltrrow}\trowd \irow6\irowband6\lastrow \ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trwWidthA91\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth950\clshdrawnil \cellx880\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth4700\clshdrawnil \cellx5580\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1260\clshdrawnil \cellx6840\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth1980\clshdrawnil \cellx8820\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\langnp1034 Uso\cell }\pard\plain \ltrpar\s4\ql \li0\ri0\keepn\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\outlinelevel3\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \f37\fs20\lang1034\langfe3082\cgrid\langnp1034\langfenp3082 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0  ' + @UsoProd + '}{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0  \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \f37\fs20\lang1034\langfe3082\langnp1034 Kilometraje:\cell }\pard\plain \ltrpar\s15\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs20\alang1025 \ltrch\fcs0 \fs20\lang1033\langfe3082\cgrid\langnp1033\langfenp3082 {\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 ' + @KmProd + '}{\rtlch\fcs1 \af38 \ltrch\fcs0 \f37\lang1034\langfe3082\langnp1034 \cell }\pard\plain \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0 \fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \f37\fs20 \trowd \irow6\irowband6\lastrow \ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth1\trftsWidthB3\trftsWidthA3\trwWidthA91\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth950\clshdrawnil \cellx880\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth4700\clshdrawnil \cellx5580\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1260\clshdrawnil \cellx6840\clvertalt\clbrdrt\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth1980\clshdrawnil \cellx8820\row }\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \af38 \ltrch\fcs0 '--}-- \par }'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))				
				SET @SeccionTabla = ' \par }{\rtlch\fcs1 \af38 \ltrch\fcs0 \lang2058\langfe3082\langnp2058  '
			End
		Else
			Begin
				SET @SeccionTabla = ' \ltrrow}\trowd \irow0\irowband0\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = '  \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth3\trwWidth9190\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth9190 \cellx9120\pard \ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \adjustright\rin0\lin0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20  ' +  @NombreProducto + '\cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 \trowd \irow0\irowband0\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth3\trwWidth9190\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth9190 \cellx9120\row \ltrrow}\trowd \irow1\irowband1\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth3\trwWidth9190\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2297 \cellx2227\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2298 \cellx4525\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2297 \cellx6822\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2298 \cellx9120\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 Marca:\cell }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 ' + @MarcaProd + '\cell }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = '  Caracteristicas:\cell }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20  ' +  @CEspecialProd + '\cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 \trowd \irow1\irowband1\ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth3\trwWidth9190\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2297 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \cellx2227\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2298 \cellx4525\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2297 \cellx6822\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2298 \cellx9120\row \ltrrow}\trowd \irow2\irowband2\lastrow \ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth3\trwWidth9190\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2297 \cellx2227\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth6893 \cellx9120\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 Uso}{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 \cell }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 ' + @UsoProd + '}{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20\highlight7'
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \cell }\pard \ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 \trowd \irow2\irowband2\lastrow \ltrrow\ts11\trgaph70\trleft-70\trbrdrt\brdrs\brdrw10 \trbrdrl\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrh\brdrs\brdrw10 \trbrdrv\brdrs\brdrw10 \trftsWidth3\trwWidth9190\trftsWidthB3\trftsWidthA3\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3 \clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 \cltxlrtb\clftsWidth3\clwWidth2297 \cellx2227\clvertalt\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10 '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \cltxlrtb\clftsWidth3\clwWidth6893 \cellx9120\row }\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \af38 \ltrch\fcs0 \lang2058\langfe3082\langnp2058  '
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @SeccionTabla
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@SeccionTabla))
				SET @SeccionTabla = ' \par }{\rtlch\fcs1 \af38 \ltrch\fcs0 \lang2058\langfe3082\langnp2058  '
				
				
				
				
				
			End
		fetch next from curProductos into @NombreProducto,@MarcaProd,@AhoProd,@ClaseProd,@ModeloProd,@CapacidadProd,@NoSerieProd,@NoMotorProd,@CEspecialProd,@UsoProd,@KmProd,@SubSerie,@VariableNumero
	end
close curProductos
deallocate curProductos

/***************** Fin descripcion bien *******************/

/*************SECCION DE AVALES**********/
DECLARE @AvalesNombres varchar(1000)
SET @AvalesNombres = ''
SET @NOFFSET = 0
SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%Avales%]'

SET @SeccionTabla = '\trowd\trpaddfl3\trpaddfr3\trftsWidth3\trftsWidthB3\trftsWidthA3\trbrdrt\trleft-70\brdrs\brdrw10\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trbrdrr\brdrs\brdrw10' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = '\clvertalt\clbrdrt\brdrs\brdrw10\clbrdrl\brdrs\brdrw10\clbrdrb\brdrs\brdrw10\clbrdrr\brdrs\brdrw10'
SET @SeccionTabla3 = '\cltxlrtb\clftsWidth3\'
SET  @SeccionTabla4 = '\pard\plain\ltrpar\ql\li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0\rtlch\fcs1\af0\afs24\alang1025\ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1\ab\af0\afs20\ltrch\fcs0\f37\fs20' 


DECLARE curAVALES cursor FOR
	SELECT CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )+' '+RTRIM(PFI_DS_NOMBRE ) ELSE rtrim(A.PNA_DS_NOMBRE) END ,A.PNA_CL_PJURIDICA, B.PRE_FL_PERSONA
	FROM CPERSONA A INNER JOIN KCTO_ASIG_LEGAL_CLIENTE B ON A.PNA_FL_PERSONA = B.PRE_FL_PERSONA 
	LEFT OUTER JOIN CPFISICA C ON C.PNA_FL_PERSONA= A.PNA_FL_PERSONA
	WHERE B.CTO_FL_CVE = @CveContrato and B.PNA_FL_PERSONA = @CveCliente AND B.ALG_CL_TIPO_RELACION  = 3	
OPEN curAVALES
FETCH NEXT FROM curAVALES INTO @VariableTexto,@VariableNumero,@VariableNumero2 
WHILE @@FETCH_STATUS = 0
	BEGIN 
		if @VariableNumero <> 20
			begin
				SET @AvalesNombres =  @AvalesNombres + @VariableTexto + ', '
			end
		else
			begin
				set @VariableTexto4 =''
				SELECT @VariableTexto4 = CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )+' '+ RTRIM(PFI_DS_NOMBRE ) ELSE rtrim(A.PNA_DS_NOMBRE) END
				FROM CPERSONA A INNER JOIN KCTO_ASIG_LEGAL_CLIENTE B ON A.PNA_FL_PERSONA = B.PRE_FL_PERSONA 
				LEFT OUTER JOIN CPFISICA  C ON C.PNA_FL_PERSONA= A.PNA_FL_PERSONA 
				WHERE B.CTO_FL_CVE = @CveContrato and B.PNA_FL_PERSONA = @VariableNumero2 AND B.ALG_CL_TIPO_RELACION  = 3	
				SET @AvalesNombres =  @AvalesNombres + @VariableTexto4 + '('+ @VariableTexto +')'+ ', '
			end
			
		IF @VariableNumero <> 20
			Begin
				SET @VariableTextoLarga = ''
				SET @VariableTextoLarga = '\ltrrow'+ @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1260 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  'Nombre\cell ' + @VariableTexto + ' \cell  }\pard\plain{'		
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = /*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\cellx1442 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth7918\cellx9360 '  +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))									

				Select @VariableTexto = CASE WHEN B.PNA_FL_PERSONA IS NOT NULL 
												THEN RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO ) +' '+RTRIM(PFI_DS_NOMBRE )
											ELSE rtrim(A.PNA_DS_NOMBRE) 
										END,
					@VariableTexto1 = case when PFI_FG_NACIONALIDAD = 1
											then 'Mexicana'
										when PFI_FG_NACIONALIDAD = 2
											then 'Extrangera'
										when PFI_FG_NACIONALIDAD is null
										    then ''
										end,
					@VariableFecha= B.PFI_FE_NACIMIENTO,
					@VariableTexto2= isnull(RTRIM(D.PAR_DS_DESCRIPCION),''),
					@VariableTexto3=isnull(RTRIM(E.PAR_DS_DESCRIPCION),''),
					@VariableTexto4=isnull(RTRIM(F.PAR_DS_DESCRIPCION),''),	
					@VariableTexto5=isnull(RTRIM(G.PAR_DS_DESCRIPCION),'')
				FROM CPERSONA A
				LEFT OUTER JOIN CPFISICA B 
				ON A.PNA_FL_PERSONA = B.PNA_FL_PERSONA		
				LEFT OUTER JOIN CPARAMETRO D 
				ON D.PAR_CL_VALOR = B.PFI_FG_OCUPACION AND D.PAR_FL_CVE= 15
				LEFT OUTER JOIN CPARAMETRO E 
				ON E.PAR_CL_VALOR = B.PFI_FG_EDO_CIVIL AND E.PAR_FL_CVE= 11
				LEFT OUTER JOIN CPARAMETRO F 
				ON F.PAR_CL_VALOR = B.PFI_FG_REGMAT AND F.PAR_FL_CVE= 16		
				LEFT OUTER JOIN CPARAMETRO G 
				ON G.PAR_CL_VALOR = B.PFI_FG_DACREDITA_NAC  
				AND F.PAR_FL_CVE= 28	
				WHERE A.PNA_FL_PERSONA = @VariableNumero2;
				
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
				
				set  @FechaTexto = cast(day(@VariableFecha) as varchar(2)) + '  de  ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								

				UPDATE #Claves 
				SET TEXTO= @FechaTexto 
				WHERE CLAVE='[%FechaNacAvalPFisica%]';
				

				update #claves 
				set texto = @VariableTexto1
				where clave = '[%NacionalidadAvalPFisica%]';
				
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2174' + @SeccionTabla2 + ' \cltxlrtb\cellx4500 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  'Lugar de Nacimiento\cell '    +  @VariableTexto1 + '\cell Fecha de Nacimiento:\cell  ' + @FechaTexto +   '\cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =/*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\cellx1900' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2324\cellx2324 ' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2360\cellx2360 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2693\cellx3693 ' +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

		
				UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%OcupacionAvalPFisica%]'
				UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%EdoCivilAvalPFisica%]'
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1260' + @SeccionTabla2 + ' \cltxlrtb\cellx4140 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx5760 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Ocupación\cell ' + @VariableTexto2 + ' \cell Estado Civil:\cell  ' + @VariableTexto3 +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =/*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1332\cellx1332' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2880\cellx2880 ' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1621\cellx1621 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth3594\cellx3594 ' +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				EXEC lsntReplace @VariableTexto4, @VariableTexto4 output   --> CAMBIO CARACTERES ESPECIALES
				UPDATE #Claves SET TEXTO= @VariableTexto4 WHERE CLAVE='[%RegAvalPFisica%]'
				SELECT @VariableTexto = RTRIM(PNA_CL_RFC) FROM CPERSONA WHERE PNA_FL_PERSONA = @VariableNumero2
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RFCAvalPFisica%]'
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx900' + @SeccionTabla2 + ' \cltxlrtb\cellx2700 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx5220 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' +  @SeccionTabla4 + '   RFC:\cell ' + @VariableTexto + ' \cell Régimen Matrimonial:\cell  ' + @VariableTexto4 +   ' \cell  }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				SET @VariableTextoLarga = /*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth969\cellx969' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1797\cellx1797 ' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2517\cellx2517 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth4133\cellx4133 ' +*/ ' \row }\pard\plain' 
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
									
									
				set 	@VariableTexto=''						
				SELECT @VariableTexto = RTRIM(DMO_DS_CALLE_NUM) + ' ' + RTRIM(DMO_DS_NUMEXT) + ' ' + RTRIM(DMO_DS_NUMINT) + ', COL. ' + RTRIM(DMO_DS_COLONIA)  
				+ ',  C.P.' +  RTRIM(DMO_CL_CPOSTAL) + ', '  + RTRIM(DMO_DS_CIUDAD)  +  ', '  +  RTRIM(DMO_DS_EFEDERATIVA)  FROM CDOMICILIO  WHERE PNA_FL_PERSONA = @VariableNumero2
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomicilioAvalPFisica%]'
				
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1620 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Domicilio:\cell ' + @VariableTexto + ' \cell }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = /*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1680\cellx1680 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth7680\cellx7680 '  +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				
				SET @VariableTexto =''
				Select @VariableTexto = RTRIM(A.PNA_DS_NOMBRE),@VariableTexto1 = ISNULL(RTRIM(PDA_DS_VALORAD),'')
				FROM CPERSONA A
				LEFT OUTER JOIN CPDATO_ADICIONAL B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA AND B.PTI_FG_VALOR = 3 AND B.DTA_FL_CVE= 3
				WHERE A.PNA_FL_PERSONA = @VariableNumero2
				UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%IdentificacionAvalPFisica%]'				
				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1620 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Identificación:\cell ' + @VariableTexto1 + ' \cell }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = /*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1680\cellx1680 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth7685\cellx7685 '  +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				
				SET @VariableNumero = 1
				SET @VariableTexto5 = ''
				SET @VariableTexto6 = ''
				SET @VariableTexto7 = ''
				SET @VariableTexto8 = ''
				DECLARE curCorreos CURSOR FOR
					Select rtrim(A.MAI_DS_EMAIL) FROM CPERSONA_EMAIL A WHERE A.PNA_FL_PERSONA = @VariableNumero2
				open curCorreos
				fetch next from curCorreos into @VariableTexto5
				while @@fetch_status = 0
					begin
						If @VariableNumero = 1
							set  @VariableTexto6 = @VariableTexto5							
						If @VariableNumero = 2
							set  @VariableTexto7 = @VariableTexto5
						If @VariableNumero = 3
							set  @VariableTexto8 = @VariableTexto5
						SET @VariableNumero = @VariableNumero + 1
						fetch next from curCorreos into @VariableTexto5
					end
				close curCorreos
				deallocate curCorreos														

				set @VariableTexto=''
				Select  TOP 1 @VariableTexto= ISNULL(TFN_CL_LARGA_DISTANCIA ,' ')+ CASE WHEN TFN_CL_LADA IS NOT NULL THEN '('+RTRIM(TFN_CL_LADA) +')' ELSE ' ' END + TFN_CL_TELEFONO + CASE WHEN TFN_CL_EXTENSION IS NOT NULL and LEN (RTRIM(ltrim(TFN_CL_EXTENSION)))>0 THEN ' EXT. ' + RTRIM(TFN_CL_EXTENSION) ELSE ' ' END 
				FROM CDOMICILIO A INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA
				INNER JOIN CTELEFONO CT ON CT.DMO_FL_CVE= A.DMO_FL_CVE 
				WHERE B.PNA_FL_PERSONA = @VariableNumero2 and DMO_FG_REGDEFAULT = 1
				ORDER BY CT.TFN_FL_CVE ASC

				SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1896' + @SeccionTabla2 + '\cltxlrtb\cellx5854' +  @SeccionTabla2 + '\cltxlrtb\cellx6766' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' +  @SeccionTabla4 + '  Correos Electrónicos:\cell ' + @VariableTexto6 + case when LEN(@VariableTexto8)>0 then ', 'else ''end +@VariableTexto8 + case when len(@VariableTexto7)>0 then ', ' else '' end + @VariableTexto7+ '\cell Teléfono:\cell ' + @VariableTexto  +   '\cell}\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = /*@SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1967\cellx1967' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth1956\cellx2000 ' +  @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2500\cellx2500 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth2500\cellx2500 ' +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				
				SET @VariableTextoLarga =  ' { \par  } '		
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES		
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
			End
		ELSE--avales morales
			Begin
				SET @VariableTextoLarga = ''
				

				SET @VariableTextoLarga =  @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3360 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Nombre, Razón Social o Denominación:\cell ' + @VariableTexto + ' \cell}\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga =/* @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth4360\cellx4360 ' + @SeccionTabla2 + ' \cltxlrtb\clftsWidth3\clwWidth5062\cellx5062 '  +*/ ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))											
--renglon 2
			SELECT @VariableTexto = RTRIM(DMO_DS_CALLE_NUM)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1069' + @SeccionTabla2 + ' \cltxlrtb\cellx4994 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx6000 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  '  Calle: \cell   '    +  @VariableTexto + '  \cell  '--}\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

			SELECT @VariableTexto =  RTRIM(DMO_DS_NUMEXT)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1					
				SET @VariableTextoLarga = ' Número:\cell  ' + @VariableTexto +   ' \cell}\pard\plain{ \row }\pard\plain'	
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				
--renglon 3				
			SELECT @VariableTexto =  RTRIM(DMO_DS_COLONIA)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1					
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1069' + @SeccionTabla2 + '\cltxlrtb\cellx4994 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx6000 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  '  Colonia: \cell   '    +  @VariableTexto + '  \cell  '--}\pard\plain{'															
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

			SELECT @VariableTexto =  RTRIM(DMO_DS_CIUDAD)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1							
				SET @VariableTextoLarga = ' Ciudad:\cell  ' + @VariableTexto +   ' \cell}\pard\plain{ \row }\pard\plain'	
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

--renglon 4		
			SELECT @VariableTexto =  RTRIM(DMO_DS_EFEDERATIVA)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1	
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1069' + @SeccionTabla2 + ' \cltxlrtb\cellx4360 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx4994 ' +@SeccionTabla2 + ' \cltxlrtb\cellx6000 ' +@SeccionTabla2 + ' \cltxlrtb\cellx7000 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  '  Estado: \cell   '    +  @VariableTexto + '\cell  '--}\pard\plain{'																		
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
			SELECT @VariableTexto =  RTRIM(DMO_CL_CPOSTAL)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1	
				SET @VariableTextoLarga = ' C.P. \cell  ' + @VariableTexto +   '\cell '	
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

			SELECT @VariableTexto = RTRIM(PNA_CL_RFC) FROM CPERSONA WHERE PNA_FL_PERSONA = @VariableNumero2
				SET @VariableTextoLarga = ' R.F.C. \cell  ' + @VariableTexto +   ' \cell}\pard\plain{ \row }\pard\plain'	
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

--renglon 5				
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1896' + @SeccionTabla2 + ' \cltxlrtb\cellx5854 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx6766 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  '  Correo electrónico: \cell   ' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				SET @VariableNumero3 = 1				
				DECLARE curCorreos CURSOR FOR
					Select rtrim(MAI_DS_EMAIL) FROM CPERSONA_EMAIL WHERE PNA_FL_PERSONA = @VariableNumero2
				open curCorreos
				fetch next from curCorreos into @VariableTexto2
				while @@fetch_status = 0
					begin					
						If @VariableNumero3 < 4
							begin
								set @VariableTextoLarga =  @VariableTexto2 +'; '-- ' \par ' 
								EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
								UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
								SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
							end													
						SET @VariableNumero3 = @VariableNumero3 + 1
						fetch next from curCorreos into @VariableTexto2
					end
				close curCorreos
				deallocate curCorreos		
				
				SET @VariableTextoLarga = ' \cell '			
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				set @VariableTexto=''
			Select  TOP 1 @VariableTexto= ISNULL(TFN_CL_LARGA_DISTANCIA ,' ')+ CASE WHEN TFN_CL_LADA IS NOT NULL THEN '('+RTRIM(TFN_CL_LADA) +')' ELSE ' ' END + TFN_CL_TELEFONO + CASE WHEN TFN_CL_EXTENSION IS NOT NULL and LEN (RTRIM(ltrim(TFN_CL_EXTENSION)))>0 THEN ' EXT. ' + RTRIM(TFN_CL_EXTENSION) ELSE ' ' END 
			FROM CDOMICILIO A INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA
			INNER JOIN CTELEFONO CT ON CT.DMO_FL_CVE= A.DMO_FL_CVE 
			WHERE B.PNA_FL_PERSONA = @VariableNumero2 and DMO_FG_REGDEFAULT = 1
			ORDER BY CT.TFN_FL_CVE ASC

				SET @VariableTextoLarga = ' Teléfono: \cell  ' + @VariableTexto +   ' \cell }\pard\plain{\row }\pard\plain'	
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
					
				SET @VariableTextoLarga =  ' {\par  } '				
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
																					
		set @VariableTexto = ''
		set @VariableNumero4 =0
		SELECT @VariableNumero4= ESC_FL_CVE ,  @VariableTexto =  ESC_NO_ESCRITURA FROM KESCRITURA WHERE PNA_FL_PERSONA = @VariableNumero2 AND ESC_CL_TESCRITURA = 1		
		IF @VariableTexto <> '' AND @VariableTexto IS NOT NULL
			Begin
			
				SET @VariableTextoLarga ='\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \b\f40\fs20\cf1\lang1034\langfe3082\langnp1034 Datos del Acta Constitutiva: \par }'
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				SET @VariableTextoLarga = ''
				SET @VariableTextoLarga =  @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3060 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Escritura Pública Número:\cell ' + @VariableTexto + ' \cell }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =  ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				--renglon 2
				
				SELECT @VariableFecha =  ESC_FE_ESCRITURA FROM KESCRITURA WHERE PNA_FL_PERSONA = @VariableNumero2 AND ESC_CL_TESCRITURA = 1
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				

				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3060' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 '  + @SeccionTabla4 +  '  Fecha:\cell '    +  @VariableTexto +   ' \cell }\pard\plain{'  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				--renglon 3				
				set	@VariableTexto=''
				set @VariableTexto1=''
				set @VariableTexto4=''	
				set @VariableFecha2 ='1900-01-01'		
				SELECT @VariableTexto = RTRIM(A.NOT_DS_NOMBRE) + ' ' + RTRIM(A.NOT_DS_APATERNO) + ' ' + RTRIM(A.NOT_DS_AMATERNO), 
				@VariableTexto1 = A.NOT_NO_NOTARIO,@VariableTexto2 = RTRIM(C.CIU_NB_CIUDAD),@VariableTexto3 = RTRIM(B.ESC_DS_REGISTRO),
				@VariableFecha2 = B.ESC_FE_INSCRITA ,
				@VariableTexto4 = B.ESC_DS_REGISTRO + '  LIBRO:' + RTRIM(B.ESC_DS_LIBRO) + ' FOJAS:' + RTRIM(B.ESC_DS_FOJAS) + ' SECCION:' + RTRIM(B.ESC_DS_SECCION) + ' VOLUMEN:' + RTRIM( B.ESC_DS_VOLUMEN) + ' TOMO:' + RTRIM( ESC_DS_TOMO)

				FROM CNOTARIO A INNER JOIN KESCRITURA B ON A.NOT_FL_CVE = B.NOT_FL_CVE AND B.ESC_CL_TESCRITURA = 1
				INNER JOIN CCIUDAD C ON C.CIU_CL_CIUDAD = A.CIU_CL_CIUDAD and C.EFD_CL_CVE =A.EFD_CL_CVE 
				WHERE B.PNA_FL_PERSONA =  @VariableNumero2							
	
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2173' + @SeccionTabla2 + ' \cltxlrtb\cellx4860 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx7380 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  ' Otorgada ante el Lic.:\cell '  +  @VariableTexto +  '\cell '  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				set @VariableTextoLarga = ' Corredor o Notario No: \cell ' + @VariableTexto1 + ' \cell}\pard\plain{' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
																				
				SET @VariableTextoLarga ='\row}\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				--renglon 4				
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1980' + @SeccionTabla2 + ' \cltxlrtb\cellx4500 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx7020 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  ' En la Ciudad de:\cell '    +  @VariableTexto2 +   ' \cell '  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				set @VariableTextoLarga = ' Inscrita en el Registro de:  \cell ' + @VariableTexto3 + '\cell }\pard\plain{' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))
									
									
		--datos del registro público		
				SET @VariableTextoLarga ='\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \b\f40\fs20\cf1\lang1034\langfe3082\langnp1034\par Datos de Registro Público de la Propiedad y Comercio:\par }'		
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			
				if month(@VariableFecha2) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha2) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha2) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha2) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha2) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha2) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha2) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha2) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha2) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha2) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha2) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha2) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha2) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha2) as varchar(4))								
				
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2160' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Datos de Registro:\cell   '    +  @VariableTexto4 +   ' \cell }\pard\plain{'  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga = ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				--renglon 2
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2160' + @SeccionTabla2 + ' \cltxlrtb\cellx4418 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx6663 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  '  De Fecha:\cell   '    +  @VariableTexto +   ' \cell '  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				set @VariableTextoLarga = ' Del Registro Público:  \cell ' + '\cell }\pard\plain{' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga =' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))
				
		--Representante
		
				SET @VariableNumero = 0

				select top 1 @VariableNumero=KE.ESC_FL_CVE , @VariableTexto = CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO ) ELSE rtrim(PE.PNA_DS_NOMBRE) END,@VariableTexto1 = ISNULL(RTRIM(PDA_DS_VALORAD),'') from KAPODERADO AP inner join  CPERSONA PE on PE.PNA_FL_PERSONA  = ap.PNA_FL_PERSONA 
				INNER JOIN KESCRITURA KE ON KE.ESC_FL_CVE = AP.ESC_FL_CVE 
				LEFT OUTER JOIN CPDATO_ADICIONAL B ON B.PNA_FL_PERSONA = PE.PNA_FL_PERSONA AND B.PTI_FG_VALOR = 4 AND B.DTA_FL_CVE= 2
				LEFT OUTER JOIN CPFISICA C ON C.PNA_FL_PERSONA = PE.PNA_FL_PERSONA 
				WHERE KE.PNA_FL_PERSONA =@VariableNumero2  AND KE.ESC_CL_TESCRITURA in (1,4) order by KE.ESC_FE_ESCRITURA desc 

				exec lsntReplace  @VariableTexto,@VariableTexto OUTPUT
				
				SET @VariableTextoLarga ='\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0\b\f40\fs20\cf1\lang1034\langfe3082\langnp1034\par Representante:\par }'				
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2880' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 '  + @SeccionTabla4 +  '  Nombre del Apoderado:\cell   '    +  @VariableTexto +   ' \cell }\pard\plain{'  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				SET @VariableTextoLarga =' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))

				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2880'  + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  '  Identificación del Apoderado:\cell   '    +  @VariableTexto1 +   ' \cell }\pard\plain{'  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))
										
				if @VariableNumero !=@VariableNumero4 
					begin
						SELECT @VariableTexto =  ESC_NO_ESCRITURA FROM KESCRITURA WHERE ESC_FL_CVE =@VariableNumero 
						IF @VariableTexto <> '' AND @VariableTexto IS NOT NULL
							Begin
					
						SET @VariableTextoLarga ='\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \b\f40\fs20\cf1\lang1034\langfe3082\langnp1034\par Datos escritura facultades del representante legal:\par }'	
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

						SET @VariableTextoLarga = ''
						SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3060 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Escritura Pública Número:\cell ' + @VariableTexto + ' \cell }\pard\plain{'						
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						SET @VariableTextoLarga =  ' \row }\pard\plain' 
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						--renglon 2
						
						SELECT @VariableFecha =  ESC_FE_ESCRITURA FROM KESCRITURA WHERE ESC_FL_CVE =@VariableNumero 
						if month(@VariableFecha) = 1
							SET @Mes = 'Enero'
						if month(@VariableFecha) = 2
							SET @Mes = 'Febrero'
						if month(@VariableFecha) = 3
							SET @Mes = 'Marzo'
						if month(@VariableFecha) = 4
							SET @Mes = 'Abril'
						if month(@VariableFecha) = 5
							SET @Mes = 'Mayo'
						if month(@VariableFecha) = 6
							SET @Mes = 'Junio'
						if month(@VariableFecha) = 7
							SET @Mes = 'Julio'
						if month(@VariableFecha) = 8
							SET @Mes = 'Agosto'
						if month(@VariableFecha) = 9
							SET @Mes = 'Septiembre'
						if month(@VariableFecha) = 10
							SET @Mes = 'Octubre'
						if month(@VariableFecha) = 11
							SET @Mes = 'Noviembre'
						if month(@VariableFecha) = 12
							SET @Mes = 'Diciembre'
						set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				

						SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3060' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Fecha:\cell   '    +  @VariableTexto +   ' \cell }\pard\plain{'  
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						
						SET @VariableTextoLarga = ' \row }\pard\plain' 
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						
						--renglon 3												
						SELECT @VariableTexto = RTRIM(A.NOT_DS_NOMBRE) + ' ' + RTRIM(A.NOT_DS_APATERNO) + ' ' + RTRIM(A.NOT_DS_AMATERNO), 
						@VariableTexto1 = A.NOT_NO_NOTARIO,@VariableTexto2 = RTRIM(C.CIU_NB_CIUDAD),@VariableTexto3 = RTRIM(B.ESC_DS_REGISTRO),
						@VariableFecha2 = B.ESC_FE_INSCRITA ,
						@VariableTexto4 = B.ESC_DS_REGISTRO + '  LIBRO:' + RTRIM(B.ESC_DS_LIBRO) + ' FOJAS:' + RTRIM(B.ESC_DS_FOJAS) + ' SECCION:' + RTRIM(B.ESC_DS_SECCION) + ' VOLUMEN:' + RTRIM( B.ESC_DS_VOLUMEN) + ' TOMO:' + RTRIM( ESC_DS_TOMO)

						FROM CNOTARIO A INNER JOIN KESCRITURA B ON A.NOT_FL_CVE = B.NOT_FL_CVE 
						INNER JOIN CCIUDAD C ON C.CIU_CL_CIUDAD = A.CIU_CL_CIUDAD and C.EFD_CL_CVE =A.EFD_CL_CVE 
						WHERE B.ESC_FL_CVE =@VariableNumero 
			
						SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2173' + @SeccionTabla2 + ' \cltxlrtb\cellx4860 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx7380 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356' + @SeccionTabla4 +  '  Otorgada ante el Lic.:\cell   '    +  @VariableTexto +   ' \cell '  
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						
						set @VariableTextoLarga = 'Corredor o Notario No:  \cell ' + @VariableTexto1 + '\cell }\pard\plain{' 
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
										
						SET @VariableTextoLarga = ' \row }\pard\plain' 
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						
						--renglon 4				
						SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1980' + @SeccionTabla2 + ' \cltxlrtb\cellx4500' +  @SeccionTabla2 + ' \cltxlrtb\cellx7020 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356' + @SeccionTabla4 +  '  En la Ciudad de:\cell   '    +  @VariableTexto2 +   ' \cell '  
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						
						set @VariableTextoLarga = 'Inscrita en el Registro de:  \cell ' + @VariableTexto3 + '\cell }\pard\plain{' 
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
						
						SET @VariableTextoLarga = ' \row }\pard\plain' 
						EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
						UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
						SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))
						end
						
					end	
													
			End
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%ApoderadoAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%IdentificacionApoderadoAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NumPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%FechaPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NotarioPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NumNotarioPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CiudadPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%RegistroPoderAvalPMoral%]'

		SET @VariableTextoLarga ='\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0\b\f40\fs20\cf1\lang1034\langfe3082\langnp1034\par Objeto de la Sociedad:\par }'				
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
		UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
		SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
		
		SELECT @VariableTextoLarga  = RTRIM(DLE_DS_OBJETOSOCIAL) FROM KDICTAMEN_LEGAL WHERE PNA_FL_PERSONA = @VariableNumero2
		exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
		
				
		SET @VariableTextoLarga = @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx900' + @SeccionTabla2 + ' \cltxlrtb\cellx9356' + @SeccionTabla4 +  ' Objeto:\cell ' + rtrim(@VariableTextoLarga) + ' \cell }\pard\plain{'						
		exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
		UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
		SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
		SET @VariableTextoLarga =  ' \row}\pard\plain' 
		exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
		UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
		SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
																				
		End
		FETCH NEXT FROM curAVALES INTO @VariableTexto,@VariableNumero,@VariableNumero2 
	END
CLOSE curAVALES
DEALLOCATE curAVALES

set @AvalesNombres=''
SET @NOFFSET = 0
SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%ClausulaFiadores%]'

DECLARE curAVALES2 cursor FOR
	SELECT CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO ) ELSE rtrim(A.PNA_DS_NOMBRE) END,
		A.PNA_CL_PJURIDICA, B.PRE_FL_PERSONA,
		'Calle: ' + DMO_DS_CALLE_NUM + ' No. ' + DMO_DS_NUMEXT + ' Col. ' + DMO_DS_COLONIA + case when DMO_DS_NUMINT != ''
															then ' - ' + DMO_DS_NUMINT
														else ''
													end + ' CP: ' + 
			DMO_CL_CPOSTAL + ', ' + DMO_DS_MUNICIPIO + ', ' + DMO_DS_EFEDERATIVA Direccion
	FROM CPERSONA A 
	INNER JOIN KCTO_ASIG_LEGAL_CLIENTE B 
	ON A.PNA_FL_PERSONA = B.PRE_FL_PERSONA 
	LEFT OUTER JOIN CPFISICA C 
	ON C.PNA_FL_PERSONA = A.PNA_FL_PERSONA
	inner join CDOMICILIO d
	on c.pna_fl_persona = d.pna_fl_persona
	WHERE B.CTO_FL_CVE = @CveContrato 
	and B.PNA_FL_PERSONA = @CveCliente 
	AND B.ALG_CL_TIPO_RELACION  = 3	
OPEN curAVALES2
FETCH NEXT FROM curAVALES2 INTO @VariableTexto,@VariableNumero,@VariableNumero2, @varDireccion 
WHILE @@FETCH_STATUS = 0
	BEGIN
		if @VariableNumero <> 20
			begin
				
				if ((
				select sum(case when items = @VariableTexto
									then 1
								else 0
							end)
					from dbo.split(@AvalesNombres, ','))= 0)
					
				begin
					SET @AvalesNombres =  @AvalesNombres + @VariableTexto + ', '
					
				end						
				
				set @AvalesNombDirec = @AvalesNombDirec + 'El(La) Sr.(a) ' + @VariableTexto + ' como “OBLIGADO SOLIDARIO” el ubicado en ' + @varDireccion + '.\par '
				
				SET @VariableTextoLarga = '\par\pard \ltrpar\s18\qj \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0\pararsid15993734 {\rtlch\fcs1 \ab\af40\afs20 \ltrch\fcs0 \b\fs20\cf1 \hich\af40\dbch\af40\loch\f40 III.- Declara(n) el(los) Fiador(es) por su propio derecho:'
				SET @VariableTextoLarga =	rtrim(@VariableTextoLarga) + ' \par {\listtext\pard\plain\ltrpar \s18 \rtlch\fcs1 \af40\afs20 \ltrch\fcs0 \b\f40\fs20\cf1\lang1034\langfe3082\langnp1034 \hich\af40\dbch\af40\loch\f40 a)\tab}}\pard \ltrpar\s18\qj \fi-630\li990\ri0\widctlpar'
				SET @VariableTextoLarga =	rtrim(@VariableTextoLarga) + ' \jclisttab\tx990\wrapdefault\aspalpha\aspnum\faauto\ls6\adjustright\rin0\lin990\itap0 {\rtlch\fcs1 \af40\afs20 \ltrch\fcs0 \fs20\cf1 \hich\af40\dbch\af40\loch\f40 \hich\f40 Ser una persona física que cuenta con la capacidad legal y económica para celebrar el presente Contrato, y que sus generales señalados en la Carátula del presente Contrato, son verdaderos, por lo que se obliga solidaria y subsidiariamente y garantiza el puntual cumplimiento de las obligaciones derivadas del presente Contrato a cargo de La Arrendataria, manifestando ser económicamente solvente.]\par }\pard '
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			end
		ELSE
			BEGIN
			
			SET @VariableTextoLarga = '\par\pard\ltrpar\s18\qj \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0\ {\rtlch\fcs1 \ab\af40\afs20 \ltrch\fcs0 \b\fs20\cf1 \hich\af40\dbch\af40\loch\f40 \hich\f40 III.- Declara(n) el(los) Fiador(es) a través de su representante legal:'
			SET @VariableTextoLarga =	rtrim(@VariableTextoLarga) + ' \par {\listtext\pard\plain\ltrpar \s18 \rtlch\fcs1 \af40\afs20 \ltrch\fcs0 \f40\fs20\cf1\lang1034\langfe3082\langnp1034 \hich\af40\dbch\af40\loch\f40 a)\tab}}\pard \ltrpar\s18\qj \fi-360\li720\ri0\widctlpar'
			SET @VariableTextoLarga =	rtrim(@VariableTextoLarga) + ' \jclisttab\tx720\wrapdefault\aspalpha\aspnum\faauto\ls7\adjustright\rin0\lin720\itap0 {\rtlch\fcs1 \af40\afs20 \ltrch\fcs0 \fs20\cf1 \hich\af40\dbch\af40\loch\f40 \hich\f40 Que es una sociedad debidamente constituida bajo las leyes de los Estados Unidos Mexicanos, e inscrita en el Registro Público y que además cuenta con la capacidad legal y económica para celebrar el presente Contrato, por así manifestarlo expresamente su objeto social, y que los datos y domicilio señalados en  la Carátula del presente Contrato son verdaderos, por lo que a través de su representante legal se obliga y garantiza el puntual cumplimiento de las obligaciones derivadas del presente Contrato a cargo de La Arrendataria, manifestando ser económicamente solvente.]\par }\pard '
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))				
			END	
		FETCH NEXT FROM curAVALES2 INTO @VariableTexto,@VariableNumero,@VariableNumero2, @varDireccion 	
	END
CLOSE curAVALES2
DEALLOCATE curAVALES2
	--UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%ClausulaFiadores%]'



/*Escritura poderes*/
SET @NOFFSET = 0
SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%EscrituraRepLegal%]'
set @VariableTexto = ''
set @VariableNumero4 =0
select top 1 @VariableNumero4= ke.ESC_FL_CVE  from KCTO_ASIG_LEGAL_ESCRITURA  kce inner join KESCRITURA ke on ke.esc_fl_cve = kce.ESC_FL_CVE  where 
KE.ESC_CL_TESCRITURA IN(4,5)  and kce.PNA_FL_PERSONA = @CveCliente and kce.CTO_FL_CVE =@CveContrato order by ke.ESC_FE_ESCRITURA desc
			
		IF @VariableNumero4 >0  AND @VariableNumero4 IS NOT NULL
			Begin						
			
			SELECT @VariableTexto =  ESC_NO_ESCRITURA FROM KESCRITURA KE WHERE KE.ESC_FL_CVE = @VariableNumero4
										
				SET @VariableTextoLarga ='\pard \ltrpar\ql \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0\b\f40\fs20\cf1\lang1034\langfe3082\langnp1034\par Datos escritura facultades del representante legal: \par }'
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

				SET @VariableTextoLarga = ''
				SET @VariableTextoLarga =  '\pard\plain \par\ltrrow'+  @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3060 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  '  Escritura Pública Número:\cell ' + @VariableTexto + ' \cell }\pard\plain{'						
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				SET @VariableTextoLarga =  ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				--renglon 2
				
				SELECT @VariableFecha =  ESC_FE_ESCRITURA FROM KESCRITURA  WHERE ESC_FL_CVE = @VariableNumero4
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				

				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx3060' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 '  + @SeccionTabla4 +  '  Fecha:\cell '    +  @VariableTexto +   ' \cell }\pard\plain{'  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				--renglon 3				
				set	@VariableTexto=''
				set @VariableTexto1=''
				set @VariableTexto4=''	
				set @VariableFecha2 ='1900-01-01'		
				SELECT @VariableTexto = RTRIM(A.NOT_DS_NOMBRE) + ' ' + RTRIM(A.NOT_DS_APATERNO) + ' ' + RTRIM(A.NOT_DS_AMATERNO), 
				@VariableTexto1 = A.NOT_NO_NOTARIO,@VariableTexto2 = RTRIM(C.CIU_NB_CIUDAD),@VariableTexto3 = RTRIM(B.ESC_DS_REGISTRO),
				@VariableFecha2 = B.ESC_FE_INSCRITA ,
				@VariableTexto4 = B.ESC_DS_REGISTRO + '  LIBRO:' + RTRIM(B.ESC_DS_LIBRO) + ' FOJAS:' + RTRIM(B.ESC_DS_FOJAS) + ' SECCION:' + RTRIM(B.ESC_DS_SECCION) + ' VOLUMEN:' + RTRIM( B.ESC_DS_VOLUMEN) + ' TOMO:' + RTRIM( ESC_DS_TOMO)

				FROM CNOTARIO A INNER JOIN KESCRITURA B ON A.NOT_FL_CVE = B.NOT_FL_CVE 
				INNER JOIN CCIUDAD C ON C.CIU_CL_CIUDAD = A.CIU_CL_CIUDAD and C.EFD_CL_CVE =A.EFD_CL_CVE 
				 WHERE ESC_FL_CVE = @VariableNumero4
	
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx2173' + @SeccionTabla2 + ' \cltxlrtb\cellx4860 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx7380 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356  ' + @SeccionTabla4 +  ' Otorgada ante el Lic.:\cell '  +  @VariableTexto +  '\cell '  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				set @VariableTextoLarga = ' Corredor o Notario No: \cell ' + @VariableTexto1 + ' \cell}\pard\plain{' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
																				
				SET @VariableTextoLarga ='\row}\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				--renglon 4				
				SET @VariableTextoLarga =   @SeccionTabla + @SeccionTabla2 + ' \cltxlrtb\cellx1980' + @SeccionTabla2 + ' \cltxlrtb\cellx4500 ' +  @SeccionTabla2 + ' \cltxlrtb\cellx7020 ' + @SeccionTabla2 + ' \cltxlrtb\cellx9356 ' + @SeccionTabla4 +  ' En la Ciudad de:\cell '    +  @VariableTexto2 +   ' \cell '  
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				set @VariableTextoLarga = ' Inscrita en el Registro de:  \cell ' + @VariableTexto3 + '\cell }\pard\plain{' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				SET @VariableTextoLarga = ' \row }\pard\plain' 
				EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))
		end

/*Escritura poderes*/

/************* FIN SECCION DE AVALES**********/


SELECT @VariableTexto = case when pf.pna_fl_persona is null then pm.PMO_DS_RAZON_SOCIAL  else RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )  end  ,@VariableNumero = A.PNA_CL_PJURIDICA,@VariableNumero2 = B.PRE_FL_PERSONA
FROM CPERSONA A INNER JOIN  KCTO_ASIG_LEGAL_CLIENTE B ON A.PNA_FL_PERSONA = B.PRE_FL_PERSONA 

left outer join cpfisica pf on pf.PNA_FL_PERSONA =a.PNA_FL_PERSONA 
left outer join cpmoral pm on pm.PNA_FL_PERSONA =a.PNA_FL_PERSONA
WHERE B.CTO_FL_CVE = @CveContrato and B.PNA_FL_PERSONA = @CveCliente AND B.ALG_CL_TIPO_RELACION  = 3;

UPDATE #Claves 
SET TEXTO= substring(@AvalesNombres, 0, len(@AvalesNombres))  
WHERE CLAVE='[%NombresAvales%]';

EXEC lsntReplace @AvalesNombDirec, @AvalesNombDirec output;

UPDATE #Claves 
SET TEXTO= @AvalesNombDirec  
WHERE CLAVE='[%AvalesNombDirec%]';


IF @VariableNumero = 20
	Begin
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NombreAvalPMoral%]'
		SELECT @VariableTexto = RTRIM(DMO_DS_CALLE_NUM)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CalleAvalPMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_NUMEXT)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NumCalleAvalPMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_COLONIA)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1	
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ColoniaAvalPMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_CIUDAD)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1	
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CiudadAvalPMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_DS_EFEDERATIVA)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1	
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%EstadoAvalPMoral%]'
		SELECT @VariableTexto =  RTRIM(DMO_CL_CPOSTAL)  FROM CDOMICILIO WHERE PNA_FL_PERSONA = @VariableNumero2 AND DMO_FG_REGDEFAULT = 1	
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CPAvalPMoral%]'
		SELECT @VariableTexto = RTRIM(PNA_CL_RFC) FROM CPERSONA WHERE PNA_FL_PERSONA = @VariableNumero2
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RFCAvalPMoral%]'
		SET @VariableNumero3 = 1
		DECLARE curCorreos CURSOR FOR
			Select rtrim(MAI_DS_EMAIL) FROM CPERSONA_EMAIL WHERE PNA_FL_PERSONA = @VariableNumero2
		open curCorreos
		fetch next from curCorreos into @VariableTexto2
		while @@fetch_status = 0
			begin
				If @VariableNumero3 = 1
					UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%CorreoAvalPMoral1%]'
				If @VariableNumero3 = 2
					UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%CorreoAvalPMoral2%]'
				If @VariableNumero3 = 3
					UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%CorreoAvalPMoral3%]'
				SET @VariableNumero3 = @VariableNumero3 + 1
				fetch next from curCorreos into @VariableTexto2
			end
		close curCorreos
		deallocate curCorreos										
		set @VariableTexto = ''
		SELECT @VariableTexto =  ESC_NO_ESCRITURA FROM KESCRITURA WHERE PNA_FL_PERSONA = @VariableNumero2 AND ESC_CL_TESCRITURA = 1		
		IF @VariableTexto <> '' AND @VariableTexto IS NOT NULL
			Begin
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NumEscAvalPMoral%]'
				SELECT @VariableFecha =  ESC_FE_ESCRITURA FROM KESCRITURA WHERE PNA_FL_PERSONA = @VariableNumero2 AND ESC_CL_TESCRITURA = 1
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaEscAvalPMoral%]'
				SELECT @VariableTexto = RTRIM(A.NOT_DS_NOMBRE) + ' ' + RTRIM(A.NOT_DS_APATERNO) + ' ' + RTRIM(A.NOT_DS_AMATERNO), 
				@VariableTexto1 = A.NOT_NO_NOTARIO,@VariableTexto2 = RTRIM(C.CIU_NB_CIUDAD),@VariableTexto3 = RTRIM(B.ESC_DS_REGISTRO)
				FROM CNOTARIO A INNER JOIN KESCRITURA B ON A.NOT_FL_CVE = B.NOT_FL_CVE AND B.ESC_CL_TESCRITURA = 1
				INNER JOIN CCIUDAD C ON C.CIU_CL_CIUDAD = A.CIU_CL_CIUDAD and C.EFD_CL_CVE =A.EFD_CL_CVE 
				WHERE B.PNA_FL_PERSONA =  @CveCliente							
	
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NotarioAvalPMoral%]'
				UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%NumNotarioAvalPMoral%]'
				UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%CiudadEscAvalPMoral%]'
				UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%RegistroEscAvalPMoral%]'
			End
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%ApoderadoAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%IdentificacionApoderadoAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NumPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%FechaPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NotarioPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NumNotarioPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%CiudadPoderAvalPMoral%]'
		UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%RegistroPoderAvalPMoral%]'
		SELECT @VariableTextoLarga  = RTRIM(DLE_DS_OBJETOSOCIAL) FROM KDICTAMEN_LEGAL WHERE PNA_FL_PERSONA = @VariableNumero2
		exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%ObjetoSocialAvalPMoral%]'
	End
Else
	Begin
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NombreAvalPFisica%]'

		Select @VariableTexto= RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO ),@VariableTexto1=isnull(RTRIM(B.PFI_DS_LNACIMIENTO),''),@VariableFecha=B.PFI_FE_NACIMIENTO,
		@VariableTexto2=isnull(RTRIM(D.PAR_DS_DESCRIPCION),''),@VariableTexto3=isnull(RTRIM(E.PAR_DS_DESCRIPCION),''),@VariableTexto4=isnull(RTRIM(F.PAR_DS_DESCRIPCION),'')
		,@VariableTexto5=isnull(RTRIM(G.PAR_DS_DESCRIPCION),'')
		FROM CPERSONA A
		LEFT OUTER JOIN CPFISICA B ON A.PNA_FL_PERSONA = B.PNA_FL_PERSONA		
		LEFT OUTER JOIN CPARAMETRO D ON D.PAR_CL_VALOR = B.PFI_FG_OCUPACION AND D.PAR_FL_CVE= 15
		LEFT OUTER JOIN CPARAMETRO E ON E.PAR_CL_VALOR = B.PFI_FG_EDO_CIVIL AND E.PAR_FL_CVE= 11
		LEFT OUTER JOIN CPARAMETRO F ON F.PAR_CL_VALOR = B.PFI_FG_REGMAT AND F.PAR_FL_CVE= 16		
		LEFT OUTER JOIN CPARAMETRO G ON G.PAR_CL_VALOR = B.PFI_FG_DACREDITA_NAC  AND F.PAR_FL_CVE= 28	
		WHERE A.PNA_FL_PERSONA = @VariableNumero2
		
		UPDATE #Claves 
		SET TEXTO= @VariableTexto1 
		WHERE CLAVE='[%LugarNacAvalPFisica%]';
		
		if month(@VariableFecha) = 1
			SET @Mes = 'Enero'
		if month(@VariableFecha) = 2
			SET @Mes = 'Febrero'
		if month(@VariableFecha) = 3
			SET @Mes = 'Marzo'
		if month(@VariableFecha) = 4
			SET @Mes = 'Abril'
		if month(@VariableFecha) = 5
			SET @Mes = 'Mayo'
		if month(@VariableFecha) = 6
			SET @Mes = 'Junio'
		if month(@VariableFecha) = 7
			SET @Mes = 'Julio'
		if month(@VariableFecha) = 8
			SET @Mes = 'Agosto'
		if month(@VariableFecha) = 9
			SET @Mes = 'Septiembre'
		if month(@VariableFecha) = 10
			SET @Mes = 'Octubre'
		if month(@VariableFecha) = 11
			SET @Mes = 'Noviembre'
		if month(@VariableFecha) = 12
			SET @Mes = 'Diciembre'
		set  @FechaTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))								

		UPDATE #Claves SET TEXTO= @FechaTexto WHERE CLAVE='[%FechaNacAvalPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%OcupacionAvalPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%EdoCivilAvalPFisica%]'
		SELECT @VariableTexto = RTRIM(PNA_CL_RFC) FROM CPERSONA WHERE PNA_FL_PERSONA = @VariableNumero2
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RFCAvalPFisica%]'
		SELECT @VariableTexto = RTRIM(DMO_DS_CALLE_NUM) + ' ' + RTRIM(DMO_DS_NUMEXT) + ' ' + RTRIM(DMO_DS_NUMINT) + ', COL. ' + RTRIM(DMO_DS_COLONIA)  
		+ ',  C.P.' +  RTRIM(DMO_CL_CPOSTAL) + ', '  + RTRIM(DMO_DS_CIUDAD)  +  ', '  +  RTRIM(DMO_DS_EFEDERATIVA)  FROM CDOMICILIO  WHERE PNA_FL_PERSONA = @VariableNumero2
		UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomicilioAvalPFisica%]'
		UPDATE #Claves SET TEXTO= @VariableTexto4 WHERE CLAVE='[%RegAvalPFisica%]'
		SET @VariableTexto =''
		Select @VariableTexto = RTRIM(A.PNA_DS_NOMBRE),@VariableTexto1 = ISNULL(RTRIM(PDA_DS_VALORAD),'')
		FROM CPERSONA A
		LEFT OUTER JOIN CPDATO_ADICIONAL B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA AND B.PTI_FG_VALOR = 3 AND B.DTA_FL_CVE= 3
		WHERE A.PNA_FL_PERSONA = @VariableNumero2
		UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%IdentificacionAvalPFisica%]'
		SET @VariableNumero = 1
		SET @VariableTexto5 = ''
		DECLARE curCorreos CURSOR FOR
			Select rtrim(A.MAI_DS_EMAIL) FROM CPERSONA_EMAIL A WHERE A.PNA_FL_PERSONA = @CveCliente
		open curCorreos
		fetch next from curCorreos into @VariableTexto5
		while @@fetch_status = 0
			begin
				If @VariableNumero = 1
					UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CorreoAvalPFisica1%]'
				If @VariableNumero = 2
					UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CorreoAvalPFisica2%]'
				If @VariableNumero = 3
					UPDATE #Claves SET TEXTO= @VariableTexto5 WHERE CLAVE='[%CorreoAvalPFisica3%]'			
				SET @VariableNumero = @VariableNumero + 1
				fetch next from curCorreos into @VariableTexto5
			end
		close curCorreos
		deallocate curCorreos										
	End

UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%AseguradoPolizaVida%]'
--acarrillo UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%TipoProducto%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%ReferenciaPago%]'

--Obtenemos los representates de la empresa
set @VariableTexto3= ''
DECLARE curRepEmpresa CURSOR FOR
	SELECT
		CEMPRESA_REPRESENTANTE.ERE_DS_NOMBRE,
		CEMPRESA_REPRESENTANTE.ERE_DS_PATERNO,
		CEMPRESA_REPRESENTANTE.ERE_DS_MATERNO
	FROM
		CEMPRESA_REPRESENTANTE
	LEFT OUTER JOIN
		KCTO_ASIG_LEGAL_EMP
	ON
		CEMPRESA_REPRESENTANTE.ERE_FL_CVE = KCTO_ASIG_LEGAL_EMP.ERE_FL_CVE
	WHERE (KCTO_ASIG_LEGAL_EMP.CTO_FL_CVE = @CveContrato)
      AND (CEMPRESA_REPRESENTANTE.ERE_FG_STATUS = 1)
      
set @VariableTextoLarga1 =''      
set @VariableTextoLarga2 =''      
      
SET @SeccionTabla = ' \posxc\trowd\trqc\qc\trleft-70 ' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = ' \clvertalt '
SET @SeccionTabla3 = ' \cltxlrtb\clftsWidth3\ '
SET  @SeccionTabla4 = ' \pard\plain\ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 ' 
      
OPEN curRepEmpresa
FETCH NEXT FROM curRepEmpresa INTO
	@VariableTexto,
	@VariableTexto1,
	@VariableTexto2
SET @VariableNumero  = 1
DECLARE @FirmaEmpresa char(5000)
SET @FirmaEmpresa = ''
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		if @VariableNumero = 1
			BEGIN
				SET @VariableTexto3 =  RTRIM(@VariableTexto1) + ' ' + RTRIM(@VariableTexto2)+ ' ' + RTRIM(@VariableTexto)
				SET @VariableNumero = 2
				SET @FirmaEmpresa = ' \par \par \par ______________________________________ '
				
				set @VariableTextoLarga1 = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\clbrdrt\brdrs\brdrw10\cellx4536' 
				set @VariableTextoLarga2 = @VariableTexto3
			End
		ELSE
			BEGIN
				SET @VariableTexto3 = RTRIM(@VariableTexto3) + '  Y  ' +   RTRIM(@VariableTexto1) + ' ' + RTRIM(@VariableTexto2)+ ' ' + RTRIM(@VariableTexto)
				SET @FirmaEmpresa = rtrim(@FirmaEmpresa) + '    ______________________________________ '							
				
				set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1) + @SeccionTabla2+ '\clvertalc\cltxlrtb\cellx4886'+ @SeccionTabla2 +'\clvertalc\cltxlrtb\clbrdrt\brdrs\brdrw10\cellx9356'
				set @VariableTextoLarga2 = rtrim(@VariableTextoLarga2) + ' \cell Y \cell '  + RTRIM(@VariableTexto) + ' ' + RTRIM(@VariableTexto1) + ' ' + RTRIM(@VariableTexto2)
			END
		FETCH NEXT FROM curRepEmpresa INTO @VariableTexto,	@VariableTexto1,@VariableTexto2
	End
CLOSE curRepEmpresa
DEALLOCATE curRepEmpresa
set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1) + @SeccionTabla4
set @VariableTextoLarga2 = rtrim(@VariableTextoLarga2) + '\cell}\pard\plain{\row}\pard\plain'

set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1)+rtrim(@VariableTextoLarga2)
EXEC lsntReplace @VariableTextoLarga1, @VariableTextoLarga1 output   --> CAMBIO CARACTERES ESPECIALES
EXEC lsntReplace @VariableTexto3, @VariableTexto3 output   --> CAMBIO CARACTERES ESPECIALES
UPDATE #Claves SET TEXTO= @VariableTexto3 WHERE CLAVE='[%RepresentantesEmpresa%]'


--set @VariableTextoLarga1 = RTRIM(@VariableTextoLarga1) + ' \par'
SET @FirmaEmpresa = rtrim(@FirmaEmpresa) + ' \par '
--SET @FirmaEmpresa = ''
SET @NOFFSET = 0
--SET @FirmaEmpresa = ' \par \par \par _________________________________________________________________________________________________________ \par'
SET @FirmaEmpresa = rtrim(@FirmaEmpresa)
INSERT INTO #Claves VALUES ('[%FirmaEmpresa%]','')
SELECT @ptr = TEXTPTR(#Claves.Texto) FROM #Claves WHERE Clave = '[%FirmaEmpresa%]'
--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaEmpresa
--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaEmpresa))
--SET @FirmaEmpresa = ' ' + rtrim(@VariableTexto3) + ' \par Representantes Legales'
--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaEmpresa
--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaEmpresa))


UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga1
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga1))
SET @VariableTextoLarga1 = ' ' + ' \par Representantes Legales'

UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga1
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga1))

UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%FirmasCliente%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%FirmasAvales%]';

UPDATE #Claves 
SET TEXTO= '' 
WHERE CLAVE='[%FirmasAvalesD%]';

set @VariableTexto  = ''
--araceli Naranjo

EXEC lsntReplace @VariableTexto7, @VariableTexto7 output 
SELECT @VariableTexto = RTRIM(DMO_DS_CALLE_NUM) + ' ' + RTRIM(DMO_DS_NUMEXT) + ' ' + RTRIM(DMO_DS_NUMINT) + ', COL.   ' +    RTRIM   (DMO_DS_COLONIA)  
+ ',  C.P. ' +  RTRIM(DMO_CL_CPOSTAL) + ', '  + RTRIM(DMO_DS_CIUDAD)  +  ', '  +  RTRIM(DMO_DS_EFEDERATIVA)  FROM CDOMICILIO  WHERE PNA_FL_PERSONA = @CveCliente 
--UPDATE #Claves SET TEXTO= @VariableTexto7 WHERE CLAVE='[%DomicilioCliente%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%DomicilioAval%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%NumIFE%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%FechaFirmaContrato%]'
SET @VariableNumero = 0
SET @VariableTexto = ''

SELECT @VariableNumero = sum(CTP_NO_MTO_PAGO)   
FROM KTPAGO_CONTRATO 
WHERE CTO_FL_CVE = @CveContrato  
AND CTP_CL_TTABLA = 1

SET @VariableTexto = convert(varchar(20),convert(money,@VariableNumero),1)

EXECUTE spLsnetCantidadLetra  @VariableNumero, @CveMoneda, @CantidadLetra output

UPDATE #CLAVES SET TEXTO='(' + @CantidadLetra +')' where CLAVE='[%MontoCapitalSoloLetra%]' 

SELECT @CantidadLetra =  '$'+rtrim(@VariableTexto) + ' (' + RTRIM(LTRIM(@CantidadLetra)) + ') '

SET @CantidadLetra = REPLACE(@CantidadLetra,'  ','')

UPDATE #CLAVES 
set TEXTO= '$' + convert(varchar(14),@VariableTexto) 
where CLAVE='[%MontoCapital+Interes%]'


UPDATE #Claves 
SET TEXTO= @CantidadLetra
WHERE CLAVE='[%montoCapitalLetra%]'

UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%DeclaraArrendataria%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%DeclaraAvales%]'
SET @VariableTextoLarga = ''
IF @TipoProducto = 5 --EquipoMedico
	Begin
		Set @VariableTextoLarga= 'La Arrendataria se obliga a no trasladar el uso del BIEN a un tercero, así como cumplir con todos los requisitos y normatividad que regula el uso y manejo del BIEN a nivel Federal, Estatal y Municipal. La Arrendataria y/o su personal deberá en todo momento contar con las licencias necesarias que faculten el uso del BIEN durante la vigencia del presente Contrato.'		
	End
IF  @TipoProducto = 2 or (@TipoProducto = 3) --Automoviles
	Begin
		Set @VariableTextoLarga= 'La Arrendataria se obliga a no trasladar el uso del BIEN a un tercero, así como cumplir con todos los requisitos y normatividad que regula el uso y manejo del BIEN a nivel Federal, Estatal y Municipal. La Arrendataria y/o su personal deberá en todo momento contar con la licencia de conducir que faculte el uso del BIEN durante la vigencia del presente Contrato.'		
	End
EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES			
UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%PrimeraClausula%]'	
--Revisamos si hay deposito en garantía
SET @VariableTextoLarga = ''
Set @VariableNumero = 0
SELECT @VariableNumero = CTO_NO_MTO_DEPRENTAS FROM KCONTRATO WHERE CTO_FL_CVE =  @CveContrato
IF @VariableNumero = 0
	Begin
		SET @VariableTextoLarga = ' { \b TERCERA.- DEPÓSITO }.-\b0 Las partes acuerdan que no será necesario constituir un depósito en garantía a favor de la Arrendadora por parte de la Arrendataria en virtud de así convenir a los intereses de las partes. \par '
		SET @VariableTextoLarga = @VariableTextoLarga + 'Por concepto de comisión por la celebración del presente Contrato se establece la cantidad señalada en la Carátula del presente Contrato, misma que deberá ser pagada a la firma del presente Contrato por la Arrendataria, cantidad a la que se le deberá de aumentar el Impuesto al Valor Agregado que corresponda y cualquier otro impuesto que llegare a generarse. \par '
		
		SET @VariableTextoLarga = @VariableTextoLarga + 'Por concepto de comisión por la celebración del presente Contrato, se establece la cantidad señalada en la Carátula del presente Contrato, misma que en conjunto con el resto de las cantidades señaladas en el apartado 3 de dicha Carátula, deberán ser pagadas a la firma del presente Contrato por La Arrendataria, aumentándose en todos los casos el Impuesto al Valor Agregado que corresponda y cualquier otro impuesto que llegare a generarse, Impuestos que serán a cargo de La Arrendataria.'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
	End
Else
	Begin				
		SET @VariableTextoLarga = ' { \b TERCERA.- DEPÓSITO Y COMISIÓN }.-\b0 La Arrendataria se obliga a constituir un depósito en garantía a favor de la Arrendadora por la cantidad señalada en la Carátula del presente Contrato. Dicha cantidad entregada en depósito no generará ningún tipo de interés a favor de la Arrendataria.  La Arrendataria autoriza expresa e irrevocablemente a la Arrendadora a utilizar el Depósito para cubrir cualquier cantidad debida y pagadera por la Arrendataria dentro del plazo estipulado en el presente Contrato, incluyendo sin limitar  el pago de rentas vencidas, daños al BIEN, penas convencionales, seguro, etc. \par '
		SET @VariableTextoLarga = @VariableTextoLarga + 'Por concepto de comisión por la celebración del presente Contrato se establece la cantidad señalada en la Carátula del presente Contrato, misma que deberá ser pagada a la firma del presente Contrato por la Arrendataria, cantidad a la que se le deberá de aumentar el Impuesto al Valor Agregado que corresponda y cualquier otro impuesto que llegare a generarse. \par '		
		SET @VariableTextoLarga = @VariableTextoLarga + 'Por concepto de comisión por la celebración del presente Contrato se establece la cantidad señalada en la Carátula del presente Contrato, misma que en conjunto con el resto de las cantidades señaladas en el apartado 3 de la Carátula, deberán ser pagadas a la firma del presente Contrato por La Arrendataria, aumentándose en todos los casos el Impuesto al Valor Agregado que corresponda y cualquier otro impuesto que llegare a generarse, Impuestos que serán a cargo de La Arrendataria.'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES	
	End
UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%DepositoComision%]'

Set @VariableNumero  = 0 
Set @VariableNumero2  = 0
SET @VariableTexto = ''
SET @VariableTextoLarga = ''
declare @refpago int
select @refpago=PNA_CL_REFPAGO from CPERSONA where PNA_FL_PERSONA =@CveCliente

SET @NOFFSET = 0
	SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%BancosVentaPlazos%]'

if @refpago=1
	begin
		DECLARE curRefClie CURSOR FOR
		Select C.BCO_DS_NOMBRE,B.BCT_DS_CVETRANS ,B.BCT_NO_CUENTA,B.BCT_DS_CLABE,(RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF))  
		FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
		inner join CBANCO C	 ON C.BCO_FL_CVE= B.BCO_FL_CVE
		WHERE A.PNA_FL_PERSONA = @CveCliente	
		open curRefClie
		fetch next from curRefClie into @variabletexto,@variabletexto2,@variabletexto3,@variabletexto4,@variabletexto5
		while @@FETCH_STATUS = 0
			Begin				
				SET @VariableTextoLarga ='\pard \ltrpar\s19\qj \b0 \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 Todos los pagos deberán realizarse en el domicilio señalado en el presente contrato por la Vendedora, o mediante depósito o transferencia a la cuenta bancaria que la Vendedora mantiene con el banco  }'
				+ RTRIM(@variabletexto)+', Convenio ' +RTRIM(@variabletexto1) +', Cuenta '+RTRIM(@variabletexto2)+', CLABE INTERBANCARIA ' + RTRIM(@variabletexto3)	
				+', Referencia ' +@variabletexto5 +'\par \par'				
				
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				fetch next from curRefClie into @variabletexto,@variabletexto2,@variabletexto3,@variabletexto4,@variabletexto5
			End
		close curRefClie
		deallocate curRefClie
	end
	
if @refpago=2
	begin
		DECLARE curRefClie CURSOR FOR
		Select C.BCO_DS_NOMBRE,B.BCT_DS_CVETRANS ,B.BCT_NO_CUENTA,B.BCT_DS_CLABE,(RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF))  
		FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
		inner join CBANCO C	 ON C.BCO_FL_CVE= B.BCO_FL_CVE
		WHERE A.CTO_FL_CVE = @CveContrato
		open curRefClie
		fetch next from curRefClie into @variabletexto,@variabletexto2,@variabletexto3,@variabletexto4,@variabletexto5
		while @@FETCH_STATUS = 0
			Begin	
				SET @VariableTextoLarga ='\pard \ltrpar\s19\qj \b0 \li0\ri0\widctlpar\wrapdefault\aspalpha\aspnum\faauto\adjustright\rin0\lin0\itap0 {\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 }{\rtlch\fcs1 \af38\afs20 \ltrch\fcs0 \fs20 Todos los pagos deberán realizarse en el domicilio señalado en el presente contrato por la Vendedora, o mediante depósito o transferencia a la cuenta bancaria que la Vendedora mantiene con el banco  }'
				+ RTRIM(@variabletexto)+', Convenio ' +RTRIM(@variabletexto1) +', Cuenta '+RTRIM(@variabletexto2)+', CLABE INTERBANCARIA ' + RTRIM(@variabletexto3)	
				+', Referencia ' +@variabletexto5 +'\par \par'				
				
				exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
				UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
				SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
				
				fetch next from curRefClie into @variabletexto,@variabletexto2,@variabletexto3,@variabletexto4,@variabletexto5
			End
		close curRefClie
		deallocate curRefClie
		
	end
Set @VariableNumero  = 0 
Set @VariableNumero2  = 0
SET @VariableTexto = ''
SET @VariableTextoLarga = ''


Set @VariableNumero  = 2 --Esta es la cuenta de Bancomer
if @refpago=1
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.PNA_FL_PERSONA = @CveCliente and  B.BCO_FL_CVE = @VariableNumero
	END	
if @refpago=2
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.CTO_FL_CVE = @CveContrato and  B.BCO_FL_CVE = @VariableNumero
	END	

IF @VariableNumero2 > 0
	Begin	
		SET @VariableTextoLarga = 'La Arrendadora manifiesta a la Arrendataria que los pagos mensuales podrán realizarse mediante depósito a  la cuenta bancaria que la Arrendadora mantiene con el banco Grupo Financiero BBVA Bancomer, Convenio 842362, Cuenta 0140796786, CLABE INTERBANCARIA 012320001407967866 REFERENCIA '		
		SET @VariableTextoLarga= rtrim(@VariableTextoLarga)+' ' + @VariableTexto + ' \par  '		
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
		UPDATE #Claves SET TEXTO= isnull(@VariableTextoLarga,'') WHERE CLAVE='[%CuartaClausulaBancomer%]'
	End
Set @VariableNumero  = 0 
Set @VariableNumero2  = 0
SET @VariableTexto = ''
SET @VariableTextoLarga = ''
Set @VariableNumero  = 5 --Esta es la cuenta de Fifomi
if @refpago=1
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.PNA_FL_PERSONA = @CveCliente and  B.BCO_FL_CVE = @VariableNumero
	END	
if @refpago=2
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.CTO_FL_CVE = @CveContrato and  B.BCO_FL_CVE = @VariableNumero
	END	
IF @VariableNumero2 > 0
	Begin
		SET @VariableTextoLarga = 'La Arrendadora manifiesta a la Arrendataria que los pagos mensuales podrán realizarse mediante depósito a la cuenta bancaria cuyo titular es ___________________, cuenta que se abrió en el banco de nombre comercial ___________, convenio ________, Cuenta ____________, CLABE INTERBANCARIA _____________  REFERENCIA '
		SET @VariableTextoLarga= rtrim(@VariableTextoLarga)+' ' + @VariableTexto + ' \par  '
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES
		UPDATE #Claves SET TEXTO= isnull(@VariableTextoLarga,'') WHERE CLAVE='[%CuartaClausulaFifomi%]'
	End 
Set @VariableNumero  = 0 
Set @VariableNumero2  = 0
SET @VariableTexto = ''
SET @VariableTextoLarga = ''
Set @VariableNumero  = 4 --Esta es la cuenta de HSBC
if @refpago=1
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.PNA_FL_PERSONA = @CveCliente and  B.BCO_FL_CVE = @VariableNumero
	END	
if @refpago=2
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.CTO_FL_CVE = @CveContrato and  B.BCO_FL_CVE = @VariableNumero
	END	
IF @VariableNumero2 > 0
	Begin
		SET @VariableTextoLarga = 'La Arrendadora manifiesta a la Arrendataria que los pagos mensuales podrán realizarse mediante depósito a  la cuenta bancaria que la Arrendadora mantiene con el banco HSBC MÉXICO S.A., a su nombre bajo el número de cuenta 4040457129 CLABE 021320040404571294, REFERENCIA '
		SET @VariableTextoLarga= rtrim(@VariableTextoLarga)+' ' + @VariableTexto + ' \par '
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES	
		UPDATE #Claves SET TEXTO= isnull(@VariableTextoLarga,'') WHERE CLAVE='[%CuartaClausulaHSBC%]'
	End 
Set @VariableNumero  = 0 
Set @VariableNumero2  = 0
SET @VariableTexto = ''
SET @VariableTextoLarga = ''
Set @VariableNumero  = 3 --Esta es la cuenta de Inbursa
if @refpago=1
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.PNA_FL_PERSONA = @CveCliente and  B.BCO_FL_CVE = @VariableNumero
	END	
if @refpago=2
	begin
	Select @VariableNumero2 = CPP_FL_CVE ,@VariableTexto = (RTRIM(A.CPP_DS_REFERENCIA)+convert(char(2),A.CPP_NO_DIGVERIF)) 
	FROM KCTO_CTASPAGO A INNER JOIN CBCO_CTAS B ON B.BCT_FL_CVE = A.BCT_FL_CVE
	WHERE A.CTO_FL_CVE = @CveContrato and  B.BCO_FL_CVE = @VariableNumero
	END	
IF @VariableNumero2 > 0
	Begin
		SET @VariableTextoLarga = 'La Arrendadora manifiesta a la Arrendataria que los pagos mensuales podrán realizarse mediante depósito a  la cuenta bancaria que la Arrendadora mantiene con Inbursa, a su    nombre bajo el número de cuenta 031003040014  CLABE 036222310030400141, REFERENCIA ?'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES			
		SET @VariableTextoLarga= rtrim(@VariableTextoLarga)+' ' + @VariableTexto + ' \par '
		UPDATE #Claves SET TEXTO= isnull(@VariableTextoLarga,'') WHERE CLAVE='[%CuartaClausulaInbursa%]'
	End 

--Reviasamos si a la persona se le manda estado de cuenta o no
SET @VariableNumero= 0
SELECT @VariableNumero = MAI_FG_OMITIR_ENVIO FROM CPERSONA_EMAIL WHERE PNA_FL_PERSONA = @CveCliente
IF @VariableNumero = 0
	Begin
		SET @VariableTextoLarga = ''
		SET @VariableTextoLarga = 'La Arrendadora enviará dentro de los siguientes 15 días hábiles siguientes al término de cada periodo de renta, un estado de cuenta a la o las cuentas de correo electrónico señaladas en la carátula de este documento, en el entendido de que el que la Arrendataria no reciba dicho estado de cuenta no la exime de la realización de cualquiera de los pagos a los que se  encuentra obligada en términos del presente Contrato.'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES			
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%ClausulaEnvioEdoCta%]'
	End

IF @TipoProducto = 5 --EquipoMedico
	Begin
		SET @VariableTextoLarga = ''
		SET @VariableTextoLarga = ' los servicios, las reparaciones, refacciones, fuentes de energía, aditivos, licencias, permiso, impuestos, registros necesarios, lubricantes, aceites'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES	
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%SeptimaClausula%]'	
	End
IF (@TipoProducto = 2) OR (@TipoProducto = 3) or (@TipoProducto = 4) --Automoviles, maquinaria
	Begin
		SET @VariableTextoLarga = 'los servicios, las reparaciones, refacciones, fuentes de energía, gasolina, aditivos, licencias, permiso, tenencia, placas, impuestos, registros necesarios, lubricantes, aceites, equipo de sonido, laminado, pintura, encerado, pulido'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES	
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%SeptimaClausula%]'
	End	

IF @TipoProducto = 5 --EquipoMedico
	Begin
		SET @VariableTextoLarga = ''
		SET @VariableTextoLarga = '{ \b OCTAVA.- SEGURO.- } En caso de que la Arrendadora acepte por escrito firmado por su representante que la Arrendataria contrate el seguro por su cuenta, ésta al recibir el BIEN deberá entregar a la Arrendadora los siguientes documentos: la póliza del seguro, el recibo de pago de la misma, con el endoso de Beneficiario Preferente a favor de la Arrendadora, por la vigencia del presente Contrato con la anotación de que dicho seguro no podrá ser cancelado ni modificado sin la previa autorización de la Arrendadora. \par  '
		SET @VariableTextoLarga = @VariableTextoLarga + 'En caso de que dicho seguro no cubra la totalidad del tiempo de vigencia de este Contrato, la Arrendataria se obliga expresamente a entregar con una anticipación mínima de 30 días al vencimiento del seguro, la renovación respectiva y el comprobante de pago de la misma, con el endoso de Beneficiario Preferente a favor de la Arrendadora y con la anotación de que dicho seguro no podrá ser cancelado ni modificado sin la previa autorización de la Arrendadora. \par  '
		SET @VariableTextoLarga = @VariableTextoLarga +  'En caso de que la Arrendataria informe que no contratará el seguro o incumpla con la obligación de contratarlo, la Arrendadora estará facultada para contratar es seguro en los términos antes mencionado; en el entendido de que en este caso, la Arrendataria se obliga a pagar a la Arrendadora la prima del seguro del BIEN arrendado, en un plazo no mayor de 30 días contados a partir de la fecha en que se lo notifique la Arrendadora, mas los intereses moratorios que sobre las cantidades pagadas por la Arrendadora se devenguen a la tasa de interés moratoria establecida en la Cláusula Quinta del presente Contrato. \par '
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%OctavaClausula%]'
	End
		
IF (@TipoProducto = 2) or (@TipoProducto = 3) or (@TipoProducto = 4) --Automoviles, Maquinaria
	Begin
		SET @VariableTextoLarga = ''
		SET @VariableTextoLarga = ' { \b OCTAVA.- SEGURO.-  } Con el fin de mantener el BIEN protegido durante la vigencia del presente contra eventualidades, la Arrendadora contratará un seguro con cobertura amplia, con limites, coberturas y deducibles que considere convenientes, ante la compañía de seguros de su elección y el costo será repercutido a la Arrendataria. \par  '
		SET @VariableTextoLarga = @VariableTextoLarga + ' La Arrendataria se obliga a pagar a la Arrendadora la prima del seguro del BIEN  arrendado, en un plazo no mayor de 30 días contados a partir de la fecha de expedición de la póliza original y de sus renovaciones. La Arrendataria se responsabiliza a vigilar estrictamente la vigencia y vencimiento del seguro manteniendo la cobertura del mismo. \par  '
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES		
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%OctavaClausula%]'
	end
--Solo para personas fisicas
if @CvePJuridica = 'PF'
	Begin
		SET @VariableTextoLarga = '{ \b SEGURO DE VIDA SOBRE SALDOS INSOLUTOS. }  La Arrendataria da su consentimiento y plena autorización a favor de la Arrendadora, para que la última adquiera un seguro de vida a favor de la Arrendataria, con coberturas y deducibles que considere convenientes hasta por la cantidad de $900,000.00 (Novecientos mil pesos 00/100 Moneda Nacional), ante la compañía de seguros de su elección, misma que deberá ser una compañía de seguros autorizada por las leyes vigentes de la República Mexicana, y el costo será repercutido íntegramente a la Arrendadora, quedando ésta como única y exclusiva beneficiaria de dicha póliza, con la finalidad, de que en caso de fallecimiento o invalidez total o permanente de la Arrendataria, la Compañía Aseguradora se obligue a pagar a favor de la Arrendadora el saldo insoluto que la Arrendataria tenga a favor de la Arrendadora. A sabiendas de que de existir varios arrendamientos, solamente se cubrirá dicha cantidad una sola vez por todas ellos. \par '
		SET @VariableTextoLarga = @VariableTextoLarga + 'El Aval, Fiador u Obligado Solidario aludido en este Contrato da su consentimiento y conformidad para que el seguro de vida mencionado en al párrafo anterior sea emitido exclusivamente para asegurar la vida o la invalidez total y permanente de la Arrendataria; por lo tanto, el seguro no incluye en su protección a las personas que juegan el carácter de avalistas o garantes.'
		EXEC lsntReplace @VariableTextoLarga, @VariableTextoLarga output   --> CAMBIO CARACTERES ESPECIALES	
		UPDATE #Claves SET TEXTO= @VariableTextoLarga WHERE CLAVE='[%OctavaClausulaSegVida%]'
	End
	
IF @TipoProducto = 5 --EquipoMedico
	UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%DecimaCuartaClausula%]'
IF (@TipoProducto = 2) or (@TipoProducto = 3) --Automoviles
	UPDATE #Claves SET TEXTO= 'o de la vialidad' WHERE CLAVE='[%DecimaCuartaClausula%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%DecimoOctavaClausula%]'

--FirmasAvales
SET @SeccionTabla = ' \posxc\trowd\trqc\qc\trleft-70 ' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = ' \clvertalt '
SET @SeccionTabla3 = ' \cltxlrtb\clftsWidth3\ '
SET  @SeccionTabla4 = ' \pard\plain\ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 ' 
--SET  @SeccionTabla4 = ' \pard\plain\ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs0 \f38\fs16\cf1\ {\rtlch\fcs0 \f38\fs16\cf1 \ltrch\fcs0 \f38\fs16\cf1'

DECLARE @FirmaAvales varchar(8000)
DECLARE @NombreAval VARCHAR(100),@PjuridicaAval int
SET @FirmaAvales = ''
SET @NOFFSET = 0
SET @NOFFSET2 = 0

SELECT @ptr = TEXTPTR(#Claves.Texto) 
FROM #Claves 
WHERE Clave = '[%FirmasAvales%]';

SELECT @ptr2 = TEXTPTR(#Claves.Texto) 
FROM #Claves 
WHERE Clave = '[%FirmasAvalesD%]';

DECLARE curFirmasAvales CURSOR FOR
	SELECT  B.PNA_FL_PERSONA, CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )ELSE rtrim(B.PNA_DS_NOMBRE) END,B.PNA_CL_PJURIDICA  FROM KCTO_ASIG_LEGAL_CLIENTE  A
	INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = A.PRE_FL_PERSONA 
	left outer join cpfisica C on c.pna_fl_persona=b.pna_fl_persona
	WHERE A.PNA_FL_PERSONA = @CveCliente  and A.CTO_FL_CVE = @CveContrato  AND A.ALG_CL_TIPO_RELACION= 3
open curFirmasAvales
fetch next from curFirmasAvales into @ClaveAval,@NombreAval,@PjuridicaAval
while @@FETCH_STATUS = 0
	Begin
		if @PjuridicaAval = 20
				Begin
					SET @VariableTexto=''
					--SET @VariableNumero=0

					SELECT @VariableTexto=CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )ELSE rtrim(A.PNA_DS_NOMBRE) END--,@VariableNumero=PNA_FL_PERSONA 
					FROM CPERSONA  A left outer join cpfisica c on c.PNA_FL_PERSONA = A.PNA_FL_PERSONA 
					WHERE a.PNA_FL_PERSONA IN (SELECT PNA_FL_PERSONA 
											FROM cprelacion 	
											WHERE PRE_FL_PERSONA = @ClaveAval 
											AND PRE_FG_VALOR = 4 
											AND PNA_FL_PERSONA IN(SELECT PRE_FL_PERSONA 
																	FROM KCTO_ASIG_LEGAL_CLIENTE 
																	WHERE CTO_FL_CVE = @CveContrato AND ALG_CL_TIPO_RELACION = 3))	
					exec lsntReplace  @VariableTexto,@VariableTexto OUTPUT
				
					SET @FirmaAvales = ' \par' + '\b ' +' _____________________________________ ' + '\b0' +'\par'
					SET 	@FirmaAvales = '\b '+ @FirmaAvales+' ' + @VariableTexto +'('+@NombreAval+')'+ '\b0' + ' \par ' 
					
					set @VariableTextoLarga1 ='\par\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\b\clvertalc\cltxlrtb\clbrdrt\brdrs\brdrw10\cellx4536'  
					set @VariableTextoLarga2 = '\b '+ @VariableTexto + '\b0' +'\par \b ('+@NombreAval+')' +'\b0'
					set @VariableTextoLarga1 =  rtrim(@VariableTextoLarga1) + @SeccionTabla4 +'\b\b0'
					set @VariableTextoLarga2 = '\b '+ rtrim(@VariableTextoLarga2) + '\cell}\pard\plain{\row}\pard\plain' + '\b0 '


					set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1)+rtrim(@VariableTextoLarga2)
					EXEC lsntReplace @VariableTextoLarga1, @VariableTextoLarga1 output   --> CAMBIO CARACTERES ESPECIALES

					set @VariableTextoLarga1= RTRIM(@VariableTextoLarga1)
					UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga1
					SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga1))

					UPDATETEXT #Claves.texto @ptr2 @NOFFSET2 NULL @VariableTextoLarga1
					SET @NOFFSET2 = @NOFFSET2 + LEN(RTRIM(@VariableTextoLarga1))

					set 	@VariableTexto=''						
					SELECT @VariableTexto = '\b' + ' \f38\fs16\cf1 Domicilio: ' + RTRIM(DMO_DS_CALLE_NUM) + ' ' + RTRIM(DMO_DS_NUMEXT) + ' ' + RTRIM(DMO_DS_NUMINT) + ', COL. ' + RTRIM(DMO_DS_COLONIA)  
					+ ',  C.P. ' +  RTRIM(DMO_CL_CPOSTAL) + ', '  + RTRIM(DMO_DS_CIUDAD)  +  ', '  +  RTRIM(DMO_DS_EFEDERATIVA) +'\b0'
					FROM CDOMICILIO  
					WHERE PNA_FL_PERSONA = @ClaveAval
					
					set @VariableTexto= rtrim(@VariableTexto)										
										
					UPDATETEXT #Claves.texto @ptr2 @NOFFSET2 NULL @VariableTexto
					SET @NOFFSET2 = @NOFFSET2 + LEN(RTRIM(@VariableTexto))									
					
					--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaAvales
					--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaAvales))
					--Buscamos el representante legal de la empresa
					
				End
		else
			Begin	
																		
					SET @FirmaAvales = '\par\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\brdrw10\cellx2500'  + @SeccionTabla4
										
					set @FirmaAvales = @FirmaAvales + ' \intbl \cf1\f38\fs16   El “AVAL” \cell }\pard\plain{\row}\pard\plain' 						

					SET @FirmaAvales = @FirmaAvales + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\brdrw10\cellx2500'  + @SeccionTabla4
					set @FirmaAvales = @FirmaAvales + ' \intbl \cf1\f38\fs16\par\par  \cell }\pard\plain{\row}\pard\plain'
					SET @FirmaAvales = @FirmaAvales + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\clbrdrt\brdrs\brdrw10\cellx2500'  + @SeccionTabla4					 						
					SET @FirmaAvales = @FirmaAvales + ' \intbl \cf1\f38\fs16' + @NombreAval + '\cell}\pard\plain{\row}\pard\plain'
					
					EXEC lsntReplace @FirmaAvales, @FirmaAvales output
					
					/*update #Claves
					set texto = @FirmaAvales + '\pard'
					where clave = '[%FirmasAvales%]'*/
					

					UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaAvales
					SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaAvales))

					--set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1)+rtrim(@VariableTextoLarga2)
					--EXEC lsntReplace @VariableTextoLarga1, @VariableTextoLarga1 output   --> CAMBIO CARACTERES ESPECIALES

					--set @VariableTextoLarga1= RTRIM(@VariableTextoLarga1)
					--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga1
					--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga1))
					
					--UPDATETEXT #Claves.texto @ptr2 @NOFFSET2 NULL @VariableTextoLarga1
					--SET @NOFFSET2 = @NOFFSET2 + LEN(RTRIM(@VariableTextoLarga1))										
					SET @FirmaAvales = @FirmaAvales + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\clbrdrt\cellx2500'  + @SeccionTabla4					 						
					SELECT @FirmaAvales = @FirmaAvales + ' \intbl \cf1\f38\fs16' +  RTRIM(DMO_DS_CALLE_NUM) + ' ' + RTRIM(DMO_DS_NUMEXT) + ' ' + RTRIM(DMO_DS_NUMINT) + ', COL. ' + RTRIM(DMO_DS_COLONIA)  
					+ ',  C.P.' +  RTRIM(DMO_CL_CPOSTAL) + ', '  + RTRIM(DMO_DS_CIUDAD)  +  ', '  +  RTRIM(DMO_DS_EFEDERATIVA) + '\cell}\pard\plain{\row}\pard\plain'
					FROM CDOMICILIO  
					WHERE PNA_FL_PERSONA = @ClaveAval 
										
					
					--UPDATETEXT #Claves.texto @ptr2 @NOFFSET2 NULL @VariableTexto
					--SET @NOFFSET2 = @NOFFSET2 +  LEN(RTRIM(@VariableTexto))															
					
					
					EXEC lsntReplace @FirmaAvales, @FirmaAvales output
					
					
					UPDATETEXT #Claves.texto @ptr2 @NOFFSET2 NULL @FirmaAvales
					SET @NOFFSET2 = @NOFFSET2 + LEN(RTRIM(@FirmaAvales))
			End		
		fetch next from curFirmasAvales into @ClaveAval,@NombreAval,@PjuridicaAval
	End
close curFirmasAvales
deallocate curFirmasAvales

--Fima Cliente
set @VariableTextoLarga1 =''      
set @VariableTextoLarga2 =''      
      
SET @SeccionTabla = ' \posxc\trowd\trqc\qc\trleft-70 ' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = ' \clvertalt '
SET @SeccionTabla3 = ' \cltxlrtb\clftsWidth3\ '
SET  @SeccionTabla4 = ' \pard\plain\ltrpar\qc \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f38\fs16\cf1\ ' 

DECLARE @FirmaCliente varchar(8000)
DECLARE @NombreClienteFirma VARCHAR(100),@PjuridicaCleinte int
SET @FirmaAvales = ''
SET @NOFFSET = 0
SELECT @ptr = TEXTPTR(#Claves.Texto) FROM #Claves WHERE Clave = '[%FirmasCliente%]'
DECLARE curFirmasAvales CURSOR FOR
	SELECT  CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )ELSE rtrim(b.PNA_DS_NOMBRE) END,B.PNA_CL_PJURIDICA  FROM CPERSONA B 
	left outer join cpfisica C on c.pna_fl_persona = b.pna_fl_persona
	WHERE B.PNA_FL_PERSONA = @CveCliente  
open curFirmasAvales
fetch next from curFirmasAvales into @NombreClienteFirma,@PjuridicaCleinte
while @@FETCH_STATUS = 0
	Begin
		if @PjuridicaCleinte = 20
				Begin
					SET @VariableTexto=''
					SET @VariableNumero=0
					Select  @VariableNumero = PRE_FL_PERSONA from KCTO_ASIG_LEGAL_CLIENTE 
					WHERE PNA_FL_PERSONA = @CveCliente AND  ALG_CL_TIPO_RELACION = 4
					IF @VariableNumero > 0 
						Begin
							--Si encontro un apoderado por lo que hay que ir por los datos
							Select @VariableTexto = CASE WHEN C.PNA_FL_PERSONA IS NOT NULL THEN RTRIM(PFI_DS_NOMBRE )+' '+RTRIM(PFI_DS_APATERNO ) + ' '+RTRIM(PFI_DS_AMATERNO )ELSE rtrim(A.PNA_DS_NOMBRE) END--,@VariableTexto1 = ISNULL(RTRIM(PDA_DS_VALORAD),'')
							FROM CPERSONA A
							LEFT OUTER JOIN CPDATO_ADICIONAL B ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA AND B.PTI_FG_VALOR = 4 AND B.DTA_FL_CVE= 2
							left outer join CPFISICA C on A.PNA_FL_PERSONA = c.PNA_FL_PERSONA 
							WHERE A.PNA_FL_PERSONA = @VariableNumero
							exec lsntReplace  @VariableTexto,@VariableTexto OUTPUT
						END	
				
					SET @FirmaAvales = ' \par  _____________________________________________________________________________________ \par'
					SET 	@FirmaAvales = @FirmaAvales +' ' + @VariableTexto + ' \par '
					
					set @VariableTextoLarga1 = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\clbrdrt\brdrs\brdrw10\cellx4536' 
					set @VariableTextoLarga2 = @VariableTexto					
					set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1) + @SeccionTabla4
					set @VariableTextoLarga2 = rtrim(@VariableTextoLarga2) + '\cell}\pard\plain{\row}\pard\plain \par'


					set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1)+rtrim(@VariableTextoLarga2)
					EXEC lsntReplace @VariableTextoLarga1, @VariableTextoLarga1 output   --> CAMBIO CARACTERES ESPECIALES

					set @VariableTextoLarga1= RTRIM(@VariableTextoLarga1)
					UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga1
					SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga1))

					--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaAvales
					--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaAvales))
					--Buscamos el representante legal de la empresa
					
					
				End
		else
			Begin
					SET @FirmaAvales = ' \par  _____________________________________________________________________________________ \par'
					SET 	@FirmaAvales = @FirmaAvales+ ' '  + @NombreClienteFirma + ' \par '

					set @VariableTextoLarga1 = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\clvertalc\cltxlrtb\clbrdrt\brdrs\brdrw10\cellx4536' 
					set @VariableTextoLarga2 = @NombreClienteFirma					
					set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1) + @SeccionTabla4
					set @VariableTextoLarga2 = rtrim(@VariableTextoLarga2) + '\cell}\pard\plain{\row}\pard\plain \par'


					set @VariableTextoLarga1 = rtrim(@VariableTextoLarga1)+rtrim(@VariableTextoLarga2)
					EXEC lsntReplace @VariableTextoLarga1, @VariableTextoLarga1 output   --> CAMBIO CARACTERES ESPECIALES

					set @VariableTextoLarga1= RTRIM(@VariableTextoLarga1)
					UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga1
					SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga1))

					--UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaAvales
					--SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaAvales))
			End		
		fetch next from curFirmasAvales into @NombreClienteFirma,@PjuridicaCleinte
	End
close curFirmasAvales
deallocate curFirmasAvales

/*************************************************/


--Fima Avales
/*
SET @FirmaAvales = ''
SET @NOFFSET = 0
SELECT @ptr = TEXTPTR(#Claves.Texto) FROM #Claves WHERE Clave = '[%FirmasAvales%]'
DECLARE curFirmasAvales CURSOR FOR
	SELECT  RTRIM(b.PNA_DS_NOMBRE),B.PNA_CL_PJURIDICA  FROM 
	KCONTRATO A INNER JOIN
	KCTO_ASIG_LEGAL_CLIENTE C ON C.CTO_FL_CVE= A.CTO_FL_CVE AND C.ALG_CL_TIPO_RELACION = 3
	INNER JOIN CPERSONA B ON B.PNA_FL_PERSONA = C.PNA_FL_PERSONA 
	WHERE A.CTO_FL_CVE = @CveContrato 
open curFirmasAvales
fetch next from curFirmasAvales into @NombreClienteFirma,@PjuridicaCleinte
while @@FETCH_STATUS = 0
	Begin
		if @PjuridicaAval = 20
				Begin
					SET @FirmaAvales = ' \par  _________________________________________________________________________________________________________ \par'
					SET 	@FirmaAvales = @FirmaAvales+ ' ' + @NombreAval + ' \par '
					UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaAvales
					SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaAvales))
					--Buscamos el representante legal de la empresa
					
				End
		else
			Begin
					SET @FirmaAvales = ' \par  _________________________________________________________________________________________________________ \par'
					SET 	@FirmaAvales = @FirmaAvales+ ' ' + @NombreAval + ' \par '
					UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @FirmaAvales
					SET @NOFFSET = @NOFFSET + LEN(RTRIM(@FirmaAvales))
			End		
		fetch next from curFirmasAvales into @NombreAval,@PjuridicaAval
	End
close curFirmasAvales
deallocate curFirmasAvales

*/
/*************************************************/


UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%tablaPagare%]'
---------------------------------------------------------------------------------------------------------------
--PAGARE AP
---------------------------------------------------------------------------------------------------------------
DECLARE @tablaPagareAP VARCHAR(8000)
DECLARE @FecPag_PAP   DATETIME
DECLARE @Pago_PAP   VARCHAR(20)
DECLARE @Fecha_PAP VARCHAR(250)
SET @NOFFSET = 0
SET @tablaPagareAP = ''
SET @tablaPagareAP = RTRIM(@tablaPagareAP) + '\trowd\trqc\qc\intbl{ \b '
SET @tablaPagareAP = RTRIM(@tablaPagareAP) + ' Fecha de Pago ' + '\cell '
SET @tablaPagareAP = RTRIM(@tablaPagareAP) + ' Pagos Parciales ' + '\cell}'
SET @tablaPagareAP = RTRIM(@tablaPagareAP) + '\pard\intbl {\trowd\trqc\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\cltxlrtb\clftsWidth2\clwWidth2136\cellx2136\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\cltxlrtb\clftsWidth2\clwWidth2136\cellx4272 \row}'
--Obtenemos el apuntador al campo que queremos cambiar
SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%tablaPagare%]'
--Se agregan los encabezados
UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @tablaPagareAP
--Se actualiza la posicion del apuntador
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@tablaPagareAP))
--
DECLARE curTablaPAP CURSOR FOR
	SELECT CTP_FE_EXIGIBILIDAD,
           convert(varchar(20),convert(money,CTP_NO_MTO_PAGO),1)
    FROM KTPAGO_CONTRATO
   WHERE CTO_FL_CVE = @CveContrato
     AND CTP_CL_TTABLA = 1
     AND CTP_NO_VERSION = 1 and CTP_NO_PAGO > 0
OPEN curTablaPAP
FETCH NEXT FROM curTablaPAP INTO @FecPag_PAP, @Pago_PAP
WHILE ( @@FETCH_STATUS = 0 )
	BEGIN
		SET @Fecha_PAP = REPLICATE('0', 2 - LEN(RTRIM(CONVERT(CHAR(2), DAY(@FecPag_PAP))))) + RTRIM(CONVERT(CHAR(2), DAY(@FecPag_PAP)))+ ' de ' +
		CASE MONTH(@FecPag_PAP)
			WHEN 1 THEN 'Enero'
			WHEN 2 THEN 'Febrero'
			WHEN 3 THEN 'Marzo'
			WHEN 4 THEN 'Abril'
			WHEN 5 THEN 'Mayo'
			WHEN 6 THEN 'Junio'
			WHEN 7 THEN 'Julio'
			WHEN 8 THEN 'Agosto'
			WHEN 9 THEN 'Septiembre'
			WHEN 10 THEN 'Octubre'
			WHEN 11 THEN 'Noviembre'
			WHEN 12 THEN 'Diciembre'
		END + ' de ' +
		CONVERT(CHAR(7), YEAR(@FecPag_PAP)) + '   '
		SET @tablaPagareAP = '\trowd\intbl{'
		SET @tablaPagareAP = RTRIM(@tablaPagareAP) + ' \qr ' + CONVERT(CHAR(30), @Fecha_PAP) + ' \cell '
		SET @tablaPagareAP = RTRIM(@tablaPagareAP) + ' \qr ' + CONVERT(CHAR(30), @Pago_PAP) + ' \cell} '
		SET @tablaPagareAP = RTRIM(@tablaPagareAP) + '{\trowd\trqc\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\cltxlrtb\clftsWidth3\clwWidth2136\cellx2136\clbrdrt\brdrs\brdrw10 \clbrdrl\brdrs\brdrw10 \clbrdrb\brdrs\brdrw10 \clbrdrr\brdrs\brdrw10\cltxlrtb\clftsWidth3\clwWidth3136\cellx4272 \row}'
		UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @tablaPagareAP
		SET @NOFFSET = @NOFFSET + LEN(RTRIM(@tablaPagareAP))
		FETCH NEXT FROM curTablaPAP INTO	@FecPag_PAP, @Pago_PAP
	end
CLOSE curTablaPAP
DEALLOCATE curTablaPAP
UPDATETEXT #Claves.texto @ptr @NOFFSET NULL ' \pard  \pard '
SET @NOFFSET = 0

/*IICI-B-XXX ini*/
Insert into #Claves values ('[%TipoOperacion%]','')
set @VariableTexto=''
select @VariableTexto=TOP_DS_DESCRIPCION from KCONTRATO a inner join KTOPERACION b on a.TOP_CL_CVE = b.TOP_CL_CVE 
where a.CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TipoOperacion%]'

/*IICI-B_XXX fin*/

/*IICI-B-XXX ini prueba deposito en garantía*/
Insert into #Claves values ('[%DepositoGarantia%]','')
set @VariableTexto=''
select @VariableTexto=CTO_NO_MTO_DEPOSITO from KCONTRATO 
where CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DepositoGarantia%]'

/*IICI-B_XXX fin*/

/*IICI-B-XXX ini prueba totalinicial */
Insert into #Claves values (convert(char(100),'[%TotalInicialPK%]'),'')
set @VariableTexto=''
DECLARE  @TOTALINICIAL NUMERIC(13,2)

SELECT  @TOTALINICIAL =  ISNULL (SUM(CTP_NO_MTO_PG_CON_IVA),0)+ 
		  ISNULL((SELECT SUM(CCI_NO_MONTO_TOTAL) FROM KCTO_CARGOINICIAL CI WHERE CI.CTO_FL_CVE = PC.CTO_FL_CVE AND KTM_CL_TMOVTO = 'CMSF'),0)+
          ISNULL((SELECT SUM(CTO_NO_MTO_DEPOSITO) FROM KCONTRATO SP WHERE SP.CTO_FL_CVE = PC.CTO_FL_CVE ),0)
           FROM  KTPAGO_CONTRATO PC
WHERE PC.CTO_FL_CVE = @CveContrato AND PC.CTP_CL_TTABLA = 1  AND CTP_NO_PAGO=1
GROUP BY PC.CTO_FL_CVE
EXEC @VariableTexto = FormatNumber @TOTALINICIAL,2,',','.'


UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TotalInicialPK%]'
/*IICI-B_XXX fin*/

/*IICI-B-XXX ini*/
Insert into #Claves values ('[%CuentaBancariaPACADA%]','')
set @VariableTexto=''
select  top 1 @VariableTexto= a.BCO_DS_NOMBRE + ' '+ c.BCT_NO_CUENTA +' CLABE INTERBANCARIA ' +c.BCT_DS_CLABE  from CBANCO a inner join cbco_ctas c on a.bco_fl_cve= c.BCO_FL_CVE  where c.BCT_FG_STATUS =1
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CuentaBancariaPACADA%]'
/*IICI-B_XXX fin*/

/*IICI-B-XXX ini*/
Insert into #Claves values ('[%PacadaRFC%]','')
set @VariableTexto=''
select @VariableTexto= EMP_CL_RFC from CEMPRESA
where EMP_FL_CVE =@CveEmpresa -- EMP_DS_NOMBRE = 'PACADA S.A. DE C.V. SOFOM E.N.R'
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%PacadaRFC%]'
/*IICI-B_XXX fin*/

/*prueba valor total de la renta pakada*/
Insert into #Claves values ('[%TOTRENTAPK%]','')
set @VariableTexto=''
declare @TOTRENTAPK INT
select @TOTRENTAPK = sum(CTP_NO_MTO_INTERES) + SUM( CTP_NO_MTO_PAGO) 
from ktpago_contrato where CTO_FL_CVE = @CveContrato AND CTP_CL_TTABLA = 1 
EXEC @VariableTexto = FormatNumber @TOTRENTAPK ,2,',','.'
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TOTRENTAPK%]'
/*IICI-B_XXX fin*/


/*Prueba Comision2*/
Insert into #Claves values ('[%ComisionP%]','')
set @VariableTexto=''
select @VariableTexto= CCI_NO_MONTO_TOTAL  from KCTO_CARGOINICIAL
where CTO_FL_CVE = @CveContrato AND KTM_CL_TMOVTO = 'CMSF'
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ComisionP%]'

/*Prueba Comision fin*/

/*Prueba Comision2*/
Insert into #Claves values ('[%gtosAdmCobPK%]','')
set @VariableTexto=''
select @VariableTexto= CTP_NO_MTO_PAGO from KTPAGO_CONTRATO where cto_fl_cve = '11cs' and CTP_CL_TTABLA =4  and CTP_NO_PAGO=1
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%gtosAdmCobPK%]'

/*Prueba Comision fin*/
 /*PRUEBA CUENTAS BANCARIAS IICI-B-XXX ini*/
Insert into #Claves values ('[%CuentaBancaria%]','')
Insert into #Claves values ('[%CLABE%]','')
Insert into #Claves values ('[%TarjetaDebito%]','')
set @VariableTexto=''
SET @VariableTexto1 =''
set @VariableTexto2 =''
select @VariableTexto= PCT_NO_CUENTA, @VariableTexto1 = PCT_NO_CLABE, @VariableTexto2 = A.PCT_DS_NUMTARJETA  from 
 CPCUENTA a inner join CPERSONA b
 on a.PNA_FL_PERSONA = b.PNA_FL_PERSONA
 inner join cbanco d on d.BCO_FL_CVE = a.BCO_FL_CVE 
 inner join KCONTRATO c
 on b.PNA_FL_PERSONA = c.PNA_FL_PERSONA 
 INNER JOIN KCTO_CTASPAGO F ON F.CTO_FL_CVE = C.CTO_FL_CVE 
where C.CTO_FL_CVE = @CveContrato
and CPP_CL_CTAPERTENECE =2 AND d.BCO_DS_CVEBANXICO  >0
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CuentaBancaria%]'
UPDATE #Claves SET TEXTO= @VariableTexto1 WHERE CLAVE='[%CLABE%]'
UPDATE #Claves SET TEXTO= @VariableTexto2 WHERE CLAVE='[%TarjetaDebito%]'

Insert into #Claves values ('[%ficha%]','')
set @VariableTexto=''
select @VariableTexto= PCT_NO_CUENTA from 
 CPCUENTA a inner join CPERSONA b
 on a.PNA_FL_PERSONA = b.PNA_FL_PERSONA
 inner join cbanco d on d.BCO_FL_CVE = a.BCO_FL_CVE 
 inner join KCONTRATO c
 on b.PNA_FL_PERSONA = c.PNA_FL_PERSONA 
where b.PNA_FL_PERSONA  = @CveCliente
and d.BCO_DS_CVEBANXICO  =0
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ficha%]'


/*PRUEBA MONTO TOTAL PAKDA*/
Insert into #Claves values (convert(char(100),'[%MontoTotal%]'),'')
set @VariableTexto=''
DECLARE @MONTOSUMAPK NUMERIC(13,2)

SELECT  @MONTOSUMAPK =  ISNULL (SUM(PC.CTP_NO_MTO_TOTPAGO),0)+ 
		  ISNULL((SELECT SUM(CCI_NO_MONTO_TOTAL) FROM KCTO_CARGOINICIAL CI WHERE CI.CTO_FL_CVE = PC.CTO_FL_CVE),0)+
          ISNULL((SELECT SUM(POL_NO_TOTAL) FROM KSEGURO_POLIZA SP WHERE SP.CTO_FL_CVE = PC.CTO_FL_CVE AND POL_FG_STATUS = 3),0)+
           ISNULL((SELECT SUM(CTP_NO_MTO_TOTPAGO) FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE = PC.CTO_FL_CVE AND CTP_CL_TTABLA = 4),0) 
FROM  KTPAGO_CONTRATO PC
WHERE PC.CTO_FL_CVE = @CveContrato AND PC.CTP_CL_TTABLA = 1 
	  AND CTP_NO_VERSION = (SELECT MAX(CTP_NO_VERSION) FROM KTPAGO_CONTRATO WHERE CTO_FL_CVE = PC.CTO_FL_CVE)
GROUP BY PC.CTO_FL_CVE
if @MONTOSUMAPK > 0
begin
	EXEC @VariableTexto = FormatNumber @MONTOSUMAPK ,2,',','.'
end
else
begin
	set @VariableTexto = '0.00'
end


UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%MontoTotal%]'

/*FIN*/

/*IICI-B_XXX fin*/

/*PRUEBA bancos IICI-B-XXX ini*/
Insert into #Claves values ('[%Banco%]','')
set @VariableTexto=''
select @VariableTexto= BCO_DS_NOMBRE 
  from CPCUENTA a
 inner join CBANCO b
 on a.BCO_FL_CVE = b.BCO_FL_CVE
 inner join CPERSONA c
 on a. pna_fl_persona = c.PNA_FL_PERSONA
 inner join KCONTRATO d
 on c.PNA_FL_PERSONA = d.PNA_FL_PERSONA
 INNER JOIN KCTO_CTASPAGO E ON E.PCT_FL_CVE =A.PCT_FL_CVE 
where D.CTO_FL_CVE = @CveContrato
AND CPP_CL_CTAPERTENECE =2
and B.BCO_DS_CVEBANXICO  >0


UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Banco%]'
/*IICI-B_XXX fin*/

/*prueba seguro del auto */
Insert into #Claves values ('[%Seg_Auto%]','')
set @VariableTexto=''
select @VariableTexto= b.CPC_DS_VALOR from ccatalogos_contratopersona a inner join ccatalogo_contrato b on a.CPC_FL_CVE = b.CPC_FL_CVE
where a.CPC_NO_CATALOGO = 8
and CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Seg_Auto%]'
/*fin prueba*/



/*PRUEBA Sucursal IICI-B-XXX ini*/
Insert into #Claves values ('[%Sucursal%]','')
set @VariableTexto=''
select @VariableTexto= PCT_NO_SUCURSAL
  from CPCUENTA a
 inner join CBANCO b
 on a.BCO_FL_CVE = b.BCO_FL_CVE
 inner join CPERSONA c
 on a. pna_fl_persona = c.PNA_FL_PERSONA
 inner join KCONTRATO d
 on c.PNA_FL_PERSONA = d.PNA_FL_PERSONA
where CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Sucursal%]'
/*IICI-B_XXX fin*/


/*PRUEBA ciudad empresa*/
Insert into #Claves values ('[%Ciudad_emp%]','')
set @VariableTexto=''
select @VariableTexto= EMP_DS_CIUDAD from CEMPRESA where EMP_FL_CVE = 1
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Ciudad_emp%]'
/*IICI-B_XXX fin*/


/*prueba rfc representante legal*/
Insert into #Claves values ('[%RFC_RepLegal%]','')
set @VariableTexto=''
Select VariableTexto = isnull(RTRIM(A.PNA_CL_RFC), '')
		from KCTO_ASIG_LEGAL_CLIENTE ALC 
		inner join CPERSONA A 
		on A.PNA_FL_PERSONA = ALC.PRE_FL_PERSONA  
		LEFT OUTER JOIN CPDATO_ADICIONAL B 
		ON B.PNA_FL_PERSONA = A.PNA_FL_PERSONA 
		AND B.PTI_FG_VALOR = 4 AND B.DTA_FL_CVE= 2
		where CTO_FL_CVE =@CveContrato	
		and ALG_CL_TIPO_RELACION =4
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RFC_RepLegal%]'

/*FIN*/




/*PRUEBA  ombre notario representante legal*/
Insert into #Claves values ('[%Notario_RepLeg%]','')
set @VariableTexto=''
select @VariableTexto = RTRIM(A.NOT_DS_NOMBRE) + ' ' + RTRIM(A.NOT_DS_APATERNO) + ' ' + RTRIM(A.NOT_DS_AMATERNO)
				from CNOTARIO a inner join KESCRITURA b
				on a.NOT_FL_CVE = b.NOT_FL_CVE
				inner join KCTO_ASIG_LEGAL_CLIENTE c
				on b.PNA_FL_PERSONA = c.PNA_FL_PERSONA
				where PRE_FL_PERSONA = @CveCliente
				and ALG_CL_TIPO_RELACION = 4
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Notario_RepLeg%]'
/*fin*/

/*PRUEBA  no.de escritura representante legal*/
Insert into #Claves values ('[%NoEsc_RepLeg%]','')
set @VariableTexto=''
select @VariableTexto = ESC_NO_ESCRITURA
				from CNOTARIO a inner join KESCRITURA b
				on a.NOT_FL_CVE = b.NOT_FL_CVE
				inner join KCTO_ASIG_LEGAL_CLIENTE c
				on b.PNA_FL_PERSONA = c.PNA_FL_PERSONA
				where PRE_FL_PERSONA = @CveCliente
				and ALG_CL_TIPO_RELACION = 4
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NoEsc_RepLeg%]'
/*fin*/

/*PRUEBA  fecha escritura representante legal*/
Insert into #Claves values ('[%FEsc_RepLeg%]','')
set @VariableTexto=''
select @VariableTexto = ESC_FE_ESCRITURA
				from CNOTARIO a inner join KESCRITURA b
				on a.NOT_FL_CVE = b.NOT_FL_CVE
				inner join KCTO_ASIG_LEGAL_CLIENTE c
				on b.PNA_FL_PERSONA = c.PNA_FL_PERSONA
				where PRE_FL_PERSONA = @CveCliente
				and ALG_CL_TIPO_RELACION = 4
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FEsc_RepLeg%]'
/*fin*/

/*PRUEBA  regimen conyugal*/
Insert into #Claves values ('[%Reg_Conyugal%]','')
set @VariableTexto=''
select @VariableTexto = PAR_DS_DESCRIPCION from CPARAMETRO a inner join CPFISICA b
         on a.PAR_CL_VALOR = b.PFI_FG_REGMAT
		 where PAR_FL_CVE = 16
		 and PNA_FL_PERSONA = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Reg_Conyugal%]'
/*fin*/

/*nacionalidad*/

DECLARE @Nacionalidad VARCHAR (25)
	 
	 SELECT @Nacionalidad = CASE PFI_FG_NACIONALIDAD
				WHEN  1 THEN 'MEXICANA'
				WHEN  2 THEN 'EXTRANJERA'
				
			END
	FROM	CPFISICA WHERE PNA_FL_PERSONA = @cveCliente
		INSERT INTO #Claves VALUES ('[%NACIONALIDAD%]',RTRIM(convert(varchar(20),@Nacionalidad)))
		/*fin nacionalidad*/

/*PRUEBA FECHA DE FACTURA IICI-B-XXX ini*/
Insert into #Claves values ('[%FechaFactura%]','')
set @VariableTexto=''
select @VariableTexto = convert (varchar,fac_fe_factura, 101) from kcto_fact a inner join
kcontrato b on a.cto_fl_cve = b.cto_fl_cve 
where a.CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaFactura%]'
/*IICI-B_XXX fin*/

/*Prueba Intereses Moratorios*/

Insert into #Claves values ('[%IntMoratorios%]','')
set @VariableTexto=''
select @VariableTexto = CTO_NO_NOMINAL_MORA from KCONTRATO
where CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%IntMoratorios%]'

/* Fin Prueba Intereses Moratorios*/

/*Prueba Depósito Capital*/
Insert into #Claves values ('[%DepositoCapital%]','')
set @VariableTexto=''
declare @DEPOSITOCAP INT
select @DEPOSITOCAP = cto_no_capital from kcontrato 
where cto_fl_cve = @CveContrato 
EXEC @VariableTexto = FormatNumber @DEPOSITOCAP ,2,',','.'

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DepositoCapital%]'



/* Fin Prueba Depósito Capital*/

/*Prueba seguro de daños por el primer año*/

Insert into #Claves values ('[%SeguroDanios%]','')
set @VariableTexto=''
select @VariableTexto = pol_no_total from kseguro_poliza
where pol_fg_status = 3 and
cto_fl_cve = @CveContrato 
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%SeguroDanios%]'

/* Fin Prueba seguro de daños por el primer año*/

/*Prueba seguro de vida por el primer año*/

Insert into #Claves values ('[%SeguroVida%]','')
set @VariableTexto=''
select @VariableTexto = 
isnull(sum(CCI_NO_MONTO_TOTAL),0)
from kcto_cargoinicial where ktm_cl_tmovto='SEGVID' and cto_fl_cve = @CveContrato 
/*isnull(sum(ctp_no_mto_totpago),0) from ktpago_contrato a inner join
kcto_ocargos b on a.ctc_fl_cve = b.ctc_fl_cve where ktm_cl_tmovto = 'segvid'
and a.cto_fl_cve = @CveContrato */
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%SeguroVida%]'

/* Fin Prueba seguro de vida por el primer año*/
/*Prueba Pago Monto Parcial*/

/*Prueba aseguradora*/

Insert into #Claves values ('[%Aseguradora%]','')
set @VariableTexto=''
select @VariableTexto = pna_ds_nombre from kseguro_poliza a inner join
cpersona b on a.pna_fl_persona = b.pna_fl_persona
--where pol_fg_status = 3
and a.cto_fl_cve = @CveContrato 
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Aseguradora%]'

/* Fin Prueba aseguradora*/


/*Prueba Valor Residual ANC*/

Insert into #Claves values ('[%VALRESID%]','')
set @VariableTexto=''
declare @valores int
select @valores = CTO_NO_MTO_VRESIDUAL from KCONTRATO
where cto_fl_cve = @CveContrato 
EXEC @VariableTexto = FormatNumber @valores,2,',','0.00'	
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%VALRESID%]'

/* Fin Prueba*/

/*Prueba Nombre Organismo*/
Insert into #Claves values ('[%Nom_Organismo%]','')
set @VariableTexto=''
select @VariableTexto =  gri_ds_nombre from cgruporiesgo a inner join
cpersona b on a.gri_fl_cve = b.gri_fl_cve where pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Nom_Organismo%]'
/* Fin Prueba*/



/*Prueba Apellido Paterno Cliente*/
Insert into #Claves values ('[%ApaternoCliente%]','')
set @VariableTexto=''
select @VariableTexto = pfi_ds_apaterno from cpfisica where pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ApaternoCliente%]'
/* Fin Prueba*/

/*Prueba Apellido materno Cliente*/
Insert into #Claves values ('[%AmaternoCliente%]','')
set @VariableTexto=''
select @VariableTexto = pfi_ds_amaterno from cpfisica where pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AmaternoCliente%]'
/* Fin Prueba */

/*Prueba Nombre Solo Cliente*/
Insert into #Claves values ('[%NomCliente%]','')
set @VariableTexto=''
select @VariableTexto = pfi_ds_nombre from cpfisica where pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomCliente%]'
/* Fin Prueba */



/*Prueba Pago Monto Parcial*/
Insert into #Claves values ('[%PagoMontoParcial%]','')
set @VariableTexto=''

SET @PagoMontoParcial  = 0

select @PagoMontoParcial = SUM(ctp_no_mto_totpago)from 
ktpago_contrato 
where cto_fl_cve = @CveContrato
AND CTP_NO_PAGO=2;

EXEC @VariableTexto = FormatNumber @PagoMontoParcial,2,',','.'	

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%PagoMontoParcial%]' 

/* Fin Prueba Pago Monto Parcial*/

/*Prueba Pago Monto Parcial*/
Insert into #Claves values ('[%TasaNominal+IVA%]','')
set @VariableTexto=''
select @VariableTexto = CONVERT(NUMERIC(10,2),CTO_NO_TASA_NOMINAL * (1 + ([CTO_CL_IVA]/100))) from kcontrato 
where cto_fl_cve = @CveContrato

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TasaNominal+IVA%]' 

/* Fin Prueba Pago Monto Parcial*/


/*Prueba Iva*/

Insert into #Claves values ('[%IVA%]','')
set @VariableTexto=''
select @VariableTexto = CTO_CL_IVA from KCONTRATO
where CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%IVA%]'

/* Fin Prueba Iva*/

/*PRUEBA equipo/bien IICI-B-XXX ini*/
Insert into #Claves values ('[%Equipo%]','')
set @VariableTexto=''
select @VariableTexto =  PRD_DS_PRODUCTO
 from CPRODUCTO a inner join KPRODUCTO_FACTURA b on a.PRD_FL_CVE = b.PRD_FL_CVE
 inner join KCONTRATO c on b.CTO_FL_CVE = c.CTO_FL_CVE
 where c.cto_fl_cve = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Equipo%]'
/*IICI-B_XXX fin*/

/*PRUEBA Forma de Pago IICI-B-XXX ini*/
Insert into #Claves values ('[%FormaPago%]','')
set @VariableTexto=''
select @VariableTexto = par_ds_descripcion
from cparametro a inner join cpcuenta b
on a.par_cl_valor = b.pct_cl_mpago inner join
kcontrato c on b.pna_fl_persona = c.pna_fl_persona
where par_fl_cve = 324 and cto_fl_cve = @CveContrato
exec lsntReplace  @VariableTexto,@VariableTexto  OUTPUT
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FormaPago%]'
/*IICI-B_XXX fin*/

/*PRUEBA MunicipioCliente/ IICI-B-XXX ini*/
Insert into #Claves values ('[%MunicipioCliente%]','')
set @VariableTexto=''
select @VariableTexto = dmo_ds_municipio from cdomicilio a  inner join cpersona b
on a.pna_fl_persona = b.pna_fl_persona
where b.pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%MunicipioCliente%]'
/*IICI-B_XXX fin*/

/*PRUEBA TelefonoMovil/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TelefonoMovil%]','')
set @VariableTexto=''
select @VariableTexto = (TFN_CL_LADA) + ' ' + tfn_cl_telefono from cpersona a inner join
ctelefono b on a.pna_fl_persona = b.pna_fl_persona
inner join cttelefono c on b.ttl_fl_cve = c.ttl_fl_cve
where b.ttl_fl_cve = 4
and a.pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelefonoMovil%]'
/*IICI-B_XXX fin*/


/*PRUEBA TelefonoMovil/ IICI-B-XXX ini*/
Insert into #Claves values ('[%Escolaridad%]','')
set @VariableTexto=''

select @VariableTexto = ccpc.cpc_ds_valor
from  CCATALOGO_PERSONA ccp
inner join CCATALOGOS_CONTRATOPERSONA ccpc
on  ccp.CPC_FL_CVE = ccpc.CPC_FL_CVE
and ccpc.cpc_no_catalogo = 4
where  ccp.cpc_no_catalogo=4 and  pna_fl_persona=@CveCliente

UPDATE #Claves SET TEXTO= @VariableTexto  WHERE CLAVE='[%Escolaridad%]'
/*IICI-B_XXX fin*/


/*PRUEBA EmpresaCliente/ IICI-B-XXX ini*/
Insert into #Claves values ('[%emp_cliente%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where b.dta_fl_cve=42 --dta_ds_dato = 'NOMBRE DE LA EMPRESA EN QUE PRESTA SUS SERVICIOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%emp_cliente%]'
/*IICI-B_XXX fin*/
/*PRUEBA EmpresaCliente/ IICI-B-XXX ini*/
Insert into #Claves values ('[%Giroemp_cliente%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where b.dta_fl_cve=43 --dta_ds_dato = 'NOMBRE DE LA EMPRESA EN QUE PRESTA SUS SERVICIOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Giroemp_cliente%]'
/*IICI-B_XXX fin*/

/*PRUEBA Antigüedad en la empresa/ IICI-B-XXX ini*/

Insert into #Claves values ('[%emp_client_antig%]','')

set @VariableTexto=''

select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where b.dta_fl_cve=10--dta_ds_dato = 'ANTIGUEDAD EN EMPLEO'
and pna_fl_persona = @CveCliente
exec lsntReplace @VariableTexto, @VariableTexto output
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%emp_client_antig%]'
/*IICI-B_XXX fin*/

/*PRUEBA nombre del jefe inmediato/ IICI-B-XXX ini*/
Insert into #Claves values ('[%jefe_inmediato%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where dta_ds_dato = 'NOMBRE DEL JEFE INMEDIATO'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%jefe_inmediato%]'
/*IICI-B_XXX fin*/

/*PRUEBA nombre del Centro de trabajo/ IICI-B-XXX ini*/
Insert into #Claves values ('[%centro_tbjo%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where b.DTA_FL_CVE = 46
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%centro_tbjo%]'
/*IICI-B_XXX fin*/

/*PRUEBA nombre del Descripcion del departamento/ IICI-B-XXX ini*/
Insert into #Claves values ('[%Ddepartamento%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where b.DTA_FL_CVE = 47
and pna_fl_persona = @CveCliente

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Ddepartamento%]'
/*IICI-B_XXX fin*/

/*PRUEBA puesto del jefe inmediato/ IICI-B-XXX ini*/
Insert into #Claves values ('[%jefe_inm_puesto%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cpdato_adicional a inner join
cdtadcxpna b on a.dta_fl_cve = b.dta_fl_cve
where dta_ds_dato = 'PUESTO DEL JEFE INMEDIATO'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%jefe_inm_puesto%]'
/*IICI-B_XXX fin*/


/*PRUEBA puesto del cliente/ IICI-B-XXX ini*/
Insert into #Claves values ('[%puesto_cliente%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =7--dta_ds_dato = 'PUESTO'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%puesto_cliente%]'
/*IICI-B_XXX fin*/

/*PRUEBA tipo de contrato/ IICI-B-XXX ini*/
Insert into #Claves values ('[%tipo_contrato%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 8--dta_ds_dato = 'TIPO DE CONTRATO'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%tipo_contrato%]'
/*IICI-B_XXX fin*/

/*PRUEBA sueldo mensual neto/ IICI-B-XXX ini*/

Insert into #Claves values ('[%sueldmen_cliente%]','')
set @VariableTexto=''
declare @sueldmen INT

select @sueldmen  = isnull(pda_ds_valorad,0) from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 9--dta_ds_dato = 'SUELDO MENSUAL NETO'
and pna_fl_persona = @CveCliente

if @sueldmen > 0
begin
	EXEC @VariableTexto = FormatNumber @sueldmen ,2,',','.'
end
else
begin
	set @VariableTexto = ''
end

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%sueldmen_cliente%]' 

--INSERT INTO #Claves VALUES ('[%PER_TIPODEVIVIENDA%]', isnull(@per_tipodevivienda, ''));
/*IICI-B_XXX fin*/



/*PRUEBA ingreso por sueldo/ IICI-B-XXX ini*/
Insert into #Claves values ('[%ingreso_sueldo%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =11 -- dta_ds_dato = 'INGRESO POR SUELDO'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ingreso_sueldo%]'
/*IICI-B_XXX fin*/

/*PRUEBA otros ingresos/ IICI-B-XXX ini*/
Insert into #Claves values ('[%otrosingresos%]','')
set @VariableTexto=''
select @VariableTexto = dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')  from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 12--dta_ds_dato = 'OTROS INGRESOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%otrosingresos%]'
/*IICI-B_XXX fin*/

/*PRUEBA otros egresos/ IICI-B-XXX ini*/
Insert into #Claves values ('[%otrosegresos%]','')
set @VariableTexto=''
select @VariableTexto = dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')  from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 14--dta_ds_dato = 'OTROS INGRESOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%otrosegresos%]'
/*IICI-B_XXX fin*/

/*PRUEBA otros ingresos/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TotalIngresos%]','')
set @VariableTexto=''
select @VariableTexto = dbo.FormatNumber ( isnull(sum(convert(numeric(13,2),pda_ds_valorad)),0) ,2,',','.') from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE in ( 11,12)--dta_ds_dato = 'OTROS INGRESOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TotalIngresos%]'
/*IICI-B_XXX fin*/

/*PRUEBA gastos familiares/ IICI-B-XXX ini*/
Insert into #Claves values ('[%gastosfam%]','')
set @VariableTexto=''
select @VariableTexto = dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')  from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =13--dta_ds_dato = 'GASTOS FAMILIARES'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%gastosfam%]'
/*IICI-B_XXX fin*/

/*PRUEBA gastos gastos/ IICI-B-XXX ini*/
Insert into #Claves values ('[%otrosgastosF%]','')
set @VariableTexto=''
select @VariableTexto = dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')  from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 14--dta_ds_dato = 'OTROS GASTOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%otrosgastosF%]'
/*IICI-B_XXX fin*/

/*PRUEBA gastos gastos/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TotalEgresos%]','')
set @VariableTexto=''
select @VariableTexto = dbo.FormatNumber ( isnull(sum(convert(numeric(13,2),pda_ds_valorad)),0) ,2,',','.')  from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE in (13,14)--dta_ds_dato = 'OTROS GASTOS'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TotalEgresos%]'
/*IICI-B_XXX fin*/

/*PRUEBA monto deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%deuda1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 15--dta_ds_dato = 'MONTO DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%deuda1%]'
/*IICI-B_XXX fin*/

/*PRUEBA institucion deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%inst_deuda1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 16 --dta_ds_dato = 'INSTITUCION DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%inst_deuda1%]'
/*IICI-B_XXX fin*/

/*PRUEBA plazo deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%plzo_deuda1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 17--dta_ds_dato = 'PLAZO DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%plzo_deuda1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%dstno_deuda1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 18--dta_ds_dato = 'DESTINO DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%dstno_deuda1%]'
/*IICI-B_XXX fin*/


/*PRUEBA monto deuda 2/ IICI-B-XXX ini*/
Insert into #Claves values ('[%deuda2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 19--dta_ds_dato = 'MONTO DEUDA 2'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%deuda2%]'
/*IICI-B_XXX fin*/

/*PRUEBA institucion deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%inst_deuda2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 20 --dta_ds_dato = 'INSTITUCION DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%inst_deuda2%]'
/*IICI-B_XXX fin*/

/*PRUEBA plazo deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%plzo_deuda2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 21--dta_ds_dato = 'PLAZO DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%plzo_deuda2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%dstno_deuda2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 22--dta_ds_dato = 'DESTINO DEUDA 1'
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%dstno_deuda2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%NomRefPers1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 23
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomRefPers1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%DomRefPers1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 24
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomRefPers1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TelRefPers1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 25
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRefPers1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%AnioRefPers1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 26
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AnioRefPers1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%NomRefPers2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 27
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomRefPers2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%DomRefPers2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 28
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomRefPers2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TelRefPers2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 29
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRefPers2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%AnioRefPers2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 30
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AnioRefPers2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%NomRefLab1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 31
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomRefLab1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%DomRefLab1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 32
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomRefLab1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TelRefLab1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 33
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRefLab1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%AnioRefLab1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 34
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AnioRefLab1%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%NomRefLab2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 35
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomRefLab2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%DomRefLab2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 36
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomRefLab2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%TelRefLab2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 37
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRefLab2%]'
/*IICI-B_XXX fin*/

/*PRUEBA destino deuda 1/ IICI-B-XXX ini*/
Insert into #Claves values ('[%AnioRefLab2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 30
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AnioRefLab2%]'
/*IICI-B_XXX fin*/

-- AOB: EMPIEZA INFORMACION DE RELACION CON PROVEEDORES DE PMORALES

Insert into #Claves values ('[%NomProv1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 51
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomProv1%]'

Insert into #Claves values ('[%DomProv1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 52
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomProv1%]'

Insert into #Claves values ('[%TelProv1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 53
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelProv1%]'

Insert into #Claves values ('[%ARelProv1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 54
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ARelProv1%]'

Insert into #Claves values ('[%NomProv2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 55
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomProv2%]'


Insert into #Claves values ('[%DomProv2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 56
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomProv2%]'

Insert into #Claves values ('[%TelProv2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 57
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelProv2%]'

Insert into #Claves values ('[%ARelProv2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 58
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ARelProv2%]'

--ANC PRUEBA CUENTA, CLABE, NO DE TARJETA AVAL
Insert into #Claves values ('[%CUENTA_AVAL%]','')
set @VariableTexto=''
select @VariableTexto = PCT_NO_CUENTA from CPRELACION a inner join  CPCUENTA b
       on a.PNA_FL_PERSONA = b.pna_fl_persona
	   INNER JOIN CBANCO C ON B.BCO_FL_CVE = C.BCO_FL_CVE
	   where PRE_FL_PERSONA = @CveCliente
	   and PRE_FG_VALOR = 3
	   AND C.BCO_DS_CVEBANXICO  >0
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CUENTA_AVAL%]'

Insert into #Claves values ('[%CLABE_AVAL%]','')
set @VariableTexto=''
select @VariableTexto = PCT_NO_CLABE from CPRELACION a inner join  CPCUENTA b
       on a.PNA_FL_PERSONA = b.pna_fl_persona
	   INNER JOIN CBANCO C ON B.BCO_FL_CVE = C.BCO_FL_CVE
	   where PRE_FL_PERSONA = @CveCliente
	   and PRE_FG_VALOR = 3
	   AND C.BCO_DS_CVEBANXICO  >0
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%CLABE_AVAL%]'


Insert into #Claves values ('[%T_AVAL%]','')
set @VariableTexto=''
select @VariableTexto = PCT_DS_NUMTARJETA from CPRELACION a inner join  CPCUENTA b
       on a.PNA_FL_PERSONA = b.pna_fl_persona
	   INNER JOIN CBANCO C ON B.BCO_FL_CVE = C.BCO_FL_CVE
	   where PRE_FL_PERSONA = @CveCliente
	   and PRE_FG_VALOR = 3
	   AND C.BCO_DS_CVEBANXICO  >0
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%T_AVAL%]'



Insert into #Claves values ('[%BANCO_AVAL%]','')
set @VariableTexto=''
select @VariableTexto = BCO_DS_NOMBRE FROM CPRELACION A
       INNER JOIN CPCUENTA B ON A.PNA_FL_PERSONA = B.PNA_FL_PERSONA
	   INNER JOIN CBANCO C ON B.BCO_FL_CVE = C.BCO_FL_CVE
	   WHERE PRE_FL_PERSONA = @CveCliente
	   AND PRE_FG_VALOR = 3
	   AND C.BCO_DS_CVEBANXICO  >0
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%BANCO_AVAL%]'




--FIN PRUEBA




-- FIN

--- FIN 


-- AOB: empieza relacion comercial de la pmoral

Insert into #Claves values ('[%NomRC1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 59
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomRC1%]'

Insert into #Claves values ('[%DomRC1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 60
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomRC1%]'

Insert into #Claves values ('[%TelRC1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 61
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRC1%]'

Insert into #Claves values ('[%ARelRC1%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 62
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ARelRC1%]'

Insert into #Claves values ('[%NomRC2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 63
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%NomRC2%]'


Insert into #Claves values ('[%DomRC2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 64
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%DomRC2%]'

Insert into #Claves values ('[%TelRC2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 65
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRC2%]'

Insert into #Claves values ('[%ARelRC2%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 66
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ARelRC2%]'

-- fin
--AOB empieza informacion de ingresos y egresos PM

Insert into #Claves values ('[%IngresoXVta%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =67 
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%IngresoXVta%]'

Insert into #Claves values ('[%OtrosIngresosPM%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =68
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%OtrosIngresosPM%]'


Insert into #Claves values ('[%TIngresosPM%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =69
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TIngresosPM%]'

Insert into #Claves values ('[%GastoXVta%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =70 
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%GastoXVta%]'

Insert into #Claves values ('[%OtrosGastosPM%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 71
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%OtrosGastosPM%]'


Insert into #Claves values ('[%TEgresosPM%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =72
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TEgresosPM%]'
--- fin

-- AOB datos de PF sueldos 

Insert into #Claves values ('[%SueldoLibre%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =73
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%SueldoLibre%]'


Insert into #Claves values ('[%FIngreso%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 74
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FIngreso%]'

Insert into #Claves values ('[%Rtahipoteca%]','')
set @VariableTexto=''
select @VariableTexto =  dbo.FormatNumber ( convert(numeric(13,2),isnull(pda_ds_valorad, 0.00)) ,2,',','.')   
from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE =75
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Rtahipoteca%]'


Insert into #Claves values ('[%TelRecados%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 76
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TelRecados%]'

Insert into #Claves values ('[%TiempoResidencia%]','')
set @VariableTexto=''
select @VariableTexto = pda_ds_valorad from cdtadcxpna a inner join cpdato_adicional b
on a.dta_fl_cve = b.dta_fl_cve where a.DTA_FL_CVE = 77
and pna_fl_persona = @CveCliente
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%TiempoResidencia%]'

-- FIN

/*PRUEBA IMPUESTO AL VALOR AGREGADO X ini*/
Insert into #Claves values ('[%ImpuestoVal%]','')
set @VariableTexto=''
declare @ImpuestoVall INT
select @ImpuestoVall = sum(CTP_NO_MTO_IVA) FROM KTPAGO_CONTRATO
 WHERE CTO_FL_CVE =  @CveContrato
 AND CTP_CL_TTABLA = 1 
 EXEC @VariableTexto = FormatNumber @ImpuestoVall ,2,',','.'
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ImpuestoVal%]'





/*PRUEBA OTROS GASTOS ini*/
Insert into #Claves values ('[%OtrosGastos%]','')
set @VariableTexto=''
declare @OtrosG INT
select @OtrosG = CTP_NO_MTO_TOTPAGO FROM KTPAGO_CONTRATO
 WHERE CTO_FL_CVE =  @CveContrato
 AND CTP_CL_TTABLA = 4
AND CTP_NO_PAGO=1;
if @OtrosG > 0
begin
	EXEC @VariableTexto = FormatNumber @OtrosG ,2,',','.'
end
else
begin
	set @VariableTexto = 0.00
end
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Otrosgastos%]'
/*IICI-B_XXX fin*/

/*PRUEBA PAGOS CON IVA TABLA DE AMORT ini*/
Insert into #Claves values ('[%PagoCIVA%]','')
set @VariableTexto=''
declare @PAGIVA INT
select @PAGIVA = isnull(CTP_NO_MTO_PG_CON_IVA,0) FROM KTPAGO_CONTRATO
 WHERE CTO_FL_CVE =  @CveContrato
 AND CTP_CL_TTABLA = 1
AND CTP_NO_PAGO=1;
if @PAGIVA > 0
begin
	EXEC @VariableTexto = FormatNumber @PAGIVA ,2,',','0.00'
end
else
begin
	set @VariableTexto = ''
end

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%PagoCIVA%]'
/*IICI-B_XXX fin*/




---AOB: INICIA ASEGURADORA SEGURO DE VIDA

Insert into #Claves values ('[%SegVDeu%]','')
set @VariableTexto=''
select @VariableTexto = a.CPC_DS_VALOR from ccatalogos_contratopersona a inner join ccatalogo_contrato b on a.CPC_FL_CVE = b.CPC_FL_CVE
where CPC_DS_NOMBRECATALOGO like '%seguro de vida deu%'
and CTO_FL_CVE = @CveContrato
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%SegVDeu%]'
--INSERT INTO #Claves VALUES ('[%SegVDeu%]', isnull(@AsegVida, ''));


------ anc seguro de vida de credito


Insert into #Claves values ('[%SegVCre%]','')
set @VariableTexto=''
select @VariableTexto = a.CPC_DS_VALOR from ccatalogos_contratopersona a inner join ccatalogo_contrato b on a.CPC_FL_CVE = b.CPC_FL_CVE
where CPC_DS_NOMBRECATALOGO like '%seguro de vida cre%'
and CTO_FL_CVE = @CveContrato
exec lsntReplace  @VariableTexto,@VariableTexto  OUTPUT
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%SegVCre%]'

----FIN

---AOB: INICIA PAGINA WEB CLIENTE
Insert into #Claves values ('[%PagWebCli%]','')
declare @PagWebCli varchar(50)
set @PagWebCli =''
select @PagWebCli = PDA_DS_VALORAD FROM CPDATO_ADICIONAL WHERE PNA_FL_PERSONA = @CveCliente and DTA_FL_CVE = 46

UPDATE #Claves SET TEXTO= ISNULL(rtrim(@PagWebCli),'') WHERE CLAVE='[%PagWebCli%]'
----FIN 

---AOB: INICIA CANTIDAD DE PERSONAL
Insert into #Claves values ('[%CantPersonal%]','')
declare @CantPersonal varchar(50)
set @CantPersonal =''
select @CantPersonal = PDA_DS_VALORAD FROM CPDATO_ADICIONAL WHERE PNA_FL_PERSONA = @CveCliente and DTA_FL_CVE = 47

UPDATE #Claves SET TEXTO= rtrim(@CantPersonal) WHERE CLAVE='[%CantPersonal%]'
----FIN 

---AOB: INICIA ACTIVIDAD PRINCIPAL ANTE LA SHCP
Insert into #Claves values ('[%ActSHCP%]','')
declare @ActSHCP varchar(50)
set @ActSHCP =''
select @ActSHCP = PDA_DS_VALORAD FROM CPDATO_ADICIONAL WHERE PNA_FL_PERSONA = @CveCliente and DTA_FL_CVE = 48

UPDATE #Claves SET TEXTO= rtrim(@ActSHCP) WHERE CLAVE='[%ActSHCP%]'
----FIN

INSERT INTO #Claves values ('[%domicilioEmpresa%]','')
set @VariableTexto=''
SELECT @VariableTexto=RTRIM(EMP_DS_CALLENUM) + ', COL. ' + RTRIM(EMP_DS_COLONIA)  
+ ',  C.P.' +  RTRIM(EMP_CL_CPOSTAL) + ', '  + RTRIM(EMP_DS_CIUDAD)  +  ', '  +  RTRIM(EMP_DS_EFEDERATIVA)  FROM CEMPRESA  
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE = '[%domicilioEmpresa%]'




UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%Fecha1OPC%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE='[%Fecha2OPC%]'
				SELECT @VariableFecha =  MAX(CTP_FE_EXIGIBILIDAD) FROM KTPAGO_CONTRATO  WHERE CTO_FL_CVE=@CveContrato 
				SET @VariableFecha = DATEADD(MM,-1,@VariableFecha)
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Fecha1OPC%]'

				SET @VariableFecha = DATEADD(MM,1,@VariableFecha)
				SET @VariableFecha = DATEADD(dd,5,@VariableFecha)
				if month(@VariableFecha) = 1
					SET @Mes = 'Enero'
				if month(@VariableFecha) = 2
					SET @Mes = 'Febrero'
				if month(@VariableFecha) = 3
					SET @Mes = 'Marzo'
				if month(@VariableFecha) = 4
					SET @Mes = 'Abril'
				if month(@VariableFecha) = 5
					SET @Mes = 'Mayo'
				if month(@VariableFecha) = 6
					SET @Mes = 'Junio'
				if month(@VariableFecha) = 7
					SET @Mes = 'Julio'
				if month(@VariableFecha) = 8
					SET @Mes = 'Agosto'
				if month(@VariableFecha) = 9
					SET @Mes = 'Septiembre'
				if month(@VariableFecha) = 10
					SET @Mes = 'Octubre'
				if month(@VariableFecha) = 11
					SET @Mes = 'Noviembre'
				if month(@VariableFecha) = 12
					SET @Mes = 'Diciembre'
				set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				
				UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Fecha2OPC%]'

UPDATE #Claves SET TEXTO= '' WHERE CLAVE= '[%LeyendaPlazo%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE= '[%FechaPrimerPago%]'
UPDATE #Claves SET TEXTO= '' WHERE CLAVE= '[%FechaUltimoPago%]'

Set @VariableTexto = ''
SET @VariableNumero = 0

SELECT @VariableNumero = A.ESQ_FG_IRREGULAR  FROM CESQUE_FINAN A INNER JOIN KTOPERACION B ON A.ESQ_CL_CVE = B.ESQ_CL_CVE 
INNER JOIN KCONTRATO C ON B.TOP_CL_CVE = C.TOP_CL_CVE  
WHERE C.CTO_FL_CVE = @CveContrato 

IF @VariableNumero =1
	UPDATE #Claves SET TEXTO= 'meses(considerar primer y último pago irregular)' WHERE CLAVE= '[%LeyendaPlazo%]'


SELECT @VariableFecha =  CTP_FE_EXIGIBILIDAD FROM KTPAGO_CONTRATO  WHERE CTO_FL_CVE=@CveContrato AND CTP_CL_TTABLA = 1 AND CTP_NO_PAGO = 1				
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))	
UPDATE #Claves SET TEXTO= isnull(@VariableTexto,'') WHERE CLAVE='[%FechaPrimerPago%]'

SELECT @VariableFecha =  MAX(CTP_FE_EXIGIBILIDAD) FROM KTPAGO_CONTRATO  WHERE CTO_FL_CVE=@CveContrato AND CTP_CL_TTABLA = 1 AND CTP_NO_PAGO > 0				
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))				
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%FechaUltimoPago%]'

SET @VariableNumero  = 0

SELECT @VariableNumero = CCI_NO_MONTO_TOTAL  
FROM KCTO_CARGOINICIAL  
WHERE CTO_FL_CVE = @CveContrato 
AND KTM_CL_TMOVTO = 'CMSF'

EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'	
	
SET @VariableTexto = @VariableTexto
UPDATE #Claves 
SET TEXTO= @VariableTexto 
WHERE CLAVE='[%Comision%]'

SET @VariableNumero  = 0
SELECT @VariableNumero = CCI_NO_MONTO_TOTAL  FROM KCTO_CARGOINICIAL  WHERE CTO_FL_CVE = @CveContrato AND KTM_CL_TMOVTO = 'GLEG'
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Gastos%]'

SET @VariableNumero  = 0
SELECT @VariableNumero =CTP_NO_MTO_TOTPAGO
FROM KTPAGO_CONTRATO   
WHERE CTO_FL_CVE = @CveContrato 
AND CTP_CL_TTABLA = 1 
AND CTP_NO_PAGO=1;

EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','0.00'		
SET @VariableTexto = @VariableTexto

UPDATE #Claves 
SET TEXTO= @VariableTexto 
WHERE CLAVE='[%PrimeraRenta%]';

/*PruebaPago*/
SET @VariableNumero  = 0
SELECT @VariableNumero = CTP_NO_MTO_PAGO    FROM KTPAGO_CONTRATO   WHERE CTO_FL_CVE = @CveContrato AND CTP_CL_TTABLA = 1 AND CTP_NO_PAGO=1
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','0.00'        
SET @VariableTexto = @VariableTexto

UPDATE #Claves 
SET TEXTO= @VariableTexto 
WHERE CLAVE='[%PrimerPagoP%]';
/*FIN*/




set @VariableTexto = replace(@VariableTexto, ',', '');

exec spLsnetCantidadLetra @VariableTexto, 1, @VariableTexto output;

UPDATE #Claves 
SET TEXTO= @VariableTexto 
WHERE CLAVE='[%PrimeraRentaLetra%]';

SET @VariableNumero  = 0
SELECT @VariableNumero =CTO_NO_MTO_DEPOSITO FROM KCONTRATO    WHERE CTO_FL_CVE = @CveContrato 
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RentaEnDeposito%]'

SET @VariableNumero  = 0
SELECT @VariableNumero = isnull(CCI_NO_MONTO_TOTAL,0)  FROM KCTO_CARGOINICIAL  WHERE CTO_FL_CVE = @CveContrato AND KTM_CL_TMOVTO = 'CMSF'
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Apertura%]'


Insert into #Claves values ('[%AperturaPK%]','')
set @VariableTexto=''
declare @Apertura INT
select @Apertura = isnull(CCI_NO_MONTO_TOTAL,0)  FROM KCTO_CARGOINICIAL  WHERE CTO_FL_CVE = @CveContrato AND KTM_CL_TMOVTO = 'CMSF'
 
if @Apertura > 0
begin
	EXEC @VariableTexto = FormatNumber @Apertura ,2,',','0.00'
end
else
begin
	set @VariableTexto = '0.00'
end

UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%AperturaPK%]'

SET @VariableNumero  = 0
SELECT @VariableNumero = CCI_NO_MONTO_TOTAL  FROM KCTO_CARGOINICIAL  WHERE CTO_FL_CVE = @CveContrato AND KTM_CL_TMOVTO = 'CELEBRACION'
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%Celebracion%]'

SET @VariableNumero  = 0
SELECT @VariableNumero = CCI_NO_MONTO_TOTAL  FROM KCTO_CARGOINICIAL  WHERE CTO_FL_CVE = @CveContrato AND KTM_CL_TMOVTO = 'SERVADMON'
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%ServAdmon%]'

SET @VariableNumero  = 0
SELECT @VariableNumero = A.CCI_NO_MONTO_TOTAL  FROM KCTO_CARGOINICIAL A
INNER JOIN KCONTRATO B ON B.CTO_FL_CVE = A.CTO_FL_CVE 
INNER JOIN KTOPERACION C ON C.TOP_CL_CVE = B.TOP_CL_CVE  AND C.KTM_CL_TMOVTO = A.KTM_CL_TMOVTO 
WHERE A.CTO_FL_CVE = @CveContrato 
EXEC @VariableTexto = FormatNumber @VariableNumero,2,',','.'		
SET @VariableTexto = @VariableTexto
UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%RentaAnt%]'

--Cargos iniciales
declare @tipoOperacion char(4)

select @tipoOperacion= TOP_CL_CVE  from KCONTRATO  where CTO_FL_CVE =@CveContrato 

SET @DescripcionProductosAutos = ''
SET @SeccionTabla = ''
SET @NOFFSET = 0
	SELECT @ptr = TEXTPTR(#Claves.Texto)  FROM #Claves WHERE Clave = '[%CondicionesContrato%]'
	
SET @SeccionTabla = ' \trowd\trbrdrt\brdrs\brdrw10\trbrdrl\brdrs\brdrw10\trbrdrb\brdrs\brdrw10\trbrdrr\trleft-70\brdrs\brdrw10 ' --\trftsWidth1\trftsWidthB3\trftsWidthA3\trautofit1\trpaddl70\trpaddr70\trpaddfl3\trpaddfr3\tblind0\tblindtype3
SET @SeccionTabla2 = ' \clvertalt\clbrdrt\brdrs\brdrw10\clbrdrl\brdrs\brdrw10\clbrdrb\brdrs\brdrw10\clbrdrr\brdrs\brdrw10 '
SET @SeccionTabla3 = ' \cltxlrtb\clftsWidth3\ '
SET  @SeccionTabla4 = ' \pard\plain\ltrpar\ql \li0\ri0\widctlpar\intbl\wrapdefault\aspalpha\aspnum\faauto\adjustleft\rin0\lin0 \rtlch\fcs1 \af38\afs24\alang1025 \ltrch\fcs0\fs24\lang3082\langfe3082\cgrid\langnp3082\langfenp3082{\rtlch\fcs1 \ab\af0\afs20 \ltrch\fcs0 \f37\fs20 ' 
	
SELECT  @plazo=KCONTRATO.CTO_NO_PLAZO
FROM KCONTRATO, CPERPAGO, CTASA
WHERE
KCONTRATO.PPG_FL_CVE=CPERPAGO.PPG_FL_CVE
AND
KCONTRATO.TAS_FL_CVE=CTASA.TAS_FL_CVE
AND
CTO_FL_CVE=@CveContrato
		
if @tipoOperacion<>'CP'
	begin			
		Select @VariableNumero = CTP_NO_MTO_PAGO from KTPAGO_CONTRATO WHERE CTO_FL_CVE = @CveContrato and CTP_CL_TTABLA = 1 AND CTP_NO_PAGO = 1
	end
else
	begin
		Select @VariableNumero = CTP_NO_MTO_TOTPAGO from KTPAGO_CONTRATO WHERE CTO_FL_CVE = @CveContrato and CTP_CL_TTABLA = 1 AND CTP_NO_PAGO = 1	
	end
EXEC @VariableTexto2 = FormatNumber @VariableNumero,2,',','.'		
	
SELECT @VariableNumero = A.ESQ_FG_IRREGULAR  FROM CESQUE_FINAN A INNER JOIN KTOPERACION B ON A.ESQ_CL_CVE = B.ESQ_CL_CVE 
INNER JOIN KCONTRATO C ON B.TOP_CL_CVE = C.TOP_CL_CVE  
WHERE C.CTO_FL_CVE = @CveContrato 

set @VariableTexto=''
IF @VariableNumero =1
	set @VariableTexto = 'meses(considerar primer y último pago irregular)'

if @tipoOperacion<>'CP'
	begin	
		SET @VariableTextoLarga = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx875'+ @SeccionTabla2 +  '\cltxlrtb\cellx9356' + @SeccionTabla4  + 'Plazo:\cell ' +  convert(char(3), @plazo)+ ' '+@VariableTexto +   ' pagos de  $'+ rtrim(@VariableTexto2)  +' pesos cada uno. \par Incluye el Impuesto al Valor Agregado\cell }\pard\plain{'						
	end
else
	begin
		SET @VariableTextoLarga = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx875'+ @SeccionTabla2 + '\cltxlrtb\cellx2736'+ @SeccionTabla2 + '\cltxlrtb\cellx3957' + @SeccionTabla2 + '\cltxlrtb\cellx9356' + @SeccionTabla4  + 'Plazo:\cell ' +  convert(char(3), @plazo)+  '\cell Renta:\cell $'+ rtrim(@VariableTexto2)  +' pesos más el Impuesto al Valor Agregado\cell }\pard\plain{'							
	end
exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
SET @VariableTextoLarga =  '\row}\pard\plain' 
exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

	
---********Sumar el primer pago de la tabla de amortizacion con sus seguros ANC *******
Insert into #Claves values (convert(char(100),'[%PTOTALPK%]'),'')
set @VariableTexto=''
DECLARE @PTOTALPK NUMERIC(13,2)
select  @PTOTALPK =isnull(sum (CTP_NO_MTO_TOTPAGO),0)+
          isnull((select sum (CTP_NO_MTO_TOTPAGO) FROM KTPAGO_CONTRATO where CTP_CL_TTABLA = 2 and cto_fl_cve = @CveContrato and ctp_no_pago = 1),0)+
             isnull((select sum (CTP_NO_MTO_TOTPAGO) FROM KTPAGO_CONTRATO where CTP_CL_TTABLA = 3 and cto_fl_cve = @CveContrato and ctp_no_pago = 1),0)+
               isnull((select sum (CTP_NO_MTO_TOTPAGO) FROM KTPAGO_CONTRATO where CTP_CL_TTABLA = 4 and cto_fl_cve = @CveContrato and ctp_no_pago = 1),0)
            FROM KTPAGO_CONTRATO where CTP_CL_TTABLA = 1 and cto_fl_cve = @CveContrato and ctp_no_pago = 1 group by CTP_CL_TTABLA
            if @PTOTALPK > 0
begin
	EXEC @VariableTexto = FormatNumber @PTOTALPK ,2,',','0.00'
end
else
begin
	set @VariableTexto = ''
end




UPDATE #Claves SET TEXTO= @VariableTexto WHERE CLAVE='[%PTOTALPK%]'
--***************FIN **************************
	
SELECT @VariableFecha =  CTP_FE_EXIGIBILIDAD FROM KTPAGO_CONTRATO  WHERE CTO_FL_CVE=@CveContrato AND CTP_CL_TTABLA = 1 AND CTP_NO_PAGO = 1				
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))	

SELECT @VariableFecha =  MAX(CTP_FE_EXIGIBILIDAD) FROM KTPAGO_CONTRATO  WHERE CTO_FL_CVE=@CveContrato AND CTP_CL_TTABLA = 1 AND CTP_NO_PAGO > 0				
if month(@VariableFecha) = 1
	SET @Mes = 'Enero'
if month(@VariableFecha) = 2
	SET @Mes = 'Febrero'
if month(@VariableFecha) = 3
	SET @Mes = 'Marzo'
if month(@VariableFecha) = 4
	SET @Mes = 'Abril'
if month(@VariableFecha) = 5
	SET @Mes = 'Mayo'
if month(@VariableFecha) = 6
	SET @Mes = 'Junio'
if month(@VariableFecha) = 7
	SET @Mes = 'Julio'
if month(@VariableFecha) = 8
	SET @Mes = 'Agosto'
if month(@VariableFecha) = 9
	SET @Mes = 'Septiembre'
if month(@VariableFecha) = 10
	SET @Mes = 'Octubre'
if month(@VariableFecha) = 11
	SET @Mes = 'Noviembre'
if month(@VariableFecha) = 12
	SET @Mes = 'Diciembre'
set  @VariableTexto2 = cast(day(@VariableFecha) as varchar(2)) + ' de ' + @Mes + ' de ' + cast(year(@VariableFecha) as varchar(4))	

if @tipoOperacion<>'CP'
	begin	
		SET @VariableTextoLarga = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx1620'+ @SeccionTabla2 + '\cltxlrtb\cellx4374'+ @SeccionTabla2 + '\cltxlrtb\cellx6599' + @SeccionTabla2 + '\cltxlrtb\cellx9356' + @SeccionTabla4  + 'Fecha de Inicio:\cell ' +  rtrim(@VariableTexto) +   '\cell Fecha de Vencimiento:\cell '+ rtrim(@VariableTexto2)  +'\cell }\pard\plain{'
	end
else
	begin
		SET @VariableTextoLarga = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx1620'+ @SeccionTabla2 + '\cltxlrtb\cellx4374'+ @SeccionTabla2 + '\cltxlrtb\cellx6599' + @SeccionTabla2 + '\cltxlrtb\cellx9356' + @SeccionTabla4  + 'Fecha de Primer pago:\cell ' +  rtrim(@VariableTexto) +   '\cell Fecha de Ultimo pago:\cell '+ rtrim(@VariableTexto2)  +'\cell }\pard\plain{'	
	end
exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
SET @VariableTextoLarga =  '\row}\pard\plain' 
exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
	
	
	
DECLARE curCargosIniciales CURSOR FOR
select CCI_NO_MONTO,CCI_NO_MONTO_TOTAL,CIN_DS_DESCRIPCION  FROM KCTO_CARGOINICIAL kcc inner join CCARGO_INICIAL cci on  cci.cin_fl_cve= kcc.cin_fl_cve
  WHERE CTO_FL_CVE = @CveContrato
		open curCargosIniciales
		fetch next from curCargosIniciales into @VariableNumero,@variablenumero3,@VariableTexto
		WHILE @@fetch_status = 0 
	begin		
	
			set @VariableTexto2=''
			if @tipoOperacion<>'CP'
				begin	
					EXEC @VariableTexto2 = FormatNumber @VariableNumero,2,',','0.0'		
					--SET @VariableTexto2 = @VariableTexto2
					SET @VariableTextoLarga = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx3690' + @SeccionTabla2 + '\cltxlrtb\cellx9356' + @SeccionTabla4 +  @VariableTexto + '\cell ' + '  $'+ RTRIM(@VariableTexto2) +   ' pesos más el Impuesto al Valor Agregado\cell}\pard\plain{'						
				end
			else
				begin
					EXEC @VariableTexto2 = FormatNumber @VariableNumero3,2,',','0.0'						
					SET @VariableTextoLarga = '\ltrrow' + @SeccionTabla + @SeccionTabla2 + '\cltxlrtb\cellx3690' + @SeccionTabla2 + '\cltxlrtb\cellx9356' + @SeccionTabla4 +  @VariableTexto + '\cell ' + '  $'+ RTRIM(@VariableTexto2) +   ' pesos MN. Incluye el Impuesto al Valor Agregado\cell}\pard\plain{'										
				end		
			exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
			UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
			SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	
			SET @VariableTextoLarga =  '\row}\pard\plain' 
			exec lsntReplace  @VariableTextoLarga,@VariableTextoLarga  OUTPUT
			UPDATETEXT #Claves.texto @ptr @NOFFSET NULL @VariableTextoLarga
			SET @NOFFSET = @NOFFSET + LEN(RTRIM(@VariableTextoLarga))	

																								
			fetch next from curCargosIniciales into @VariableNumero,@variablenumero3,@VariableTexto
	end
close curCargosIniciales
deallocate curCargosIniciales






SELECT * FROM #CLAVES

DROP TABLE #CLAVES
---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
