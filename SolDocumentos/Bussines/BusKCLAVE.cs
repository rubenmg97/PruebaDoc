using Data;
using Entity;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Bussines
{
    public class BusKclave
    {
        DatKclave data = new DatKclave();

    public List<EntKclave> Obtener(int idDoc, int idSolicitud)
    {
        List<EntKclave> ls = new List<EntKclave>();
        DataTable tabla = new DataTable();
        tabla = data.Obtner(idDoc, idSolicitud);

        try
        {
            foreach (DataRow fila in tabla.Rows)
            {
                EntKclave cve = new EntKclave();
                cve.Id = Convert.ToInt32(fila["CVE_FL_KCLAVE"]);
                cve.Clave = fila["CVE_DS_MACHOTE"].ToString();
                cve.Texto = fila["CVE_DS_RCONSULTA"].ToString();
                ls.Add(cve);
            }
            return ls;
        }
        catch (Exception)
        {
            throw;
        }
    }


}
}
