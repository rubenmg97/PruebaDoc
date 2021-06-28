using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Data;
using EntityRTF;

namespace Machote
{
    class Program
    {
        public Errores objError { get; set; } = new Errores() { bError = false, uException = null };

        static void Main(string[] args)
        {
            String path = @"C:\Users\rmancilla\Documents\Visual Studio 2015\Projects\Machote\Machote\Machotes\VWFS.rtf";
            String dato = "DATA";
            String newDato = "RUBEN";
            String opcion = "Editar";//"Lectura"; //"Carga";

            int fmt_fl_machote = 1; int cst_fl_kconsulta = 1;
            try
            {
                //ManejaFormatos(path, opcion, fmt_fl_machote, cst_fl_kconsulta,dato,newDato);
                ModificacionArchivo(path);
            }
            catch (Exception ex)
            {
                Console.Clear();
                Console.WriteLine(ex.Message);
                Console.ReadKey();
            }
        }


        public static DataTable KCLAVE()
        {
            // Create new DataTable.
            DataTable KCLAVE = new DataTable();

            // Declare DataColumn and DataRow variables.
            DataColumn column;
            DataRow row;
            
            // Create new DataColumn, set DataType, ColumnName
            // and add to DataTable.
            column = new DataColumn();
            column.DataType = System.Type.GetType("System.Int32");
            column.ColumnName = "CVE_FL_KCLAVE";
            KCLAVE.Columns.Add(column);

            // Create second column.
            column = new DataColumn();
            column.DataType = Type.GetType("System.String");
            column.ColumnName = "CVE_DS_MACHOTE";
            KCLAVE.Columns.Add(column);

            // Create second column.
            column = new DataColumn();
            column.DataType = Type.GetType("System.String");
            column.ColumnName = "CVE_DS_RCONSULTA";
            KCLAVE.Columns.Add(column);


            //string[] arrMachote ={"[%NombreCliente%]", "[%rfcCliente%]", "[%DomicilioCliente%]", "[%PoblacionCliente%]", "[%telefonoCliente%]"};
            //string[] arrRespuesta = { "Ruben Mancilla", "MAGR970126HDFNRB09", "ECATEPEC", "111", "91124742" };

            //Prueba 
            String[] arrMachote = { "[%CotizacionId%]", "[%Vigencia%]", "[%Marca%]", "[%Precio%]", "[%SubMarca%]", "[%Plazo%]", "[%Version%]", "[%Iva%]", "[%Año%]", "[%Clasificacion%]", "[%Cantidad%]", "[%InicialTotal%]", "[%MenTotal%]", "[%ComApertura%]", "[%Seguro%]", "[%SerAdicional%]", "[%NomConcesoria%]", "[%TelInterior%]", "[%TelExterior%]", "[%ContactoNombre%]", "[%TelCel%]", "[%Email%]", "[%1RenMenIVA%]", "[%1RentMenSegServicios%]", "[%AntRenPorcentaje%]", "[%AntRentMonto%]", "[%ApeComision%]", "[%SeguroContado%]", "[%PagoInicialTot%]", "[%RenMensual%]", "[%MensualidadRMSS%]", "[%PagoMenIva%]", "[%CAT%]", "[%TipoSeguroAut%]", "[%GarantiaExtendida%]", "[%ServicioMantenimiento%]", "[%TotalFinanciarIva%]" };
            String[] arrRespuesta = { "7329", "28/02/2021", "AUDI", "$500,000.00", "Q7", "24 meses", " 2.0T 252HP Dynamic TIP", "19.3", "2017", "USADO", "1", "25,023.59", "15,023.59", "10,000.00", "0.00", "13,541.00", " AUDI CENTER INTERLOMAS", "5552340888", " ", "LAURA AKEMI ARISHITA", " ", " laura.akemi.arishita.calderon@vwfs.com", "14,342.20", "681.40", "0.00", "0.00", "10,000.00", "0.00", "25,023.59", "14,342.20", "681.40", "15,023.59", "19.3", "Programa Único Contado", "7,699.00", "5,842.00", "13,541.00" };



            // Create new DataRow objects and add to DataTable.
            for (int i = 0; i < 35; i++)
            {
                row = KCLAVE.NewRow();
                row["CVE_FL_KCLAVE"] = i;
                row["CVE_DS_MACHOTE"] = arrMachote[i] ;
                row["CVE_DS_RCONSULTA"] = arrRespuesta[i] ;
                KCLAVE.Rows.Add(row);
            }

            // Set to DataGrid.DataSource property to the table.
            //dataGrid1.DataSource = KCLAVE;
            return KCLAVE;
        }

        public static void ModificacionArchivo(String path)
        {
            DataTable CLAVE = KCLAVE();
            try
            { 
                foreach (DataRow fila in CLAVE.Rows)
                {
                    EntKCLAVE cve = new EntKCLAVE();

                    cve.cve_fl_kclave = Convert.ToInt32(fila["CVE_FL_KCLAVE"]);
                    cve.cve_ds_machote = fila["CVE_DS_MACHOTE"].ToString();
                    cve.cve_ds_rconsulta = fila["CVE_DS_RCONSULTA"].ToString();
                    EditarArchivo(path,cve.cve_ds_machote, cve.cve_ds_rconsulta);
                }
           }
            catch (Exception)
            {
                throw new ApplicationException("Error al Modificar Documento");
            }
        }


        //****************
        //Metodos Basicos
        //****************
        public static void ManejaFormatos (String path,String opcion, int fmt_fl_machote, int cst_fl_kconsulta, String dato, String newDato)
        {
            try
            {
                switch (opcion)
                {
                    case "Carga":
                        CargaArchivo(path, dato);
                        break;
                    case "Lectura":
                        LecturaArchivo(path);
                        break;
                    case "Editar":
                        EditarArchivo(path,dato,newDato);
                        break;
                    case "Delete":
                        DeleteArchivo(path);
                        break;
                    default:
                        throw new ApplicationException("Error Opcion de Formato invalida");
          
                }

            }
            catch (Exception ex)
            {
                Console.Clear();
                Console.WriteLine(ex.Message);
                Console.ReadKey();
                //objError.bError = true;
                //objError.uException = ex;
            }
        }
        

        public static void LecturaArchivo(String path)
        {
            try
            {
                //Lectura
                String contenido = String.Empty;
            using (StreamReader oSr = File.OpenText(path))
            {
                String aux = "";
                //Lectura lineaxlinea
                while ((aux = oSr.ReadLine()) != null)
                {
                    contenido += aux;
                }
            }
            Console.Clear();
            Console.WriteLine(contenido);
            Console.ReadKey();
            }
            catch (Exception)
            {
                throw new ApplicationException("Error al Leer Documento");
            }
          
        }

        public static void CargaArchivo(String path,String data)
        {
            try
            {
            //Escritura
            using (FileStream oFs = File.Create(path))
            {
                Byte[] informacion = new UTF8Encoding(true).GetBytes(data);
                oFs.Write(informacion, 0, informacion.Length);
            }
            }
            catch (Exception)
            {
                throw new ApplicationException("Error al Crear Documento");
            }
        }

        public static void EditarArchivo(String path,String match, String newValue)
        {
            try
            {
                string text = File.ReadAllText(path);
                text = text.Replace(match, newValue);
                File.WriteAllText(path, text);
            }
            catch (Exception)
            {
                throw new ApplicationException("Error al Editar Documento");
            }
        }

        public static void DeleteArchivo(String path)
        {
            try
            {            
                //Si existe archivo
                if (File.Exists(path))
                {
                    //Elimina
                    DeleteArchivo(path);
                }
            }
            catch (Exception ex)
            {
                throw new ApplicationException("Error al Eliminar Documento");
            }
        }

        public class Errores
        {
            public bool bError { get; set; }
            public Exception uException { get; set; }
            public string sMensaje { get; set; }
        }

    }
}





