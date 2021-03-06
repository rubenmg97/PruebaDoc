USE [ProdeskNet_VWFS]
GO
ALTER PROCEDURE [dbo].[spTablaAmortizacionLeasingRTF]
		@idSolicitud INT = NULL	
AS
BEGIN

--IF EXISTS (SELECT @idSolicitud FROM PDK_TAB_SECCION_CERO WHERE PDK_ID_SECCCERO = @idSolicitud)
--BEGIN	

CREATE TABLE #CLAVES(ID INT IDENTITY(1,1),CLAVE CHAR(100), TEXTO TEXT)
	--*****************# DATOS 
DECLARE @MARCA VARCHAR(100) 
DECLARE @DISTRIBUIDOR VARCHAR(100)
DECLARE @NOCONTRATO VARCHAR(100) 
DECLARE @CAPITAL VARCHAR(100)
DECLARE @AMORTIZACION_TTA VARCHAR(MAX)
DECLARE @NOMBRE VARCHAR(100)
	--*****************# CONSULTAS
SET	@MARCA = 'AXOLOTL'
SET @DISTRIBUIDOR = 'AXOLOTL'
SET @NOCONTRATO = 'BAD01AXO' 
SET @CAPITAL = '10000000'
SET @AMORTIZACION_TTA = 'AS'
SET @NOMBRE = 'RMG'

	--*****************# Claves a Remplazar 
--ENCABEZADO
INSERT INTO #Claves VALUES ('[%MARCA%]',ISNULL(@MARCA, '  '))
INSERT INTO #Claves VALUES ('[%DISTRIBUIDOR%]',ISNULL(@DISTRIBUIDOR, '  '))
INSERT INTO #Claves VALUES ('[%NOCONTRATO%]',ISNULL(@NOCONTRATO, '  '))
--CUERPO
INSERT INTO #Claves VALUES ('[%CAPITAL%]',ISNULL(@CAPITAL, '  '))
--TABLA AMORTIZACION 
INSERT INTO #Claves VALUES ('[%AMORTIZACION-TT%]',ISNULL(@AMORTIZACION_TTA, '  '))
--FIRMAS
INSERT INTO #Claves VALUES ('[%NOMBRE%]',ISNULL(@NOMBRE,' '))

	--*****************# ACENTOS
DECLARE @MIN INT =0
DECLARE @MAX INT =0
DECLARE @texto AS VARCHAR(MAX)

SELECT @MAX=MAX(ID),@MIN=MIN(ID) FROM #CLAVES

WHILE @MIN <= @MAX
	BEGIN
		SELECT @texto=TEXTO FROM #CLAVES WHERE ID=@MIN

		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¡','\''a1')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¢','\''a2')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'£','\''a3')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¤','\''a4')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¥','\''a5')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¦','\''a6')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'§','\''a7')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¨','\''a8')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'©','\''a9')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ª','\''aa')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'«','\''ab')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¬','\''ac')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'®','\''ae')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¯','\''af')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'°','\''b0')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'±','\''b1')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'²','\''b2')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'³','\''b3')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'´','\''b4')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'µ','\''b5')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¶','\''b6')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'·','\''b7')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¸','\''b8')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¹','\''b9')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'º','\''ba')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'»','\''bb')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¼','\''bc')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'½','\''bd')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¾','\''be')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'¿','\''bf')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'À','\''c0')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Á','\''c1')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Â','\''c2')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ã','\''c3')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ä','\''c4')
          SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Å','\''c5')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Æ','\''c6')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ç','\''c7')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'È','\''c8')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'É','\''c9')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ê','\''ca')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ë','\''cb')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ì','\''cc')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Í','\''cd')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Î','\''ce')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ï','\''cf')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ð','\''d0')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ñ','\''d1')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ò','\''d2')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ó','\''d3')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ô','\''d4')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Õ','\''d5')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ö','\''d6')
          SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'×','\''d7')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ø','\''d8')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ù','\''d9')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ú','\''da')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Û','\''db')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ü','\''dc')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Ý','\''dd')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'Þ','\''de')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ß','\''df')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'à','\''e0')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'á','\''e1')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'â','\''e2')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ã','\''e3')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ä','\''e4')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'å','\''e5')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'æ','\''e6')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ç','\''e7')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'è','\''e8')
          SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'é','\''e9')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ê','\''ea')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ë','\''eb')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ì','\''ec')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'í','\''ed')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'î','\''ee')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ï','\''ef')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ð','\''f0')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ñ','\''f1')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ò','\''f2')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ó','\''f3')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ô','\''f4')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'õ','\''f5')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ö','\''f6')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'÷','\''f7')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ø','\''f8')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ù','\''f9')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ú','\''fa')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'û','\''fb')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ü','\''fc')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ý','\''fd')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'þ','\''fe')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'ÿ','\''ff')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'!','\''21')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'"','\''22')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'#','\''23')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'$','\''24')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'%','\''25')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'&','\''26')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'''','\''27')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'(','\''28')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,')','\''29')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'*','\''2a')
          SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'+','\''2b')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,',','\''2c')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'-','\''2d')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'.','\''2e')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'/','\''2f')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,':','\''3a')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,';','\''3b')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'<','\''3c')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'=','\''3d')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'>','\''3e')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'?','\''3f')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'@','\''40')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'[','\''5b')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'\','\''5c')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,']','\''5d')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'^','\''5e')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'_','\''5f')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'`','\''60')
          SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'{','\''7b')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'|','\''7c')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'}','\''7d')
		  SET @texto  = REPLACE(RTRIM(@texto) collate Modern_Spanish_CS_AS,'~','\''7e')
										  
		  UPDATE #CLAVES SET TEXTO=@texto WHERE ID=@MIN					  
																		  
		SET @MIN = @MIN + 1												  
	END																	  
																  
  SELECT * FROM #CLAVES													  
  DROP TABLE #CLAVES														  
																		  																		 																	
 END	
--END 