using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Data
{
    public class DatReporte
    {
        SqlConnection conexion = new SqlConnection(ConfigurationManager.ConnectionStrings["Axolotl"].ConnectionString);
        
        public DataTable Obtener()
        {
            DataTable dtsRes = new DataTable();
            String strSQL = $"SELECT CD_REPORTE, NB_REPORTE, TP_REPORTE, NB_RUTAGUARDADO, NB_PROCEDIMIENTO, NB_PARAM1, NB_TAREA, FH_ALTA FROM tblPDK_REPORTES ";
            try
            {
                SqlDataAdapter data = new SqlDataAdapter(strSQL, conexion);
                data.Fill(dtsRes);
                conexion.Close();
                return dtsRes;
            }
            catch (Exception)
            {
                conexion.Close();
                throw;
            }
        }
        public DataRow Obtener(int id)
        {
            DataTable dtsRes = new DataTable();
            String strSQL = $"SELECT CD_REPORTE, NB_REPORTE, TP_REPORTE, NB_RUTAGUARDADO, NB_PROCEDIMIENTO, NB_PARAM1, NB_TAREA, FH_ALTA FROM tblPDK_REPORTES  WHERE CD_REPORTE = {id}";
            try
            {
                SqlDataAdapter data = new SqlDataAdapter(strSQL, conexion);
                data.Fill(dtsRes);
                conexion.Close();
                return dtsRes.Rows[0];
            }
            catch (Exception)
            {
                conexion.Close();
                throw;
            }
        }

    }
}

