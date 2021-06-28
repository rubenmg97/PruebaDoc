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
    public class DatKclave
    {
        SqlConnection conexion = new SqlConnection(ConfigurationManager.ConnectionStrings["Axolotl"].ConnectionString);

        public DataTable Obtner(int idDoc, int idSolicitud)
        {
            DataTable tabla = new DataTable();
            try
            {
                //SqlCommand comando = new SqlCommand("spManejaReportesRTF", conexion);

                SqlCommand comando = new SqlCommand("spTablaAmortizacionLeasingRTF", conexion);
                comando.CommandType = CommandType.StoredProcedure;
                //comando.Parameters.AddWithValue("@ID", idDoc);
                comando.Parameters.AddWithValue("@ID_SOLICITUD", idSolicitud);
                SqlDataAdapter data = new SqlDataAdapter(comando);
                data.Fill(tabla);
                return tabla;
            }
            catch
            {
                throw;
            }
        }

    }
}
