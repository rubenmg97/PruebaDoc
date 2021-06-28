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
    public class BusDocumento
    {
        DatDocumento data = new DatDocumento();

    public List<EntDocumento> Obtener()
    {
        List<EntDocumento> ls = new List<EntDocumento>();
        DataTable tabla = new DataTable();
        tabla = data.Obtener();
        foreach (DataRow fila in tabla.Rows)
        {
            EntDocumento machote = new EntDocumento();
            machote.Id = Convert.ToInt32(fila["FMT_FL_CVE"]);
            machote.Nombre = fila["FMT_DS_DESCRIPCION"].ToString();
            machote.Documento = fila["MatFMT_DS_MACHOTEerno"].ToString();

            ls.Add(machote);
        }
        return ls;
    }

    public EntDocumento Obtener(int id)
    {
        DataRow fila = data.Obtener(id);
        EntDocumento machote = new EntDocumento();
        machote.Id = Convert.ToInt32(fila["FMT_FL_CVE"]);
        machote.Nombre = fila["FMT_DS_DESCRIPCION"].ToString();
        machote.Documento = fila["MatFMT_DS_MACHOTEerno"].ToString();
        return machote;
    }

 }
}