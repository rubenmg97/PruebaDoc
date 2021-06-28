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
    public class HandlerBD
    {

        // CONSULTAS
        public DataTable QueryConsulta( string strSQL,String sConex)
        {
            DataTable dtsRes = new DataTable();
            SqlConnection conexion = new SqlConnection(ConfigurationManager.ConnectionStrings[sConex].ConnectionString);

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

        // Modificaciones
        public int QueryAlter(string strSQL,String sConex)
        {
            int dtsRes = 0;
            System.Data.SqlClient.SqlConnection conexion = new SqlConnection(ConfigurationManager.ConnectionStrings[sConex].ConnectionString);
            try
            {
                using (SqlCommand comando = new SqlCommand())
                {
                    comando.CommandText = strSQL;
                    comando.CommandType = CommandType.Text;
                    comando.Connection = conexion;

                    conexion.Open();
                    dtsRes = comando.ExecuteNonQuery();
                    conexion.Close();
                }
                return dtsRes;
            }
            catch
            {
                conexion.Close();
                throw;
            }
        }
    }
}
