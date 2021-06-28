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
    public class DatDocumento
    {
        SqlConnection conexion = new SqlConnection(ConfigurationManager.ConnectionStrings["Axolotl"].ConnectionString);

        public DataTable Obtener()
        {
            DataTable dtsRes = new DataTable();
            String strSQL = $"SELECT FMT_FL_CVE, FMT_DS_DESCRIPCION, TOP_CL_CVE, FMT_DS_MACHOTE FROM CCTO_MACHOTE";
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
            String strSQL = $"SELECT FMT_FL_CVE, FMT_DS_DESCRIPCION, TOP_CL_CVE, FMT_DS_MACHOTE FROM CCTO_MACHOTE WHERE FMT_FL_CVE = {id}";
            
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
